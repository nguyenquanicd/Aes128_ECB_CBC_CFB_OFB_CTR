//-----------------------------------------------------------
// Function:	Simple test for ECB mode
//-----------------------------------------------------------
// Author: Nguyen Hung Quan
// Website: http://nguyenquanicd.blogspot.com/
//-----------------------------------------------------------
module tb_aes128_ecb;
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
  
  initial begin
    cipher_en   = 0;
    decipher_en = 0;
    chain_en    = 0;
    data_in     = 128'd0;
    key         = 128'd0;
    mode        = 4'd0;
    init_vector = 128'd0;
    segment_len = 4'd0;
    //
    //Do NOT assert chain_en
    //
    //--------------------------------------------------
    //Cipher 1
    //ECB
    //--------------------------------------------------
    repeat (1) @ (posedge clk);
    cipher_en   = 1;
    decipher_en = 0;
    chain_en    = 0;
    data_in     = 128'h6bc1bee22e409f96e93d7e117393172a;
    key         = 128'h2b7e151628aed2a6abf7158809cf4f3c;
    mode        = 4'd0;
    init_vector = 128'h000102030405060708090a0b0c0d0e0f;
    segment_len = 4'd0;
    repeat (1) @ (posedge clk);
    cipher_en   = 0;
    //
    @ (posedge ready);
    info_task();
    if (data_out != 128'h3ad77bb40d7a3660a89ecaf32466ef97) begin
      fail_flag = 1;
      $strobe ("----- FAIL");
      $strobe ("  +++ Expected: 3ad77bb40d7a3660a89ecaf32466ef97");
      $strobe ("  +++ Actual:   %32h", data_out);
    end
    else begin
      $strobe ("----- PASS");
    end
    //--------------------------------------------------
    //Cipher 2
    //ECB
    //--------------------------------------------------
    repeat (1) @ (posedge clk);
    cipher_en   = 1;
    decipher_en = 0;
    chain_en    = 0;
    data_in     = 128'hae2d8a571e03ac9c9eb76fac45af8e51;
    key         = 128'h2b7e151628aed2a6abf7158809cf4f3c;
    mode        = 4'd0;
    init_vector = 128'h000102030405060708090a0b0c0d0e0f;
    segment_len = 4'd0;
    repeat (1) @ (posedge clk);
    cipher_en   = 0;
    //
    @ (posedge ready);
    info_task();
    if (data_out != 128'hf5d3d58503b9699de785895a96fdbaaf) begin
      fail_flag = 1;
      $strobe ("----- FAIL");
      $strobe ("  +++ Expected: f5d3d58503b9699de785895a96fdbaaf");
      $strobe ("  +++ Actual:   %32h", data_out);
    end
    else begin
      $strobe ("----- PASS");
    end
    //--------------------------------------------------
    //Decipher 1
    //ECB
    //--------------------------------------------------
    repeat (1) @ (posedge clk);
    cipher_en   = 0;
    decipher_en = 1;
    chain_en    = 0;
    data_in     = 128'h3ad77bb40d7a3660a89ecaf32466ef97;
    key         = 128'h2b7e151628aed2a6abf7158809cf4f3c;
    mode        = 4'd0;
    init_vector = 128'h000102030405060708090a0b0c0d0e0f;
    segment_len = 4'd0;
    repeat (1) @ (posedge clk);
    decipher_en   = 0;
    //
    @ (posedge ready);
    info_task();
    if (data_out != 128'h6bc1bee22e409f96e93d7e117393172a) begin
      fail_flag = 1;
      $strobe ("----- FAIL");
      $strobe ("  +++ Expected: 6bc1bee22e409f96e93d7e117393172a");
      $strobe ("  +++ Actual:   %32h", data_out);
    end
    else begin
      $strobe ("----- PASS");
    end
    //--------------------------------------------------
    //Decipher 2
    //ECB
    //--------------------------------------------------
    //repeat (1) @ (posedge clk);
    //chain_en    = 1;
    repeat (1) @ (posedge clk);
    cipher_en   = 0;
    decipher_en = 1;
    chain_en    = 0;
    data_in     = 128'hf5d3d58503b9699de785895a96fdbaaf;
    key         = 128'h2b7e151628aed2a6abf7158809cf4f3c;
    mode        = 4'd0;
    init_vector = 128'h000102030405060708090a0b0c0d0e0f;
    segment_len = 4'd0;
    repeat (1) @ (posedge clk);
    decipher_en   = 0;
    //
    @ (posedge ready);
    info_task();
    if (data_out != 128'hae2d8a571e03ac9c9eb76fac45af8e51) begin
      fail_flag = 1;
      $strobe ("----- FAIL");
      $strobe ("  +++ Expected: ae2d8a571e03ac9c9eb76fac45af8e51");
      $strobe ("  +++ Actual:   %32h", data_out);
    end
    else begin
      $strobe ("----- PASS");
    end
    //
    //Assert chain_en
    //
    //--------------------------------------------------
    //Cipher 1
    //ECB
    //--------------------------------------------------
    repeat (1) @ (posedge clk);
    cipher_en   = 1;
    decipher_en = 0;
    chain_en    = 1;
    data_in     = 128'h6bc1bee22e409f96e93d7e117393172a;
    key         = 128'h2b7e151628aed2a6abf7158809cf4f3c;
    mode        = 4'd0;
    init_vector = 128'h000102030405060708090a0b0c0d0e0f;
    segment_len = 4'd0;
    repeat (1) @ (posedge clk);
    cipher_en   = 0;
    //
    @ (posedge ready);
    info_task();
    if (data_out != 128'h3ad77bb40d7a3660a89ecaf32466ef97) begin
      fail_flag = 1;
      $strobe ("----- FAIL");
      $strobe ("  +++ Expected: 3ad77bb40d7a3660a89ecaf32466ef97");
      $strobe ("  +++ Actual:   %32h", data_out);
    end
    else begin
      $strobe ("----- PASS");
    end
    //--------------------------------------------------
    //Cipher 2
    //ECB
    //--------------------------------------------------
    repeat (1) @ (posedge clk);
    cipher_en   = 1;
    decipher_en = 0;
    chain_en    = 1;
    data_in     = 128'hae2d8a571e03ac9c9eb76fac45af8e51;
    key         = 128'h2b7e151628aed2a6abf7158809cf4f3c;
    mode        = 4'd0;
    init_vector = 128'h000102030405060708090a0b0c0d0e0f;
    segment_len = 4'd0;
    repeat (1) @ (posedge clk);
    cipher_en   = 0;
    //
    @ (posedge ready);
    info_task();
    if (data_out != 128'hf5d3d58503b9699de785895a96fdbaaf) begin
      fail_flag = 1;
      $strobe ("----- FAIL");
      $strobe ("  +++ Expected: f5d3d58503b9699de785895a96fdbaaf");
      $strobe ("  +++ Actual:   %32h", data_out);
    end
    else begin
      $strobe ("----- PASS");
    end
    //--------------------------------------------------
    //Decipher 1
    //ECB
    //--------------------------------------------------
    //repeat (1) @ (posedge clk);
    //chain_en    = 1;
    repeat (1) @ (posedge clk);
    cipher_en   = 0;
    decipher_en = 1;
    chain_en    = 1;
    data_in     = 128'h3ad77bb40d7a3660a89ecaf32466ef97;
    key         = 128'h2b7e151628aed2a6abf7158809cf4f3c;
    mode        = 4'd0;
    init_vector = 128'h000102030405060708090a0b0c0d0e0f;
    segment_len = 4'd0;
    repeat (1) @ (posedge clk);
    decipher_en   = 0;
    //
    @ (posedge ready);
    info_task();
    if (data_out != 128'h6bc1bee22e409f96e93d7e117393172a) begin
      fail_flag = 1;
      $strobe ("----- FAIL");
      $strobe ("  +++ Expected: 6bc1bee22e409f96e93d7e117393172a");
      $strobe ("  +++ Actual:   %32h", data_out);
    end
    else begin
      $strobe ("----- PASS");
    end
    //--------------------------------------------------
    //Decipher 2
    //ECB
    //--------------------------------------------------
    repeat (1) @ (posedge clk);
    cipher_en   = 0;
    decipher_en = 1;
    chain_en    = 1;
    data_in     = 128'hf5d3d58503b9699de785895a96fdbaaf;
    key         = 128'h2b7e151628aed2a6abf7158809cf4f3c;
    mode        = 4'd0;
    init_vector = 128'h000102030405060708090a0b0c0d0e0f;
    segment_len = 4'd0;
    repeat (1) @ (posedge clk);
    decipher_en   = 0;
    //
    @ (posedge ready);
    info_task();
    if (data_out != 128'hae2d8a571e03ac9c9eb76fac45af8e51) begin
      fail_flag = 1;
      $strobe ("----- FAIL");
      $strobe ("  +++ Expected: ae2d8a571e03ac9c9eb76fac45af8e51");
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
  //
  //
  //
  //
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
    $strobe ("----- chain_en: %b", chain_en);
    $strobe ("----- data_in = %32h", data_in);
    $strobe ("----- data_out = %32h", data_out);
  endtask
endmodule