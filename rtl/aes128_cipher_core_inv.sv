//-----------------------------------------------------------
// Author: Nguyen Hung Quan
// Website: http://nguyenquanicd.blogspot.com/
//-----------------------------------------------------------
//`include "aes128_sbox.sv"
`include "aes128_mul_inv.sv"
module aes128_cipher_core_inv (
  //input
  input clk_sys,
  input rst_n,
  input	[127:0]	round_key_10,
  input	[127:0]	round_key_inv,
  input	[127:0]	cipher_text,
  input		decipher_en,
  //output
  output logic [127:0] plain_text,
  output logic decipher_ready,
  output logic [3:0] round_num,
  output logic rkey_en 
  );
  //
  //Internal signals
  //
  logic [3:0] decipher_counter;
  logic decipher_complete;
  logic [127:0] InvShiftRows_in;
  logic [127:0] after_InvShiftRows;
  logic [127:0] after_InvSubBytes;
  logic [127:0] after_InvMixColumns;
  logic [127:0] round_key;
  logic [127:0] AddRoundKey_in;
  logic [127:0] after_AddRoundKey;
  logic [127:0] plainText_reg;
  logic [127:0] InvShiftRows_result;
  wire first_time_en;
  //-------------------------------------------------------------------
  //Monitor counters
  //-------------------------------------------------------------------
  always	@ (posedge clk_sys, negedge rst_n) begin
  	if (~rst_n)
      decipher_counter	<= 4'd0;
  	else if (decipher_complete)
  		decipher_counter	<= 4'd0;
  	else if (decipher_en | rkey_en)
  		decipher_counter	<= decipher_counter + 1'b1;
  end
  assign decipher_complete = (decipher_counter == 4'b1010)? 1'b1: 1'b0;
  assign round_num[3:0]  = decipher_counter[3:0];
  //Cipher status
  always @ (posedge clk_sys, negedge rst_n) begin
  	if (~rst_n)
      decipher_ready	<= 1'b1;
  	else if (decipher_en)
  		decipher_ready	<= 1'b0;
  	else if (decipher_complete)
      decipher_ready	<= 1'b1;
  end
  assign rkey_en = ~decipher_ready;
  //----------------------------------------------------------------------------
  //InvShiftRows
  //----------------------------------------------------------------------------
  //Select the connection for first time and next times
  assign first_time_en = (decipher_counter[3:0] == 4'd1);
  //Re-order from bit stream to columns
  assign InvShiftRows_in[127:120]	= first_time_en? plainText_reg[127:120]: after_InvMixColumns[127:120];
  assign InvShiftRows_in[119:112]	= first_time_en? plainText_reg[95:88]  : after_InvMixColumns[95:88]  ;
  assign InvShiftRows_in[111:104]	= first_time_en? plainText_reg[63:56]  : after_InvMixColumns[63:56]  ;
  assign InvShiftRows_in[103:96]	= first_time_en? plainText_reg[31:24]  : after_InvMixColumns[31:24]  ;
  assign InvShiftRows_in[95:88]	  = first_time_en? plainText_reg[119:112]: after_InvMixColumns[119:112];
  assign InvShiftRows_in[87:80]	  = first_time_en? plainText_reg[87:80]  : after_InvMixColumns[87:80]  ;
  assign InvShiftRows_in[79:72]	  = first_time_en? plainText_reg[55:48]  : after_InvMixColumns[55:48]  ;
  assign InvShiftRows_in[71:64]	  = first_time_en? plainText_reg[23:16]  : after_InvMixColumns[23:16]  ;
  assign InvShiftRows_in[63:56]	  = first_time_en? plainText_reg[111:104]: after_InvMixColumns[111:104];
  assign InvShiftRows_in[55:48]	  = first_time_en? plainText_reg[79:72]  : after_InvMixColumns[79:72]  ;
  assign InvShiftRows_in[47:40]	  = first_time_en? plainText_reg[47:40]  : after_InvMixColumns[47:40]  ;
  assign InvShiftRows_in[39:32]	  = first_time_en? plainText_reg[15:8]   : after_InvMixColumns[15:8]   ;
  assign InvShiftRows_in[31:24]	  = first_time_en? plainText_reg[103:96] : after_InvMixColumns[103:96] ;
  assign InvShiftRows_in[23:16]	  = first_time_en? plainText_reg[71:64]  : after_InvMixColumns[71:64]  ;
  assign InvShiftRows_in[15:8]	  = first_time_en? plainText_reg[39:32]  : after_InvMixColumns[39:32]  ;
  assign InvShiftRows_in[7:0]	    = first_time_en? plainText_reg[7:0]    : after_InvMixColumns[7:0]    ;
  //
  //Only perform the step "Shift" because they are columns
  //
  assign after_InvShiftRows[127:0]		= 
        {InvShiftRows_in[127:96],  //No shift
         InvShiftRows_in[71:64], InvShiftRows_in[95:72], //Shift 1 byte
				 InvShiftRows_in[47:32], InvShiftRows_in[63:48], //Shift 2 byte
         InvShiftRows_in[23:0],  InvShiftRows_in[31:24]}; //Shift 3 byte
  //Re-order from bit stream to columns
  assign InvShiftRows_result[127:120]	= after_InvShiftRows[127:120];
  assign InvShiftRows_result[119:112]	= after_InvShiftRows[95:88]  ;
  assign InvShiftRows_result[111:104]	= after_InvShiftRows[63:56]  ;
  assign InvShiftRows_result[103:96]	= after_InvShiftRows[31:24]  ;
  assign InvShiftRows_result[95:88]	  = after_InvShiftRows[119:112];
  assign InvShiftRows_result[87:80]	  = after_InvShiftRows[87:80]  ;
  assign InvShiftRows_result[79:72]	  = after_InvShiftRows[55:48]  ;
  assign InvShiftRows_result[71:64]	  = after_InvShiftRows[23:16]  ;
  assign InvShiftRows_result[63:56]	  = after_InvShiftRows[111:104];
  assign InvShiftRows_result[55:48]	  = after_InvShiftRows[79:72]  ;
  assign InvShiftRows_result[47:40]	  = after_InvShiftRows[47:40]  ;
  assign InvShiftRows_result[39:32]	  = after_InvShiftRows[15:8]   ;
  assign InvShiftRows_result[31:24]	  = after_InvShiftRows[103:96] ;
  assign InvShiftRows_result[23:16]	  = after_InvShiftRows[71:64]  ;
  assign InvShiftRows_result[15:8]	  = after_InvShiftRows[39:32]  ;
  assign InvShiftRows_result[7:0]	    = after_InvShiftRows[7:0]    ;
  //-------------------------------------------------------------------
  //InvSubBytes
  //-------------------------------------------------------------------
  assign after_InvSubBytes[127:120] =  aes128_sbox(InvShiftRows_result[127:120], 1'b0);
  assign after_InvSubBytes[119:112] =  aes128_sbox(InvShiftRows_result[119:112], 1'b0);
  assign after_InvSubBytes[111:104] =  aes128_sbox(InvShiftRows_result[111:104], 1'b0);
  assign after_InvSubBytes[103:96]	=  aes128_sbox(InvShiftRows_result[103:96],  1'b0);
  assign after_InvSubBytes[95:88]	  =  aes128_sbox(InvShiftRows_result[95:88],   1'b0);
  assign after_InvSubBytes[87:80]	  =  aes128_sbox(InvShiftRows_result[87:80],   1'b0);
  assign after_InvSubBytes[79:72]	  =  aes128_sbox(InvShiftRows_result[79:72],   1'b0);
  assign after_InvSubBytes[71:64]	  =  aes128_sbox(InvShiftRows_result[71:64],   1'b0);
  assign after_InvSubBytes[63:56]	  =  aes128_sbox(InvShiftRows_result[63:56],   1'b0);
  assign after_InvSubBytes[55:48]	  =  aes128_sbox(InvShiftRows_result[55:48],   1'b0);
  assign after_InvSubBytes[47:40]	  =  aes128_sbox(InvShiftRows_result[47:40],   1'b0);
  assign after_InvSubBytes[39:32]	  =  aes128_sbox(InvShiftRows_result[39:32],   1'b0);
  assign after_InvSubBytes[31:24]	  =  aes128_sbox(InvShiftRows_result[31:24],   1'b0);
  assign after_InvSubBytes[23:16]	  =  aes128_sbox(InvShiftRows_result[23:16],   1'b0);
  assign after_InvSubBytes[15:8]	  =  aes128_sbox(InvShiftRows_result[15:8],    1'b0);
  assign after_InvSubBytes[7:0]	    =  aes128_sbox(InvShiftRows_result[7:0],     1'b0);
  //----------------------------------------------------------------------------
  //InvMixColumns - only input from AddRoundKey
  //----------------------------------------------------------------------------
  assign after_InvMixColumns[127:96] = mixcolInv(plainText_reg[127:96]);
  assign after_InvMixColumns[95:64]	 = mixcolInv(plainText_reg[95:64]);
  assign after_InvMixColumns[63:32]	 = mixcolInv(plainText_reg[63:32]);
  assign after_InvMixColumns[31:0]	 = mixcolInv(plainText_reg[31:0]);
  //----------------------------------------------------------------------------
  //AddRoundKey
  //----------------------------------------------------------------------------
  assign round_key[127:0]         = decipher_en? round_key_10[127:0]: round_key_inv[127:0];
  assign AddRoundKey_in[127:0]    = decipher_en? cipher_text[127:0]:  after_InvSubBytes[127:0];
  assign after_AddRoundKey[127:0] = AddRoundKey_in[127:0] ^ round_key[127:0];
  //----------------------------------------------------------------------------
  //Output register
  //----------------------------------------------------------------------------
  always @ (posedge clk_sys) begin
  	if (decipher_en | rkey_en)
      plainText_reg <= after_AddRoundKey[127:0];
  end
  assign plain_text[127:0] = plainText_reg[127:0];
endmodule
