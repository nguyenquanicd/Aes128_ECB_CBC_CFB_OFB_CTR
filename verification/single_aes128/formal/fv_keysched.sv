// Formal: the inverse key expansion regenerates exactly the forward round keys 9..0 from
// round key 10, for ANY 128-bit key (real RTL modules, real round counters/round constants).
module fv_keysched (input logic clk, input logic [127:0] key);
  logic [4:0]   t = 5'd0;
  logic [127:0] key_q = 128'd0;
  logic [127:0] kst [0:10];
  wire  [127:0] fk, ik;
  wire          en_f = (t <= 5'd9);
  wire  [3:0]   rn_f = t[3:0];
  wire          en_i = (t >= 5'd11) && (t <= 5'd20);
  wire  [3:0]   rn_i = t[3:0] - 4'd11;
  always_ff @(posedge clk) begin
    if (t != 5'd31) t <= t + 5'd1;
    key_q <= key;
    if (t >= 5'd1 && t <= 5'd10) kst[t] <= fk;
  end
  always_comb if (t != 5'd0) assume (key == key_q);        // the key is held constant
  aes128_key_expansion u_f (.clk_sys(clk), .rst_n(1'b1), .cipher_en(1'b0), .rkey_en(en_f),
                            .cipher_key(key), .round_num(rn_f), .round_key_out(fk));
  aes128_key_expansion_inv u_i (.clk_sys(clk), .rst_n(1'b1), .decipher_en(1'b0), .rkey_en(en_i),
                            .round_key_10(kst[10]), .round_num(rn_i), .round_key_inv_out(ik));
  // after inverse step m (cycle t = 12+m) ik must equal forward round key (9-m)
  always_comb if (t >= 5'd12 && t <= 5'd20) assert (ik == kst[21 - t]);
  always_comb if (t == 5'd21) assert (ik == key);
endmodule
