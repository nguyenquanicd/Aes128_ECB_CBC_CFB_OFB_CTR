//-----------------------------------------------------------
// Function:	AES-128 encrypt/cipher TOP module
//            Modes: ECB, CBC, CFB (1/2/4/8/16/32/64/128-bit segment), OFB, CTR
//-----------------------------------------------------------
// Author: Nguyen Hung Quan
// Website: http://nguyenquanicd.blogspot.com/
//-----------------------------------------------------------
// History:
// 2019.10.22 - Simple test of ECB mode is PASS
// 2019.10.23
//     - Simple test of CBC mode is PASS
//     - Simple test of CFB mode is PASS
//     - Simple test of OFB mode is PASS
//     - Simple test of CTR mode is PASS
// 2026.10.10 - Review + formal + golden-model regression. Changes:
//     [BUG]  CFB decipher was wrong from the 2nd block on: the cipher engine
//            input was shifted twice and took its low bits from the never-
//            initialised end_reg. start_reg already holds the shifted register.
//     [BUG]  mode_reg was loaded only when chain_en=1, so a chain_en=0 operation
//            silently used the mode of the previous stream. It is now loaded on
//            every first block (chain_en=0 => every block is a first block).
//     [BUG]  start_reg was reloaded with data_in on every clock while
//            first_block=1, destroying the IV of a chain_en=0 CBC decipher.
//     [FIX]  first_block no longer depends on chain_en being raised in the same
//            cycle as the start pulse (chain_en may rise earlier).
//     [FIX]  data_in and segment_len are captured at the start pulse. The host
//            no longer has to hold them until ready. end_reg is updated only at
//            the end of an operation (it used to follow the live data_in).
//     [NEW]  A start pulse while ready=0 is ignored (it used to corrupt the
//            running operation) and err_busy pulses for one cycle.
//     [NEW]  Illegal configuration (mode>4, CFB segment_len>7, cipher_en and
//            decipher_en together) is rejected without starting; err_cfg pulses.
//     [NEW]  CFB: the (128-segment) low bits of data_out are 0 (they used to
//            carry raw AES output bits).
//     RTL functions moved to aes128_pkg (see aes128_pkg.sv).
//-----------------------------------------------------------
module aes128 (
  //input
  input clk,
  input rst_n,
  input cipher_en,
  input decipher_en,
  input chain_en,
  input [127:0] data_in,
  input [127:0] key,
  input [3:0]   mode,
  input [127:0] init_vector,
  input [3:0]  segment_len,
  //output
  output logic [127:0] data_out,
  output logic ready,
  output logic err_busy,
  output logic err_cfg
  );
  //-------------------------------------------------
  // Parameters
  //-------------------------------------------------
  //AES crypto modes
  localparam AES128ECB = 4'b0000;
  localparam AES128CBC = 4'b0001;
  localparam AES128CFB = 4'b0010;
  localparam AES128OFB = 4'b0011;
  localparam AES128CTR = 4'b0100;
  //AES CFB modes
  localparam CFB1b   = 4'd0;
  localparam CFB2b   = 4'd1;
  localparam CFB4b   = 4'd2;
  localparam CFB8b   = 4'd3;
  localparam CFB16b  = 4'd4;
  localparam CFB32b  = 4'd5;
  localparam CFB64b  = 4'd6;
  localparam CFB128b = 4'd7;
  //-------------------------------------------------
  // Internal signals
  //-------------------------------------------------
  logic cipher_ready;
  logic decipher_ready;
  logic [127:0] cipher_out;
  logic [127:0] decipher_out;
  logic [127:0] cipher_key10;
  logic start_req;
  logic cfg_bad;
  logic start_process;     //accepted start pulse
  logic stream_active;
  logic first_block;
  logic [3:0] mode_reg;
  logic [3:0] mode_req;
  logic [3:0] mode_e;
  logic [127:0] data_r;
  logic [3:0]   seg_r;
  logic [127:0] data_e;
  logic decipher_mode;
  logic [127:0] start_reg;
  logic [127:0] end_reg;
  logic [127:0] cipher_start_in;
  logic [127:0] decipher_start_in;
  logic [127:0] cipher_next_in;
  logic [127:0] decipher_next_in;
  logic [127:0] decipher_input_block;
  logic [127:0] cipher_input_block;
  logic [127:0] cfb_seg_mask;
  logic [127:0] c_cfb_out;
  logic [127:0] c_ofb_ctr_out;
  logic [127:0] d_cbc_out;
  logic [127:0] cout;
  logic [127:0] dout;
  logic cipher_ready_dly;
  logic decipher_ready_dly;
  logic end_cipher;
  logic end_decipher;
  logic start_decipher;
  logic set_ready;
  //-------------------------------------------------
  // Start request, acceptance and configuration check
  //-------------------------------------------------
  assign start_req = cipher_en | decipher_en;
  //The mode input applies only to the first block of a stream
  assign mode_req  = first_block? mode[3:0]: mode_reg[3:0];
  assign cfg_bad   = (cipher_en & decipher_en)
                   | (mode_req[3:0] > AES128CTR)
                   | ((mode_req[3:0] == AES128CFB) & (segment_len[3:0] > CFB128b));
  assign start_process = start_req & ready & ~cfg_bad;
  //Error flags (1-cycle pulses)
  always_ff @ (posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      err_busy <= 1'b0;
      err_cfg  <= 1'b0;
    end
    else begin
      err_busy <= start_req & ~ready;
      err_cfg  <= start_req &  ready & cfg_bad;
    end
  end
  //-------------------------------------------------
  // Position of a block in a data stream.
  // chain_en=1 : the first accepted start after chain_en rose is the first
  //              block, all following blocks continue the stream.
  // chain_en=0 : every block is a first block (single-shot operation),
  //              even when the previous operation belonged to a stream.
  // chain_en must be 1 on the start clock of every block of a stream and
  // must be 0 for at least one clock between two streams.
  //-------------------------------------------------
  always_ff @ (posedge clk, negedge rst_n) begin
    if (~rst_n)
      stream_active <= 1'b0;
    else if (~chain_en)
      stream_active <= 1'b0;
    else if (start_process)
      stream_active <= 1'b1;
  end
  assign first_block = ~stream_active | ~chain_en;
  //-------------------------------------------------
  // Crypt MODE register (loaded on every first block)
  //-------------------------------------------------
  always_ff @ (posedge clk, negedge rst_n) begin
    if (~rst_n)
      mode_reg[3:0] <= 4'b0000;
    else if (start_process & first_block)
      mode_reg[3:0] <= mode[3:0];
  end
  //Effective mode: the mode input at the start edge of a first block,
  //otherwise the stored mode
  assign mode_e[3:0] = (start_process & first_block)? mode[3:0]: mode_reg[3:0];
  //-------------------------------------------------
  // Capture of data_in and segment_len at the start pulse, so the host does
  // not need to hold them until ready.
  //   data_e : live data_in on the start cycle, the captured value afterwards
  //            (ECB/CBC decipher consumes it ~11 clocks after the start)
  //   seg_r  : captured segment_len, used when the operation ends
  //   The start-cycle logic uses segment_len directly (it is only sampled there).
  //-------------------------------------------------
  always_ff @ (posedge clk) begin
    if (start_process) begin
      data_r[127:0] <= data_in[127:0];
      seg_r[3:0]    <= segment_len[3:0];
    end
  end
  assign data_e[127:0] = start_process? data_in[127:0]: data_r[127:0];
  //-------------------------------------------------
  // Crypt process
  //-------------------------------------------------
  always_ff @ (posedge clk, negedge rst_n) begin
    if (~rst_n)
      decipher_mode <= 1'b0;
    else if (start_process)
      decipher_mode <= decipher_en;
  end
  //-------------------------------------------------
  // Start Decipher after round key 10 is calculated
  //-------------------------------------------------
  always_ff @ (posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      cipher_ready_dly   <= 1'b1;
      decipher_ready_dly <= 1'b1;
    end
    else begin
      cipher_ready_dly   <= cipher_ready;
      decipher_ready_dly <= decipher_ready;
    end
  end
  assign end_cipher = ~cipher_ready_dly & cipher_ready;
  assign end_decipher   = ~decipher_ready_dly & decipher_ready;
  always_comb begin
    case (mode_reg[3:0])
      AES128ECB, AES128CBC: start_decipher = end_cipher & decipher_mode;
      default: start_decipher = 1'b0;
    endcase
  end
  //-------------------------------------------------
  // START register
  //   CFB    : the shift register that precedes the current segment
  //   CBC dec: the previous ciphertext block (IV for the first block)
  // It is updated only at an accepted start, and at the end of a CBC decipher.
  //-------------------------------------------------
  always_ff @ (posedge clk) begin
    if (start_process) begin
      if (first_block) begin
        if (decipher_en)
          start_reg[127:0] <= decipher_start_in[127:0];
        else
          start_reg[127:0] <= cipher_start_in[127:0];
      end
      else begin
        if (decipher_en)
          start_reg[127:0] <= decipher_next_in[127:0];
        else
          start_reg[127:0] <= cipher_next_in[127:0];
      end
    end
    else if (end_decipher & (mode_reg[3:0] == AES128CBC)) begin
      //The ciphertext just consumed becomes the "previous ciphertext"
      start_reg[127:0] <= data_r[127:0];
    end
  end
  //First block, cipher direction
  always_comb begin
    case (mode_e[3:0])
      AES128CFB: cipher_start_in[127:0] = init_vector[127:0];
      default:   cipher_start_in[127:0] = start_reg[127:0];
    endcase
  end
  //First block, decipher direction
  always_comb begin
    case (mode_e[3:0])
      AES128CBC: decipher_start_in[127:0] = init_vector[127:0];
      AES128CFB: begin
        case (segment_len[3:0])
          CFB1b:   decipher_start_in[127:0] = {init_vector[126:0], data_e[127]};
          CFB2b:   decipher_start_in[127:0] = {init_vector[125:0], data_e[127:126]};
          CFB4b:   decipher_start_in[127:0] = {init_vector[123:0], data_e[127:124]};
          CFB8b:   decipher_start_in[127:0] = {init_vector[119:0], data_e[127:120]};
          CFB16b:  decipher_start_in[127:0] = {init_vector[111:0], data_e[127:112]};
          CFB32b:  decipher_start_in[127:0] = {init_vector[95:0], data_e[127:96]};
          CFB64b:  decipher_start_in[127:0] = {init_vector[63:0], data_e[127:64]};
          default: decipher_start_in[127:0] = data_e[127:0];   //CFB128b
        endcase
      end
      default: decipher_start_in[127:0] = start_reg[127:0];
    endcase
  end
  //Next blocks, cipher direction: CFB keeps the input block of this segment
  always_comb begin
    case (mode_e[3:0])
      AES128CFB: cipher_next_in[127:0] = cipher_input_block[127:0];
      default:   cipher_next_in[127:0] = start_reg[127:0];
    endcase
  end
  //Next blocks, decipher direction: CFB shifts the received ciphertext segment in
  always_comb begin
    case (mode_e[3:0])
      AES128CFB: begin
        case (segment_len[3:0])
          CFB1b:   decipher_next_in[127:0] = {start_reg[126:0], data_e[127]};
          CFB2b:   decipher_next_in[127:0] = {start_reg[125:0], data_e[127:126]};
          CFB4b:   decipher_next_in[127:0] = {start_reg[123:0], data_e[127:124]};
          CFB8b:   decipher_next_in[127:0] = {start_reg[119:0], data_e[127:120]};
          CFB16b:  decipher_next_in[127:0] = {start_reg[111:0], data_e[127:112]};
          CFB32b:  decipher_next_in[127:0] = {start_reg[95:0], data_e[127:96]};
          CFB64b:  decipher_next_in[127:0] = {start_reg[63:0], data_e[127:64]};
          default: decipher_next_in[127:0] = data_e[127:0];    //CFB128b
        endcase
      end
      default: decipher_next_in[127:0] = start_reg[127:0];
    endcase
  end
  //-------------------------------------------------
  // END register stores the END values of a process
  // because it is used to the next step.
  // It is updated only when the cipher engine finishes.
  //   CBC cipher : the ciphertext block
  //   CFB cipher : data ^ AES output (its top bits are the ciphertext segment)
  //   OFB        : the AES output block (cipher and decipher)
  //-------------------------------------------------
  always_ff @ (posedge clk) begin
    if (end_cipher) begin
      case (mode_reg[3:0])
        AES128CBC: if (~decipher_mode) end_reg[127:0] <= cipher_out[127:0];
        AES128CFB: if (~decipher_mode) end_reg[127:0] <= c_ofb_ctr_out[127:0];
        AES128OFB: end_reg[127:0] <= cipher_out[127:0];
        default: ;
      endcase
    end
  end
  //-------------------------------------------------
  // Input Block of the cipher engine (sampled at the start pulse)
  //-------------------------------------------------
  always_comb begin
    if (first_block) begin
      case (mode_e[3:0])
        AES128ECB: cipher_input_block[127:0] = data_e[127:0];
        AES128CBC: cipher_input_block[127:0] = data_e[127:0] ^ init_vector[127:0];
        default:   cipher_input_block[127:0] = init_vector[127:0];
      endcase
    end
    else begin
      case (mode_e[3:0])
        AES128CBC: cipher_input_block[127:0] = data_e[127:0] ^ end_reg[127:0];
        AES128CFB: begin
          if (decipher_en)
            //start_reg already holds the register shifted with the previous ciphertext
            cipher_input_block[127:0] = start_reg[127:0];
          else
            case (segment_len[3:0])
              CFB1b:   cipher_input_block[127:0] = {start_reg[126:0], end_reg[127]};
              CFB2b:   cipher_input_block[127:0] = {start_reg[125:0], end_reg[127:126]};
              CFB4b:   cipher_input_block[127:0] = {start_reg[123:0], end_reg[127:124]};
              CFB8b:   cipher_input_block[127:0] = {start_reg[119:0], end_reg[127:120]};
              CFB16b:  cipher_input_block[127:0] = {start_reg[111:0], end_reg[127:112]};
              CFB32b:  cipher_input_block[127:0] = {start_reg[95:0], end_reg[127:96]};
              CFB64b:  cipher_input_block[127:0] = {start_reg[63:0], end_reg[127:64]};
              default: cipher_input_block[127:0] = end_reg[127:0];   //CFB128b
            endcase
        end
        AES128OFB: cipher_input_block[127:0] = end_reg[127:0];
        AES128CTR: cipher_input_block[127:0] = init_vector[127:0];
        default:   cipher_input_block[127:0] = data_e[127:0];
      endcase
    end
  end
  //Input block of the decipher engine (ECB/CBC decipher only): the ciphertext,
  //sampled when the engine starts (after round key 10 is ready)
  assign decipher_input_block[127:0] = data_e[127:0];
  //-------------------------------------------------
  // Data output
  //-------------------------------------------------
  always_ff @ (posedge clk) begin
    if (decipher_mode) begin
      case (mode_reg[3:0])
        AES128ECB, AES128CBC: begin
          if (end_decipher)
            data_out[127:0] <= dout;
        end
        default: begin
          if (end_cipher)
            data_out[127:0] <= cout;
        end
      endcase
    end
    else if (end_cipher) begin
      data_out[127:0] <= cout;
    end
  end
  //Cipher (the CFB formula is the same for the cipher and decipher direction)
  always_comb begin
    case (seg_r[3:0])
      CFB1b:   cfb_seg_mask[127:0] = {1'd1,   127'd0};
      CFB2b:   cfb_seg_mask[127:0] = {2'd3,   126'd0};
      CFB4b:   cfb_seg_mask[127:0] = {4'hf,   124'd0};
      CFB8b:   cfb_seg_mask[127:0] = {8'hff,  120'd0};
      CFB16b:  cfb_seg_mask[127:0] = {16'hffff, 112'd0};
      CFB32b:  cfb_seg_mask[127:0] = {32'hffff_ffff, 96'd0};
      CFB64b:  cfb_seg_mask[127:0] = {64'hffff_ffff_ffff_ffff, 64'd0};
      default: cfb_seg_mask[127:0] = {128{1'b1}};
    endcase
  end
  assign c_cfb_out[127:0]     = (data_r[127:0] ^ cipher_out[127:0]) & cfb_seg_mask[127:0];
  assign c_ofb_ctr_out[127:0] = data_r[127:0] ^ cipher_out[127:0];
  //
  always_comb begin
    case (mode_reg[3:0])
      AES128CFB: cout[127:0] = c_cfb_out[127:0];
      AES128OFB, AES128CTR: cout[127:0] = c_ofb_ctr_out[127:0];
      default: cout[127:0] = cipher_out[127:0];
    endcase
  end
  //Decipher (ECB/CBC only, the other modes use the cipher engine)
  assign d_cbc_out[127:0] = start_reg[127:0] ^ decipher_out[127:0];
  always_comb begin
    case (mode_reg[3:0])
      AES128CBC: dout[127:0] = d_cbc_out[127:0];
      default:   dout[127:0] = decipher_out[127:0];
    endcase
  end
  //-------------------------------------------------
  // Ready signal
  //-------------------------------------------------
  always_comb begin
    if (decipher_mode) begin
      case (mode_reg[3:0])
        AES128ECB: set_ready = end_decipher;
        AES128CBC: set_ready = end_decipher;
        default: set_ready = end_cipher;
      endcase
    end
    else begin
      set_ready = end_cipher;
    end
  end
  always_ff @ (posedge clk, negedge rst_n) begin
    if (~rst_n)
      ready <= 1'b1;
    else if (start_process)
      ready <= 1'b0;
    else if (set_ready)
      ready <= 1'b1;
  end
  //Cipher core
  aes128_cipher_top cipher (
    //input
    .clk_sys(clk),
    .rst_n(rst_n),
    .cipher_key(key[127:0]),
    .plain_text(cipher_input_block[127:0]),
    .cipher_en(start_process),
    //output
    .cipher_text(cipher_out[127:0]),
    .cipher_ready(cipher_ready),
    .cipher_key10(cipher_key10[127:0])
    );
  //Decipher core
  aes128_cipher_inv_top decipher (
    //input
    .clk_sys(clk),
    .rst_n(rst_n),
    .cipher_text(decipher_input_block[127:0]),
    .round_key_10(cipher_key10[127:0]),
    .decipher_en(start_decipher),
    //output
    .plain_text(decipher_out[127:0]),
    .decipher_ready(decipher_ready)
    );

endmodule
