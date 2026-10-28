/*
 * Project      : AES-128 ECB/CBC/CFB/OFB/CTR
 * Author       : Nguyen Hung Quan (user)
 * AI Flow      : VLSIT RTL Generator AI Automation Flow
 * AI Flow Page : https://github.com/nguyenquanicd/VLSIT_RTL_Generator_AI_Model
 * Date         : 2026-10-28
 * Description  : Structural top that exposes the AES message and batch interfaces.
 */
`timescale 1ns/1ps

module m_aes128_batch_top #(
  // Parameter Description: number of AES lanes available in each input batch.
  // Parameter values: legal values are 1 through 4; default is 4.
  // Parameter unit: count
  parameter logic [31:0] PARA_AES_LANE_NUM = 32'd4,
  // Parameter Description: width of the incrementing low CTR field.
  // Parameter values: legal values are 1 through 128; default is 32.
  // Parameter unit: bit
  parameter logic [31:0] PARA_CTR_WIDTH = 32'd32,
  localparam logic [31:0] LPARA_AES_BLOCK_WIDTH = 32'd128,
  localparam logic [31:0] LPARA_BATCH_DATA_WIDTH = PARA_AES_LANE_NUM * 32'd128
) (
  // Clock and reset
  input  wire                               i_clk_core,
  input  wire                               i_rst_n_core,

  // Message configuration
  input  wire                               i_cfg_valid,
  output logic                              o_cfg_ready,
  input  wire  [LPARA_AES_BLOCK_WIDTH-1:0]  i_cfg_key,
  input  wire  [2:0]                        i_cfg_mode,
  input  wire                               i_cfg_decipher,
  input  wire  [LPARA_AES_BLOCK_WIDTH-1:0]  i_cfg_iv,
  input  wire  [3:0]                        i_cfg_cfb_segment_size,

  // Input batch
  input  wire                               i_batch_valid,
  output logic                              o_batch_ready,
  input  wire  [LPARA_BATCH_DATA_WIDTH-1:0] i_batch_data,
  input  wire  [PARA_AES_LANE_NUM-1:0]      i_batch_lane_valid,
  input  wire                               i_batch_last,

  // Output batch
  output logic                              o_batch_valid,
  input  wire                               i_batch_ready,
  output logic [LPARA_BATCH_DATA_WIDTH-1:0] o_batch_data,
  output logic [PARA_AES_LANE_NUM-1:0]      o_batch_lane_valid,
  output logic                              o_batch_last,

  // Error record
  output logic                              o_err_valid,
  input  wire                               i_err_ready,
  output logic [3:0]                        o_err_code,

  // Zeroize control
  input  wire                               i_zeroize_req,
  output logic                              o_zeroize_done
);

  // The top contains only the core instance and forwards every interface by name.
  m_aes128_batch_core #(
    .PARA_AES_LANE_NUM (PARA_AES_LANE_NUM),
    .PARA_CTR_WIDTH    (PARA_CTR_WIDTH)
  ) u_aes128_batch_core (
    .i_clk_core             (i_clk_core),
    .i_rst_n_core           (i_rst_n_core),
    .i_cfg_valid            (i_cfg_valid),
    .o_cfg_ready            (o_cfg_ready),
    .i_cfg_key              (i_cfg_key),
    .i_cfg_mode             (i_cfg_mode),
    .i_cfg_decipher         (i_cfg_decipher),
    .i_cfg_iv               (i_cfg_iv),
    .i_cfg_cfb_segment_size (i_cfg_cfb_segment_size),
    .i_batch_valid          (i_batch_valid),
    .o_batch_ready          (o_batch_ready),
    .i_batch_data           (i_batch_data),
    .i_batch_lane_valid     (i_batch_lane_valid),
    .i_batch_last           (i_batch_last),
    .o_batch_valid          (o_batch_valid),
    .i_batch_ready          (i_batch_ready),
    .o_batch_data           (o_batch_data),
    .o_batch_lane_valid     (o_batch_lane_valid),
    .o_batch_last           (o_batch_last),
    .o_err_valid            (o_err_valid),
    .i_err_ready            (i_err_ready),
    .o_err_code             (o_err_code),
    .i_zeroize_req          (i_zeroize_req),
    .o_zeroize_done         (o_zeroize_done)
  );

endmodule
