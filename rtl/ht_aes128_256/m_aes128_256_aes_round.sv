/*
 * Project      : AES-128/AES-256 ECB/CBC/CFB/OFB/CTR
 * Author       : Nguyen Hung Quan (user)
 * AI Flow      : VLSIT RTL Generator AI Automation Flow
 * AI Flow Page : https://github.com/nguyenquanicd/VLSIT_RTL_Generator_AI_Model
 * Date         : 2026-10-29
 * Description  : One combinational forward or inverse AES round.
 */
`timescale 1ns/1ps

module m_aes128_256_aes_round #(
  // Parameter Description: zero-based AES round stage index inside the shared pipeline.
  // Parameter values: legal values are 0 through 13; default is 0.
  // Parameter unit: count
  parameter logic [31:0] PARA_AES_ROUND_IDX = 0,
  localparam logic [31:0] LPARA_AES_BYTE_W = 8,
  localparam logic [31:0] LPARA_AES_BLOCK_W = 128,
  localparam logic [31:0] LPARA_AES128_LAST_ROUND_IDX = 9,
  localparam logic [31:0] LPARA_AES256_LAST_ROUND_IDX = 13,
  localparam logic [31:0] LPARA_AES_BYTE_COUNT = 16
) (
  // AES state and round key
  input  wire  [127:0] i_state,
  input  wire  [127:0] i_round_key,
  output logic [127:0] o_state,

  // Round operation selection
  input  wire          i_key_size,
  input  wire          i_decipher
);

  // Internal signal declarations
  logic         w_is_final_round;
  logic [127:0] w_sub_state;
  logic [127:0] w_shift_state;
  logic [127:0] w_mix_state;
  logic [127:0] w_key_state;

  // AES S-box lookup: rows select the high nibble and columns select the low nibble.
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

  // Inverse AES S-box lookup for the inverse cipher rounds.
  function automatic logic [7:0] f_aes_inv_sbox(input logic [7:0] i_value);
    logic [127:0] w_row;
    begin
      w_row = '0;
      case (i_value[7:4])
        4'h0: w_row = 128'h52096ad53036a538bf40a39e81f3d7fb;
        4'h1: w_row = 128'h7ce339829b2fff87348e4344c4dee9cb;
        4'h2: w_row = 128'h547b9432a6c2233dee4c950b42fac34e;
        4'h3: w_row = 128'h082ea16628d924b2765ba2496d8bd125;
        4'h4: w_row = 128'h72f8f66486689816d4a45ccc5d65b692;
        4'h5: w_row = 128'h6c704850fdedb9da5e154657a78d9d84;
        4'h6: w_row = 128'h90d8ab008cbcd30af7e45805b8b34506;
        4'h7: w_row = 128'hd02c1e8fca3f0f02c1afbd0301138a6b;
        4'h8: w_row = 128'h3a9111414f67dcea97f2cfcef0b4e673;
        4'h9: w_row = 128'h96ac7422e7ad3585e2f937e81c75df6e;
        4'ha: w_row = 128'h47f11a711d29c5896fb7620eaa18be1b;
        4'hb: w_row = 128'hfc563e4bc6d279209adbc0fe78cd5af4;
        4'hc: w_row = 128'h1fdda8338807c731b11210592780ec5f;
        4'hd: w_row = 128'h60517fa919b54a0d2de57a9f93c99cef;
        4'he: w_row = 128'ha0e03b4dae2af5b0c8ebbb3c83539961;
        4'hf: w_row = 128'h172b047eba77d626e169146355210c7d;
        default: w_row = '0;
      endcase
      f_aes_inv_sbox = w_row[{~i_value[3:0], 3'b111} -: LPARA_AES_BYTE_W];
    end
  endfunction

  // Substitute each state byte using the forward AES S-box.
  function automatic logic [127:0] f_sub_bytes(input logic [127:0] i_value);
    logic [127:0] w_result;
    begin
      w_result = '0;
      for (int idx = 0; idx < LPARA_AES_BYTE_COUNT; idx++)
        w_result[(LPARA_AES_BLOCK_W - LPARA_AES_BYTE_W - (idx * LPARA_AES_BYTE_W)) +: LPARA_AES_BYTE_W] =
          f_aes_sbox(i_value[(LPARA_AES_BLOCK_W - LPARA_AES_BYTE_W - (idx * LPARA_AES_BYTE_W)) +: LPARA_AES_BYTE_W]);
      f_sub_bytes = w_result;
    end
  endfunction

  // Substitute each state byte using the inverse AES S-box.
  function automatic logic [127:0] f_inv_sub_bytes(input logic [127:0] i_value);
    logic [127:0] w_result;
    begin
      w_result = '0;
      for (int idx = 0; idx < LPARA_AES_BYTE_COUNT; idx++)
        w_result[(LPARA_AES_BLOCK_W - LPARA_AES_BYTE_W - (idx * LPARA_AES_BYTE_W)) +: LPARA_AES_BYTE_W] =
          f_aes_inv_sbox(i_value[(LPARA_AES_BLOCK_W - LPARA_AES_BYTE_W - (idx * LPARA_AES_BYTE_W)) +: LPARA_AES_BYTE_W]);
      f_inv_sub_bytes = w_result;
    end
  endfunction

  // Shift AES rows left by their row number in the forward cipher.
  function automatic logic [127:0] f_shift_rows(input logic [127:0] i_value);
    f_shift_rows = {
      i_value[127:120], i_value[87:80], i_value[47:40], i_value[7:0],
      i_value[95:88], i_value[55:48], i_value[15:8], i_value[103:96],
      i_value[63:56], i_value[23:16], i_value[111:104], i_value[71:64],
      i_value[31:24], i_value[119:112], i_value[79:72], i_value[39:32]
    };
  endfunction

  // Shift AES rows right by their row number in the inverse cipher.
  function automatic logic [127:0] f_inv_shift_rows(input logic [127:0] i_value);
    f_inv_shift_rows = {
      i_value[127:120], i_value[23:16], i_value[47:40], i_value[71:64],
      i_value[95:88], i_value[119:112], i_value[15:8], i_value[39:32],
      i_value[63:56], i_value[87:80], i_value[111:104], i_value[7:0],
      i_value[31:24], i_value[55:48], i_value[79:72], i_value[103:96]
    };
  endfunction

  // Multiply one byte by x in GF(2^8), reducing with the AES polynomial.
  function automatic logic [7:0] f_xtime(input logic [7:0] i_value);
    if (i_value[7])
      f_xtime = $bits(i_value)'((i_value << 1) ^ 8'h1b);
    else
      f_xtime = $bits(i_value)'(i_value << 1);
  endfunction

  function automatic logic [7:0] f_mul2(input logic [7:0] i_value);
    f_mul2 = f_xtime(i_value);
  endfunction

  function automatic logic [7:0] f_mul3(input logic [7:0] i_value);
    f_mul3 = $bits(i_value)'(f_xtime(i_value) ^ i_value);
  endfunction

  function automatic logic [7:0] f_mul9(input logic [7:0] i_value);
    logic [7:0] w_x2;
    logic [7:0] w_x4;
    logic [7:0] w_x8;
    begin
      w_x2 = f_xtime(i_value);
      w_x4 = f_xtime(w_x2);
      w_x8 = f_xtime(w_x4);
      f_mul9 = $bits(i_value)'(w_x8 ^ i_value);
    end
  endfunction

  function automatic logic [7:0] f_mul11(input logic [7:0] i_value);
    logic [7:0] w_x2;
    logic [7:0] w_x4;
    logic [7:0] w_x8;
    begin
      w_x2 = f_xtime(i_value);
      w_x4 = f_xtime(w_x2);
      w_x8 = f_xtime(w_x4);
      f_mul11 = $bits(i_value)'(w_x8 ^ w_x2 ^ i_value);
    end
  endfunction

  function automatic logic [7:0] f_mul13(input logic [7:0] i_value);
    logic [7:0] w_x2;
    logic [7:0] w_x4;
    logic [7:0] w_x8;
    begin
      w_x2 = f_xtime(i_value);
      w_x4 = f_xtime(w_x2);
      w_x8 = f_xtime(w_x4);
      f_mul13 = $bits(i_value)'(w_x8 ^ w_x4 ^ i_value);
    end
  endfunction

  function automatic logic [7:0] f_mul14(input logic [7:0] i_value);
    logic [7:0] w_x2;
    logic [7:0] w_x4;
    logic [7:0] w_x8;
    begin
      w_x2 = f_xtime(i_value);
      w_x4 = f_xtime(w_x2);
      w_x8 = f_xtime(w_x4);
      f_mul14 = $bits(i_value)'(w_x8 ^ w_x4 ^ w_x2);
    end
  endfunction

  // Mix one AES column in the forward or inverse direction.
  function automatic logic [31:0] f_mix_column(
    input logic [31:0] i_column,
    input logic        i_inverse
  );
    logic [7:0] w_a;
    logic [7:0] w_b;
    logic [7:0] w_c;
    logic [7:0] w_d;
    logic [7:0] w_o0;
    logic [7:0] w_o1;
    logic [7:0] w_o2;
    logic [7:0] w_o3;
    begin
      w_a = i_column[31:24];
      w_b = i_column[23:16];
      w_c = i_column[15:8];
      w_d = i_column[7:0];
      w_o0 = '0;
      w_o1 = '0;
      w_o2 = '0;
      w_o3 = '0;
      if (i_inverse) begin
        w_o0 = f_mul14(w_a) ^ f_mul11(w_b) ^ f_mul13(w_c) ^ f_mul9(w_d);
        w_o1 = f_mul9(w_a) ^ f_mul14(w_b) ^ f_mul11(w_c) ^ f_mul13(w_d);
        w_o2 = f_mul13(w_a) ^ f_mul9(w_b) ^ f_mul14(w_c) ^ f_mul11(w_d);
        w_o3 = f_mul11(w_a) ^ f_mul13(w_b) ^ f_mul9(w_c) ^ f_mul14(w_d);
      end else begin
        w_o0 = f_mul2(w_a) ^ f_mul3(w_b) ^ w_c ^ w_d;
        w_o1 = w_a ^ f_mul2(w_b) ^ f_mul3(w_c) ^ w_d;
        w_o2 = w_a ^ w_b ^ f_mul2(w_c) ^ f_mul3(w_d);
        w_o3 = f_mul3(w_a) ^ w_b ^ w_c ^ f_mul2(w_d);
      end
      f_mix_column = {w_o0, w_o1, w_o2, w_o3};
    end
  endfunction

  // Mix each of the four columns independently.
  function automatic logic [127:0] f_mix_columns(
    input logic [127:0] i_value,
    input logic         i_inverse
  );
    f_mix_columns = {
      f_mix_column(i_value[127:96], i_inverse),
      f_mix_column(i_value[95:64], i_inverse),
      f_mix_column(i_value[63:32], i_inverse),
      f_mix_column(i_value[31:0], i_inverse)
    };
  endfunction

  // Apply the selected AES round; final rounds omit MixColumns or InvMixColumns.
  always_comb begin : p_com_round
    w_is_final_round = 1'b0;
    w_sub_state = '0;
    w_shift_state = '0;
    w_mix_state = '0;
    w_key_state = '0;
    o_state = '0;

    if (!i_key_size && (PARA_AES_ROUND_IDX == LPARA_AES128_LAST_ROUND_IDX))
      w_is_final_round = 1'b1;
    else if (i_key_size && (PARA_AES_ROUND_IDX == LPARA_AES256_LAST_ROUND_IDX))
      w_is_final_round = 1'b1;

    if (i_decipher) begin
      w_shift_state = f_inv_shift_rows(i_state);
      w_sub_state = f_inv_sub_bytes(w_shift_state);
      w_key_state = $bits(w_key_state)'(w_sub_state ^ i_round_key);
      if (w_is_final_round)
        o_state = w_key_state;
      else
        o_state = f_mix_columns(w_key_state, 1'b1);
    end else begin
      w_sub_state = f_sub_bytes(i_state);
      w_shift_state = f_shift_rows(w_sub_state);
      if (w_is_final_round)
        w_mix_state = w_shift_state;
      else
        w_mix_state = f_mix_columns(w_shift_state, 1'b0);
      o_state = $bits(o_state)'(w_mix_state ^ i_round_key);
    end
  end

endmodule
