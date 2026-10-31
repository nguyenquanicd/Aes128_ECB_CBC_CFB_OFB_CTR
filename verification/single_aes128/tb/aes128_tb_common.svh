//-----------------------------------------------------------
// Common testbench infrastructure for aes128 (textual include, used INSIDE a module)
//-----------------------------------------------------------
// Provides: DUT + clock + protocol checker, the pin-level driver tasks, a
// scoreboard-style comparator and the final report.
// Inputs are always driven on the FALLING clock edge, the DUT samples on the
// rising edge, so the testbench has no race with the DUT (the original
// simpleTestcase drove with blocking assignments exactly on the rising edge).
//-----------------------------------------------------------
  //---------------------------------------------------------
  // DUT signals
  //---------------------------------------------------------
  logic         clk = 1'b0;
  logic         rst_n = 1'b0;
  logic         cipher_en = 1'b0;
  logic         decipher_en = 1'b0;
  logic         chain_en = 1'b0;
  logic [127:0] data_in = '0;
  logic [127:0] key = '0;
  logic [3:0]   mode = '0;
  logic [127:0] init_vector = '0;
  logic [3:0]   segment_len = '0;
  wire  [127:0] data_out;
  wire          ready;
  wire          err_busy;
  wire          err_cfg;
  //
  localparam logic [3:0] M_ECB = 4'd0, M_CBC = 4'd1, M_CFB = 4'd2, M_OFB = 4'd3, M_CTR = 4'd4;
  localparam logic [127:0] ALL1 = {128{1'b1}};
  //
  aes128 dut (.clk(clk), .rst_n(rst_n), .cipher_en(cipher_en), .decipher_en(decipher_en),
              .chain_en(chain_en), .data_in(data_in), .key(key), .mode(mode),
              .init_vector(init_vector), .segment_len(segment_len),
              .data_out(data_out), .ready(ready), .err_busy(err_busy), .err_cfg(err_cfg));
  always #2 clk = ~clk;
  //---------------------------------------------------------
  // Protocol checker + counters of the error flags
  //---------------------------------------------------------
  logic [31:0] chk_viol;
  aes128_protocol_checker u_chk (.clk(clk), .rst_n(rst_n), .cipher_en(cipher_en), .decipher_en(decipher_en),
                                 .ready(ready), .err_busy(err_busy), .err_cfg(err_cfg),
                                 .data_out(data_out), .viol_cnt(chk_viol));
  int n_err_busy = 0;
  int n_err_cfg  = 0;
  always @ (posedge clk) begin
    if (err_busy === 1'b1) n_err_busy++;
    if (err_cfg  === 1'b1) n_err_cfg++;
  end
  //---------------------------------------------------------
  // Result bookkeeping
  //---------------------------------------------------------
  int n_pass = 0;
  int n_fail = 0;
  int n_to   = 0;     //timeouts (ready never came back)
  int n_print = 0;
  int max_print = 12;
  //---------------------------------------------------------
  // Driver tasks
  //---------------------------------------------------------
  task automatic tick(input int n);
    repeat (n) @ (negedge clk);
  endtask
  task automatic apply_reset(input int cycles);
    @ (negedge clk);
    rst_n = 1'b0; cipher_en = 1'b0; decipher_en = 1'b0; chain_en = 1'b0;
    repeat (cycles) @ (negedge clk);
    rst_n = 1'b1;
    @ (negedge clk);
  endtask
  //Present one operation and pulse the start for exactly one clock.
  //The pulse is sampled by the DUT on the rising edge between the two falling edges.
  task automatic start_op(input bit dec, input logic [3:0] m, input logic [3:0] seg, input bit chain,
                          input logic [127:0] k, input logic [127:0] iv, input logic [127:0] din);
    @ (negedge clk);
    key = k; init_vector = iv; data_in = din; mode = m; segment_len = seg; chain_en = chain;
    cipher_en = ~dec; decipher_en = dec;
    @ (negedge clk);
    cipher_en = 1'b0; decipher_en = 1'b0;
  endtask
  //Wait (falling edges) until ready is high again. cyc = clocks waited.
  task automatic wait_ready(output int cyc, input int limit);
    cyc = 0;
    while (ready !== 1'b1 && cyc < limit) begin @ (negedge clk); cyc++; end
  endtask
  //Compare under a mask; X in the DUT output always fails (!==).
  task automatic check_eq(input string name, input logic [127:0] got, input logic [127:0] expv, input logic [127:0] msk);
    if ((got & msk) !== (expv & msk)) begin
      n_fail++;
      if (n_print < max_print) begin
        n_print++;
        $display("FAIL %s\n   exp=%032h\n   got=%032h  (mask=%032h)", name, expv & msk, got & msk, msk);
      end
    end
    else n_pass++;
  endtask
  task automatic check_true(input string name, input bit cond);
    if (!cond) begin
      n_fail++;
      if (n_print < max_print) begin n_print++; $display("FAIL %s", name); end
    end
    else n_pass++;
  endtask
  //One complete operation. Returns data_out sampled one clock after ready is high.
  task automatic run_op(input bit dec, input logic [3:0] m, input logic [3:0] seg, input bit chain,
                        input logic [127:0] k, input logic [127:0] iv, input logic [127:0] din,
                        output logic [127:0] dout, output int lat);
    int cyc;
    start_op(dec, m, seg, chain, k, iv, din);
    wait_ready(cyc, 200);
    if (ready !== 1'b1) begin n_to++; dout = 'x; lat = -1; end
    else begin
      lat = cyc;          //clocks ready was low = latency (11 cipher, 22 ECB/CBC decipher)
      @ (negedge clk);
      dout = data_out;
    end
  endtask
  //Final report (parsed by sim/run_regression.ps1)
  task automatic report(input string tbname);
    bit ok;
    ok = (n_fail == 0) && (n_to == 0) && (chk_viol == 0) && (n_pass > 0);
    $display("SUMMARY %s: checks=%0d pass=%0d fail=%0d timeout=%0d checker_violations=%0d err_busy=%0d err_cfg=%0d",
             tbname, n_pass + n_fail, n_pass, n_fail, n_to, chk_viol, n_err_busy, n_err_cfg);
    $display("TEST_RESULT: %s %s", ok ? "PASS" : "FAIL", tbname);
    //$fatal makes vvp exit with code 1, so make / CI scripts can use the exit status
    if (!ok) $fatal(1, "%s FAILED", tbname);
    $finish;
  endtask
