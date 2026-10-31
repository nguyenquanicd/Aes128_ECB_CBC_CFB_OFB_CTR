//-----------------------------------------------------------
// Function: Constrained-random round-trip / self-consistency testbench for aes128
//-----------------------------------------------------------
// No reference model is needed, so this complements the golden-vector testbench:
//   R1  decipher(cipher(P)) == P for random mode / segment / key / IV / stream length
//       (CFB: only the top 'segment' bits are data; the lower bits of data_in are
//        random on purpose because they must not matter)
//   R2  OFB and CTR are symmetric: deciphering P gives exactly the same data as
//       enciphering P
//   R3  ECB is deterministic: the same block twice gives the same ciphertext
//   R4  CBC chaining: changing block 0 changes ciphertext 1 (diffusion through the chain)
//   R5  random timing: idle clocks, chain_en gap, junk on the inputs while idle,
//       inputs scrambled after the start clock
// Plusargs: +N=<streams> (default 300)  +SEED=<n> (default 1)
//-----------------------------------------------------------
`timescale 1ns/1ps
module tb_aes128_roundtrip;
  `include "aes128_tb_common.svh"
  //---------------------------------------------------------
  localparam int B_P = 0, B_C = 1, B_E = 2, B_D = 3;        //buffer selectors: plain, cipher, cipher+junk, decrypted
  logic [127:0] BUF [0:3][0:7];
  int n_streams, seed_v, s, bk, nb, j;
  logic [3:0]   md, sg;
  logic [127:0] k, iv, mask;
  int cov_m [0:4];
  int cov_s [0:7];
  //
  function automatic logic [127:0] rnd128();
    return {$urandom, $urandom, $urandom, $urandom};
  endfunction
  function automatic logic [127:0] seg_mask(input logic [3:0] code);
    case (code)
      4'd0: return {1'b1, 127'd0};
      4'd1: return {2'b11, 126'd0};
      4'd2: return {4'hf, 124'd0};
      4'd3: return {8'hff, 120'd0};
      4'd4: return {16'hffff, 112'd0};
      4'd5: return {32'hffff_ffff, 96'd0};
      4'd6: return {64'hffff_ffff_ffff_ffff, 64'd0};
      default: return {128{1'b1}};
    endcase
  endfunction
  //Random idle time with junk on the inputs (the DUT must not care about them)
  task automatic idle_junk;
    int n;
    n = $urandom_range(0, 3);
    repeat (n) begin
      data_in = rnd128(); key = rnd128(); init_vector = rnd128();
      mode = $urandom_range(0, 15); segment_len = $urandom_range(0, 15);
      @ (negedge clk);
    end
  endtask
  //One stream (all blocks) in one direction: BUF[src][b] -> BUF[dst][b]
  task automatic do_stream(input bit dec, input int nblk, input logic [3:0] m, input logic [3:0] seg,
                           input logic [127:0] kk, input logic [127:0] ivv, input int src, input int dst);
    int b, l;
    logic [127:0] ivb;
    chain_en = 1'b0;
    tick($urandom_range(1, 3));
    for (b = 0; b < nblk; b++) begin
      idle_junk;
      ivb = (m == M_CTR) ? ivv + b : ivv;                        //CTR: the host supplies the counter block
      start_op(dec, m, seg, 1'b1, kk, ivb, BUF[src][b]);
      if ($urandom_range(0, 1)) begin data_in = rnd128(); key = rnd128(); init_vector = rnd128(); end
      wait_ready(l, 200);
      if (ready !== 1'b1) begin n_to++; BUF[dst][b] = 'x; end
      else begin @ (negedge clk); BUF[dst][b] = data_out; end
    end
  endtask
  //---------------------------------------------------------
  initial begin
    if (!$value$plusargs("N=%d", n_streams))    n_streams = 300;
    if (!$value$plusargs("SEED=%d", seed_v))    seed_v = 1;
    void'($urandom(seed_v));
    for (j = 0; j < 5; j++) cov_m[j] = 0;
    for (j = 0; j < 8; j++) cov_s[j] = 0;
    repeat (4) @ (negedge clk);
    rst_n = 1'b1;
    repeat (2) @ (negedge clk);
    for (s = 0; s < n_streams; s++) begin
      md = $urandom_range(0, 4);
      sg = (md == M_CFB) ? $urandom_range(0, 7) : 4'd7;
      nb = $urandom_range(1, 8);
      k = rnd128(); iv = rnd128();
      mask = (md == M_CFB) ? seg_mask(sg) : ALL1;
      for (bk = 0; bk < 8; bk++) BUF[B_P][bk] = rnd128();
      cov_m[md] = cov_m[md] + 1;
      if (md == M_CFB) cov_s[sg] = cov_s[sg] + 1;
      //R1: cipher, then decipher the produced ciphertext
      do_stream(1'b0, nb, md, sg, k, iv, B_P, B_C);
      for (bk = 0; bk < nb; bk++) BUF[B_E][bk] = BUF[B_C][bk] | (rnd128() & ~mask);   //random don't-care low bits
      do_stream(1'b1, nb, md, sg, k, iv, B_E, B_D);
      for (bk = 0; bk < nb; bk++)
        check_eq($sformatf("R1 stream=%0d mode=%0d seg=%0d blk=%0d roundtrip", s, md, sg, bk), BUF[B_D][bk], BUF[B_P][bk], mask);
      //R2: OFB / CTR are symmetric
      if (md == M_OFB || md == M_CTR) begin
        do_stream(1'b1, nb, md, sg, k, iv, B_P, B_D);
        for (bk = 0; bk < nb; bk++)
          check_eq($sformatf("R2 stream=%0d mode=%0d blk=%0d decipher(P)==cipher(P)", s, md, bk), BUF[B_D][bk], BUF[B_C][bk], ALL1);
      end
      //R3: ECB is deterministic
      if (md == M_ECB && nb >= 2) begin
        BUF[B_P][1] = BUF[B_P][0];
        do_stream(1'b0, 2, md, sg, k, iv, B_P, B_D);
        check_eq($sformatf("R3 stream=%0d ECB same block, same ciphertext", s), BUF[B_D][1], BUF[B_D][0], ALL1);
      end
      //R4: CBC diffusion along the chain (ciphertext 1 depends on plaintext 0)
      if (md == M_CBC && nb >= 2) begin
        do_stream(1'b0, 2, md, sg, k, iv, B_P, B_D);
        BUF[B_P][0] = BUF[B_P][0] ^ 128'h1;
        do_stream(1'b0, 2, md, sg, k, iv, B_P, B_E);
        check_true($sformatf("R4 stream=%0d CBC ciphertext 1 depends on plaintext 0", s), BUF[B_D][1] !== BUF[B_E][1]);
      end
    end
    $display("---- coverage (streams): ECB=%0d CBC=%0d CFB=%0d OFB=%0d CTR=%0d | CFB segments %0d %0d %0d %0d %0d %0d %0d %0d",
             cov_m[0], cov_m[1], cov_m[2], cov_m[3], cov_m[4], cov_s[0], cov_s[1], cov_s[2], cov_s[3], cov_s[4], cov_s[5], cov_s[6], cov_s[7]);
    check_true("no err_busy / err_cfg during legal random stimulus", n_err_busy == 0 && n_err_cfg == 0);
    report("tb_aes128_roundtrip");
  end
  initial begin
    #400000000;
    $display("GLOBAL WATCHDOG");
    $display("TEST_RESULT: FAIL watchdog tb_aes128_roundtrip");
    $fatal(1, "watchdog");
  end
endmodule
