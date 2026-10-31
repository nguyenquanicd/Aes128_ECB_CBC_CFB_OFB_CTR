/*
 * Project      : AES-128/AES-256 ECB/CBC/CFB/OFB/CTR
 * Author       : Nguyen Hung Quan (user)
 * AI Flow      : VLSIT RTL Generator AI Automation Flow
 * AI Flow Page : https://github.com/nguyenquanicd/VLSIT_RTL_Generator_AI_Model
 * Date         : 2026-10-29
 * Description  : Replicated block lanes with common batch and backpressure control.
 */
`timescale 1ns/1ps

module m_aes128_256_lane_array #(
  // Parameter Description: number of parallel 128-bit AES block lanes.
  // Parameter values: legal values are 1 through 4; default is 4.
  // Parameter unit: count
  parameter logic [31:0] PARA_AES_LANE_NUM = 4,
  localparam logic [31:0] LPARA_AES_BLOCK_W = 128,
  localparam logic [31:0] LPARA_AES_BATCH_DATA_W = PARA_AES_LANE_NUM * LPARA_AES_BLOCK_W
) (
  // Clock, reset, and clear
  input  wire                               i_clk_core,
  input  wire                               i_rst_n_core,
  input  wire                               i_clear,

  // Message key context
  input  wire                               i_key_size,
  input  wire                               i_decipher,
  input  wire  [1919:0]                     i_round_keys,

  // Input batch stream
  input  wire                               i_valid,
  output logic                              o_ready,
  input  wire  [LPARA_AES_BATCH_DATA_W-1:0] i_data,
  input  wire  [PARA_AES_LANE_NUM-1:0]      i_lane_valid,
  input  wire                               i_last,
  input  wire  [LPARA_AES_BATCH_DATA_W-1:0] i_post_xor_data,

  // Final round batch stream
  output logic                              o_valid,
  input  wire                               i_ready,
  output logic [LPARA_AES_BATCH_DATA_W-1:0] o_data,
  output logic [PARA_AES_LANE_NUM-1:0]      o_lane_valid,
  output logic                              o_last,
  output logic [LPARA_AES_BATCH_DATA_W-1:0] o_post_xor_data
);

  // Internal signal declarations
  logic [PARA_AES_LANE_NUM-1:0] w_lane_ready;
  logic [PARA_AES_LANE_NUM-1:0] w_lane_valid_out;
  logic [PARA_AES_LANE_NUM-1:0] w_lane_active_out;
  logic [PARA_AES_LANE_NUM-1:0] w_lane_last_out;
  logic [PARA_AES_LANE_NUM-1:0][LPARA_AES_BLOCK_W-1:0] w_lane_data_out;
  logic [PARA_AES_LANE_NUM-1:0][LPARA_AES_BLOCK_W-1:0] w_lane_post_xor_out;

  // Every lane sees the same batch handshake and sink readiness, keeping all taps aligned.
  for (genvar gen_idx = 0; gen_idx < PARA_AES_LANE_NUM; gen_idx++) begin : gen_lane
    // One pipe lane transforms one block and carries the corresponding mask and mode operand.
    m_aes128_256_pipe_lane u_aes128_256_pipe_lane (
      .i_clk_core       (i_clk_core),
      .i_rst_n_core     (i_rst_n_core),
      .i_clear          (i_clear),
      .i_key_size       (i_key_size),
      .i_decipher       (i_decipher),
      .i_round_keys     (i_round_keys),
      .i_valid          (i_valid),
      .o_ready          (w_lane_ready[gen_idx]),
      .i_data           (i_data[(gen_idx * LPARA_AES_BLOCK_W) +: LPARA_AES_BLOCK_W]),
      .i_lane_active    (i_lane_valid[gen_idx]),
      .i_last           (i_last),
      .i_post_xor_data  (i_post_xor_data[(gen_idx * LPARA_AES_BLOCK_W) +: LPARA_AES_BLOCK_W]),
      .o_valid          (w_lane_valid_out[gen_idx]),
      .i_ready          (i_ready),
      .o_data           (w_lane_data_out[gen_idx]),
      .o_lane_active    (w_lane_active_out[gen_idx]),
      .o_last           (w_lane_last_out[gen_idx]),
      .o_post_xor_data  (w_lane_post_xor_out[gen_idx])
    );
  end

  // Lane zero is active for every legal prefix mask and identifies the batch transfer.
  assign o_ready = w_lane_ready[0];
  assign o_valid = w_lane_valid_out[0];
  assign o_last = w_lane_last_out[0];

  // Packed lane arrays preserve lane zero in the least-significant 128-bit slice.
  assign o_data = w_lane_data_out;
  assign o_lane_valid = w_lane_active_out;
  assign o_post_xor_data = w_lane_post_xor_out;

endmodule
