// Formal: S-box and inverse S-box of the RTL package are exact inverses (all 256 inputs, both directions)
module fv_sbox (input logic [7:0] x);
  import aes128_pkg::*;
  always_comb begin
    assert (aes128_sbox(aes128_sbox(x, 1'b1), 1'b0) == x);   // InvSub(Sub(x)) == x
    assert (aes128_sbox(aes128_sbox(x, 1'b0), 1'b1) == x);   // Sub(InvSub(x)) == x
  end
endmodule
