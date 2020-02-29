//-----------------------------------------------------------
// Author: Nguyen Hung Quan
// Website: http://nguyenquanicd.blogspot.com/
//-----------------------------------------------------------

//`include "aes128_sbox.sv"
//`include "aes128_rcon.sv"
module	aes128_key_expansion (
  //input
  input	 clk_sys,
  input	 rst_n,
  input  cipher_en,
  input  rkey_en,
  input	 [127:0] cipher_key,
  input  [3:0] round_num,
  //output
  output	logic	[127:0]	round_key_out
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
  logic	[31:0]	rcon_value;
  //----------------------------------------------------------------------------
  //Storing round key
  //----------------------------------------------------------------------------
  always @ (posedge clk_sys) begin
  	if (cipher_en | rkey_en) begin
  		  round_key_reg[127:0] <= round_key[127:0];
    end
  end
  assign round_key_out[127:0] = round_key_reg[127:0];
  assign key_in[127:0] = (round_num[3:0] == 4'd0)? cipher_key[127:0]: round_key_reg[127:0];
  //----------------------------------------------------------------------------
  //rotW - Rotate LSB [31:0]
  //  w0 is MSB [127:96], w3 is LSB [31:0]
  //----------------------------------------------------------------------------
  assign	after_rotW	= {key_in[23:0], key_in[31:24]};
  //----------------------------------------------------------------------------
  //subW Subword with S-BOX
  //----------------------------------------------------------------------------
  assign after_subW[31:24] = aes128_sbox(after_rotW[31:24], 1'b1);
  assign after_subW[23:16] = aes128_sbox(after_rotW[23:16], 1'b1);
  assign after_subW[15:8]  = aes128_sbox(after_rotW[15:8],  1'b1);
  assign after_subW[7:0]   = aes128_sbox(after_rotW[7:0],   1'b1);
  //----------------------------------------------------------------------------
  //addRcon is XOR Rcon value
  //----------------------------------------------------------------------------
  assign rcon_value     = aes128_rcon(round_num);
  assign after_addRcon	= after_subW ^ rcon_value;
  //Round key
  assign	round_key[127:96]	= after_addRcon     ^ key_in[127:96];
  assign	round_key[95:64]	= round_key[127:96] ^ key_in[95:64];
  assign	round_key[63:32]	= round_key[95:64]  ^ key_in[63:32];
  assign	round_key[31:0]	  = round_key[63:32]  ^ key_in[31:0];

endmodule
