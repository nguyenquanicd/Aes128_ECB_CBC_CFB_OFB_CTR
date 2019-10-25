//-----------------------------------------------------------
// Function:	Simple test for OFB mode
//-----------------------------------------------------------
// Author: Nguyen Hung Quan
// Website: http://nguyenquanicd.blogspot.com/
//-----------------------------------------------------------
module tb_aes128_ofb;
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
    
    //--------------------------------------------------
    //Cipher 1
    //--------------------------------------------------
    repeat (1) @ (posedge clk);
    cipher_en   = 1;
    decipher_en = 0;
    chain_en    = 1;
    data_in     = 128'h6bc1bee22e409f96e93d7e117393172a;
    key         = 128'h2b7e151628aed2a6abf7158809cf4f3c;
    mode        = 4'd3; //OFB
    init_vector = 128'h000102030405060708090a0b0c0d0e0f;
    segment_len = 4'd0;
    repeat (1) @ (posedge clk);
    cipher_en   = 0;
    //
    @ (posedge ready);
    info_task();
    if (data_out != 128'h3b3fd92eb72dad20333449f8e83cfb4a) begin
      fail_flag = 1;
      $strobe ("----- FAIL");
      $strobe ("  +++ Expected: 3b3fd92eb72dad20333449f8e83cfb4a");
      $strobe ("  +++ Actual:   %32h", data_out);
    end
    else begin
      $strobe ("----- PASS");
    end
    //--------------------------------------------------
    //Cipher 2
    //--------------------------------------------------
    repeat (1) @ (posedge clk);
    cipher_en   = 1;
    decipher_en = 0;
    chain_en    = 1;
    data_in     = 128'hae2d8a571e03ac9c9eb76fac45af8e51;
    key         = 128'h2b7e151628aed2a6abf7158809cf4f3c;
    mode        = 4'd3; //OFB
    init_vector = 128'h000102030405060708090a0b0c0d0e0f;
    segment_len = 4'd0;
    repeat (1) @ (posedge clk);
    cipher_en   = 0;
    //
    @ (posedge ready);
    info_task();
    if (data_out != 128'h7789508d16918f03f53c52dac54ed825) begin
      fail_flag = 1;
      $strobe ("----- FAIL");
      $strobe ("  +++ Expected: 7789508d16918f03f53c52dac54ed825");
      $strobe ("  +++ Actual:   %32h", data_out);
    end
    else begin
      $strobe ("----- PASS");
    end
    //--------------------------------------------------
    //Cipher 3
    //--------------------------------------------------
    repeat (1) @ (posedge clk);
    cipher_en   = 1;
    decipher_en = 0;
    chain_en    = 1;
    data_in     = 128'h30c81c46a35ce411e5fbc1191a0a52ef;
    key         = 128'h2b7e151628aed2a6abf7158809cf4f3c;
    mode        = 4'd3; //OFB
    init_vector = 128'h000102030405060708090a0b0c0d0e0f;
    segment_len = 4'd0;
    repeat (1) @ (posedge clk);
    cipher_en   = 0;
    //
    @ (posedge ready);
    info_task();
    if (data_out != 128'h9740051e9c5fecf64344f7a82260edcc) begin
      fail_flag = 1;
      $strobe ("----- FAIL");
      $strobe ("  +++ Expected: 9740051e9c5fecf64344f7a82260edcc");
      $strobe ("  +++ Actual:   %32h", data_out);
    end
    else begin
      $strobe ("----- PASS");
    end
    //--------------------------------------------------
    //Cipher 4
    //--------------------------------------------------
    repeat (1) @ (posedge clk);
    cipher_en   = 1;
    decipher_en = 0;
    chain_en    = 1;
    data_in     = 128'hf69f2445df4f9b17ad2b417be66c3710;
    key         = 128'h2b7e151628aed2a6abf7158809cf4f3c;
    mode        = 4'd3; //OFB
    init_vector = 128'h000102030405060708090a0b0c0d0e0f;
    segment_len = 4'd0;
    repeat (1) @ (posedge clk);
    cipher_en   = 0;
    //
    @ (posedge ready);
    info_task();
    if (data_out != 128'h304c6528f659c77866a510d9c1d6ae5e) begin
      fail_flag = 1;
      $strobe ("----- FAIL");
      $strobe ("  +++ Expected: 304c6528f659c77866a510d9c1d6ae5e");
      $strobe ("  +++ Actual:   %32h", data_out);
    end
    else begin
      $strobe ("----- PASS");
    end
    
    //
    //
    //Decipher
    //
    repeat (1) @ (posedge clk);
    chain_en = 0;
    //--------------------------------------------------
    //Decipher 1
    //--------------------------------------------------
    repeat (1) @ (posedge clk);
    cipher_en   = 0;
    decipher_en = 1;
    chain_en    = 1;
    data_in     = 128'h3b3fd92eb72dad20333449f8e83cfb4a;
    key         = 128'h2b7e151628aed2a6abf7158809cf4f3c;
    mode        = 4'd3; //OFB
    init_vector = 128'h000102030405060708090a0b0c0d0e0f;
    segment_len = 4'd3;
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
    //--------------------------------------------------
    repeat (1) @ (posedge clk);
    cipher_en   = 0;
    decipher_en = 1;
    chain_en    = 1;
    data_in     = 128'h7789508d16918f03f53c52dac54ed825;
    key         = 128'h2b7e151628aed2a6abf7158809cf4f3c;
    mode        = 4'd3; //OFB
    init_vector = 128'h000102030405060708090a0b0c0d0e0f;
    segment_len = 4'd3;
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
    //--------------------------------------------------
    //Decipher 3
    //--------------------------------------------------
    repeat (1) @ (posedge clk);
    cipher_en   = 0;
    decipher_en = 1;
    chain_en    = 1;
    data_in     = 128'h9740051e9c5fecf64344f7a82260edcc;
    key         = 128'h2b7e151628aed2a6abf7158809cf4f3c;
    mode        = 4'd3; //OFB
    init_vector = 128'h000102030405060708090a0b0c0d0e0f;
    segment_len = 4'd3;
    repeat (1) @ (posedge clk);
    decipher_en   = 0;
    //
    @ (posedge ready);
    info_task();
    if (data_out != 128'h30c81c46a35ce411e5fbc1191a0a52ef) begin
      fail_flag = 1;
      $strobe ("----- FAIL");
      $strobe ("  +++ Expected: 30c81c46a35ce411e5fbc1191a0a52ef");
      $strobe ("  +++ Actual:   %32h", data_out);
    end
    else begin
      $strobe ("----- PASS");
    end
    //--------------------------------------------------
    //Decipher 3
    //--------------------------------------------------
    repeat (1) @ (posedge clk);
    cipher_en   = 0;
    decipher_en = 1;
    chain_en    = 1;
    data_in     = 128'h304c6528f659c77866a510d9c1d6ae5e;
    key         = 128'h2b7e151628aed2a6abf7158809cf4f3c;
    mode        = 4'd3; //OFB
    init_vector = 128'h000102030405060708090a0b0c0d0e0f;
    segment_len = 4'd3;
    repeat (1) @ (posedge clk);
    decipher_en   = 0;
    //
    @ (posedge ready);
    info_task();
    if (data_out != 128'hf69f2445df4f9b17ad2b417be66c3710) begin
      fail_flag = 1;
      $strobe ("----- FAIL");
      $strobe ("  +++ Expected: f69f2445df4f9b17ad2b417be66c3710");
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
    $strobe ("----- mode_reg = %b", aes128.mode_reg);
    $strobe ("----- chain_en = %b", chain_en);
    $strobe ("----- data_in = %32h", data_in);
    $strobe ("----- data_out = %32h", data_out);
    $strobe ("----- init_vector = %32h", init_vector);
    $strobe ("----- decipher_start_in = %32h", aes128.decipher_start_in);
    $strobe ("----- start_reg = %32h", aes128.start_reg);
    $strobe ("----- end_reg = %32h", aes128.end_reg);
    $strobe ("----- output_block = %32h", aes128.output_block);
    $strobe ("----- cipher_input_block for the NEXT step = %32h", aes128.cipher_input_block);
    $strobe ("----- decipher_input_block for the NEXT step = %32h", aes128.decipher_input_block);
  endtask
  
endmodule
