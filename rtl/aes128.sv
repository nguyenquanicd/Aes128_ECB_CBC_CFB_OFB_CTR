//-----------------------------------------------------------
// Function:	AES-128 encrypt/cipher TOP module
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
  output logic ready
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
  logic start_process;
  logic load_first_info;
  logic first_block;
  logic [3:0] mode_reg;
  logic decipher_mode;
  logic [127:0] start_reg;
  logic [127:0] cipher_start_in;
  logic [127:0] decipher_start_in;
  logic [127:0] cipher_next_in;
  logic [127:0] decipher_next_in;
  logic [127:0] end_reg;
  logic [127:0] cipher_end_reg;
  logic [127:0] decipher_end_reg;
  logic [127:0] decipher_input_block;
  logic [127:0] cipher_input_block;
  logic [127:0] output_block;
  logic [127:0] c_cfb_mask;
  logic [127:0] c_cfb_out;
  logic [127:0] c_ofb_ctr_out;
  logic [127:0] d_cbc_out;
  logic [127:0] d_cfb_ofb_ctr_out;
  logic [127:0] cout;
  logic [127:0] dout;
  logic cipher_ready_dly;
  logic decipher_ready_dly;
  logic end_cipher;
  logic end_decipher;
  logic start_decipher;
  logic set_ready;
  logic update_end_reg;
  //-------------------------------------------------
  // Store control information
  //-------------------------------------------------
  assign start_process   = cipher_en | decipher_en;
  assign load_first_info = start_process & chain_en & first_block;
  //-------------------------------------------------
  // Position of block in a data stream
  //-------------------------------------------------
  always_ff @ (posedge clk, negedge rst_n) begin
    if (~rst_n)
      first_block <= 1'b1;
    else
      first_block <= ~chain_en;
  end
  //-------------------------------------------------
  // Crypt MODE register
  //-------------------------------------------------
  always_ff @ (posedge clk, negedge rst_n) begin
    if (~rst_n)
      mode_reg[3:0] <= 4'b0000;
    else if (load_first_info)
      mode_reg[3:0] <= mode[3:0];
  end
  //-------------------------------------------------
  // Crypt process
  //-------------------------------------------------
  always_ff @ (posedge clk, negedge rst_n) begin
    if (~rst_n)
      decipher_mode <= 1'b0;
    else if (cipher_en)
      decipher_mode <= 1'b0;
    else if (decipher_en)
      decipher_mode <= 1'b1;
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
  // START register stores the START values of a process
  // because it is used to the next step
  //-------------------------------------------------
  always_ff @ (posedge clk) begin
    if (first_block) begin
      if (decipher_en)
        start_reg[127:0] <= decipher_start_in[127:0];
      else
        start_reg[127:0] <= cipher_start_in[127:0];
    end
    else begin
      if (decipher_mode)
        start_reg[127:0] <= decipher_next_in[127:0];
      else if (cipher_en)
        start_reg[127:0] <= cipher_next_in[127:0];
    end
  end
  //
  always_comb begin
    case (mode[3:0])
      AES128CFB: cipher_start_in[127:0] = init_vector[127:0];
      default: cipher_start_in[127:0] = data_in[127:0];
    endcase
  end
  //
  always_comb begin
    case (mode[3:0])
      AES128CBC: decipher_start_in[127:0] = init_vector[127:0];
      AES128CFB: begin
        case (segment_len[3:0])
          CFB1b:   decipher_start_in[127:0] = {init_vector[126:0], data_in[127]};
          CFB2b:   decipher_start_in[127:0] = {init_vector[125:0], data_in[127:126]};
          CFB4b:   decipher_start_in[127:0] = {init_vector[123:0], data_in[127:124]};
          CFB8b:   decipher_start_in[127:0] = {init_vector[119:0], data_in[127:120]};
          CFB16b:  decipher_start_in[127:0] = {init_vector[111:0], data_in[127:112]};
          CFB32b:  decipher_start_in[127:0] = {init_vector[95:0], data_in[127:96]};
          CFB64b:  decipher_start_in[127:0] = {init_vector[63:0], data_in[127:64]};
          CFB128b: decipher_start_in[127:0] = data_in[127:0];
          default: decipher_start_in[127:0] = data_in[127:0];
        endcase
      end
      default: decipher_start_in[127:0] = data_in[127:0];
    endcase
  end
  //
  always_comb begin
    case (mode_reg[3:0])
      AES128CFB: cipher_next_in[127:0] = cipher_input_block[127:0];
      default:   cipher_next_in[127:0] = data_in[127:0];
    endcase
  end
  //
  always_comb begin
    case (mode_reg[3:0])
      AES128CBC: begin
        if (end_decipher)
          decipher_next_in[127:0] = data_in[127:0];
        else
          decipher_next_in[127:0] = start_reg[127:0];
      end
      AES128CFB: begin
        if (decipher_en)
          case (segment_len[3:0])
            CFB1b:   decipher_next_in[127:0] = {start_reg[126:0], data_in[127]};
            CFB2b:   decipher_next_in[127:0] = {start_reg[125:0], data_in[127:126]};
            CFB4b:   decipher_next_in[127:0] = {start_reg[123:0], data_in[127:124]};
            CFB8b:   decipher_next_in[127:0] = {start_reg[119:0], data_in[127:120]};
            CFB16b:  decipher_next_in[127:0] = {start_reg[111:0], data_in[127:112]};
            CFB32b:  decipher_next_in[127:0] = {start_reg[95:0], data_in[127:96]};
            CFB64b:  decipher_next_in[127:0] = {start_reg[63:0], data_in[127:64]};
            CFB128b: decipher_next_in[127:0] = data_in[127:0];
            default: decipher_next_in[127:0] = start_reg[127:0];
          endcase
        else
          decipher_next_in[127:0] = start_reg[127:0];
      end
      default: decipher_next_in[127:0] = start_reg[127:0];
    endcase
  end
  //-------------------------------------------------
  // END register stores the END values of a process
  // because it is used to the next step
  //-------------------------------------------------
  assign update_end_reg = decipher_mode? decipher_ready: cipher_ready;
  always_ff @ (posedge clk) begin
    if (update_end_reg) begin
      if (decipher_mode)
        end_reg[127:0] <= decipher_end_reg[127:0];
      else
        end_reg[127:0] <= cipher_end_reg[127:0];
    end
  end
  always_comb begin
    case (mode_reg[3:0])
      AES128CBC: cipher_end_reg[127:0] = output_block[127:0];
      AES128CFB: cipher_end_reg[127:0] = c_ofb_ctr_out[127:0];
      AES128OFB: cipher_end_reg[127:0] = output_block[127:0];
      default: cipher_end_reg[127:0] = end_reg[127:0];
    endcase
  end
  always_comb begin
    case (mode_reg[3:0])
      AES128OFB: decipher_end_reg[127:0] = output_block[127:0];
      default: decipher_end_reg[127:0] = end_reg[127:0];
    endcase
  end
  //-------------------------------------------------
  // Input Block
  //-------------------------------------------------
  always_comb begin
    if (first_block) begin
      case (mode[3:0])
        AES128ECB: decipher_input_block[127:0] = data_in[127:0];
        AES128CBC: decipher_input_block[127:0] = data_in[127:0];
        default: decipher_input_block[127:0] = init_vector[127:0];
      endcase
    end
    else begin
      case (mode_reg[3:0])
        AES128CBC: decipher_input_block[127:0] = data_in[127:0];
        AES128CFB: decipher_input_block[127:0] = start_reg[127:0];
        AES128OFB: decipher_input_block[127:0] = end_reg[127:0];
        AES128CTR: decipher_input_block[127:0] = init_vector[127:0];
        default: decipher_input_block[127:0] = data_in[127:0];
      endcase
    end
  end
  //
  always_comb begin
    if (first_block) begin
      case (mode[3:0])
        AES128ECB: cipher_input_block[127:0] = data_in[127:0];
        AES128CBC: cipher_input_block[127:0] = data_in[127:0] ^ init_vector[127:0];
        default: cipher_input_block[127:0] = init_vector[127:0];
      endcase
    end
    else begin
      case (mode_reg[3:0])
        AES128CBC: cipher_input_block[127:0] = data_in[127:0] ^ end_reg[127:0];
        AES128CFB: begin
          case (segment_len[3:0])
            CFB1b:   cipher_input_block[127:0] = {start_reg[126:0], end_reg[127]};
            CFB2b:   cipher_input_block[127:0] = {start_reg[125:0], end_reg[127:126]};
            CFB4b:   cipher_input_block[127:0] = {start_reg[123:0], end_reg[127:124]};
            CFB8b:   cipher_input_block[127:0] = {start_reg[119:0], end_reg[127:120]};
            CFB16b:  cipher_input_block[127:0] = {start_reg[111:0], end_reg[127:112]};
            CFB32b:  cipher_input_block[127:0] = {start_reg[95:0], end_reg[127:96]};
            CFB64b:  cipher_input_block[127:0] = {start_reg[63:0], end_reg[127:64]};
            CFB128b: cipher_input_block[127:0] = end_reg[127:0];
            default: cipher_input_block[127:0] = end_reg[127:0];
          endcase
        end
        AES128OFB: cipher_input_block[127:0] = end_reg[127:0];
        AES128CTR: cipher_input_block[127:0] = init_vector[127:0];
        default: cipher_input_block[127:0] = data_in[127:0];
      endcase
    end
  end
  //
  //always_comb begin
  //  if (first_block) begin
  //    if (decipher_en)
  //      case (mode[3:0])
  //        AES128ECB: input_block[127:0] = data_in[127:0];
  //        AES128CBC: input_block[127:0] = data_in[127:0];
  //        default: input_block[127:0] = init_vector[127:0];
  //      endcase
  //    else
  //      case (mode[3:0])
  //        AES128ECB: input_block[127:0] = data_in[127:0];
  //        AES128CBC: input_block[127:0] = data_in[127:0] ^ init_vector[127:0];
  //        default: input_block[127:0] = init_vector[127:0];
  //      endcase
  //  end
  //  else begin
  //    if (decipher_mode)
  //      case (mode_reg[3:0])
  //        AES128CBC: input_block[127:0] = data_in[127:0];
  //        AES128CFB: input_block[127:0] = start_reg[127:0];
  //        AES128OFB: input_block[127:0] = end_reg[127:0];
  //        AES128CTR: input_block[127:0] = init_vector[127:0];
  //        default: input_block[127:0] = data_in[127:0];
  //      endcase
  //    else
  //      case (mode_reg[3:0])
  //        AES128CBC: input_block[127:0] = data_in[127:0] ^ end_reg[127:0];
  //        AES128CFB: begin
  //          case (segment_len[3:0])
  //            CFB1b:   input_block[127:0] = {start_reg[126:0], end_reg[127]};
  //            CFB2b:   input_block[127:0] = {start_reg[125:0], end_reg[127:126]};
  //            CFB4b:   input_block[127:0] = {start_reg[123:0], end_reg[127:124]};
  //            CFB8b:   input_block[127:0] = {start_reg[119:0], end_reg[127:120]};
  //            CFB16b:  input_block[127:0] = {start_reg[111:0], end_reg[127:112]};
  //            CFB32b:  input_block[127:0] = {start_reg[95:0], end_reg[127:96]};
  //            CFB64b:  input_block[127:0] = {start_reg[63:0], end_reg[127:64]};
  //            CFB128b: input_block[127:0] = end_reg[127:0];
  //            default: input_block[127:0] = end_reg[127:0];
  //          endcase
  //        end
  //        AES128OFB: input_block[127:0] = end_reg[127:0];
  //        AES128CTR: input_block[127:0] = init_vector[127:0];
  //        default: input_block[127:0] = data_in[127:0];
  //      endcase
  //  end
  //end
  //-------------------------------------------------
  // Output Block
  //-------------------------------------------------
  always_comb begin
    if (decipher_mode) begin
      case (mode_reg[3:0])
        AES128ECB: output_block[127:0] = decipher_out;
        AES128CBC: output_block[127:0] = decipher_out;
        default: output_block[127:0] = cipher_out;
      endcase
    end
    else begin
      output_block[127:0] = cipher_out;
    end
  end
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
  //Cipher
  always_comb begin
    case (segment_len[3:0])
      CFB1b:   c_cfb_mask[127:0] = {data_in[127], 127'd0};
      CFB2b:   c_cfb_mask[127:0] = {data_in[127:126], 126'd0};
      CFB4b:   c_cfb_mask[127:0] = {data_in[127:124], 124'd0};
      CFB8b:   c_cfb_mask[127:0] = {data_in[127:120], 120'd0};
      CFB16b:  c_cfb_mask[127:0] = {data_in[127:112], 112'd0};
      CFB32b:  c_cfb_mask[127:0] = {data_in[127:96], 96'd0};
      CFB64b:  c_cfb_mask[127:0] = {data_in[127:64], 64'd0};
      CFB128b: c_cfb_mask[127:0] = data_in[127:0];
      default: c_cfb_mask[127:0] = data_in[127:0];
    endcase
  end
  assign c_cfb_out[127:0] = c_cfb_mask[127:0] ^ cipher_out[127:0];
  assign c_ofb_ctr_out[127:0] = data_in[127:0] ^ cipher_out[127:0];
  //
  always_comb begin
    case (mode_reg[3:0])
      AES128CFB: cout[127:0] = c_cfb_out[127:0];
      AES128OFB, AES128CTR: cout[127:0] = c_ofb_ctr_out[127:0];
      default: cout[127:0] = cipher_out[127:0];
    endcase
  end
  //Decipher
  assign d_cbc_out[127:0] = start_reg[127:0] ^ decipher_out[127:0];
  assign d_cfb_ofb_ctr_out[127:0] = data_in[127:0] ^ cipher_out[127:0];
  always_comb begin
    case (mode_reg[3:0])
      AES128ECB: dout[127:0] = decipher_out[127:0];
      AES128CBC: dout[127:0] = d_cbc_out[127:0];
      AES128CFB, AES128OFB, AES128CTR: dout[127:0] = d_cfb_ofb_ctr_out[127:0];
      default: dout[127:0] = decipher_out[127:0];
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