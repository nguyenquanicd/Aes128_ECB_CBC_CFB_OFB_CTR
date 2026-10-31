//-----------------------------------------------------------
// Author: Nguyen Hung Quan
// Website: http://nguyenquanicd.blogspot.com/
//-----------------------------------------------------------
module aes128_cipher_top (
  //input
  input clk_sys,
  input rst_n,
  input [127:0] cipher_key,
  input [127:0] plain_text,
  input cipher_en,
  //output
  output logic [127:0] cipher_text,
  output logic cipher_ready,
  output logic [127:0] cipher_key10
  );
  //
  logic [3:0] round_num;
  logic rkey_en;
  logic [127:0] round_key_out;
  //
  always_ff @ (posedge clk_sys) begin
    if (rkey_en)
      cipher_key10[127:0] <= round_key_out[127:0];
  end
  //
  aes128_cipher_core aes128_cipher_core(
    //input
    .clk_sys(clk_sys),
    .rst_n(rst_n),
    .cipher_key(cipher_key[127:0]),
    .round_key(round_key_out[127:0]),
    .plain_text(plain_text[127:0]),
    .cipher_en(cipher_en),
    //output
    .cipher_text(cipher_text[127:0]),
    .cipher_ready(cipher_ready),
    .round_num(round_num[3:0]),
    .rkey_en(rkey_en) 
    );
  //
  aes128_key_expansion aes128_key_expansion (
    //input
    .clk_sys(clk_sys),
    .rst_n(rst_n),
    .cipher_en(cipher_en),
    .rkey_en(rkey_en),
    .cipher_key(cipher_key[127:0]),
    .round_num(round_num[3:0]),
    //output
    .round_key_out(round_key_out[127:0])
    );

endmodule
