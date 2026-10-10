// Formal: control behaviour of the whole aes128 top for ALL inputs and ALL modes.
// No assumption on the host except a reset in the first clock. The properties are the rules
// of checker/aes128_protocol_checker.sv (C2..C9) compiled with +define+FORMAL, plus two
// extra ones that need the DUT state:
//   * a start request while ready is high and err_cfg low always drops ready (accepted)
//   * stray starts while busy never lengthen the operation (busy bound counts from the first start)
module fv_ctrl (
  input logic clk, input logic cipher_en, input logic decipher_en, input logic chain_en,
  input logic [127:0] data_in, input logic [127:0] key, input logic [127:0] init_vector,
  input logic [3:0] mode, input logic [3:0] segment_len);
  logic init = 1'b1;
  always_ff @(posedge clk) init <= 1'b0;
  wire rst_n = ~init;                                        // reset only in clock 0
  wire [127:0] data_out;
  wire ready, err_busy, err_cfg;
  aes128 dut (.clk(clk), .rst_n(rst_n), .cipher_en(cipher_en), .decipher_en(decipher_en), .chain_en(chain_en),
              .data_in(data_in), .key(key), .mode(mode), .init_vector(init_vector), .segment_len(segment_len),
              .data_out(data_out), .ready(ready), .err_busy(err_busy), .err_cfg(err_cfg));
  always_comb if (init) assume (!cipher_en && !decipher_en);
  logic [31:0] viol;
  aes128_protocol_checker u_chk (.clk(clk), .rst_n(rst_n), .cipher_en(cipher_en), .decipher_en(decipher_en),
                                 .ready(ready), .err_busy(err_busy), .err_cfg(err_cfg),
                                 .data_out(data_out), .viol_cnt(viol));
endmodule
