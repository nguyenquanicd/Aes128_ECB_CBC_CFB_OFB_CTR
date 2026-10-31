/*
 * Project      : AES-128/AES-256 ECB/CBC/CFB/OFB/CTR
 * Author       : Nguyen Hung Quan (user)
 * AI Flow      : VLSIT RTL Generator AI Automation Flow
 * AI Flow Page : https://github.com/nguyenquanicd/VLSIT_RTL_Generator_AI_Model
 * Date         : 2026-10-29
 * Description  : One block lane with an input capture and a shared 14-round pipeline.
 */
`timescale 1ns/1ps

module m_aes128_256_pipe_lane #(
  localparam logic [31:0] LPARA_AES_BLOCK_W = 128,
  localparam logic [31:0] LPARA_AES_ROUND_NUM = 14,
  localparam logic [31:0] LPARA_AES128_ROUND_NUM = 10,
  localparam logic [31:0] LPARA_AES128_LAST_ROUND_IDX = 9,
  localparam logic [31:0] LPARA_AES256_LAST_ROUND_IDX = 13,
  localparam logic [31:0] LPARA_AES128_LAST_PIPE_IDX = 8,
  localparam logic [31:0] LPARA_AES256_LAST_PIPE_IDX = 12,
  localparam logic [31:0] LPARA_AES128_KEY_NUM = 11,
  localparam logic [31:0] LPARA_AES256_KEY_NUM = 15,
  localparam logic [31:0] LPARA_AES_PIPE_REG_NUM = 13
) (
  // Clock, reset, and clear
  input  wire           i_clk_core,
  input  wire           i_rst_n_core,
  input  wire           i_clear,

  // Message key context
  input  wire           i_key_size,
  input  wire           i_decipher,
  input  wire  [1919:0] i_round_keys,

  // Input block stream
  input  wire           i_valid,
  output logic          o_ready,
  input  wire  [127:0]  i_data,
  input  wire           i_lane_active,
  input  wire           i_last,
  input  wire  [127:0]  i_post_xor_data,

  // Final round result stream
  output logic          o_valid,
  input  wire           i_ready,
  output logic [127:0]  o_data,
  output logic          o_lane_active,
  output logic          o_last,
  output logic [127:0]  o_post_xor_data
);

  // Internal signal declarations
  logic          reg_input_valid;
  logic [127:0]  reg_input_data;
  logic          reg_input_active;
  logic          reg_input_last;
  logic [127:0]  reg_input_post_xor;
  logic [LPARA_AES_PIPE_REG_NUM-1:0][127:0] reg_stage_data;
  logic [LPARA_AES_PIPE_REG_NUM-1:0]        reg_stage_valid;
  logic [LPARA_AES_PIPE_REG_NUM-1:0]        reg_stage_active;
  logic [LPARA_AES_PIPE_REG_NUM-1:0]        reg_stage_last;
  logic [LPARA_AES_PIPE_REG_NUM-1:0][127:0] reg_stage_post_xor;
  logic                                      w_input_valid_nxt;
  logic [127:0]                              w_input_data_nxt;
  logic                                      w_input_active_nxt;
  logic                                      w_input_last_nxt;
  logic [127:0]                              w_input_post_xor_nxt;
  logic [LPARA_AES_PIPE_REG_NUM-1:0][127:0] w_stage_data_nxt;
  logic [LPARA_AES_PIPE_REG_NUM-1:0]        w_stage_valid_nxt;
  logic [LPARA_AES_PIPE_REG_NUM-1:0]        w_stage_active_nxt;
  logic [LPARA_AES_PIPE_REG_NUM-1:0]        w_stage_last_nxt;
  logic [LPARA_AES_PIPE_REG_NUM-1:0][127:0] w_stage_post_xor_nxt;
  logic [127:0]  w_round_state [0:LPARA_AES_ROUND_NUM-1];
  logic [127:0]  w_round_input [0:LPARA_AES_ROUND_NUM-1];
  logic [127:0]  w_round_key [0:LPARA_AES_ROUND_NUM-1];
  logic          w_round_valid [0:LPARA_AES_ROUND_NUM-1];
  logic          w_round_active [0:LPARA_AES_ROUND_NUM-1];
  logic          w_round_last [0:LPARA_AES_ROUND_NUM-1];
  logic [127:0]  w_round_post_xor [0:LPARA_AES_ROUND_NUM-1];
  logic          w_input_ready;
  logic [127:0]  w_initial_key;

  // Select the initial AddRoundKey value for the configured key size and direction.
  always_comb begin : p_com_initial_key
    w_initial_key = '0;
    if (i_key_size) begin
      if (i_decipher)
        w_initial_key = i_round_keys[((LPARA_AES256_KEY_NUM - 1) * LPARA_AES_BLOCK_W) +: LPARA_AES_BLOCK_W];
      else
        w_initial_key = i_round_keys[0 +: LPARA_AES_BLOCK_W];
    end else begin
      if (i_decipher)
        w_initial_key = i_round_keys[((LPARA_AES128_KEY_NUM - 1) * LPARA_AES_BLOCK_W) +: LPARA_AES_BLOCK_W];
      else
        w_initial_key = i_round_keys[0 +: LPARA_AES_BLOCK_W];
    end
  end

  // The registered pipeline freezes together when the core cannot capture its final result.
  assign w_input_ready = !reg_input_valid || i_ready;

  // Transfer each block and its sideband through the unrolled round functions.
  for (genvar gen_idx = 0; gen_idx < LPARA_AES_ROUND_NUM; gen_idx++) begin : gen_round
    if (gen_idx == 0) begin : gen_first_round_input
      // Round zero consumes the input-capture register after the initial AddRoundKey.
      assign w_round_input[gen_idx] = $bits(w_round_input[gen_idx])'(reg_input_data ^ w_initial_key);
      assign w_round_valid[gen_idx] = reg_input_valid;
      assign w_round_active[gen_idx] = reg_input_active;
      assign w_round_last[gen_idx] = reg_input_last;
      assign w_round_post_xor[gen_idx] = reg_input_post_xor;
    end else begin : gen_following_round_input
      // Later rounds consume the preceding round register and its aligned sideband.
      assign w_round_input[gen_idx] = reg_stage_data[gen_idx - 1];
      assign w_round_valid[gen_idx] = reg_stage_valid[gen_idx - 1];
      assign w_round_active[gen_idx] = reg_stage_active[gen_idx - 1];
      assign w_round_last[gen_idx] = reg_stage_last[gen_idx - 1];
      assign w_round_post_xor[gen_idx] = reg_stage_post_xor[gen_idx - 1];
    end

    if (gen_idx < LPARA_AES128_ROUND_NUM) begin : gen_dual_key_sel
      // AES-128 and AES-256 use key indexes selected by the configured direction.
      assign w_round_key[gen_idx] = i_key_size
        ? (i_decipher
          ? i_round_keys[((LPARA_AES256_LAST_ROUND_IDX - gen_idx) * LPARA_AES_BLOCK_W) +: LPARA_AES_BLOCK_W]
          : i_round_keys[((gen_idx + 1) * LPARA_AES_BLOCK_W) +: LPARA_AES_BLOCK_W])
        : (i_decipher
          ? i_round_keys[((LPARA_AES128_LAST_ROUND_IDX - gen_idx) * LPARA_AES_BLOCK_W) +: LPARA_AES_BLOCK_W]
          : i_round_keys[((gen_idx + 1) * LPARA_AES_BLOCK_W) +: LPARA_AES_BLOCK_W]);
    end else begin : gen_aes256_key_sel
      // AES-128 does not use stages beyond its tenth round.
      assign w_round_key[gen_idx] = i_decipher
        ? i_round_keys[((LPARA_AES256_LAST_ROUND_IDX - gen_idx) * LPARA_AES_BLOCK_W) +: LPARA_AES_BLOCK_W]
        : i_round_keys[((gen_idx + 1) * LPARA_AES_BLOCK_W) +: LPARA_AES_BLOCK_W];
    end

    // One combinational AES transform is used for this registered round stage.
    m_aes128_256_aes_round #(
      .PARA_AES_ROUND_IDX (gen_idx)
    ) u_aes128_256_aes_round (
      .i_state      (w_round_input[gen_idx]),
      .i_round_key  (w_round_key[gen_idx]),
      .o_state      (w_round_state[gen_idx]),
      .i_key_size   (i_key_size),
      .i_decipher   (i_decipher)
    );
  end

  // Compute input-capture and round-stage next state with shared pipeline backpressure.
  always_comb begin : p_com_pipeline_nxt
    w_input_valid_nxt = reg_input_valid;
    w_input_data_nxt = reg_input_data;
    w_input_active_nxt = reg_input_active;
    w_input_last_nxt = reg_input_last;
    w_input_post_xor_nxt = reg_input_post_xor;
    w_stage_data_nxt = reg_stage_data;
    w_stage_valid_nxt = reg_stage_valid;
    w_stage_active_nxt = reg_stage_active;
    w_stage_last_nxt = reg_stage_last;
    w_stage_post_xor_nxt = reg_stage_post_xor;

    if (i_clear) begin
      w_input_valid_nxt = 1'b0;
      w_input_data_nxt = '0;
      w_input_active_nxt = 1'b0;
      w_input_last_nxt = 1'b0;
      w_input_post_xor_nxt = '0;
      w_stage_data_nxt = '0;
      w_stage_valid_nxt = '0;
      w_stage_active_nxt = '0;
      w_stage_last_nxt = '0;
      w_stage_post_xor_nxt = '0;
    end else begin
      if (i_ready) begin
        for (int idx = 0; idx < LPARA_AES_PIPE_REG_NUM; idx++) begin
          if (i_key_size || (idx <= LPARA_AES128_LAST_PIPE_IDX)) begin
            w_stage_valid_nxt[idx] = w_round_valid[idx];
            w_stage_data_nxt[idx] = w_round_valid[idx] ? w_round_state[idx] : '0;
            w_stage_active_nxt[idx] = w_round_valid[idx] ? w_round_active[idx] : 1'b0;
            w_stage_last_nxt[idx] = w_round_valid[idx] ? w_round_last[idx] : 1'b0;
            w_stage_post_xor_nxt[idx] = w_round_valid[idx] ? w_round_post_xor[idx] : '0;
          end
        end
      end

      if (!i_key_size) begin
        for (int idx = LPARA_AES128_LAST_PIPE_IDX + 1;
             idx < LPARA_AES_PIPE_REG_NUM; idx++) begin
          w_stage_data_nxt[idx] = '0;
          w_stage_valid_nxt[idx] = 1'b0;
          w_stage_active_nxt[idx] = 1'b0;
          w_stage_last_nxt[idx] = 1'b0;
          w_stage_post_xor_nxt[idx] = '0;
        end
      end

      if (w_input_ready) begin
        w_input_valid_nxt = i_valid;
        if (i_valid) begin
          w_input_data_nxt = i_data;
          w_input_active_nxt = i_lane_active;
          w_input_last_nxt = i_last;
          w_input_post_xor_nxt = i_post_xor_data;
        end else begin
          w_input_data_nxt = '0;
          w_input_active_nxt = 1'b0;
          w_input_last_nxt = 1'b0;
          w_input_post_xor_nxt = '0;
        end
      end
    end
  end

  // Register the input and round-stage next-state values.
  always_ff @(posedge i_clk_core, negedge i_rst_n_core) begin : p_ff_pipeline
    if (!i_rst_n_core) begin
      reg_input_valid <= 1'b0;
      reg_input_data <= '0;
      reg_input_active <= 1'b0;
      reg_input_last <= 1'b0;
      reg_input_post_xor <= '0;
      reg_stage_data <= '0;
      reg_stage_valid <= '0;
      reg_stage_active <= '0;
      reg_stage_last <= '0;
      reg_stage_post_xor <= '0;
    end else begin
      reg_input_valid <= w_input_valid_nxt;
      reg_input_data <= w_input_data_nxt;
      reg_input_active <= w_input_active_nxt;
      reg_input_last <= w_input_last_nxt;
      reg_input_post_xor <= w_input_post_xor_nxt;
      reg_stage_data <= w_stage_data_nxt;
      reg_stage_valid <= w_stage_valid_nxt;
      reg_stage_active <= w_stage_active_nxt;
      reg_stage_last <= w_stage_last_nxt;
      reg_stage_post_xor <= w_stage_post_xor_nxt;
    end
  end

  // Select the active final-round tap; the core captures this result at C10 or C14.
  assign o_ready = w_input_ready;

  // The result valid follows the selected AES-128 or AES-256 final-round input.
  assign o_valid = i_key_size ? reg_stage_valid[LPARA_AES256_LAST_PIPE_IDX]
                              : reg_stage_valid[LPARA_AES128_LAST_PIPE_IDX];

  // The selected final round transforms the registered state combinationally.
  assign o_data = i_key_size ? w_round_state[LPARA_AES256_LAST_ROUND_IDX]
                             : w_round_state[LPARA_AES128_LAST_ROUND_IDX];

  // Sideband fields use the same selected stage as the block result.
  assign o_lane_active = i_key_size ? reg_stage_active[LPARA_AES256_LAST_PIPE_IDX]
                                    : reg_stage_active[LPARA_AES128_LAST_PIPE_IDX];

  // The batch end marker remains aligned with the selected AES round.
  assign o_last = i_key_size ? reg_stage_last[LPARA_AES256_LAST_PIPE_IDX]
                             : reg_stage_last[LPARA_AES128_LAST_PIPE_IDX];

  // The core uses this aligned operand for its mode-specific final XOR.
  assign o_post_xor_data = i_key_size ? reg_stage_post_xor[LPARA_AES256_LAST_PIPE_IDX]
                                      : reg_stage_post_xor[LPARA_AES128_LAST_PIPE_IDX];

endmodule
