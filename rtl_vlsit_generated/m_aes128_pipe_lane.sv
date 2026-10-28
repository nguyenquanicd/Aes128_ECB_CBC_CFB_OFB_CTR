/*
 * Project      : AES-128 ECB/CBC/CFB/OFB/CTR
 * Author       : Nguyen Hung Quan (user)
 * AI Flow      : VLSIT RTL Generator AI Automation Flow
 * AI Flow Page : https://github.com/nguyenquanicd/VLSIT_RTL_Generator_AI_Model
 * Date         : 2026-10-28
 * Description  : One input capture register and ten elastic AES round stages per lane.
 */
`timescale 1ns/1ps

module m_aes128_pipe_lane #(
  localparam logic [31:0] LPARA_AES_BLOCK_WIDTH = 32'd128,
  localparam logic [31:0] LPARA_ROUND_KEYS_WIDTH = 32'd1408,
  localparam logic [31:0] LPARA_AES_ROUND_COUNT = 32'd10
) (
  // Clock and reset
  input  wire                               i_clk_core,
  input  wire                               i_rst_n_core,

  // Pipeline control
  input  wire                               i_clear,
  input  wire                               i_valid,
  output logic                              o_ready,
  output logic                              o_valid,
  input  wire                               i_ready,

  // AES data and context
  input  wire  [LPARA_AES_BLOCK_WIDTH-1:0]  i_data,
  input  wire  [LPARA_AES_BLOCK_WIDTH-1:0]  i_sideband_data,
  input  wire  [LPARA_ROUND_KEYS_WIDTH-1:0] i_round_keys,
  input  wire                               i_aes_decipher,
  input  wire                               i_last,
  output logic [LPARA_AES_BLOCK_WIDTH-1:0]  o_data,
  output logic [LPARA_AES_BLOCK_WIDTH-1:0]  o_sideband_data,
  output logic                              o_last
);

  // Per-stage state, sideband, valid, and last values stay aligned under stalls.
  logic [LPARA_AES_BLOCK_WIDTH-1:0] w_stage_input_data [0:LPARA_AES_ROUND_COUNT-32'd1];
  logic [LPARA_AES_BLOCK_WIDTH-1:0] w_round_key [0:LPARA_AES_ROUND_COUNT-32'd1];
  logic [LPARA_AES_BLOCK_WIDTH-1:0] w_round_state [0:LPARA_AES_ROUND_COUNT-32'd1];
  logic [LPARA_AES_BLOCK_WIDTH-1:0] reg_stage_data [0:LPARA_AES_ROUND_COUNT-32'd1];
  logic [LPARA_AES_BLOCK_WIDTH-1:0] reg_stage_sideband [0:LPARA_AES_ROUND_COUNT-32'd1];
  logic [LPARA_AES_ROUND_COUNT-32'd1:0] reg_stage_valid;
  logic [LPARA_AES_ROUND_COUNT-32'd1:0] reg_stage_last;
  logic [LPARA_AES_ROUND_COUNT:0] w_stage_ready;
  logic reg_input_valid;
  logic [LPARA_AES_BLOCK_WIDTH-1:0] reg_input_data;
  logic [LPARA_AES_BLOCK_WIDTH-1:0] reg_input_sideband_data;
  logic reg_input_last;

  // Explicit stage codes keep AES round instances tied to fixed parameter values.
  typedef enum logic [31:0] {
    ENUM_AES_STAGE_1 = 32'd1,
    ENUM_AES_STAGE_2 = 32'd2,
    ENUM_AES_STAGE_3 = 32'd3,
    ENUM_AES_STAGE_4 = 32'd4,
    ENUM_AES_STAGE_5 = 32'd5,
    ENUM_AES_STAGE_6 = 32'd6,
    ENUM_AES_STAGE_7 = 32'd7,
    ENUM_AES_STAGE_8 = 32'd8,
    ENUM_AES_STAGE_9 = 32'd9,
    ENUM_AES_STAGE_10 = 32'd10
  } aes_pipe_stage_type_def;

  // Key slices map K1..K10 forward and K9..K0 in reverse order.
  assign w_round_key[0] = i_aes_decipher ? i_round_keys[1152 +: LPARA_AES_BLOCK_WIDTH] : i_round_keys[128 +: LPARA_AES_BLOCK_WIDTH];
  assign w_round_key[1] = i_aes_decipher ? i_round_keys[1024 +: LPARA_AES_BLOCK_WIDTH] : i_round_keys[256 +: LPARA_AES_BLOCK_WIDTH];
  assign w_round_key[2] = i_aes_decipher ? i_round_keys[896 +: LPARA_AES_BLOCK_WIDTH] : i_round_keys[384 +: LPARA_AES_BLOCK_WIDTH];
  assign w_round_key[3] = i_aes_decipher ? i_round_keys[768 +: LPARA_AES_BLOCK_WIDTH] : i_round_keys[512 +: LPARA_AES_BLOCK_WIDTH];
  assign w_round_key[4] = i_aes_decipher ? i_round_keys[640 +: LPARA_AES_BLOCK_WIDTH] : i_round_keys[640 +: LPARA_AES_BLOCK_WIDTH];
  assign w_round_key[5] = i_aes_decipher ? i_round_keys[512 +: LPARA_AES_BLOCK_WIDTH] : i_round_keys[768 +: LPARA_AES_BLOCK_WIDTH];
  assign w_round_key[6] = i_aes_decipher ? i_round_keys[384 +: LPARA_AES_BLOCK_WIDTH] : i_round_keys[896 +: LPARA_AES_BLOCK_WIDTH];
  assign w_round_key[7] = i_aes_decipher ? i_round_keys[256 +: LPARA_AES_BLOCK_WIDTH] : i_round_keys[1024 +: LPARA_AES_BLOCK_WIDTH];
  assign w_round_key[8] = i_aes_decipher ? i_round_keys[128 +: LPARA_AES_BLOCK_WIDTH] : i_round_keys[1152 +: LPARA_AES_BLOCK_WIDTH];
  assign w_round_key[9] = i_aes_decipher ? i_round_keys[0 +: LPARA_AES_BLOCK_WIDTH] : i_round_keys[1280 +: LPARA_AES_BLOCK_WIDTH];

  // Initial AddRoundKey uses K0 for encryption and K10 for decipher.
  assign w_stage_input_data[0] = reg_input_data ^ (i_aes_decipher ? i_round_keys[LPARA_AES_ROUND_COUNT * LPARA_AES_BLOCK_WIDTH +: LPARA_AES_BLOCK_WIDTH] :
                     i_round_keys[0 +: LPARA_AES_BLOCK_WIDTH]);

  // Each later round starts from the preceding registered AES state.
  assign w_stage_input_data[1] = reg_stage_data[0];
  assign w_stage_input_data[2] = reg_stage_data[1];
  assign w_stage_input_data[3] = reg_stage_data[2];
  assign w_stage_input_data[4] = reg_stage_data[3];
  assign w_stage_input_data[5] = reg_stage_data[4];
  assign w_stage_input_data[6] = reg_stage_data[5];
  assign w_stage_input_data[7] = reg_stage_data[6];
  assign w_stage_input_data[8] = reg_stage_data[7];
  assign w_stage_input_data[9] = reg_stage_data[8];

  // Ready propagates from the output register to each earlier round stage.
  assign w_stage_ready[LPARA_AES_ROUND_COUNT] = i_ready;
  assign w_stage_ready[9] = ~reg_stage_valid[9] | w_stage_ready[10];
  assign w_stage_ready[8] = ~reg_stage_valid[8] | w_stage_ready[9];
  assign w_stage_ready[7] = ~reg_stage_valid[7] | w_stage_ready[8];
  assign w_stage_ready[6] = ~reg_stage_valid[6] | w_stage_ready[7];
  assign w_stage_ready[5] = ~reg_stage_valid[5] | w_stage_ready[6];
  assign w_stage_ready[4] = ~reg_stage_valid[4] | w_stage_ready[5];
  assign w_stage_ready[3] = ~reg_stage_valid[3] | w_stage_ready[4];
  assign w_stage_ready[2] = ~reg_stage_valid[2] | w_stage_ready[3];
  assign w_stage_ready[1] = ~reg_stage_valid[1] | w_stage_ready[2];
  assign w_stage_ready[0] = ~reg_stage_valid[0] | w_stage_ready[1];

  // The input buffer accepts a new block when empty or when its held block can advance.
  assign o_ready = ~reg_input_valid | w_stage_ready[0];

  // The final round register holds the raw result until the consumer accepts it.
  assign o_valid = reg_stage_valid[LPARA_AES_ROUND_COUNT-32'd1];
  assign o_data = reg_stage_data[LPARA_AES_ROUND_COUNT-32'd1];
  assign o_sideband_data = reg_stage_sideband[LPARA_AES_ROUND_COUNT-32'd1];
  assign o_last = reg_stage_last[LPARA_AES_ROUND_COUNT-32'd1];

  // The input capture register makes the specified C0-to-C10 latency explicit.
  always_ff @(posedge i_clk_core, negedge i_rst_n_core) begin : p_ff_input_capture
    if (!i_rst_n_core) begin
      reg_input_valid <= 1'b0;
      reg_input_data <= '0;
      reg_input_sideband_data <= '0;
      reg_input_last <= 1'b0;
    end else if (i_clear) begin
      reg_input_valid <= 1'b0;
      reg_input_data <= '0;
      reg_input_sideband_data <= '0;
      reg_input_last <= 1'b0;
    end else if (o_ready) begin
      reg_input_valid <= i_valid;
      if (i_valid) begin
        reg_input_data <= i_data;
        reg_input_sideband_data <= i_sideband_data;
        reg_input_last <= i_last;
      end
    end
  end

  // Each valid bit resets asynchronously; clear aborts and zeroes sensitive pipeline data.
  for (genvar gen_idx = 0; gen_idx < LPARA_AES_ROUND_COUNT; gen_idx++) begin : gen_pipe_stage
    if (gen_idx == 0) begin : gen_input_stage
      // The first round consumes the aligned input capture register.
      always_ff @(posedge i_clk_core, negedge i_rst_n_core) begin : p_ff_stage
        if (!i_rst_n_core) begin
          reg_stage_valid[gen_idx] <= 1'b0;
          reg_stage_data[gen_idx] <= '0;
          reg_stage_sideband[gen_idx] <= '0;
          reg_stage_last[gen_idx] <= 1'b0;
        end else if (i_clear) begin
          reg_stage_valid[gen_idx] <= 1'b0;
          reg_stage_data[gen_idx] <= '0;
          reg_stage_sideband[gen_idx] <= '0;
          reg_stage_last[gen_idx] <= 1'b0;
        end else if (w_stage_ready[gen_idx]) begin
          reg_stage_valid[gen_idx] <= reg_input_valid;
          if (reg_input_valid) begin
            reg_stage_data[gen_idx] <= w_round_state[gen_idx];
            reg_stage_sideband[gen_idx] <= reg_input_sideband_data;
            reg_stage_last[gen_idx] <= reg_input_last;
          end
        end
      end
    end else begin : gen_inner_stage
      // Each later round consumes the preceding stage's registered state and sideband.
      always_ff @(posedge i_clk_core, negedge i_rst_n_core) begin : p_ff_stage
        if (!i_rst_n_core) begin
          reg_stage_valid[gen_idx] <= 1'b0;
          reg_stage_data[gen_idx] <= '0;
          reg_stage_sideband[gen_idx] <= '0;
          reg_stage_last[gen_idx] <= 1'b0;
        end else if (i_clear) begin
          reg_stage_valid[gen_idx] <= 1'b0;
          reg_stage_data[gen_idx] <= '0;
          reg_stage_sideband[gen_idx] <= '0;
          reg_stage_last[gen_idx] <= 1'b0;
        end else if (w_stage_ready[gen_idx]) begin
          reg_stage_valid[gen_idx] <= reg_stage_valid[gen_idx-1];
          if (reg_stage_valid[gen_idx-1]) begin
            reg_stage_data[gen_idx] <= w_round_state[gen_idx];
            reg_stage_sideband[gen_idx] <= reg_stage_sideband[gen_idx-1];
            reg_stage_last[gen_idx] <= reg_stage_last[gen_idx-1];
          end
        end
      end
    end
  end

  // Ten direction-selectable AES rounds form one registered round per stage.
  // Stage 1 uses the selected forward or reverse AES round key.
  m_aes128_aes_round #(
    .PARA_AES_PIPE_STAGE (aes_pipe_stage_type_def'(ENUM_AES_STAGE_1))
  ) u_aes128_aes_round_0 (
    .i_state       (w_stage_input_data[0]),
    .i_round_key   (w_round_key[0]),
    .i_aes_decipher(i_aes_decipher),
    .o_state       (w_round_state[0])
  );

  // Stage 2 uses the selected forward or reverse AES round key.
  m_aes128_aes_round #(
    .PARA_AES_PIPE_STAGE (aes_pipe_stage_type_def'(ENUM_AES_STAGE_2))
  ) u_aes128_aes_round_1 (
    .i_state       (w_stage_input_data[1]),
    .i_round_key   (w_round_key[1]),
    .i_aes_decipher(i_aes_decipher),
    .o_state       (w_round_state[1])
  );

  // Stage 3 uses the selected forward or reverse AES round key.
  m_aes128_aes_round #(
    .PARA_AES_PIPE_STAGE (aes_pipe_stage_type_def'(ENUM_AES_STAGE_3))
  ) u_aes128_aes_round_2 (
    .i_state       (w_stage_input_data[2]),
    .i_round_key   (w_round_key[2]),
    .i_aes_decipher(i_aes_decipher),
    .o_state       (w_round_state[2])
  );

  // Stage 4 uses the selected forward or reverse AES round key.
  m_aes128_aes_round #(
    .PARA_AES_PIPE_STAGE (aes_pipe_stage_type_def'(ENUM_AES_STAGE_4))
  ) u_aes128_aes_round_3 (
    .i_state       (w_stage_input_data[3]),
    .i_round_key   (w_round_key[3]),
    .i_aes_decipher(i_aes_decipher),
    .o_state       (w_round_state[3])
  );

  // Stage 5 uses the selected forward or reverse AES round key.
  m_aes128_aes_round #(
    .PARA_AES_PIPE_STAGE (aes_pipe_stage_type_def'(ENUM_AES_STAGE_5))
  ) u_aes128_aes_round_4 (
    .i_state       (w_stage_input_data[4]),
    .i_round_key   (w_round_key[4]),
    .i_aes_decipher(i_aes_decipher),
    .o_state       (w_round_state[4])
  );

  // Stage 6 uses the selected forward or reverse AES round key.
  m_aes128_aes_round #(
    .PARA_AES_PIPE_STAGE (aes_pipe_stage_type_def'(ENUM_AES_STAGE_6))
  ) u_aes128_aes_round_5 (
    .i_state       (w_stage_input_data[5]),
    .i_round_key   (w_round_key[5]),
    .i_aes_decipher(i_aes_decipher),
    .o_state       (w_round_state[5])
  );

  // Stage 7 uses the selected forward or reverse AES round key.
  m_aes128_aes_round #(
    .PARA_AES_PIPE_STAGE (aes_pipe_stage_type_def'(ENUM_AES_STAGE_7))
  ) u_aes128_aes_round_6 (
    .i_state       (w_stage_input_data[6]),
    .i_round_key   (w_round_key[6]),
    .i_aes_decipher(i_aes_decipher),
    .o_state       (w_round_state[6])
  );

  // Stage 8 uses the selected forward or reverse AES round key.
  m_aes128_aes_round #(
    .PARA_AES_PIPE_STAGE (aes_pipe_stage_type_def'(ENUM_AES_STAGE_8))
  ) u_aes128_aes_round_7 (
    .i_state       (w_stage_input_data[7]),
    .i_round_key   (w_round_key[7]),
    .i_aes_decipher(i_aes_decipher),
    .o_state       (w_round_state[7])
  );

  // Stage 9 uses the selected forward or reverse AES round key.
  m_aes128_aes_round #(
    .PARA_AES_PIPE_STAGE (aes_pipe_stage_type_def'(ENUM_AES_STAGE_9))
  ) u_aes128_aes_round_8 (
    .i_state       (w_stage_input_data[8]),
    .i_round_key   (w_round_key[8]),
    .i_aes_decipher(i_aes_decipher),
    .o_state       (w_round_state[8])
  );

  // Stage 10 uses the selected forward or reverse AES round key.
  m_aes128_aes_round #(
    .PARA_AES_PIPE_STAGE (aes_pipe_stage_type_def'(ENUM_AES_STAGE_10))
  ) u_aes128_aes_round_9 (
    .i_state       (w_stage_input_data[9]),
    .i_round_key   (w_round_key[9]),
    .i_aes_decipher(i_aes_decipher),
    .o_state       (w_round_state[9])
  );

endmodule
