//-----------------------------------------------------------
// Function: Golden-vector driven regression testbench for aes128
//-----------------------------------------------------------
// The expected data comes from tools/aes_ref.py (independent pure-python model,
// validated against FIPS-197 / NIST SP 800-38A / AESAVS). Vector files live in
// vectors/ and are produced by tools/gen_vectors.py.
//
// Plusargs
//   +VEC=<file>    vector file (required)
//   +SEED=<n>      seed of the random junk / stress generators (default 1)
//   +JUNK=1        drive random values on data_in/key/init_vector/mode/segment_len
//                  while the DUT is idle (proves that inputs matter only on the
//                  start clock; the original design failed this)
//   +SCR=<mask>    after the start pulse overwrite with random values:
//                  bit0 data_in, bit1 key, bit2 init_vector, bit3 mode, bit4 segment_len
//   +EARLY=<n>     raise chain_en n clocks BEFORE the first start of every stream
//   +MID=<k>       issue a second (stray) start k clocks after every start (k<=8,
//                  must be rejected: err_busy pulses, the result must be unchanged)
//   +COVCHK=1      fail if a (mode x direction) or CFB-segment bin was never hit
//-----------------------------------------------------------
`timescale 1ns/1ps
module tb_aes128_vec;
  `include "aes128_tb_common.svh"
  //---------------------------------------------------------
  logic [127:0] vec [0:6*4500];
  string  fname;
  int     n_ops, i, seed_v, junk_v, scr_v, early_v, mid_v, covchk_v, fd, nw;
  logic [127:0] w128;
  logic [127:0] ctrl, k_, iv_, din_, exp_, msk_, got;
  logic         dec_, ch_, ns_;
  logic [3:0]   md_, sg_, gap_, idle_;
  int           lat;
  int           lat_min [0:4][0:1];
  int           lat_max [0:4][0:1];
  int           cov_md  [0:4][0:1];
  int           cov_seg [0:7][0:1];
  int           j, d;
  int           exp_busy;
  //
  function automatic logic [127:0] rnd128();
    return {$urandom, $urandom, $urandom, $urandom};
  endfunction
  task automatic junk_inputs;
    if (junk_v != 0) begin
      data_in = rnd128(); key = rnd128(); init_vector = rnd128();
      mode = $urandom_range(0, 15); segment_len = $urandom_range(0, 15);
    end
  endtask
  //---------------------------------------------------------
  initial begin
    if (!$value$plusargs("VEC=%s", fname)) begin $display("ERROR: +VEC=<file> is required"); $fatal(1, "missing +VEC"); end
    if (!$value$plusargs("SEED=%d", seed_v))   seed_v = 1;
    if (!$value$plusargs("JUNK=%d", junk_v))   junk_v = 0;
    if (!$value$plusargs("SCR=%d", scr_v))     scr_v = 0;
    if (!$value$plusargs("EARLY=%d", early_v)) early_v = 0;
    if (!$value$plusargs("MID=%d", mid_v))     mid_v = 0;
    if (!$value$plusargs("COVCHK=%d", covchk_v)) covchk_v = 0;
    void'($urandom(seed_v));
    fd = $fopen(fname, "r");
    if (fd == 0) begin $display("ERROR: cannot open %s", fname); $display("TEST_RESULT: FAIL %s", fname); $fatal(1, "cannot open vector file"); end
    nw = 0;
    while (nw < 6*4500 + 1 && $fscanf(fd, "%h", w128) == 1) begin vec[nw] = w128; nw = nw + 1; end
    $fclose(fd);
    n_ops = vec[0];
    for (j = 0; j < 5; j++) for (d = 0; d < 2; d++) begin lat_min[j][d] = 1000; lat_max[j][d] = 0; cov_md[j][d] = 0; end
    for (j = 0; j < 8; j++) for (d = 0; d < 2; d++) cov_seg[j][d] = 0;
    exp_busy = 0;
    repeat (4) @ (negedge clk);
    rst_n = 1'b1;
    repeat (2) @ (negedge clk);
    for (i = 0; i < n_ops; i++) begin
      ctrl = vec[1 + 6*i]; k_ = vec[2 + 6*i]; iv_ = vec[3 + 6*i]; din_ = vec[4 + 6*i];
      exp_ = vec[5 + 6*i]; msk_ = vec[6 + 6*i];
      dec_ = ctrl[0]; md_ = ctrl[4:1]; sg_ = ctrl[8:5]; ch_ = ctrl[9]; ns_ = ctrl[10];
      gap_ = ctrl[15:12]; idle_ = ctrl[19:16];
      //-- idle time before the op (junk on the inputs) and chain_en handling
      repeat (idle_) begin junk_inputs; @ (negedge clk); end
      if (ns_) begin
        chain_en = 1'b0;
        repeat (gap_) begin junk_inputs; @ (negedge clk); end
        if (early_v > 0 && ch_) begin chain_en = 1'b1; repeat (early_v) begin junk_inputs; @ (negedge clk); end end
      end
      //-- start pulse
      start_op(dec_, md_, sg_, ch_, k_, iv_, din_);
      if (scr_v[0]) data_in     = rnd128();
      if (scr_v[1]) key         = rnd128();
      if (scr_v[2]) init_vector = rnd128();
      if (scr_v[3]) mode        = $urandom_range(0, 15);
      if (scr_v[4]) segment_len = $urandom_range(0, 15);
      if (mid_v > 0) begin
        repeat (mid_v - 1) @ (negedge clk);
        cipher_en = ~dec_; decipher_en = dec_;       //stray start while busy
        @ (negedge clk);
        cipher_en = 1'b0; decipher_en = 1'b0;
        exp_busy++;
      end
      wait_ready(lat, 200);
      if (ready !== 1'b1) begin
        n_to++;
        if (n_print < max_print) begin n_print++; $display("TIMEOUT op=%0d mode=%0d dec=%0d seg=%0d chain=%0d (ready stuck low) -> reset", i, md_, dec_, sg_, ch_); end
        apply_reset(3);
      end
      else begin
        //lat = clocks ready was low (11 cipher, 22 ECB/CBC decipher)
        @ (negedge clk);
        got = data_out;
        check_eq($sformatf("op=%0d mode=%0d dec=%0d seg=%0d chain=%0d ns=%0d gap=%0d idle=%0d", i, md_, dec_, sg_, ch_, ns_, gap_, idle_), got, exp_, msk_);
        if (md_ < 5) begin
          cov_md[md_][dec_] = cov_md[md_][dec_] + 1;
          if (md_ == M_CFB && sg_ < 8) cov_seg[sg_][dec_] = cov_seg[sg_][dec_] + 1;
          if (mid_v == 0) begin
            if (lat < lat_min[md_][dec_]) lat_min[md_][dec_] = lat;
            if (lat > lat_max[md_][dec_]) lat_max[md_][dec_] = lat;
          end
        end
        junk_inputs;
      end
    end
    //-- error flag accounting
    if (mid_v > 0) check_true("err_busy count == number of stray starts", n_err_busy == exp_busy);
    else           check_true("no err_busy for protocol-correct stimulus", n_err_busy == 0);
    check_true("no err_cfg for legal configurations", n_err_cfg == 0);
    //-- coverage / latency table
    $display("---- coverage (ops) and latency (clocks ready low) per mode ----");
    for (j = 0; j < 5; j++)
      $display("  mode %0d: enc ops=%0d lat=%0d..%0d | dec ops=%0d lat=%0d..%0d", j,
               cov_md[j][0], (lat_max[j][0] == 0) ? 0 : lat_min[j][0], lat_max[j][0],
               cov_md[j][1], (lat_max[j][1] == 0) ? 0 : lat_min[j][1], lat_max[j][1]);
    $write("  CFB segments hit (enc/dec):");
    for (j = 0; j < 8; j++) $write(" %0d:%0d/%0d", j, cov_seg[j][0], cov_seg[j][1]);
    $write("\n");
    if (covchk_v != 0) begin
      for (j = 0; j < 5; j++) for (d = 0; d < 2; d++) check_true($sformatf("coverage hole: mode %0d dir %0d", j, d), cov_md[j][d] > 0);
      for (j = 0; j < 8; j++) for (d = 0; d < 2; d++) check_true($sformatf("coverage hole: CFB seg %0d dir %0d", j, d), cov_seg[j][d] > 0);
    end
    report(fname);
  end
  //Global watchdog
  initial begin
    #200000000;
    $display("GLOBAL WATCHDOG");
    $display("TEST_RESULT: FAIL watchdog");
    $fatal(1, "watchdog");
  end
endmodule
