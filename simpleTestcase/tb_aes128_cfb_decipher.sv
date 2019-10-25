//-----------------------------------------------------------
// Function:	Simple test for CFB decipher mode
//-----------------------------------------------------------
// Author: Nguyen Hung Quan
// Website: http://nguyenquanicd.blogspot.com/
//-----------------------------------------------------------
module tb_aes128_cfb_decipher;
  //input
  logic clk;
  logic rst_n;
  logic cipher_en;
  logic decipher_en;
  logic chain_en;
  logic [127:0] data_in;
  logic [127:0] key;
  logic [3:0]   mode;
  logic [127:0] init_vector;
  logic [15:0]  segment_len;
  //output
  logic [127:0] data_out;
  logic ready;
  
  logic fail_flag;
  logic [127:0] mask;
  
  aes128 aes128 (
    //input
    clk,
    rst_n,
    cipher_en,
    decipher_en,
    chain_en,
    data_in,
    key,
    mode,
    init_vector,
    segment_len,
    //output
    data_out,
    ready
    );
  
  initial begin
    clk <= 0;
    forever #2 clk = ~clk;
  end
  
  initial begin
    rst_n <= 0;
    #5
    rst_n <= 1;
  end
  //
  always_comb begin
    case (segment_len)
      0: mask = 128'h80000000000000000000000000000000; //1-CFB
      1: mask = 128'hC0000000000000000000000000000000; //2-CFB
      2: mask = 128'hF0000000000000000000000000000000; //4-CFB
      3: mask = 128'hFF000000000000000000000000000000; //8-CFB
      4: mask = 128'hFFFF0000000000000000000000000000; //16-CFB
      5: mask = 128'hFFFFFFFF000000000000000000000000; //32-CFB
      6: mask = 128'hFFFFFFFFFFFFFFFF0000000000000000; //64-CFB
      7: mask = 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; //128-CFB
    endcase
  end
  //
  initial begin
    cipher_en   = 0;
    decipher_en = 0;
    chain_en    = 0;
    data_in     = 128'd0;
    key         = 128'd0;
    mode        = 4'd2;
    init_vector = 128'd0;
    segment_len = 4'd0;
    
    //
    //1-CFB
    //
    repeat (1) @ (posedge clk);
    chain_en    = 0;
    //--------------------------------------------------
    //DECIPHER 1
    //--------------------------------------------------
    repeat (1) @ (posedge clk);
    cipher_en   = 0;
    decipher_en = 1;
    chain_en    = 1;
    data_in     = 128'h0123456789abcdeffedcba987654321f;
    key         = 128'h2b7e151628aed2a6abf7158809cf4f3c;
    init_vector = 128'h000102030405060708090a0b0c0d0e0f;
    segment_len = 4'd0;
    repeat (1) @ (posedge clk);
    decipher_en   = 0;
    //
    @ (posedge ready);
    info_task();
    if ((data_out & mask) != 0 ||
        (aes128.output_block != 128'h50fe67cc996d32b6da0937e99bafec60)) begin
      fail_flag = 1;
      $strobe ("----- FAIL");
      $strobe ("  +++ Input block: %32h", aes128.decipher_input_block);
      $strobe ("  +++ Output block: %32h", aes128.output_block);
      $strobe ("  +++ Expected: 0");
      $strobe ("  +++ Actual:   %32h", data_out);
    end
    else begin
      $strobe ("----- PASS");
    end
    //--------------------------------------------------
    //DECIPHER 2
    //--------------------------------------------------
    repeat (1) @ (posedge clk);
    cipher_en   = 0;
    decipher_en = 1;
    chain_en    = 1;
    data_in     = 128'h8123456789abcdeffedcba987654321f;
    key         = 128'h2b7e151628aed2a6abf7158809cf4f3c;
    init_vector = 128'h000102030405060708090a0b0c0d0e0f;
    segment_len = 4'd0;
    repeat (1) @ (posedge clk);
    decipher_en   = 0;
    //
    @ (posedge ready);
    info_task();
    if ((data_out & mask) != 128'h80000000000000000000000000000000 ||
    (aes128.output_block != 128'h19cf576c7596e702f298b35666955c79)) begin
      fail_flag = 1;
      $strobe ("----- FAIL");
      $strobe ("  +++ Input block: %32h", aes128.decipher_input_block);
      $strobe ("  +++ Output block: %32h", aes128.output_block);
      $strobe ("  +++ Expected: 0");
      $strobe ("  +++ Actual:   %32h", data_out);
    end
    else begin
      $strobe ("----- PASS");
    end
    //--------------------------------------------------
    //DECIPHER 3
    //--------------------------------------------------
    repeat (1) @ (posedge clk);
    cipher_en   = 0;
    decipher_en = 1;
    chain_en    = 1;
    data_in     = 128'h80000000000000000000000000000000;
    key         = 128'h2b7e151628aed2a6abf7158809cf4f3c;
    init_vector = 128'h000102030405060708090a0b0c0d0e0f;
    segment_len = 4'd0;
    repeat (1) @ (posedge clk);
    decipher_en   = 0;
    //
    @ (posedge ready);
    info_task();
    if ((data_out & mask) != 128'h80000000000000000000000000000000 ||
    (aes128.output_block != 128'h59e17759acd02b801fa321ea059e331f)) begin
      fail_flag = 1;
      $strobe ("----- FAIL");
      $strobe ("  +++ Input block: %32h", aes128.decipher_input_block);
      $strobe ("  +++ Output block: %32h", aes128.output_block);
      $strobe ("  +++ Expected: 0");
      $strobe ("  +++ Actual:   %32h", data_out);
    end
    else begin
      $strobe ("----- PASS");
    end
    //--------------------------------------------------
    //DECIPHER 4
    //--------------------------------------------------
    repeat (1) @ (posedge clk);
    cipher_en   = 0;
    decipher_en = 1;
    chain_en    = 1;
    data_in     = 128'h00000000000000000000000000000000;
    key         = 128'h2b7e151628aed2a6abf7158809cf4f3c;
    init_vector = 128'h000102030405060708090a0b0c0d0e0f;
    segment_len = 4'd0;
    repeat (1) @ (posedge clk);
    decipher_en   = 0;
    //
    @ (posedge ready);
    info_task();
    if ((data_out & mask) != 0 ||
    (aes128.output_block != 128'h71f415b0cc109e8b0faa14ab740c22f4)) begin
      fail_flag = 1;
      $strobe ("----- FAIL");
      $strobe ("  +++ Input block: %32h", aes128.decipher_input_block);
      $strobe ("  +++ Output block: %32h", aes128.output_block);
      $strobe ("  +++ Expected: 0");
      $strobe ("  +++ Actual:   %32h", data_out);
    end
    else begin
      $strobe ("----- PASS");
    end
    
    //
    //8-CFB
    //
    repeat (1) @ (posedge clk);
    chain_en    = 0;
    //--------------------------------------------------
    //DECIPHER 1
    //--------------------------------------------------
    repeat (1) @ (posedge clk);
    cipher_en   = 0;
    decipher_en = 1;
    chain_en    = 1;
    data_in     = 128'h3b23456789abcdeffedcba987654321f;
    key         = 128'h2b7e151628aed2a6abf7158809cf4f3c;
    init_vector = 128'h000102030405060708090a0b0c0d0e0f;
    segment_len = 4'd3;
    repeat (1) @ (posedge clk);
    decipher_en   = 0;
    //
    @ (posedge ready);
    info_task();
    if ((data_out & mask) != 128'h6b000000000000000000000000000000 ||
        (aes128.output_block != 128'h50fe67cc996d32b6da0937e99bafec60)) begin
      fail_flag = 1;
      $strobe ("----- FAIL");
      $strobe ("  +++ Input block: %32h", aes128.decipher_input_block);
      $strobe ("  +++ Output block: %32h", aes128.output_block);
      $strobe ("  +++ Expected: 0");
      $strobe ("  +++ Actual:   %32h", data_out);
    end
    else begin
      $strobe ("----- PASS");
    end
    //--------------------------------------------------
    //DECIPHER 2
    //--------------------------------------------------
    repeat (1) @ (posedge clk);
    cipher_en   = 0;
    decipher_en = 1;
    chain_en    = 1;
    data_in     = 128'h7923456789abcdeffedcba987654321f;
    key         = 128'h2b7e151628aed2a6abf7158809cf4f3c;
    init_vector = 128'h000102030405060708090a0b0c0d0e0f;
    segment_len = 4'd3;
    repeat (1) @ (posedge clk);
    decipher_en   = 0;
    //
    @ (posedge ready);
    info_task();
    if ((data_out & mask) != 128'hc1000000000000000000000000000000 ||
    (aes128.output_block != 128'hb8eb865a2b026381abb1d6560ed20f68)) begin
      fail_flag = 1;
      $strobe ("----- FAIL");
      $strobe ("  +++ Input block: %32h", aes128.decipher_input_block);
      $strobe ("  +++ Output block: %32h", aes128.output_block);
      $strobe ("  +++ Expected: 0");
      $strobe ("  +++ Actual:   %32h", data_out);
    end
    else begin
      $strobe ("----- PASS");
    end
    //--------------------------------------------------
    //DECIPHER 3
    //--------------------------------------------------
    repeat (1) @ (posedge clk);
    cipher_en   = 0;
    decipher_en = 1;
    chain_en    = 1;
    data_in     = 128'h42000000000000000000000000000000;
    key         = 128'h2b7e151628aed2a6abf7158809cf4f3c;
    init_vector = 128'h000102030405060708090a0b0c0d0e0f;
    segment_len = 4'd3;
    repeat (1) @ (posedge clk);
    decipher_en   = 0;
    //
    @ (posedge ready);
    info_task();
    if ((data_out & mask) != 128'hbe000000000000000000000000000000 ||
    (aes128.output_block != 128'hfce6033b4edce64cbaed3f61ff5b927c)) begin
      fail_flag = 1;
      $strobe ("----- FAIL");
      $strobe ("  +++ Input block: %32h", aes128.decipher_input_block);
      $strobe ("  +++ Output block: %32h", aes128.output_block);
      $strobe ("  +++ Expected: 0");
      $strobe ("  +++ Actual:   %32h", data_out);
    end
    else begin
      $strobe ("----- PASS");
    end
    //--------------------------------------------------
    //DECIPHER 4
    //--------------------------------------------------
    repeat (1) @ (posedge clk);
    cipher_en   = 0;
    decipher_en = 1;
    chain_en    = 1;
    data_in     = 128'h4c000000000000000000000000000000;
    key         = 128'h2b7e151628aed2a6abf7158809cf4f3c;
    init_vector = 128'h000102030405060708090a0b0c0d0e0f;
    segment_len = 4'd3;
    repeat (1) @ (posedge clk);
    decipher_en   = 0;
    //
    @ (posedge ready);
    info_task();
    if ((data_out & mask) != 128'he2000000000000000000000000000000 ||
    (aes128.output_block != 128'hae4e5e7ffe805f7a4395b180004f8ca8)) begin
      fail_flag = 1;
      $strobe ("----- FAIL");
      $strobe ("  +++ Input block: %32h", aes128.decipher_input_block);
      $strobe ("  +++ Output block: %32h", aes128.output_block);
      $strobe ("  +++ Expected: 0");
      $strobe ("  +++ Actual:   %32h", data_out);
    end
    else begin
      $strobe ("----- PASS");
    end
    
    //
    //128-CFB
    //
    repeat (1) @ (posedge clk);
    chain_en    = 0;
    //--------------------------------------------------
    //DECIPHER 1
    //--------------------------------------------------
    repeat (1) @ (posedge clk);
    cipher_en   = 0;
    decipher_en = 1;
    chain_en    = 1;
    data_in     = 128'h3b3fd92eb72dad20333449f8e83cfb4a;
    key         = 128'h2b7e151628aed2a6abf7158809cf4f3c;
    init_vector = 128'h000102030405060708090a0b0c0d0e0f;
    segment_len = 4'd7;
    repeat (1) @ (posedge clk);
    decipher_en   = 0;
    //
    @ (posedge ready);
    info_task();
    if ((data_out & mask) != 128'h6bc1bee22e409f96e93d7e117393172a ||
        (aes128.output_block != 128'h50fe67cc996d32b6da0937e99bafec60)) begin
      fail_flag = 1;
      $strobe ("----- FAIL");
      $strobe ("  +++ Input block: %32h", aes128.decipher_input_block);
      $strobe ("  +++ Output block: %32h", aes128.output_block);
      $strobe ("  +++ Expected: 0");
      $strobe ("  +++ Actual:   %32h", data_out);
    end
    else begin
      $strobe ("----- PASS");
    end
    //--------------------------------------------------
    //DECIPHER 2
    //--------------------------------------------------
    repeat (1) @ (posedge clk);
    cipher_en   = 0;
    decipher_en = 1;
    chain_en    = 1;
    data_in     = 128'hc8a64537a0b3a93fcde3cdad9f1ce58b;
    key         = 128'h2b7e151628aed2a6abf7158809cf4f3c;
    init_vector = 128'h000102030405060708090a0b0c0d0e0f;
    segment_len = 4'd7;
    repeat (1) @ (posedge clk);
    decipher_en   = 0;
    //
    @ (posedge ready);
    info_task();
    if ((data_out & mask) != 128'hae2d8a571e03ac9c9eb76fac45af8e51 ||
    (aes128.output_block != 128'h668bcf60beb005a35354a201dab36bda)) begin
      fail_flag = 1;
      $strobe ("----- FAIL");
      $strobe ("  +++ Input block: %32h", aes128.decipher_input_block);
      $strobe ("  +++ Output block: %32h", aes128.output_block);
      $strobe ("  +++ Expected: 0");
      $strobe ("  +++ Actual:   %32h", data_out);
    end
    else begin
      $strobe ("----- PASS");
    end
    //--------------------------------------------------
    //DECIPHER 3
    //--------------------------------------------------
    repeat (1) @ (posedge clk);
    cipher_en   = 0;
    decipher_en = 1;
    chain_en    = 1;
    data_in     = 128'h26751f67a3cbb140b1808cf187a4f4df;
    key         = 128'h2b7e151628aed2a6abf7158809cf4f3c;
    init_vector = 128'h000102030405060708090a0b0c0d0e0f;
    segment_len = 4'd7;
    repeat (1) @ (posedge clk);
    decipher_en   = 0;
    //
    @ (posedge ready);
    info_task();
    if ((data_out & mask) != 128'h30c81c46a35ce411e5fbc1191a0a52ef ||
    (aes128.output_block != 128'h16bd032100975551547b4de89daea630)) begin
      fail_flag = 1;
      $strobe ("----- FAIL");
      $strobe ("  +++ Input block: %32h", aes128.decipher_input_block);
      $strobe ("  +++ Output block: %32h", aes128.output_block);
      $strobe ("  +++ Expected: 0");
      $strobe ("  +++ Actual:   %32h", data_out);
    end
    else begin
      $strobe ("----- PASS");
    end
    //--------------------------------------------------
    //DECIPHER 4
    //--------------------------------------------------
    repeat (1) @ (posedge clk);
    cipher_en   = 0;
    decipher_en = 1;
    chain_en    = 1;
    data_in     = 128'hc04b05357c5d1c0eeac4c66f9ff7f2e6;
    key         = 128'h2b7e151628aed2a6abf7158809cf4f3c;
    init_vector = 128'h000102030405060708090a0b0c0d0e0f;
    segment_len = 4'd7;
    repeat (1) @ (posedge clk);
    decipher_en   = 0;
    //
    @ (posedge ready);
    info_task();
    if ((data_out & mask) != 128'hf69f2445df4f9b17ad2b417be66c3710 ||
    (aes128.output_block != 128'h36d42170a312871947ef8714799bc5f6)) begin
      fail_flag = 1;
      $strobe ("----- FAIL");
      $strobe ("  +++ Input block: %32h", aes128.decipher_input_block);
      $strobe ("  +++ Output block: %32h", aes128.output_block);
      $strobe ("  +++ Expected: 0");
      $strobe ("  +++ Actual:   %32h", data_out);
    end
    else begin
      $strobe ("----- PASS");
    end
    //
    //
    //
    //
    //
    repeat (1) @ (posedge clk);
    if (fail_flag) begin
      $strobe ("--------------------------------------------------");
      $strobe ("FAIL FAIL FAIL FAIL FAIL FAIL FAIL");
      $strobe ("FAIL FAIL FAIL FAIL FAIL FAIL FAIL");
      $strobe ("FAIL FAIL FAIL FAIL FAIL FAIL FAIL");
      $strobe ("--------------------------------------------------");
    end
    else begin
      $strobe ("--------------------------------------------------");
      $strobe ("PASS PASS PASS PASS PASS PASS PASS");
      $strobe ("PASS PASS PASS PASS PASS PASS PASS");
      $strobe ("PASS PASS PASS PASS PASS PASS PASS");
      $strobe ("--------------------------------------------------");
    end
    repeat (1) @ (posedge clk);
    $stop;
  end
  
  task info_task;
    $strobe ("--------------------------------------------------");
    if (aes128.decipher_mode) begin
      $strobe ("----- Process: DECIPHER");
    end
    else begin
      $strobe ("----- Process: CIPHER");
    end
    //
    case (mode)
      4'd0: $strobe("----- Crypt mode: ECB");
      4'd1: $strobe("----- Crypt mode: CBC");
      4'd2: $strobe("----- Crypt mode: CFB");
      4'd3: $strobe("----- Crypt mode: OFB");
      4'd4: $strobe("----- Crypt mode: CTR");
      default: $strobe("----- FAIL");
    endcase
    $strobe ("----- segment_len = %b", segment_len);
    $strobe ("----- mode_reg = %b", aes128.mode_reg);
    $strobe ("----- chain_en = %b", chain_en);
    $strobe ("----- data_in = %32h", data_in);
    $strobe ("----- data_out = %32h", data_out);
    $strobe ("----- init_vector = %32h", init_vector);
    $strobe ("----- decipher_start_in = %32h", aes128.decipher_start_in);
    $strobe ("----- start_reg = %32h", aes128.start_reg);
    $strobe ("----- end_reg = %32h", aes128.end_reg);
    $strobe ("----- output_block = %32h", aes128.output_block);
    $strobe ("----- decipher_input_block for the NEXT step = %32h", aes128.decipher_input_block);
  endtask
  
endmodule
