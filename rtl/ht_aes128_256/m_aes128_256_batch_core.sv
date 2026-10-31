/*
 * Project      : AES-128/AES-256 ECB/CBC/CFB/OFB/CTR
 * Author       : Nguyen Hung Quan (user)
 * AI Flow      : VLSIT RTL Generator AI Automation Flow
 * AI Flow Page : https://github.com/nguyenquanicd/VLSIT_RTL_Generator_AI_Model
 * Date         : 2026-10-29
 * Description  : Message context, mode processing, errors, zeroize, and result capture.
 */
`timescale 1ns/1ps

module m_aes128_256_batch_core #(
  // Parameter Description: number of parallel 128-bit AES block lanes.
  // Parameter values: legal values are 1 through 4; default is 4.
  // Parameter unit: count
  parameter logic [31:0] PARA_AES_LANE_NUM = 4,
  // Parameter Description: width of the low CTR field that increments per block.
  // Parameter values: legal values are 1 through 128; default is 32.
  // Parameter unit: bit
  parameter logic [31:0] PARA_CTR_WIDTH = 32,
  localparam logic [31:0] LPARA_AES_BLOCK_W = 128,
  localparam logic [31:0] LPARA_AES_BATCH_W = PARA_AES_LANE_NUM * LPARA_AES_BLOCK_W,
  localparam logic [31:0] LPARA_AES_CFB_MAX_CODE = 7,
  localparam logic [31:0] LPARA_AES_COUNT_W = 3,
  localparam logic [31:0] LPARA_AES_CTR_CALC_W =
    (PARA_CTR_WIDTH > 1) ? (PARA_CTR_WIDTH + 1) : LPARA_AES_COUNT_W,
  localparam logic [31:0] LPARA_AES_LANE0_MASK = 1,
  localparam logic [31:0] LPARA_AES_BLOCK_SHIFT_W = 128
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

  // Module-local types define the supported modes and response codes.
  typedef enum logic [2:0] {
    ENUM_AES_MODE_ECB = 3'b000,
    ENUM_AES_MODE_CBC = 3'b001,
    ENUM_AES_MODE_CFB = 3'b010,
    ENUM_AES_MODE_OFB = 3'b011,
    ENUM_AES_MODE_CTR = 3'b100
  } aes_mode_type_def;

  typedef enum logic [3:0] {
    ENUM_AES_ERR_NONE   = 4'h0,
    ENUM_AES_ERR_CONFIG = 4'h1,
    ENUM_AES_ERR_LANE   = 4'h2,
    ENUM_AES_ERR_CTR    = 4'h3,
    ENUM_AES_ERR_RSV    = 4'h4,
    ENUM_AES_ERR_PROTO  = 4'h5
  } aes_err_type_def;

  // Internal context, handshake, and mode datapath signals.
  logic                         reg_ctx_active;
  logic                         reg_input_closed;
  logic                         reg_key_size;
  logic                         reg_decipher;
  aes_mode_type_def             reg_mode;
  logic [3:0]                   reg_cfb_segment_size;
  logic [1919:0]                reg_round_keys;
  logic [127:0]                 reg_feedback;
  logic                         reg_ctr_exhausted;
  logic                         reg_feedback_pending;
  logic                         reg_out_valid;
  logic [LPARA_AES_BATCH_W-1:0] reg_out_data;
  logic [PARA_AES_LANE_NUM-1:0] reg_out_lane_valid;
  logic                         reg_out_last;
  logic                         reg_err_valid;
  aes_err_type_def              reg_err_code;
  logic                         reg_zeroize_done;

  logic                         w_ctx_active_nxt;
  logic                         w_input_closed_nxt;
  logic                         w_key_size_nxt;
  logic                         w_decipher_nxt;
  aes_mode_type_def              w_mode_nxt;
  logic [3:0]                   w_cfb_segment_size_nxt;
  logic [1919:0]                w_round_keys_nxt;
  logic [127:0]                 w_feedback_nxt;
  logic                         w_ctr_exhausted_nxt;
  logic                         w_feedback_pending_nxt;
  logic                         w_out_valid_nxt;
  logic [LPARA_AES_BATCH_W-1:0] w_out_data_nxt;
  logic [PARA_AES_LANE_NUM-1:0] w_out_lane_valid_nxt;
  logic                         w_out_last_nxt;
  logic                         w_err_valid_nxt;
  aes_err_type_def              w_err_code_nxt;
  logic                         w_zeroize_done_nxt;

  logic                         w_cfg_valid;
  logic                         w_cfg_fire;
  logic [1919:0]                w_cfg_round_keys;
  logic                         w_feedback_mode;
  logic                         w_mode_aes_decipher;
  logic                         w_lane_prefix_ok;
  logic                         w_lane_mode_bad;
  logic                         w_lane_bad;
  logic                         w_protocol_bad;
  logic                         w_ctr_wrap;
  logic                         w_ctr_bad;
  logic                         w_data_bad;
  aes_err_type_def              w_data_err_code;
  logic                         w_batch_fire;
  logic                         w_data_accept;
  logic                         w_pipe_clear;
  logic                         w_pipe_in_ready;
  logic                         w_pipe_in_valid;
  logic                         w_pipe_out_valid;
  logic                         w_pipe_out_ready;
  logic                         w_pipe_out_last;
  logic                         w_out_slot_ready;
  logic                         w_result_fire;
  logic [2:0]                   w_active_count;
  logic [LPARA_AES_CTR_CALC_W-1:0] w_ctr_advance;
  logic [127:0]                 w_ctr_base_nxt;
  logic [127:0]                 w_batch_tail_data;
  logic [LPARA_AES_BATCH_W-1:0] w_lane_input_data;
  logic [LPARA_AES_BATCH_W-1:0] w_lane_post_xor_data;
  logic [LPARA_AES_BATCH_W-1:0] w_pipe_out_data;
  logic [PARA_AES_LANE_NUM-1:0] w_pipe_out_lane_valid;
  logic [LPARA_AES_BATCH_W-1:0] w_pipe_post_xor_data;
  logic [LPARA_AES_BATCH_W-1:0] w_result_data;
  logic [127:0]                 w_cfb_mask;
  logic [7:0]                   w_cfb_segment_bits;
  logic [7:0]                   w_cfb_shift_bits;
  logic [127:0]                 w_cfb_cipher_word;
  logic [127:0]                 w_cfb_feedback_nxt;
  logic                         w_prefix_zero_seen;

  logic [PARA_AES_LANE_NUM-1:0][LPARA_AES_CTR_CALC_W-1:0] w_lane_ctr_sum;
  logic [PARA_AES_LANE_NUM-1:0][127:0] w_lane_ctr_data;
  logic [PARA_AES_LANE_NUM-1:0][127:0] w_lane_prev_data;

  // Add an unsigned lane offset to only the configured low counter field.
  function automatic logic [LPARA_AES_CTR_CALC_W-1:0] f_ctr_add(
    input logic [PARA_CTR_WIDTH-1:0] i_base,
    input logic [2:0] i_increment
  );
    logic [LPARA_AES_CTR_CALC_W-1:0] w_base_ext;
    logic [LPARA_AES_CTR_CALC_W-1:0] w_increment_ext;
    begin
      w_base_ext = '0;
      w_increment_ext = '0;
      w_base_ext[PARA_CTR_WIDTH-1:0] = i_base;
      w_increment_ext[2:0] = i_increment;
      f_ctr_add = $bits(w_base_ext)'(w_base_ext + w_increment_ext);
    end
  endfunction

  // The counter addition is widened so carry out is detected before truncation.
  for (genvar gen_ctr_idx = 0; gen_ctr_idx < PARA_AES_LANE_NUM; gen_ctr_idx++) begin : gen_ctr_lane
    // Calculate each lane counter in a widened field for per-lane wrap detection.
    assign w_lane_ctr_sum[gen_ctr_idx] =
      f_ctr_add(reg_feedback[PARA_CTR_WIDTH-1:0], 3'(gen_ctr_idx));
    // Preserve the fixed upper counter bits and use the incremented low field.
    assign w_lane_ctr_data[gen_ctr_idx] =
      (reg_feedback & (128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF << PARA_CTR_WIDTH)) |
      $bits(w_lane_ctr_data[gen_ctr_idx])'(
        w_lane_ctr_sum[gen_ctr_idx][PARA_CTR_WIDTH-1:0]);
  end

  // Each lane carries the preceding ciphertext for parallel CBC decryption.
  for (genvar gen_prev_idx = 0; gen_prev_idx < PARA_AES_LANE_NUM; gen_prev_idx++) begin : gen_prev_data
    if (gen_prev_idx == 0) begin : gen_prev_first
      // Lane zero uses the IV or the prior accepted CBC ciphertext.
      assign w_lane_prev_data[gen_prev_idx] = reg_feedback;
    end else begin : gen_prev_following
      // Later lanes use the preceding ciphertext from this batch.
      assign w_lane_prev_data[gen_prev_idx] =
        i_batch_data[((gen_prev_idx - 1) * LPARA_AES_BLOCK_W) +: LPARA_AES_BLOCK_W];
    end
  end

  // Configuration, batch, mode, and result control derive from registered context.
  assign w_cfg_fire = i_cfg_valid && o_cfg_ready;
  assign w_batch_fire = i_batch_valid && o_batch_ready;
  assign w_data_accept = w_batch_fire && !w_data_bad && reg_ctx_active && !reg_input_closed;
  assign w_pipe_in_valid = w_data_accept;
  assign w_pipe_clear = i_zeroize_req;
  assign w_pipe_out_ready = w_out_slot_ready;
  assign w_result_fire = w_pipe_out_valid && w_pipe_out_ready;
  assign w_feedback_mode =
    ((reg_mode == ENUM_AES_MODE_CBC) && !reg_decipher) ||
    (reg_mode == ENUM_AES_MODE_CFB) ||
    (reg_mode == ENUM_AES_MODE_OFB);
  // Feedback and counter modes always use the AES encryption transform.
  assign w_mode_aes_decipher =
    ((reg_mode == ENUM_AES_MODE_ECB) || (reg_mode == ENUM_AES_MODE_CBC)) &&
    reg_decipher;
  // The core accepts a round result when its output slot is empty or being consumed.
  assign w_out_slot_ready = !reg_out_valid || i_batch_ready;
  assign o_batch_valid = reg_out_valid;
  assign o_batch_data = reg_out_data;
  assign o_batch_lane_valid = reg_out_lane_valid;
  assign o_batch_last = reg_out_last;
  assign o_err_valid = reg_err_valid;
  assign o_err_code = reg_err_code;
  assign o_zeroize_done = reg_zeroize_done;

  // Configuration validation rejects unsupported mode fields and malformed AES-128 keys.
  always_comb begin : p_com_cfg_check
    w_cfg_valid = 1'b1;
    if (i_cfg_mode > ENUM_AES_MODE_CTR)
      w_cfg_valid = 1'b0;
    if ((i_cfg_mode == ENUM_AES_MODE_CFB) &&
        (i_cfg_cfb_segment_size > 4'(LPARA_AES_CFB_MAX_CODE)))
      w_cfg_valid = 1'b0;
    if (!i_cfg_key_size && (i_cfg_key[255:128] != 128'b0))
      w_cfg_valid = 1'b0;
  end

  // Validate the prefix mask, count active blocks, and detect any CTR lane wrap.
  always_comb begin : p_com_batch_check
    w_lane_prefix_ok = 1'b1;
    w_prefix_zero_seen = 1'b0;
    w_active_count = '0;
    w_ctr_wrap = reg_ctr_exhausted;
    for (int idx = 0; idx < PARA_AES_LANE_NUM; idx++) begin
      if (i_batch_lane_valid[idx]) begin
        w_active_count = $bits(w_active_count)'(w_active_count + 3'd1);
        if (w_prefix_zero_seen)
          w_lane_prefix_ok = 1'b0;
        if (|w_lane_ctr_sum[idx][LPARA_AES_CTR_CALC_W-1:PARA_CTR_WIDTH])
          w_ctr_wrap = 1'b1;
      end else begin
        w_prefix_zero_seen = 1'b1;
      end
    end
  end

  // Data without a live context and data after the final input use protocol error 5.
  // Invalid message sequencing takes precedence over mask and counter checks.
  assign w_protocol_bad = !reg_ctx_active || reg_input_closed;
  assign w_lane_mode_bad = w_feedback_mode &&
    (i_batch_lane_valid != PARA_AES_LANE_NUM'(LPARA_AES_LANE0_MASK));
  // Reject empty, non-prefix, or feedback-mode multi-lane masks.
  assign w_lane_bad = !w_lane_prefix_ok || w_lane_mode_bad || (w_active_count == 3'd0);
  // Counter exhaustion applies only to CTR configuration.
  assign w_ctr_bad = (reg_mode == ENUM_AES_MODE_CTR) && w_ctr_wrap;
  // Any selected rejection condition makes the accepted batch non-work.
  assign w_data_bad = w_protocol_bad || w_lane_bad || w_ctr_bad;

  // Error response selection keeps the documented priority and explicit code values.
  always_comb begin : p_com_err_code
    w_data_err_code = ENUM_AES_ERR_NONE;
    casez ({w_protocol_bad, w_lane_bad, w_ctr_bad})
      3'b1??:   w_data_err_code = ENUM_AES_ERR_PROTO;
      3'b01?:   w_data_err_code = ENUM_AES_ERR_LANE;
      3'b001:   w_data_err_code = ENUM_AES_ERR_CTR;
      default:  w_data_err_code = ENUM_AES_ERR_NONE;
    endcase
  end

  // Pipeline input and external ready follow the active message and feedback dependency.
  always_comb begin : p_com_ready
    o_cfg_ready = 1'b0;
    o_batch_ready = 1'b0;
    if (i_rst_n_core && !i_zeroize_req && !reg_err_valid) begin
      if (!reg_ctx_active && !reg_out_valid)
        o_cfg_ready = 1'b1;
      if (!w_cfg_fire) begin
        if (!reg_ctx_active || reg_input_closed)
          o_batch_ready = 1'b1;
        else if (!reg_feedback_pending)
          o_batch_ready = w_pipe_in_ready;
      end
    end
  end

  // Prepare each lane's AES input and mode operand at the accepted batch boundary.
  always_comb begin : p_com_lane_prep
    w_lane_input_data = '0;
    w_lane_post_xor_data = '0;
    for (int idx = 0; idx < PARA_AES_LANE_NUM; idx++) begin
      case (reg_mode)
        ENUM_AES_MODE_ECB: begin
          w_lane_input_data[(idx * LPARA_AES_BLOCK_W) +: LPARA_AES_BLOCK_W] =
            i_batch_data[(idx * LPARA_AES_BLOCK_W) +: LPARA_AES_BLOCK_W];
        end
        ENUM_AES_MODE_CBC: begin
          if (reg_decipher) begin
            w_lane_input_data[(idx * LPARA_AES_BLOCK_W) +: LPARA_AES_BLOCK_W] =
              i_batch_data[(idx * LPARA_AES_BLOCK_W) +: LPARA_AES_BLOCK_W];
            w_lane_post_xor_data[(idx * LPARA_AES_BLOCK_W) +: LPARA_AES_BLOCK_W] =
              w_lane_prev_data[idx];
          end else begin
            w_lane_input_data[(idx * LPARA_AES_BLOCK_W) +: LPARA_AES_BLOCK_W] =
              i_batch_data[(idx * LPARA_AES_BLOCK_W) +: LPARA_AES_BLOCK_W] ^ reg_feedback;
          end
        end
        ENUM_AES_MODE_CFB, ENUM_AES_MODE_OFB: begin
          w_lane_input_data[(idx * LPARA_AES_BLOCK_W) +: LPARA_AES_BLOCK_W] = reg_feedback;
          w_lane_post_xor_data[(idx * LPARA_AES_BLOCK_W) +: LPARA_AES_BLOCK_W] =
            i_batch_data[(idx * LPARA_AES_BLOCK_W) +: LPARA_AES_BLOCK_W];
        end
        ENUM_AES_MODE_CTR: begin
          w_lane_input_data[(idx * LPARA_AES_BLOCK_W) +: LPARA_AES_BLOCK_W] =
            w_lane_ctr_data[idx];
          w_lane_post_xor_data[(idx * LPARA_AES_BLOCK_W) +: LPARA_AES_BLOCK_W] =
            i_batch_data[(idx * LPARA_AES_BLOCK_W) +: LPARA_AES_BLOCK_W];
        end
        default: begin
          w_lane_input_data[(idx * LPARA_AES_BLOCK_W) +: LPARA_AES_BLOCK_W] = '0;
          w_lane_post_xor_data[(idx * LPARA_AES_BLOCK_W) +: LPARA_AES_BLOCK_W] = '0;
        end
      endcase
    end
  end

  // Convert round results to the selected mode output before the core result register.
  always_comb begin : p_com_result_data
    w_result_data = '0;
    for (int idx = 0; idx < PARA_AES_LANE_NUM; idx++) begin
      if (w_pipe_out_lane_valid[idx]) begin
        case (reg_mode)
          ENUM_AES_MODE_CBC, ENUM_AES_MODE_CFB, ENUM_AES_MODE_OFB, ENUM_AES_MODE_CTR:
            w_result_data[(idx * LPARA_AES_BLOCK_W) +: LPARA_AES_BLOCK_W] =
              w_pipe_out_data[(idx * LPARA_AES_BLOCK_W) +: LPARA_AES_BLOCK_W] ^
              w_pipe_post_xor_data[(idx * LPARA_AES_BLOCK_W) +: LPARA_AES_BLOCK_W];
          default:
            w_result_data[(idx * LPARA_AES_BLOCK_W) +: LPARA_AES_BLOCK_W] =
              w_pipe_out_data[(idx * LPARA_AES_BLOCK_W) +: LPARA_AES_BLOCK_W];
        endcase
      end
    end
    if (reg_mode == ENUM_AES_MODE_CFB)
      w_result_data[127:0] = w_result_data[127:0] & w_cfb_mask;
  end

  // CFB segment masks retain the most-significant configured segment bits.
  always_comb begin : p_com_cfb_shift
    w_cfb_cipher_word = '0;
    w_cfb_segment_bits = 8'd1 << reg_cfb_segment_size;
    w_cfb_shift_bits = 8'(LPARA_AES_BLOCK_SHIFT_W) - w_cfb_segment_bits;
    w_cfb_mask = {LPARA_AES_BLOCK_W{1'b1}} << w_cfb_shift_bits;
    if (reg_decipher)
      w_cfb_cipher_word = w_pipe_post_xor_data[127:0] & w_cfb_mask;
    else
      w_cfb_cipher_word = w_result_data[127:0] & w_cfb_mask;
    w_cfb_feedback_nxt =
      (reg_feedback << w_cfb_segment_bits) |
      (w_cfb_cipher_word >> w_cfb_shift_bits);
  end

  // Select the final ciphertext of a CBC-decrypt batch for the next batch context.
  always_comb begin : p_com_batch_tail
    w_batch_tail_data = '0;
    for (int idx = 0; idx < PARA_AES_LANE_NUM; idx++) begin
      if (i_batch_lane_valid[idx])
        w_batch_tail_data = i_batch_data[(idx * LPARA_AES_BLOCK_W) +: LPARA_AES_BLOCK_W];
    end
  end

  // Retain the fixed upper counter bits and advance only the configured low field.
  always_comb begin : p_com_ctr_nxt
    w_ctr_advance = f_ctr_add(reg_feedback[PARA_CTR_WIDTH-1:0], w_active_count);
    w_ctr_base_nxt = reg_feedback;
    w_ctr_base_nxt[PARA_CTR_WIDTH-1:0] =
      w_ctr_advance[PARA_CTR_WIDTH-1:0];
  end

  // Compute the next context, feedback, output, error, and zeroize state.
  always_comb begin : p_com_state_nxt
    w_ctx_active_nxt = reg_ctx_active;
    w_input_closed_nxt = reg_input_closed;
    w_key_size_nxt = reg_key_size;
    w_decipher_nxt = reg_decipher;
    w_mode_nxt = reg_mode;
    w_cfb_segment_size_nxt = reg_cfb_segment_size;
    w_round_keys_nxt = reg_round_keys;
    w_feedback_nxt = reg_feedback;
    w_ctr_exhausted_nxt = reg_ctr_exhausted;
    w_feedback_pending_nxt = reg_feedback_pending;
    w_out_valid_nxt = reg_out_valid;
    w_out_data_nxt = reg_out_data;
    w_out_lane_valid_nxt = reg_out_lane_valid;
    w_out_last_nxt = reg_out_last;
    w_err_valid_nxt = reg_err_valid;
    w_err_code_nxt = reg_err_code;
    w_zeroize_done_nxt = 1'b0;

    if (i_zeroize_req) begin
      w_ctx_active_nxt = 1'b0;
      w_input_closed_nxt = 1'b0;
      w_key_size_nxt = 1'b0;
      w_decipher_nxt = 1'b0;
      w_mode_nxt = ENUM_AES_MODE_ECB;
      w_cfb_segment_size_nxt = '0;
      w_round_keys_nxt = '0;
      w_feedback_nxt = '0;
      w_ctr_exhausted_nxt = 1'b0;
      w_feedback_pending_nxt = 1'b0;
      w_out_valid_nxt = 1'b0;
      w_out_data_nxt = '0;
      w_out_lane_valid_nxt = '0;
      w_out_last_nxt = 1'b0;
      w_err_valid_nxt = 1'b0;
      w_err_code_nxt = ENUM_AES_ERR_NONE;
      w_zeroize_done_nxt = 1'b1;
    end else begin
      if (w_cfg_fire) begin
        if (w_cfg_valid) begin
          w_ctx_active_nxt = 1'b1;
          w_input_closed_nxt = 1'b0;
          w_key_size_nxt = i_cfg_key_size;
          w_decipher_nxt = i_cfg_decipher;
          w_mode_nxt = aes_mode_type_def'(i_cfg_mode);
          w_cfb_segment_size_nxt = i_cfg_cfb_segment_size;
          w_round_keys_nxt = w_cfg_round_keys;
          w_feedback_nxt = i_cfg_iv;
          w_ctr_exhausted_nxt = 1'b0;
          w_feedback_pending_nxt = 1'b0;
        end else begin
          w_err_valid_nxt = 1'b1;
          w_err_code_nxt = ENUM_AES_ERR_CONFIG;
        end
      end

      if (w_batch_fire && w_data_bad) begin
        w_err_valid_nxt = 1'b1;
        w_err_code_nxt = w_data_err_code;
      end

      if (w_data_accept) begin
        if (i_batch_last)
          w_input_closed_nxt = 1'b1;
        if ((reg_mode == ENUM_AES_MODE_CBC) && reg_decipher)
          w_feedback_nxt = w_batch_tail_data;
        if (reg_mode == ENUM_AES_MODE_CTR) begin
          w_feedback_nxt = w_ctr_base_nxt;
          if (|w_ctr_advance[LPARA_AES_CTR_CALC_W-1:PARA_CTR_WIDTH])
            w_ctr_exhausted_nxt = 1'b1;
        end
        if (w_feedback_mode)
          w_feedback_pending_nxt = 1'b1;
      end

      if (w_result_fire && w_feedback_mode) begin
        case (reg_mode)
          ENUM_AES_MODE_CBC: w_feedback_nxt = w_pipe_out_data[127:0];
          ENUM_AES_MODE_CFB: w_feedback_nxt = w_cfb_feedback_nxt;
          ENUM_AES_MODE_OFB: w_feedback_nxt = w_pipe_out_data[127:0];
          default:           w_feedback_nxt = reg_feedback;
        endcase
        w_feedback_pending_nxt = 1'b0;
      end

      if (w_result_fire) begin
        w_out_valid_nxt = 1'b1;
        w_out_data_nxt = w_result_data;
        w_out_lane_valid_nxt = w_pipe_out_lane_valid;
        w_out_last_nxt = w_pipe_out_last;
      end else if (reg_out_valid && i_batch_ready) begin
        w_out_valid_nxt = 1'b0;
        w_out_data_nxt = '0;
        w_out_lane_valid_nxt = '0;
        w_out_last_nxt = 1'b0;
      end

      if (reg_out_valid && i_batch_ready && reg_out_last) begin
        w_ctx_active_nxt = 1'b0;
        w_input_closed_nxt = 1'b0;
        w_key_size_nxt = 1'b0;
        w_decipher_nxt = 1'b0;
        w_mode_nxt = ENUM_AES_MODE_ECB;
        w_cfb_segment_size_nxt = '0;
        w_round_keys_nxt = '0;
        w_feedback_nxt = '0;
        w_ctr_exhausted_nxt = 1'b0;
        w_feedback_pending_nxt = 1'b0;
      end

      if (reg_err_valid && i_err_ready) begin
        w_err_valid_nxt = 1'b0;
        w_err_code_nxt = ENUM_AES_ERR_NONE;
      end
    end
  end

  // Register next-state values; the SoC synchronizes reset release before this boundary.
  always_ff @(posedge i_clk_core, negedge i_rst_n_core) begin : p_ff_core_state
    if (!i_rst_n_core) begin
      reg_ctx_active <= 1'b0;
      reg_input_closed <= 1'b0;
      reg_key_size <= 1'b0;
      reg_decipher <= 1'b0;
      reg_mode <= ENUM_AES_MODE_ECB;
      reg_cfb_segment_size <= '0;
      reg_round_keys <= '0;
      reg_feedback <= '0;
      reg_ctr_exhausted <= 1'b0;
      reg_feedback_pending <= 1'b0;
      reg_out_valid <= 1'b0;
      reg_out_data <= '0;
      reg_out_lane_valid <= '0;
      reg_out_last <= 1'b0;
      reg_err_valid <= 1'b0;
      reg_err_code <= ENUM_AES_ERR_NONE;
      reg_zeroize_done <= 1'b0;
    end else begin
      reg_ctx_active <= w_ctx_active_nxt;
      reg_input_closed <= w_input_closed_nxt;
      reg_key_size <= w_key_size_nxt;
      reg_decipher <= w_decipher_nxt;
      reg_mode <= w_mode_nxt;
      reg_cfb_segment_size <= w_cfb_segment_size_nxt;
      reg_round_keys <= w_round_keys_nxt;
      reg_feedback <= w_feedback_nxt;
      reg_ctr_exhausted <= w_ctr_exhausted_nxt;
      reg_feedback_pending <= w_feedback_pending_nxt;
      reg_out_valid <= w_out_valid_nxt;
      reg_out_data <= w_out_data_nxt;
      reg_out_lane_valid <= w_out_lane_valid_nxt;
      reg_out_last <= w_out_last_nxt;
      reg_err_valid <= w_err_valid_nxt;
      reg_err_code <= w_err_code_nxt;
      reg_zeroize_done <= w_zeroize_done_nxt;
    end
  end

  // The key expander is combinational; its schedule is captured with valid context.
  m_aes128_256_key_expand u_aes128_256_key_expand (
    .i_cfg_key_size (i_cfg_key_size),
    .i_cfg_key      (i_cfg_key),
    .o_round_keys   (w_cfg_round_keys)
  );

  // The lane array shares key context and backpressure across all generated lanes.
  m_aes128_256_lane_array #(
    .PARA_AES_LANE_NUM (PARA_AES_LANE_NUM)
  ) u_aes128_256_lane_array (
    .i_clk_core      (i_clk_core),
    .i_rst_n_core    (i_rst_n_core),
    .i_clear         (w_pipe_clear),
    .i_key_size      (reg_key_size),
    .i_decipher      (w_mode_aes_decipher),
    .i_round_keys    (reg_round_keys),
    .i_valid         (w_pipe_in_valid),
    .o_ready         (w_pipe_in_ready),
    .i_data          (w_lane_input_data),
    .i_lane_valid    (i_batch_lane_valid),
    .i_last          (i_batch_last),
    .i_post_xor_data (w_lane_post_xor_data),
    .o_valid         (w_pipe_out_valid),
    .i_ready         (w_pipe_out_ready),
    .o_data          (w_pipe_out_data),
    .o_lane_valid    (w_pipe_out_lane_valid),
    .o_last          (w_pipe_out_last),
    .o_post_xor_data (w_pipe_post_xor_data)
  );


endmodule
