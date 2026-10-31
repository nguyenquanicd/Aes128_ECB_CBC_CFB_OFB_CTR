/*
 * Project      : AES-128/AES-256 ECB/CBC/CFB/OFB/CTR
 * Author       : Nguyen Hung Quan (user)
 * AI Flow      : VLSIT RTL Generator AI Automation Flow
 * AI Flow Page : https://github.com/nguyenquanicd/VLSIT_RTL_Generator_AI_Model
 * Date         : 2026-10-29
 * Description  : Structural top-level wrapper for the AES batch engine.
 */
`timescale 1ns/1ps

module m_aes128_256_batch_top #(
  // Parameter Description: number of parallel 128-bit AES block lanes.
  // Parameter values: legal values are 1 through 4; default is 4.
  // Parameter unit: count
  parameter logic [31:0] PARA_AES_LANE_NUM = 4,
  // Parameter Description: width of the low CTR field that increments per block.
  // Parameter values: legal values are 1 through 128; default is 32.
  // Parameter unit: bit
  parameter logic [31:0] PARA_CTR_WIDTH = 32,
  localparam logic [31:0] LPARA_AES_BLOCK_W = 128,
  localparam logic [31:0] LPARA_AES_BATCH_W = PARA_AES_LANE_NUM * LPARA_AES_BLOCK_W
) (
  // Clock and reset
  input  wire                          i_clk_core,
  input  wire                          i_rst_n_core,

  // Message configuration
  input  wire                          i_cfg_valid,
  output logic                         o_cfg_ready,
  input  wire                          i_cfg_key_size,
  input  wire  [255:0]                 i_cfg_key,
  input  wire  [2:0]                   i_cfg_mode,
  input  wire                          i_cfg_decipher,
  input  wire  [127:0]                 i_cfg_iv,
  input  wire  [3:0]                   i_cfg_cfb_segment_size,

  // Input batch stream
  input  wire                          i_batch_valid,
  output logic                         o_batch_ready,
  input  wire  [LPARA_AES_BATCH_W-1:0] i_batch_data,
  input  wire  [PARA_AES_LANE_NUM-1:0] i_batch_lane_valid,
  input  wire                          i_batch_last,

  // Output batch stream
  output logic                         o_batch_valid,
  input  wire                          i_batch_ready,
  output logic [LPARA_AES_BATCH_W-1:0] o_batch_data,
  output logic [PARA_AES_LANE_NUM-1:0] o_batch_lane_valid,
  output logic                         o_batch_last,

  // Error stream
  output logic                         o_err_valid,
  input  wire                          i_err_ready,
  output logic [3:0]                   o_err_code,

  // Zeroize request and completion
  input  wire                          i_zeroize_req,
  output logic                         o_zeroize_done
);

  // The top directly exposes the core's complete configuration, stream, error, and zeroize ports.
  m_aes128_256_batch_core #(
    .PARA_AES_LANE_NUM (PARA_AES_LANE_NUM),
    .PARA_CTR_WIDTH    (PARA_CTR_WIDTH)
  ) u_aes128_256_batch_core (
    .i_clk_core              (i_clk_core),
    .i_rst_n_core            (i_rst_n_core),
    .i_cfg_valid             (i_cfg_valid),
    .o_cfg_ready             (o_cfg_ready),
    .i_cfg_key_size          (i_cfg_key_size),
    .i_cfg_key               (i_cfg_key),
    .i_cfg_mode              (i_cfg_mode),
    .i_cfg_decipher          (i_cfg_decipher),
    .i_cfg_iv                (i_cfg_iv),
    .i_cfg_cfb_segment_size  (i_cfg_cfb_segment_size),
    .i_batch_valid           (i_batch_valid),
    .o_batch_ready           (o_batch_ready),
    .i_batch_data            (i_batch_data),
    .i_batch_lane_valid      (i_batch_lane_valid),
    .i_batch_last            (i_batch_last),
    .o_batch_valid           (o_batch_valid),
    .i_batch_ready           (i_batch_ready),
    .o_batch_data            (o_batch_data),
    .o_batch_lane_valid      (o_batch_lane_valid),
    .o_batch_last            (o_batch_last),
    .o_err_valid             (o_err_valid),
    .i_err_ready             (i_err_ready),
    .o_err_code              (o_err_code),
    .i_zeroize_req           (i_zeroize_req),
    .o_zeroize_done          (o_zeroize_done)
  );

endmodule
