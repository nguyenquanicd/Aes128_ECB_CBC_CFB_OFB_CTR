//-----------------------------------------------------------
// Function: Directed protocol / corner-case test of aes128
//-----------------------------------------------------------
// Covered:
//   T1  reset values                       T7  start while busy is rejected
//   T2  exact latency of every mode        T8  illegal configuration is rejected
//   T3  data_out lower bits of CFB are 0   T9  reset in the middle of an operation
//   T4  chain_en: restart / single-shot    T10 any mode after any mode (5x5, key change)
//   T5  chain_en raised early              T11 inputs are not needed after the start clock
//   T6  back-to-back start on the first clock where ready is high
// All expectations are NIST SP 800-38A known answers (first block).
//-----------------------------------------------------------
`timescale 1ns/1ps
module tb_aes128_protocol;
  `include "aes128_tb_common.svh"
  //---------------------------------------------------------
  localparam logic [127:0] KEY    = 128'h2b7e151628aed2a6abf7158809cf4f3c;
  localparam logic [127:0] IV     = 128'h000102030405060708090a0b0c0d0e0f;
  localparam logic [127:0] CTR_IV = 128'hf0f1f2f3f4f5f6f7f8f9fafbfcfdfeff;
  localparam logic [127:0] P1     = 128'h6bc1bee22e409f96e93d7e117393172a;
  localparam logic [127:0] P2     = 128'hae2d8a571e03ac9c9eb76fac45af8e51;
  localparam logic [127:0] C_ECB  = 128'h3ad77bb40d7a3660a89ecaf32466ef97;
  localparam logic [127:0] C_CBC1 = 128'h7649abac8119b246cee98e9b12e9197d;
  localparam logic [127:0] C_CBC2 = 128'h5086cb9b507219ee95db113a917678b2;
  localparam logic [127:0] C_CFB  = 128'h3b3fd92eb72dad20333449f8e83cfb4a;   //CFB128 and OFB, block 1
  localparam logic [127:0] C_CTR  = 128'h874d6191b620e3261bef6864990db6ce;
  //
  logic [127:0] d;
  int lat, m, dd, a, b;
  int busy_before;
  logic [127:0] dout_hold;
  //---------------------------------------------------------
  // Known-answer helpers
  //---------------------------------------------------------
  function automatic logic [127:0] kat_iv(input int mm);
    case (mm)
      1, 2, 3: return IV;
      4:       return CTR_IV;
      default: return IV;
    endcase
  endfunction
  function automatic logic [127:0] kat_c1(input int mm);
    case (mm)
      0: return C_ECB;
      1: return C_CBC1;
      2, 3: return C_CFB;
      default: return C_CTR;
    endcase
  endfunction
  //Run the first-block KAT of mode mm in direction dir (chain_en=1) and check it
  task automatic kat(input int mm, input bit dir, input string tag);
    logic [127:0] o;
    int l;
    run_op(dir, mm[3:0], 4'd7, 1'b1, KEY, kat_iv(mm), dir ? kat_c1(mm) : P1, o, l);
    check_eq($sformatf("%s mode %0d %s", tag, mm, dir ? "dec" : "enc"), o, dir ? P1 : kat_c1(mm), ALL1);
  endtask
  task automatic chain_gap;
    chain_en = 1'b0;
    tick(2);
  endtask
  //---------------------------------------------------------
  initial begin
    repeat (3) @ (negedge clk);
    rst_n = 1'b1;
    tick(2);
    //-------------------------------------------------------
    // T1 reset values
    //-------------------------------------------------------
    check_true("T1 ready=1 after reset", ready === 1'b1);
    check_true("T1 err flags 0 after reset", err_busy === 1'b0 && err_cfg === 1'b0);
    //-------------------------------------------------------
    // T2 latency: 11 clocks (cipher, CFB/OFB/CTR decipher), 22 clocks (ECB/CBC decipher)
    //-------------------------------------------------------
    for (m = 0; m < 5; m++) for (dd = 0; dd < 2; dd++) begin
      chain_gap;
      run_op(dd[0], m[3:0], 4'd7, 1'b1, KEY, kat_iv(m), dd ? kat_c1(m) : P1, d, lat);
      check_eq($sformatf("T2 KAT mode %0d dir %0d", m, dd), d, dd ? P1 : kat_c1(m), ALL1);
      check_true($sformatf("T2 latency mode %0d dir %0d is %0d (got %0d)", m, dd, (dd && m < 2) ? 22 : 11, lat),
                 lat == ((dd && m < 2) ? 22 : 11));
    end
    //-------------------------------------------------------
    // T3 CFB: the (128-segment) low bits of data_out are 0 (enc and dec)
    //-------------------------------------------------------
    chain_gap;
    run_op(1'b0, M_CFB, 4'd3, 1'b1, KEY, IV, {8'h6b, 120'hdeadbeefcafe0123456789abcdef01}, d, lat);   //CFB8
    check_eq("T3 CFB8 enc ciphertext byte", d, {8'h3b, 120'h0}, {8'hff, 120'h0});
    check_true("T3 CFB8 enc low 120 bits are 0", d[119:0] === 120'd0);
    chain_gap;
    run_op(1'b1, M_CFB, 4'd3, 1'b1, KEY, IV, {8'h3b, 120'h123456789abcdef0fedcba98765432}, d, lat);
    check_eq("T3 CFB8 dec plaintext byte", d, {8'h6b, 120'h0}, {8'hff, 120'h0});
    check_true("T3 CFB8 dec low 120 bits are 0", d[119:0] === 120'd0);
    //-------------------------------------------------------
    // T4 chain_en: CBC stream and restart, single-shot, chain_en low in the middle
    //-------------------------------------------------------
    chain_gap;
    run_op(1'b0, M_CBC, 4'd0, 1'b1, KEY, IV, P1, d, lat);   check_eq("T4 CBC blk1", d, C_CBC1, ALL1);
    run_op(1'b0, M_CBC, 4'd0, 1'b1, KEY, IV, P2, d, lat);   check_eq("T4 CBC blk2 (chained)", d, C_CBC2, ALL1);
    chain_gap;                                              //chain_en low for 2 clocks -> new stream
    run_op(1'b0, M_CBC, 4'd0, 1'b1, KEY, IV, P1, d, lat);   check_eq("T4 CBC restart = blk1 again", d, C_CBC1, ALL1);
    run_op(1'b0, M_CBC, 4'd0, 1'b0, KEY, IV, P2, d, lat);   //chain_en=0: single-shot CBC with the IV
    begin : t4_single
      logic [127:0] ecb_of_p2_xor_iv, cbc_single;
      cbc_single = d;
      chain_gap;
      run_op(1'b0, M_ECB, 4'd0, 1'b0, KEY, IV, P2 ^ IV, ecb_of_p2_xor_iv, lat);
      check_eq("T4 chain_en=0 CBC == ECB(P ^ IV)", cbc_single, ecb_of_p2_xor_iv, ALL1);
    end
    //chain_en=0 ECB / decipher right after a CBC stream (mode of the previous stream must not leak)
    chain_gap;
    run_op(1'b0, M_CBC, 4'd0, 1'b1, KEY, IV, P1, d, lat);
    run_op(1'b0, M_ECB, 4'd0, 1'b0, KEY, IV, P1, d, lat);   check_eq("T4 ECB enc chain_en=0 after CBC stream", d, C_ECB, ALL1);
    run_op(1'b1, M_ECB, 4'd0, 1'b0, KEY, IV, C_ECB, d, lat); check_eq("T4 ECB dec chain_en=0 after CBC stream", d, P1, ALL1);
    run_op(1'b1, M_CBC, 4'd0, 1'b0, KEY, IV, C_CBC1, d, lat); check_eq("T4 CBC dec single-shot (chain_en=0)", d, P1, ALL1);
    //mode input is ignored for the 2nd+ block of a stream (even if it is illegal)
    chain_gap;
    run_op(1'b0, M_CBC, 4'd0, 1'b1, KEY, IV, P1, d, lat);
    run_op(1'b0, 4'd13, 4'd0, 1'b1, KEY, IV, P2, d, lat);
    check_eq("T4 mode ignored inside a stream", d, C_CBC2, ALL1);
    check_true("T4 no err_cfg for ignored mode", n_err_cfg == 0);
    //-------------------------------------------------------
    // T5 chain_en raised 3 clocks before the first start
    //-------------------------------------------------------
    chain_gap;
    chain_en = 1'b1; tick(3);
    run_op(1'b0, M_CBC, 4'd0, 1'b1, KEY, IV, P1, d, lat);   check_eq("T5 CBC blk1 with early chain_en", d, C_CBC1, ALL1);
    run_op(1'b0, M_CBC, 4'd0, 1'b1, KEY, IV, P2, d, lat);   check_eq("T5 CBC blk2 with early chain_en", d, C_CBC2, ALL1);
    //-------------------------------------------------------
    // T6 start on the very first clock where ready is high (back-to-back)
    //-------------------------------------------------------
    chain_gap;
    start_op(1'b0, M_ECB, 4'd0, 1'b0, KEY, IV, P1);
    wait_ready(lat, 100);
    cipher_en = 1'b1; data_in = P2; chain_en = 1'b0;          //same negedge in which ready is first seen high
    @ (negedge clk); cipher_en = 1'b0;
    check_true("T6 second start accepted (ready low)", ready === 1'b0);
    wait_ready(lat, 100);
    @ (negedge clk);
    check_eq("T6 back-to-back ECB 2nd result", data_out, 128'hf5d3d58503b9699de785895a96fdbaaf, ALL1);
    check_true("T6 no err_busy on back-to-back", n_err_busy == 0);
    //-------------------------------------------------------
    // T7 start while busy is rejected and does not disturb the operation
    //-------------------------------------------------------
    for (m = 0; m < 5; m++) for (dd = 0; dd < 2; dd++) begin
      chain_gap;
      busy_before = n_err_busy;
      start_op(dd[0], m[3:0], 4'd7, 1'b1, KEY, kat_iv(m), dd ? kat_c1(m) : P1);
      tick(3);
      cipher_en = 1'b1; data_in = ~P1; key = ~KEY;            //stray start with different data and key
      @ (negedge clk); cipher_en = 1'b0;
      data_in = dd ? kat_c1(m) : P1; key = KEY;
      wait_ready(lat, 100);
      @ (negedge clk);
      check_eq($sformatf("T7 result unchanged mode %0d dir %0d", m, dd), data_out, dd ? P1 : kat_c1(m), ALL1);
      check_true($sformatf("T7 exactly one err_busy mode %0d dir %0d", m, dd), n_err_busy == busy_before + 1);
    end
    //-------------------------------------------------------
    // T8 illegal configuration: rejected, ready stays high, data_out unchanged
    //-------------------------------------------------------
    chain_gap;
    run_op(1'b0, M_ECB, 4'd0, 1'b0, KEY, IV, P1, d, lat);
    dout_hold = data_out;
    for (a = 5; a < 16; a++) begin                              //illegal modes
      start_op(1'b0, a[3:0], 4'd0, 1'b0, KEY, IV, P2);
      tick(2);
      check_true($sformatf("T8 illegal mode %0d keeps ready high", a), ready === 1'b1);
    end
    check_true("T8 11 err_cfg pulses for 11 illegal modes", n_err_cfg == 11);
    for (a = 8; a < 16; a++) begin                              //illegal CFB segment code
      start_op(1'b1, M_CFB, a[3:0], 1'b0, KEY, IV, P2);
      tick(2);
      check_true($sformatf("T8 illegal CFB segment %0d keeps ready high", a), ready === 1'b1);
    end
    check_true("T8 8 more err_cfg pulses for illegal CFB segments", n_err_cfg == 19);
    @ (negedge clk);                                            //both enables together
    key = KEY; mode = M_ECB; chain_en = 1'b0; data_in = P2; cipher_en = 1'b1; decipher_en = 1'b1;
    @ (negedge clk); cipher_en = 1'b0; decipher_en = 1'b0;
    tick(2);
    check_true("T8 cipher_en+decipher_en together is rejected", ready === 1'b1 && n_err_cfg == 20);
    check_true("T8 data_out unchanged by rejected starts", data_out === dout_hold);
    run_op(1'b0, M_ECB, 4'd0, 1'b0, KEY, IV, P1, d, lat);       //still works after the errors
    check_eq("T8 good op after rejected ones", d, C_ECB, ALL1);
    //-------------------------------------------------------
    // T9 reset in the middle of an operation
    //-------------------------------------------------------
    chain_gap;
    start_op(1'b0, M_CBC, 4'd0, 1'b1, KEY, IV, P1);
    tick(5);
    rst_n = 1'b0; tick(2); rst_n = 1'b1; tick(2);
    check_true("T9 ready=1 after reset in the middle of an operation", ready === 1'b1);
    check_true("T9 err flags 0 after reset", err_busy === 1'b0 && err_cfg === 1'b0);
    chain_gap;
    run_op(1'b0, M_CBC, 4'd0, 1'b1, KEY, IV, P1, d, lat);
    check_eq("T9 first op after reset", d, C_CBC1, ALL1);
    //reset while a long ECB decipher is running
    chain_gap;
    start_op(1'b1, M_ECB, 4'd0, 1'b1, KEY, IV, C_ECB);
    tick(15);
    rst_n = 1'b0; tick(2); rst_n = 1'b1; tick(2);
    run_op(1'b1, M_ECB, 4'd0, 1'b1, KEY, IV, C_ECB, d, lat);
    check_eq("T9 ECB decipher after reset in decipher pass", d, P1, ALL1);
    //-------------------------------------------------------
    // T10 any mode after any mode, with a key change in between
    //-------------------------------------------------------
    for (a = 0; a < 5; a++) for (b = 0; b < 5; b++) for (dd = 0; dd < 2; dd++) begin
      chain_gap;
      run_op(a[0], a[3:0], 4'd7, 1'b1, ~KEY, ~IV, ~P1, d, lat);       //other key, other direction
      chain_gap;
      kat(b, dd[0], $sformatf("T10 after mode %0d:", a));
    end
    //-------------------------------------------------------
    // T11 the inputs are only needed on the start clock
    //-------------------------------------------------------
    for (m = 0; m < 5; m++) for (dd = 0; dd < 2; dd++) begin
      chain_gap;
      start_op(dd[0], m[3:0], 4'd7, 1'b1, KEY, kat_iv(m), dd ? kat_c1(m) : P1);
      data_in = 128'hdeadbeefdeadbeefdeadbeefdeadbeef; key = 128'h0; init_vector = 128'h1; mode = 4'd9; segment_len = 4'd15;
      wait_ready(lat, 100);
      @ (negedge clk);
      check_eq($sformatf("T11 inputs scrambled after start, mode %0d dir %0d", m, dd), data_out, dd ? P1 : kat_c1(m), ALL1);
    end
    tick(5);
    report("tb_aes128_protocol");
  end
  initial begin
    #2000000;
    $display("GLOBAL WATCHDOG");
    $display("TEST_RESULT: FAIL watchdog tb_aes128_protocol");
    $fatal(1, "watchdog");
  end
endmodule
