//-----------------------------------------------------------
// Author: Nguyen Hung Quan
// Website: http://nguyenquanicd.blogspot.com/
//-----------------------------------------------------------
//`include "aes128_sbox.sv"
//`include "aes128_rcon_inv.sv"
module	aes128_key_expansion_inv (
  //input
  input clk_sys,
  input	rst_n,
  input	decipher_en,
  input rkey_en,
  input	[127:0]	round_key_10,
  input [3:0] round_num,
  //output
  output	logic	[127:0]	round_key_inv_out
  );
  //
  //Internal signals
  //
  logic	[127:0]	round_key_reg;
  logic [127:0] key_in;
  logic [127:0]	round_key;
  logic	[31:0]	after_subW;
  logic [31:0]	after_rotW;
  logic [31:0]	after_addRcon;
  logic	[31:0]	rcon_value_inv;
  //----------------------------------------------------------------------------
  //Storing round key
  //----------------------------------------------------------------------------
  always @ (posedge clk_sys) begin
  	if (decipher_en | rkey_en) begin
  		  round_key_reg[127:0] <= round_key[127:0];
    end
  end
  assign round_key_inv_out[127:0] = round_key_reg[127:0];
  assign key_in[127:0] = (round_num[3:0] == 4'd0)? round_key_10[127:0]: round_key_reg[127:0];
  //----------------------------------------------------------------------------
  //AddW
  //----------------------------------------------------------------------------
  assign round_key[31:0]  = key_in[31:0] ^ key_in[63:32];
  assign round_key[63:32] = key_in[63:32] ^ key_in[95:64];
  assign round_key[95:64] = key_in[95:64] ^ key_in[127:96];
  //RotWord
  assign	after_rotW = {round_key[23:0], round_key[31:24]};
  //----------------------------------------------------------------------------
  //SubWord with S-BOX
  //----------------------------------------------------------------------------
  assign after_subW[31:24] = aes128_sbox(after_rotW[31:24], 1'b1);
  assign after_subW[23:16] = aes128_sbox(after_rotW[23:16], 1'b1);
  assign after_subW[15:8]  = aes128_sbox(after_rotW[15:8],  1'b1);
  assign after_subW[7:0]   = aes128_sbox(after_rotW[7:0],   1'b1);
  //----------------------------------------------------------------------------
  //InvAddRcon is XOR Rcon value
  //----------------------------------------------------------------------------
  assign rcon_value_inv = aes128_rcon_inv(round_num);
  assign after_addRcon	= after_subW ^ rcon_value_inv;
  //Calculate word[0]
  assign round_key[127:96] = after_addRcon[31:0] ^ key_in[127:96];
  //
endmodule
