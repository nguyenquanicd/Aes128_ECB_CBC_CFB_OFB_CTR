/*
 * Project      : AES-128 ECB/CBC/CFB/OFB/CTR
 * Author       : Nguyen Hung Quan (user)
 * AI Flow      : VLSIT RTL Generator AI Automation Flow
 * AI Flow Page : https://github.com/nguyenquanicd/VLSIT_RTL_Generator_AI_Model
 * Date         : 2026-10-28
 * Description  : Carries one N-block batch through aligned AES lanes and metadata stages.
 */
`timescale 1ns/1ps

module m_aes128_lane_array #(
  // Parameter Description: number of parallel AES lanes in one message batch.
  // Parameter values: legal values are 1 through 4; default is 4.
  // Parameter unit: count
  parameter logic [31:0] PARA_AES_LANE_NUM = 32'd4,
  localparam logic [31:0] LPARA_AES_BLOCK_WIDTH = 32'd128,
  localparam logic [31:0] LPARA_ROUND_KEYS_WIDTH = 32'd1408,
  localparam logic [31:0] LPARA_BATCH_DATA_WIDTH = PARA_AES_LANE_NUM * 32'd128,
  localparam logic [31:0] LPARA_LANE_COUNT_THREE = 32'd3,
  localparam logic [31:0] LPARA_LANE_COUNT_FOUR = 32'd4
) (
  // Clock and reset
  input  wire                               i_clk_core,
  input  wire                               i_rst_n_core,

  // Batch pipeline control
  input  wire                               i_clear,
  input  wire                               i_batch_valid,
  output logic                              o_batch_ready,
  input  wire  [PARA_AES_LANE_NUM-1:0]      i_lane_valid,
  input  wire                               i_batch_last,

  // AES lane inputs
  input  wire  [LPARA_BATCH_DATA_WIDTH-1:0] i_batch_data,
  input  wire  [LPARA_BATCH_DATA_WIDTH-1:0] i_sideband_data,
  input  wire  [LPARA_ROUND_KEYS_WIDTH-1:0] i_round_keys,
  input  wire                               i_aes_decipher,

  // Batch result control
  output logic                              o_result_valid,
  input  wire                               i_result_ready,
  output logic [LPARA_BATCH_DATA_WIDTH-1:0] o_result_data,
  output logic [LPARA_BATCH_DATA_WIDTH-1:0] o_result_sideband_data,
  output logic [PARA_AES_LANE_NUM-1:0]      o_result_lane_valid,
  output logic                              o_result_last
);

  // Input and stage metadata stay aligned with the capture register and AES round stages.
  logic [9:0] reg_batch_valid;
  logic [PARA_AES_LANE_NUM-1:0] reg_batch_lane_valid [0:9];
  logic [9:0] reg_batch_last;
  logic reg_input_batch_valid;
  logic [PARA_AES_LANE_NUM-1:0] reg_input_lane_valid;
  logic reg_input_batch_last;
  logic [10:0] w_batch_stage_ready;
  logic w_batch_input_ready;
  logic [PARA_AES_LANE_NUM-1:0] w_lane_ready;
  logic [PARA_AES_LANE_NUM-1:0] w_lane_valid;
  logic [PARA_AES_LANE_NUM-1:0] w_lane_last;
  logic [LPARA_BATCH_DATA_WIDTH-1:0] w_lane_result_data;
  logic [LPARA_BATCH_DATA_WIDTH-1:0] w_lane_result_sideband;

  // Ready propagates through the ten round stages and the input capture register.
  assign w_batch_stage_ready[10] = i_result_ready;
  assign w_batch_stage_ready[9] = ~reg_batch_valid[9] | w_batch_stage_ready[10];
  assign w_batch_stage_ready[8] = ~reg_batch_valid[8] | w_batch_stage_ready[9];
  assign w_batch_stage_ready[7] = ~reg_batch_valid[7] | w_batch_stage_ready[8];
  assign w_batch_stage_ready[6] = ~reg_batch_valid[6] | w_batch_stage_ready[7];
  assign w_batch_stage_ready[5] = ~reg_batch_valid[5] | w_batch_stage_ready[6];
  assign w_batch_stage_ready[4] = ~reg_batch_valid[4] | w_batch_stage_ready[5];
  assign w_batch_stage_ready[3] = ~reg_batch_valid[3] | w_batch_stage_ready[4];
  assign w_batch_stage_ready[2] = ~reg_batch_valid[2] | w_batch_stage_ready[3];
  assign w_batch_stage_ready[1] = ~reg_batch_valid[1] | w_batch_stage_ready[2];
  assign w_batch_stage_ready[0] = ~reg_batch_valid[0] | w_batch_stage_ready[1];

  // Input readiness reflects room in the capture register and all AES lanes.
  assign w_batch_input_ready = ~reg_input_batch_valid | w_batch_stage_ready[0];
  assign o_batch_ready = w_batch_input_ready & (&w_lane_ready);

  // Output metadata is valid only when every AES lane result is aligned.
  assign o_result_valid = reg_batch_valid[9] & (&w_lane_valid);
  assign o_result_lane_valid = reg_batch_lane_valid[9];
  assign o_result_last = reg_batch_last[9] & (&w_lane_last);
  assign o_result_data = w_lane_result_data;
  assign o_result_sideband_data = w_lane_result_sideband;

  // This capture register aligns the batch mask and last marker with each lane input.
  always_ff @(posedge i_clk_core, negedge i_rst_n_core) begin : p_ff_input_meta
    if (!i_rst_n_core) begin
      reg_input_batch_valid <= 1'b0;
      reg_input_lane_valid <= '0;
      reg_input_batch_last <= 1'b0;
    end else if (i_clear) begin
      reg_input_batch_valid <= 1'b0;
      reg_input_lane_valid <= '0;
      reg_input_batch_last <= 1'b0;
    end else if (o_batch_ready) begin
      reg_input_batch_valid <= i_batch_valid;
      if (i_batch_valid) begin
        reg_input_lane_valid <= i_lane_valid;
        reg_input_batch_last <= i_batch_last;
      end
    end
  end

  // Metadata uses the same ten elastic round stages and flushes on reset or zeroize.
  for (genvar gen_idx = 0; gen_idx < 10; gen_idx++) begin : gen_batch_stage
    if (gen_idx == 0) begin : gen_input_stage
      // Stage zero captures the registered batch metadata into the first AES round stage.
      always_ff @(posedge i_clk_core, negedge i_rst_n_core) begin : p_ff_meta
        if (!i_rst_n_core) begin
          reg_batch_valid[gen_idx] <= 1'b0;
          reg_batch_lane_valid[gen_idx] <= '0;
          reg_batch_last[gen_idx] <= 1'b0;
        end else if (i_clear) begin
          reg_batch_valid[gen_idx] <= 1'b0;
          reg_batch_lane_valid[gen_idx] <= '0;
          reg_batch_last[gen_idx] <= 1'b0;
        end else if (w_batch_stage_ready[gen_idx]) begin
          reg_batch_valid[gen_idx] <= reg_input_batch_valid;
          if (reg_input_batch_valid) begin
            reg_batch_lane_valid[gen_idx] <= reg_input_lane_valid;
            reg_batch_last[gen_idx] <= reg_input_batch_last;
          end
        end
      end
    end else begin : gen_inner_stage
      // Later stages advance mask and last metadata with their corresponding AES state.
      always_ff @(posedge i_clk_core, negedge i_rst_n_core) begin : p_ff_meta
        if (!i_rst_n_core) begin
          reg_batch_valid[gen_idx] <= 1'b0;
          reg_batch_lane_valid[gen_idx] <= '0;
          reg_batch_last[gen_idx] <= 1'b0;
        end else if (i_clear) begin
          reg_batch_valid[gen_idx] <= 1'b0;
          reg_batch_lane_valid[gen_idx] <= '0;
          reg_batch_last[gen_idx] <= 1'b0;
        end else if (w_batch_stage_ready[gen_idx]) begin
          reg_batch_valid[gen_idx] <= reg_batch_valid[gen_idx-1];
          if (reg_batch_valid[gen_idx-1]) begin
            reg_batch_lane_valid[gen_idx] <= reg_batch_lane_valid[gen_idx-1];
            reg_batch_last[gen_idx] <= reg_batch_last[gen_idx-1];
          end
        end
      end
    end
  end

  // Lane 0 processes every batch; the mask marks inactive result slots invalid.
  m_aes128_pipe_lane u_aes128_pipe_lane_0 (
      .i_clk_core       (i_clk_core),
      .i_rst_n_core     (i_rst_n_core),
      .i_clear          (i_clear),
      .i_valid          (i_batch_valid),
      .o_ready          (w_lane_ready[0]),
      .o_valid          (w_lane_valid[0]),
      .i_ready          (i_result_ready),
      .i_data           (i_batch_data[0 +: LPARA_AES_BLOCK_WIDTH]),
      .i_sideband_data  (i_sideband_data[0 +: LPARA_AES_BLOCK_WIDTH]),
      .i_round_keys     (i_round_keys),
      .i_aes_decipher   (i_aes_decipher),
      .i_last           (i_batch_last),
      .o_data           (w_lane_result_data[0 +: LPARA_AES_BLOCK_WIDTH]),
      .o_sideband_data  (w_lane_result_sideband[0 +: LPARA_AES_BLOCK_WIDTH]),
      .o_last           (w_lane_last[0])
  );

  // Lane 1 is present only when the configured lane count is at least two.
  if (PARA_AES_LANE_NUM > 32'd1) begin : gen_lane_1
    m_aes128_pipe_lane u_aes128_pipe_lane_1 (
      .i_clk_core       (i_clk_core),
      .i_rst_n_core     (i_rst_n_core),
      .i_clear          (i_clear),
      .i_valid          (i_batch_valid),
      .o_ready          (w_lane_ready[1]),
      .o_valid          (w_lane_valid[1]),
      .i_ready          (i_result_ready),
      .i_data           (i_batch_data[LPARA_AES_BLOCK_WIDTH +: LPARA_AES_BLOCK_WIDTH]),
      .i_sideband_data  (i_sideband_data[LPARA_AES_BLOCK_WIDTH +: LPARA_AES_BLOCK_WIDTH]),
      .i_round_keys     (i_round_keys),
      .i_aes_decipher   (i_aes_decipher),
      .i_last           (i_batch_last),
      .o_data           (w_lane_result_data[LPARA_AES_BLOCK_WIDTH +: LPARA_AES_BLOCK_WIDTH]),
      .o_sideband_data  (w_lane_result_sideband[LPARA_AES_BLOCK_WIDTH +: LPARA_AES_BLOCK_WIDTH]),
      .o_last           (w_lane_last[1])
    );
  end

  // Lane 2 is present only when the configured lane count is at least three.
  if (PARA_AES_LANE_NUM >= LPARA_LANE_COUNT_THREE) begin : gen_lane_2
    m_aes128_pipe_lane u_aes128_pipe_lane_2 (
      .i_clk_core       (i_clk_core),
      .i_rst_n_core     (i_rst_n_core),
      .i_clear          (i_clear),
      .i_valid          (i_batch_valid),
      .o_ready          (w_lane_ready[2]),
      .o_valid          (w_lane_valid[2]),
      .i_ready          (i_result_ready),
      .i_data           (i_batch_data[2 * LPARA_AES_BLOCK_WIDTH +: LPARA_AES_BLOCK_WIDTH]),
      .i_sideband_data  (i_sideband_data[2 * LPARA_AES_BLOCK_WIDTH +: LPARA_AES_BLOCK_WIDTH]),
      .i_round_keys     (i_round_keys),
      .i_aes_decipher   (i_aes_decipher),
      .i_last           (i_batch_last),
      .o_data           (w_lane_result_data[2 * LPARA_AES_BLOCK_WIDTH +: LPARA_AES_BLOCK_WIDTH]),
      .o_sideband_data  (w_lane_result_sideband[2 * LPARA_AES_BLOCK_WIDTH +: LPARA_AES_BLOCK_WIDTH]),
      .o_last           (w_lane_last[2])
    );
  end

  // Lane 3 is present only when the configured lane count is four.
  if (PARA_AES_LANE_NUM >= LPARA_LANE_COUNT_FOUR) begin : gen_lane_3
    m_aes128_pipe_lane u_aes128_pipe_lane_3 (
      .i_clk_core       (i_clk_core),
      .i_rst_n_core     (i_rst_n_core),
      .i_clear          (i_clear),
      .i_valid          (i_batch_valid),
      .o_ready          (w_lane_ready[3]),
      .o_valid          (w_lane_valid[3]),
      .i_ready          (i_result_ready),
      .i_data           (i_batch_data[3 * LPARA_AES_BLOCK_WIDTH +: LPARA_AES_BLOCK_WIDTH]),
      .i_sideband_data  (i_sideband_data[3 * LPARA_AES_BLOCK_WIDTH +: LPARA_AES_BLOCK_WIDTH]),
      .i_round_keys     (i_round_keys),
      .i_aes_decipher   (i_aes_decipher),
      .i_last           (i_batch_last),
      .o_data           (w_lane_result_data[3 * LPARA_AES_BLOCK_WIDTH +: LPARA_AES_BLOCK_WIDTH]),
      .o_sideband_data  (w_lane_result_sideband[3 * LPARA_AES_BLOCK_WIDTH +: LPARA_AES_BLOCK_WIDTH]),
      .o_last           (w_lane_last[3])
    );
  end

endmodule
