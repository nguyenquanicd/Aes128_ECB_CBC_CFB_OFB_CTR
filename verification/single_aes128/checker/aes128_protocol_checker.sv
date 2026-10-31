//-----------------------------------------------------------
// Function: Interface/protocol checker of the aes128 top module
//-----------------------------------------------------------
// Author: Nguyen Hung Quan
// Website: http://nguyenquanicd.blogspot.com/
//-----------------------------------------------------------
// The checker only looks at the top-level ports, so it can be bound to any
// aes128 instance (simulation) or instantiated in a formal harness.
//   * simulation : a failed check prints "[CHK]" and increments viol_cnt
//   * formal     : compile with +define+FORMAL, each check becomes an assert
//
// Rules (all are exercised by the testbenches and proven by formal/fv_ctrl):
//   C1  after reset ready=1 and both error flags are 0
//   C2  err_busy pulses exactly one cycle after a start request while ready=0
//   C3  err_busy and err_cfg are never high together
//   C4  an accepted start (request while ready=1 and no err_cfg) drops ready
//   C5  a rejected start (err_cfg) leaves ready high
//   C6  ready stays low for at most MAX_LAT clocks
//   C7  ready stays low for at least MIN_LAT clocks
//   C8  data_out changes only on the clock where ready rises
//   C9  ready, err_busy and err_cfg are never X/Z
//-----------------------------------------------------------
`timescale 1ns/1ps
module aes128_protocol_checker #(
  parameter integer MIN_LAT = 11,   //cipher (all modes) and CFB/OFB/CTR decipher
  parameter integer MAX_LAT = 22    //ECB/CBC decipher (key schedule pass + decipher pass)
  ) (
  input logic clk,
  input logic rst_n,
  input logic cipher_en,
  input logic decipher_en,
  input logic ready,
  input logic err_busy,
  input logic err_cfg,
  input logic [127:0] data_out,
  output logic [31:0] viol_cnt
  );
  logic        rst_n_q;
  logic        rst_low_q;          //reset was already low on the previous clock
  logic        start_q;
  logic        ready_q;
  logic [127:0] data_out_q;
  logic [7:0]  busy_cnt;
  logic        started;
  wire         start_req = cipher_en | decipher_en;
  initial begin
    viol_cnt = 32'd0;
    rst_n_q  = 1'b0;
    rst_low_q = 1'b0;
    start_q  = 1'b0;
    ready_q  = 1'b1;
    busy_cnt = 8'd0;
    started  = 1'b0;
  end
  always @ (posedge clk) begin
    rst_n_q    <= rst_n;
    rst_low_q  <= ~rst_n;
    start_q    <= start_req & rst_n;
    ready_q    <= ready;
    data_out_q <= data_out;
    if (~rst_n)       busy_cnt <= 8'd0;
    else if (ready)   busy_cnt <= 8'd0;
    else if (busy_cnt != 8'hff) busy_cnt <= busy_cnt + 8'd1;
  end
`ifdef FORMAL
  `define AES_CHK(cond, msg) assert (cond);
`else
  `define AES_CHK(cond, msg) if (!(cond)) begin viol_cnt <= viol_cnt + 32'd1; $display("[CHK] %m @%0t: %s", $time, msg); end
`endif
  always @ (posedge clk) begin
    if (~rst_n) begin
      //C1 (the asynchronous reset needs one clock with rst_n low to be visible in simulation)
      if (rst_low_q)
        `AES_CHK(ready === 1'b1 && err_busy === 1'b0 && err_cfg === 1'b0, "C1 reset values")
    end
    else if (rst_n_q) begin
`ifndef FORMAL
      //C9 (X/Z only exists in simulation; formal is two-state)
      `AES_CHK(^{ready, err_busy, err_cfg} !== 1'bx, "C9 X on control outputs")
`endif
      //C2
      `AES_CHK(err_busy === (start_q & ~ready_q), "C2 err_busy must equal (start while busy)")
      //C3
      `AES_CHK(!(err_busy && err_cfg), "C3 err_busy and err_cfg together")
      //C4
      if (start_q && ready_q && !err_cfg)
        `AES_CHK(ready === 1'b0, "C4 accepted start must drop ready")
      //C5
      if (start_q && ready_q && err_cfg)
        `AES_CHK(ready === 1'b1, "C5 rejected start must keep ready high")
      //C6
      `AES_CHK(busy_cnt <= MAX_LAT, "C6 ready low longer than MAX_LAT")
      //C7
      if (ready && !ready_q)
        `AES_CHK(busy_cnt >= MIN_LAT, "C7 ready rose before MIN_LAT clocks")
      //C8
      if (data_out !== data_out_q)
        `AES_CHK(ready && !ready_q, "C8 data_out changed outside the completion clock")
    end
  end
endmodule
