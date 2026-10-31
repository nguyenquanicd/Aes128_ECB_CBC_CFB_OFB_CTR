//-----------------------------------------------------------
// Author: Nguyen Hung Quan
// Website: http://nguyenquanicd.blogspot.com/
//-----------------------------------------------------------
module aes128_cipher_inv_top (
  //input
  input clk_sys,
  input rst_n,
  input [127:0] cipher_text,
  input [127:0] round_key_10,
  input decipher_en,
  //output
  output [127:0] plain_text,
  output decipher_ready
  );
  //
  //Internal signals
  //
  logic [127:0] round_key_inv_out;
  logic [3:0] round_num;
  logic rkey_en;
  //
  //Instances
  //
  aes128_cipher_core_inv aes128_cipher_core_inv (
    //input
    .clk_sys(clk_sys),
    .rst_n(rst_n),
    .round_key_10(round_key_10[127:0]),
    .round_key_inv(round_key_inv_out[127:0]),
    .cipher_text(cipher_text[127:0]),
    .decipher_en(decipher_en),
    //output
    .plain_text(plain_text[127:0]),
    .decipher_ready(decipher_ready),
    .round_num(round_num[3:0]),
    .rkey_en(rkey_en)
    );
  
  aes128_key_expansion_inv aes128_key_expansion_inv (
    //input
    .clk_sys(clk_sys),
    .rst_n(rst_n),
    .decipher_en(decipher_en),
    .rkey_en(rkey_en),
    .round_key_10(round_key_10[127:0]),
    .round_num(round_num[3:0]),
    //output
    .round_key_inv_out(round_key_inv_out[127:0])
    );

endmodule //aes128_cipher_inv_top