/*
 * Project      : AES-128/AES-256 ECB/CBC/CFB/OFB/CTR
 * Author       : Nguyen Hung Quan (user)
 * AI Flow      : VLSIT RTL Generator AI Automation Flow
 * AI Flow Page : https://github.com/nguyenquanicd/VLSIT_RTL_Generator_AI_Model
 * Date         : 2026-10-29
 * Description  : Combinational AES-128/AES-256 key expansion for round-key capture.
 */
`timescale 1ns/1ps

module m_aes128_256_key_expand #(
  localparam logic [31:0] LPARA_AES_BYTE_W = 8,
  localparam logic [31:0] LPARA_AES_WORD_W = 32,
  localparam logic [31:0] LPARA_AES_BLOCK_W = 128,
  localparam logic [31:0] LPARA_AES256_KEY_W = 256,
  localparam logic [31:0] LPARA_AES128_KEY_WORD_NUM = 4,
  localparam logic [31:0] LPARA_AES256_KEY_WORD_NUM = 8,
  localparam logic [31:0] LPARA_AES_WORDS_PER_ROUND = 4,
  localparam logic [31:0] LPARA_AES_WORD_IDX2 = 2,
  localparam logic [31:0] LPARA_AES_WORD_IDX3 = 3,
  localparam logic [31:0] LPARA_AES128_WORD_NUM = 44,
  localparam logic [31:0] LPARA_AES256_WORD_NUM = 60,
  localparam logic [31:0] LPARA_AES128_ROUND_KEY_NUM = 11,
  localparam logic [31:0] LPARA_AES256_ROUND_KEY_NUM = 15,
  localparam logic [31:0] LPARA_AES256_KEY_CADENCE = 8
) (
  // Key configuration
  input  wire           i_cfg_key_size,
  input  wire  [255:0]  i_cfg_key,

  // Expanded encryption round keys, with K0 in the least-significant slot
  output logic [1919:0] o_round_keys
);

  // Internal signal declarations
  logic [31:0] w_word [0:LPARA_AES256_WORD_NUM-1];
  logic [31:0] w_temp;
  logic [7:0]  w_rcon;

  // AES S-box lookup: the table is organized by high nibble and indexed by low nibble.
  function automatic logic [7:0] f_aes_sbox(input logic [7:0] i_value);
    logic [127:0] w_row;
    begin
      w_row = '0;
      case (i_value[7:4])
        4'h0: w_row = 128'h637c777bf26b6fc53001672bfed7ab76;
        4'h1: w_row = 128'hca82c97dfa5947f0add4a2af9ca472c0;
        4'h2: w_row = 128'hb7fd9326363ff7cc34a5e5f171d83115;
        4'h3: w_row = 128'h04c723c31896059a071280e2eb27b275;
        4'h4: w_row = 128'h09832c1a1b6e5aa0523bd6b329e32f84;
        4'h5: w_row = 128'h53d100ed20fcb15b6acbbe394a4c58cf;
        4'h6: w_row = 128'hd0efaafb434d338545f9027f503c9fa8;
        4'h7: w_row = 128'h51a3408f929d38f5bcb6da2110fff3d2;
        4'h8: w_row = 128'hcd0c13ec5f974417c4a77e3d645d1973;
        4'h9: w_row = 128'h60814fdc222a908846eeb814de5e0bdb;
        4'ha: w_row = 128'he0323a0a4906245cc2d3ac629195e479;
        4'hb: w_row = 128'he7c8376d8dd54ea96c56f4ea657aae08;
        4'hc: w_row = 128'hba78252e1ca6b4c6e8dd741f4bbd8b8a;
        4'hd: w_row = 128'h703eb5664803f60e613557b986c11d9e;
        4'he: w_row = 128'he1f8981169d98e949b1e87e9ce5528df;
        4'hf: w_row = 128'h8ca1890dbfe6426841992d0fb054bb16;
        default: w_row = '0;
      endcase
      f_aes_sbox = w_row[{~i_value[3:0], 3'b111} -: LPARA_AES_BYTE_W];
    end
  endfunction

  // RotWord rotates one 32-bit word left by one byte as specified by FIPS 197.
  function automatic logic [31:0] f_rot_word(input logic [31:0] i_word);
    f_rot_word = {i_word[23:0], i_word[31:24]};
  endfunction

  // SubWord applies the AES S-box independently to each byte of one key word.
  function automatic logic [31:0] f_sub_word(input logic [31:0] i_word);
    f_sub_word = {
      f_aes_sbox(i_word[31:24]),
      f_aes_sbox(i_word[23:16]),
      f_aes_sbox(i_word[15:8]),
      f_aes_sbox(i_word[7:0])
    };
  endfunction

  // Rcon advances in GF(2^8) with the AES irreducible polynomial x^8+x^4+x^3+x+1.
  function automatic logic [7:0] f_xtime(input logic [7:0] i_value);
    if (i_value[7])
      f_xtime = $bits(i_value)'((i_value << 1) ^ 8'h1b);
    else
      f_xtime = $bits(i_value)'(i_value << 1);
  endfunction

  // Key expansion: create 44 or 60 words, then pack 11 or 15 round keys.
  always_comb begin : p_com_key_expand
    w_word[0] = '0;
    w_word[1] = '0;
    w_word[2] = '0;
    w_word[3] = '0;
    w_word[4] = '0;
    w_word[5] = '0;
    w_word[6] = '0;
    w_word[7] = '0;
    w_word[8] = '0;
    w_word[9] = '0;
    w_word[10] = '0;
    w_word[11] = '0;
    w_word[12] = '0;
    w_word[13] = '0;
    w_word[14] = '0;
    w_word[15] = '0;
    w_word[16] = '0;
    w_word[17] = '0;
    w_word[18] = '0;
    w_word[19] = '0;
    w_word[20] = '0;
    w_word[21] = '0;
    w_word[22] = '0;
    w_word[23] = '0;
    w_word[24] = '0;
    w_word[25] = '0;
    w_word[26] = '0;
    w_word[27] = '0;
    w_word[28] = '0;
    w_word[29] = '0;
    w_word[30] = '0;
    w_word[31] = '0;
    w_word[32] = '0;
    w_word[33] = '0;
    w_word[34] = '0;
    w_word[35] = '0;
    w_word[36] = '0;
    w_word[37] = '0;
    w_word[38] = '0;
    w_word[39] = '0;
    w_word[40] = '0;
    w_word[41] = '0;
    w_word[42] = '0;
    w_word[43] = '0;
    w_word[44] = '0;
    w_word[45] = '0;
    w_word[46] = '0;
    w_word[47] = '0;
    w_word[48] = '0;
    w_word[49] = '0;
    w_word[50] = '0;
    w_word[51] = '0;
    w_word[52] = '0;
    w_word[53] = '0;
    w_word[54] = '0;
    w_word[55] = '0;
    w_word[56] = '0;
    w_word[57] = '0;
    w_word[58] = '0;
    w_word[59] = '0;
    w_temp = '0;
    w_rcon = 8'h01;
    o_round_keys = '0;

    if (!i_cfg_key_size) begin
      for (int idx = 0; idx < LPARA_AES128_KEY_WORD_NUM; idx++)
        w_word[idx] = i_cfg_key[LPARA_AES_BLOCK_W - 1 - (idx * LPARA_AES_WORD_W) -: LPARA_AES_WORD_W];

      for (int idx = LPARA_AES128_KEY_WORD_NUM; idx < LPARA_AES128_WORD_NUM; idx++) begin
        w_temp = w_word[idx - 1];
        if ((idx % LPARA_AES_WORDS_PER_ROUND) == 0) begin
          w_temp = $bits(w_temp)'(f_sub_word(f_rot_word(w_temp)) ^ {
            w_rcon,
            {(LPARA_AES_WORD_W - LPARA_AES_BYTE_W){1'b0}}
          });
          w_rcon = f_xtime(w_rcon);
        end
        w_word[idx] = $bits(w_word[idx])'(w_word[idx - LPARA_AES_WORDS_PER_ROUND] ^ w_temp);
      end

      for (int round_idx = 0; round_idx < LPARA_AES128_ROUND_KEY_NUM; round_idx++)
        o_round_keys[(round_idx * LPARA_AES_BLOCK_W) +: LPARA_AES_BLOCK_W] = {
          w_word[(round_idx * LPARA_AES_WORDS_PER_ROUND)],
          w_word[(round_idx * LPARA_AES_WORDS_PER_ROUND) + 1],
          w_word[(round_idx * LPARA_AES_WORDS_PER_ROUND) + LPARA_AES_WORD_IDX2],
          w_word[(round_idx * LPARA_AES_WORDS_PER_ROUND) + LPARA_AES_WORD_IDX3]
        };
    end else begin
      for (int idx = 0; idx < LPARA_AES256_KEY_WORD_NUM; idx++)
        w_word[idx] = i_cfg_key[LPARA_AES256_KEY_W - 1 - (idx * LPARA_AES_WORD_W) -: LPARA_AES_WORD_W];

      for (int idx = LPARA_AES256_KEY_WORD_NUM; idx < LPARA_AES256_WORD_NUM; idx++) begin
        w_temp = w_word[idx - 1];
        if ((idx % LPARA_AES256_KEY_CADENCE) == 0) begin
          w_temp = $bits(w_temp)'(f_sub_word(f_rot_word(w_temp)) ^ {
            w_rcon,
            {(LPARA_AES_WORD_W - LPARA_AES_BYTE_W){1'b0}}
          });
          w_rcon = f_xtime(w_rcon);
        end else if ((idx % LPARA_AES256_KEY_CADENCE) == LPARA_AES_WORDS_PER_ROUND) begin
          w_temp = f_sub_word(w_temp);
        end
        w_word[idx] = $bits(w_word[idx])'(w_word[idx - LPARA_AES256_KEY_CADENCE] ^ w_temp);
      end

      for (int round_idx = 0; round_idx < LPARA_AES256_ROUND_KEY_NUM; round_idx++)
        o_round_keys[(round_idx * LPARA_AES_BLOCK_W) +: LPARA_AES_BLOCK_W] = {
          w_word[(round_idx * LPARA_AES_WORDS_PER_ROUND)],
          w_word[(round_idx * LPARA_AES_WORDS_PER_ROUND) + 1],
          w_word[(round_idx * LPARA_AES_WORDS_PER_ROUND) + LPARA_AES_WORD_IDX2],
          w_word[(round_idx * LPARA_AES_WORDS_PER_ROUND) + LPARA_AES_WORD_IDX3]
        };
    end
  end

endmodule
