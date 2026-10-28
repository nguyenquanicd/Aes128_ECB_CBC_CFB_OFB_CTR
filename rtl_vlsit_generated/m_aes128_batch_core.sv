/*
 * Project      : AES-128 ECB/CBC/CFB/OFB/CTR
 * Author       : Nguyen Hung Quan (user)
 * AI Flow      : VLSIT RTL Generator AI Automation Flow
 * AI Flow Page : https://github.com/nguyenquanicd/VLSIT_RTL_Generator_AI_Model
 * Date         : 2026-10-28
 * Description  : Stores one message context, validates batches, controls modes and
 *                counters, and reports errors and zeroize completion.
 */
`timescale 1ns/1ps

module m_aes128_batch_core #(
  // Parameter Description: number of AES lanes available in each input batch.
  // Parameter values: legal values are 1 through 4; default is 4.
  // Parameter unit: count
  parameter logic [31:0] PARA_AES_LANE_NUM = 32'd4,
  // Parameter Description: width of the incrementing low CTR field.
  // Parameter values: legal values are 1 through 128; default is 32.
  // Parameter unit: bit
  parameter logic [31:0] PARA_CTR_WIDTH = 32'd32,
  localparam logic [31:0] LPARA_AES_BLOCK_WIDTH = 32'd128,
  localparam logic [31:0] LPARA_ROUND_KEYS_WIDTH = 32'd1408,
  localparam logic [31:0] LPARA_BATCH_DATA_WIDTH = PARA_AES_LANE_NUM * 32'd128,
  localparam logic [31:0] LPARA_CTR_EXT_WIDTH = 32'd129,
  localparam logic [31:0] LPARA_CTR_COUNT_WIDTH = 32'd3,
  localparam logic [31:0] LPARA_BATCH_COUNT_WIDTH = 32'd4,
  localparam logic [31:0] LPARA_CFB_SEGMENT_WIDTH = 32'd8,
  localparam logic [31:0] LPARA_CFB_CODE_COUNT = 32'd8
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

  // Mode and error encodings follow the specification's external field values.
  typedef enum logic [2:0] {
    ENUM_MODE_ECB = 3'd0,
    ENUM_MODE_CBC = 3'd1,
    ENUM_MODE_CFB = 3'd2,
    ENUM_MODE_OFB = 3'd3,
    ENUM_MODE_CTR = 3'd4
  } aes_mode_type_def;

  typedef enum logic [3:0] {
    ENUM_ERR_NONE = 4'd0,
    ENUM_ERR_CONFIG = 4'd1,
    ENUM_ERR_LANE = 4'd2,
    ENUM_ERR_CTR_WRAP = 4'd3,
    ENUM_ERR_PROTOCOL = 4'd5
  } aes_err_type_def;

  // Context registers hold key schedule, mode state, and accepted-work tracking.
  logic reg_context_valid;
  logic reg_context_stop;
  aes_mode_type_def reg_context_mode;
  logic reg_context_decipher;
  logic reg_feedback_pending;
  logic [LPARA_ROUND_KEYS_WIDTH-1:0] reg_round_keys;
  logic [LPARA_AES_BLOCK_WIDTH-1:0] reg_feedback;
  logic [LPARA_AES_BLOCK_WIDTH-1:0] reg_ctr_base;
  logic reg_ctr_exhausted;
  logic [LPARA_CFB_SEGMENT_WIDTH-1:0] reg_cfb_segment_size;
  logic [LPARA_BATCH_COUNT_WIDTH-1:0] reg_outstanding_batches;
  logic reg_err_valid;
  aes_err_type_def reg_err_code;
  logic reg_zeroize_done;

  // Combinational data connects configuration, preprocessing, lane results, and mode output.
  logic [LPARA_ROUND_KEYS_WIDTH-1:0] w_cfg_round_keys;
  logic [LPARA_BATCH_DATA_WIDTH-1:0] w_array_input_data;
  logic [LPARA_BATCH_DATA_WIDTH-1:0] w_array_input_sideband;
  logic [LPARA_BATCH_DATA_WIDTH-1:0] w_array_result_data;
  logic [LPARA_BATCH_DATA_WIDTH-1:0] w_array_result_sideband;
  logic [LPARA_BATCH_DATA_WIDTH-1:0] w_batch_result_data;
  logic [PARA_AES_LANE_NUM-1:0] w_array_result_lane_valid;
  logic w_array_batch_ready;
  logic w_array_result_valid;
  logic w_array_result_last;
  logic w_array_input_valid;
  logic w_array_input_fire;
  logic w_output_handshake;
  logic w_config_handshake;
  logic w_batch_handshake;
  logic w_cfg_err_fire;
  logic w_batch_err_fire;
  logic w_err_handshake;
  logic w_cfg_mode_valid;
  logic w_cfg_segment_valid;
  logic w_cfg_valid;
  logic w_cfg_aes_decipher;
  logic w_lane_mask_valid;
  logic w_mode_lane_valid;
  logic w_batch_mask_valid;
  logic w_feedback_mode;
  logic w_feedback_slot_available;
  logic w_ctr_wrap;
  logic w_ctr_at_limit;
  logic [3:0] w_batch_err_code;
  logic [LPARA_CTR_COUNT_WIDTH-1:0] w_active_lane_count;
  logic [LPARA_CFB_SEGMENT_WIDTH-1:0] w_cfg_segment_len;
  logic [LPARA_CFB_SEGMENT_WIDTH-1:0] w_cfb_shift_count;
  logic [LPARA_CTR_EXT_WIDTH-1:0] w_ctr_base_ext;
  logic [LPARA_CTR_EXT_WIDTH-1:0] w_ctr_sum;
  logic [LPARA_CTR_EXT_WIDTH-1:0] w_ctr_limit;
  logic [LPARA_AES_BLOCK_WIDTH-1:0] w_ctr_lane_sum;
  logic [LPARA_AES_BLOCK_WIDTH-1:0] w_ctr_low_mask;
  logic [LPARA_AES_BLOCK_WIDTH-1:0] w_ctr_upper_mask;
  logic [LPARA_AES_BLOCK_WIDTH-1:0] w_last_input_ciphertext;
  logic [LPARA_AES_BLOCK_WIDTH-1:0] w_feedback_after_output;
  logic [LPARA_AES_BLOCK_WIDTH-1:0] w_feedback_for_input;
  logic [LPARA_AES_BLOCK_WIDTH-1:0] w_cfb_cipher_segment;
  logic [LPARA_AES_BLOCK_WIDTH-1:0] w_input_block;
  logic [LPARA_AES_BLOCK_WIDTH-1:0] w_input_sideband_block;
  logic [LPARA_AES_BLOCK_WIDTH-1:0] w_result_block;
  logic [LPARA_AES_BLOCK_WIDTH-1:0] w_raw_result_block;
  logic [LPARA_AES_BLOCK_WIDTH-1:0] w_result_sideband_block;
  logic [LPARA_AES_BLOCK_WIDTH-1:0] w_ctr_lane_block;
  logic w_aes_decipher;

  // The lane mask must be a nonzero prefix beginning at lane zero.
  function automatic logic f_lane_mask_valid(
    input logic [PARA_AES_LANE_NUM-1:0] i_mask
  );
    logic w_is_prefix;
    begin
      w_is_prefix = (i_mask != '0);
      for (int lane_idx = 1; lane_idx < PARA_AES_LANE_NUM; lane_idx++) begin
        if (i_mask[lane_idx] & ~i_mask[lane_idx-1])
          w_is_prefix = 1'b0;
      end
      f_lane_mask_valid = w_is_prefix;
    end
  endfunction

  // The public status ports expose held error state and the one-cycle clear pulse.
  assign o_err_valid = reg_err_valid;
  assign o_err_code = reg_err_code;
  assign o_zeroize_done = reg_zeroize_done;

  // Validate configuration and batches, and size the CTR field arithmetic explicitly.
  always_comb begin : p_com_validate
    w_cfg_mode_valid = 1'b0;
    case (i_cfg_mode)
      ENUM_MODE_ECB, ENUM_MODE_CBC, ENUM_MODE_CFB,
      ENUM_MODE_OFB, ENUM_MODE_CTR: w_cfg_mode_valid = 1'b1;
      default:                      w_cfg_mode_valid = 1'b0;
    endcase
    w_cfg_segment_valid =
      (i_cfg_cfb_segment_size < LPARA_CFB_CODE_COUNT[3:0]);
    w_cfg_valid = w_cfg_mode_valid &
      ((i_cfg_mode != ENUM_MODE_CFB) | w_cfg_segment_valid);
    w_lane_mask_valid = f_lane_mask_valid(i_batch_lane_valid);
    w_mode_lane_valid = 1'b1;
    w_feedback_mode = 1'b0;
    w_batch_mask_valid = 1'b0;
    w_active_lane_count = '0;
    w_cfg_segment_len = '0;
    w_ctr_base_ext = {{(LPARA_CTR_EXT_WIDTH-PARA_CTR_WIDTH){1'b0}},
                      reg_ctr_base[PARA_CTR_WIDTH-1:0]};
    w_ctr_sum = '0;
    w_ctr_limit = '0;
    w_ctr_wrap = 1'b0;
    w_ctr_at_limit = 1'b0;
    w_ctr_low_mask = '0;
    w_ctr_upper_mask = '0;
    w_last_input_ciphertext = '0;
    w_batch_err_code = 4'd0;
    if (w_cfg_segment_valid)
      w_cfg_segment_len = 8'd1 << i_cfg_cfb_segment_size;
    case (reg_context_mode)
      ENUM_MODE_CBC: w_feedback_mode = ~reg_context_decipher;
      ENUM_MODE_CFB: w_feedback_mode = 1'b1;
      ENUM_MODE_OFB: w_feedback_mode = 1'b1;
      default:       w_feedback_mode = 1'b0;
    endcase
    w_mode_lane_valid = 1'b1;
    if (w_feedback_mode) begin
      if (i_batch_lane_valid !=
          {{(PARA_AES_LANE_NUM-1){1'b0}}, 1'b1})
        w_mode_lane_valid = 1'b0;
    end
    w_batch_mask_valid = w_lane_mask_valid & w_mode_lane_valid;
    for (int lane_idx = 0; lane_idx < PARA_AES_LANE_NUM; lane_idx++) begin
      if (i_batch_lane_valid[lane_idx])
        w_active_lane_count = $bits(w_active_lane_count)'(
          w_active_lane_count + 3'd1);
      if (i_batch_lane_valid[lane_idx])
        w_last_input_ciphertext =
          i_batch_data[lane_idx * LPARA_AES_BLOCK_WIDTH +: LPARA_AES_BLOCK_WIDTH];
    end
    w_ctr_sum = $bits(w_ctr_sum)'(
      w_ctr_base_ext
      + {{(LPARA_CTR_EXT_WIDTH-LPARA_CTR_COUNT_WIDTH){1'b0}},
         w_active_lane_count});
    w_ctr_limit[PARA_CTR_WIDTH] = 1'b1;
    w_ctr_wrap = reg_ctr_exhausted | (w_ctr_sum > w_ctr_limit);
    w_ctr_at_limit = (w_ctr_sum == w_ctr_limit);
    w_ctr_low_mask[PARA_CTR_WIDTH-1:0] = '1;
    w_ctr_upper_mask = ~w_ctr_low_mask;
    // Priority is protocol, then lane mask, then CTR exhaustion; defaults remain defined.
    casez ({!reg_context_valid, reg_context_stop, !w_batch_mask_valid,
            (reg_context_mode == ENUM_MODE_CTR) & w_ctr_wrap})
      4'b1???: w_batch_err_code = ENUM_ERR_PROTOCOL;
      4'b01??: w_batch_err_code = ENUM_ERR_PROTOCOL;
      4'b001?: w_batch_err_code = ENUM_ERR_LANE;
      4'b0001: w_batch_err_code = ENUM_ERR_CTR_WRAP;
      default: w_batch_err_code = 4'd0;
    endcase
  end

  // Mode logic prepares AES inputs and forms stable data from the output registers.
  always_comb begin : p_com_mode
    w_cfg_aes_decipher = 1'b0;
    if (reg_context_decipher &
        ((reg_context_mode == ENUM_MODE_ECB) |
         (reg_context_mode == ENUM_MODE_CBC)))
      w_cfg_aes_decipher = 1'b1;
    w_aes_decipher = w_cfg_aes_decipher;
    w_cfb_shift_count = 8'd0;
    if (reg_cfb_segment_size != '0)
      w_cfb_shift_count = $bits(w_cfb_shift_count)'(
        LPARA_AES_BLOCK_WIDTH - reg_cfb_segment_size);
    w_batch_result_data = '0;
    w_result_block = '0;
    w_raw_result_block = '0;
    w_result_sideband_block = '0;
    w_cfb_cipher_segment = '0;
    for (int lane_idx = 0; lane_idx < PARA_AES_LANE_NUM; lane_idx++) begin
      w_raw_result_block =
        w_array_result_data[lane_idx * LPARA_AES_BLOCK_WIDTH
                            +: LPARA_AES_BLOCK_WIDTH];
      w_result_sideband_block =
        w_array_result_sideband[lane_idx * LPARA_AES_BLOCK_WIDTH
                                +: LPARA_AES_BLOCK_WIDTH];
      w_result_block = w_raw_result_block;
      case (reg_context_mode)
        ENUM_MODE_CBC: begin
          if (reg_context_decipher)
            w_result_block = w_raw_result_block ^ w_result_sideband_block;
        end
        ENUM_MODE_CTR, ENUM_MODE_OFB:
          w_result_block = w_raw_result_block ^ w_result_sideband_block;
        ENUM_MODE_CFB: begin
          w_result_block =
            ((w_raw_result_block >> w_cfb_shift_count) ^
             (w_result_sideband_block >> w_cfb_shift_count))
            << w_cfb_shift_count;
        end
        default: begin
          w_result_block = w_raw_result_block;
        end
      endcase
      w_batch_result_data[lane_idx * LPARA_AES_BLOCK_WIDTH
                          +: LPARA_AES_BLOCK_WIDTH] = w_result_block;
    end
    w_feedback_after_output = reg_feedback;
    case (reg_context_mode)
      ENUM_MODE_CBC: begin
        if (!reg_context_decipher)
          w_feedback_after_output =
            w_array_result_data[LPARA_AES_BLOCK_WIDTH-1:0];
      end
      ENUM_MODE_CFB: begin
        if (reg_context_decipher)
        w_cfb_cipher_segment =
          w_array_result_sideband[LPARA_AES_BLOCK_WIDTH-1:0]
          >> w_cfb_shift_count;
        else
          w_cfb_cipher_segment =
            w_batch_result_data[LPARA_AES_BLOCK_WIDTH-1:0]
            >> w_cfb_shift_count;
        w_feedback_after_output =
          (reg_feedback << reg_cfb_segment_size) | w_cfb_cipher_segment;
      end
      ENUM_MODE_OFB:
        w_feedback_after_output =
          w_array_result_data[LPARA_AES_BLOCK_WIDTH-1:0];
      default: begin
        w_feedback_after_output = reg_feedback;
      end
    endcase
    w_feedback_for_input = reg_feedback;
    if (reg_feedback_pending & w_output_handshake)
      w_feedback_for_input = w_feedback_after_output;
    w_array_input_data = '0;
    w_array_input_sideband = '0;
    w_input_block = '0;
    w_input_sideband_block = '0;
    w_ctr_lane_block = '0;
    w_ctr_lane_sum = '0;
    for (int lane_idx = 0; lane_idx < PARA_AES_LANE_NUM; lane_idx++) begin
      w_input_block = i_batch_data[lane_idx * LPARA_AES_BLOCK_WIDTH
                                   +: LPARA_AES_BLOCK_WIDTH];
      w_input_sideband_block = w_input_block;
      case (reg_context_mode)
        ENUM_MODE_CBC: begin
          if (reg_context_decipher) begin
            if (lane_idx == 0)
              w_input_sideband_block = w_feedback_for_input;
            else
              w_input_sideband_block =
                i_batch_data[(lane_idx * LPARA_AES_BLOCK_WIDTH)
                             - LPARA_AES_BLOCK_WIDTH
                             +: LPARA_AES_BLOCK_WIDTH];
          end else begin
            w_input_block = w_input_block ^ w_feedback_for_input;
          end
        end
        ENUM_MODE_CFB, ENUM_MODE_OFB: begin
          w_input_block = w_feedback_for_input;
        end
        ENUM_MODE_CTR: begin
          w_ctr_lane_sum = $bits(w_ctr_lane_sum)'(
            w_ctr_base_ext[LPARA_AES_BLOCK_WIDTH-1:0]
            + $bits(w_ctr_lane_sum)'(lane_idx));
          w_ctr_lane_block =
            (reg_ctr_base & w_ctr_upper_mask) |
            (w_ctr_lane_sum & w_ctr_low_mask);
          w_input_block = w_ctr_lane_block;
        end
        default: begin
          w_input_block = i_batch_data[lane_idx * LPARA_AES_BLOCK_WIDTH
                                       +: LPARA_AES_BLOCK_WIDTH];
        end
      endcase
      w_array_input_data[lane_idx * LPARA_AES_BLOCK_WIDTH
                         +: LPARA_AES_BLOCK_WIDTH] = w_input_block;
      w_array_input_sideband[lane_idx * LPARA_AES_BLOCK_WIDTH
                             +: LPARA_AES_BLOCK_WIDTH] =
        w_input_sideband_block;
    end
    o_batch_valid = w_array_result_valid;
    o_batch_data = w_batch_result_data;
    o_batch_lane_valid = w_array_result_lane_valid;
    o_batch_last = w_array_result_last;
  end

  // Handshakes allow one configuration context and preserve registered feedback ordering.
  always_comb begin : p_com_ctrl
    o_cfg_ready = 1'b0;
    o_batch_ready = 1'b0;
    w_output_handshake = w_array_result_valid & i_batch_ready;
    w_config_handshake = 1'b0;
    w_batch_handshake = 1'b0;
    w_cfg_err_fire = 1'b0;
    w_batch_err_fire = 1'b0;
    w_err_handshake = reg_err_valid & i_err_ready;
    w_feedback_slot_available = 1'b0;
    w_array_input_valid = 1'b0;
    w_array_input_fire = 1'b0;
    if (!i_zeroize_req & !reg_err_valid &
        !reg_context_valid & (reg_outstanding_batches == 4'd0))
      o_cfg_ready = 1'b1;
    w_config_handshake = i_cfg_valid & o_cfg_ready;
    if (!i_zeroize_req & !reg_err_valid &
        !(i_cfg_valid & o_cfg_ready)) begin
      if (!reg_context_valid | reg_context_stop)
        o_batch_ready = 1'b1;
      else begin
        w_feedback_slot_available =
          !w_feedback_mode | !reg_feedback_pending | w_output_handshake;
        if (w_array_batch_ready & w_feedback_slot_available)
          o_batch_ready = 1'b1;
      end
    end
    w_batch_handshake = i_batch_valid & o_batch_ready;
    w_batch_err_fire = w_batch_handshake &
      (w_batch_err_code != 4'd0);
    w_cfg_err_fire = w_config_handshake & !w_cfg_valid;
    w_array_input_valid = i_batch_valid & reg_context_valid &
      !reg_context_stop & !reg_err_valid & !i_zeroize_req &
      (w_batch_err_code == 4'd0) &
      (!w_feedback_mode | !reg_feedback_pending | w_output_handshake);
    w_array_input_fire = w_array_input_valid & w_array_batch_ready;
  end

  // Context, error, outstanding-batch, and zeroize state use the core clock.
  always_ff @(posedge i_clk_core, negedge i_rst_n_core) begin : p_ff_context
    if (!i_rst_n_core) begin
      reg_context_valid <= 1'b0;
      reg_context_stop <= 1'b0;
      reg_context_mode <= ENUM_MODE_ECB;
      reg_context_decipher <= 1'b0;
      reg_feedback_pending <= 1'b0;
      reg_round_keys <= '0;
      reg_feedback <= '0;
      reg_ctr_base <= '0;
      reg_ctr_exhausted <= 1'b0;
      reg_cfb_segment_size <= '0;
      reg_outstanding_batches <= '0;
      reg_err_valid <= 1'b0;
      reg_err_code <= ENUM_ERR_NONE;
      reg_zeroize_done <= 1'b0;
    end else if (i_zeroize_req) begin
      reg_context_valid <= 1'b0;
      reg_context_stop <= 1'b0;
      reg_context_mode <= ENUM_MODE_ECB;
      reg_context_decipher <= 1'b0;
      reg_feedback_pending <= 1'b0;
      reg_round_keys <= '0;
      reg_feedback <= '0;
      reg_ctr_base <= '0;
      reg_ctr_exhausted <= 1'b0;
      reg_cfb_segment_size <= '0;
      reg_outstanding_batches <= '0;
      reg_err_valid <= 1'b0;
      reg_err_code <= ENUM_ERR_NONE;
      reg_zeroize_done <= 1'b1;
    end else begin
      reg_zeroize_done <= 1'b0;
      if (w_err_handshake) begin
        reg_err_valid <= 1'b0;
        reg_err_code <= ENUM_ERR_NONE;
      end
      if (w_cfg_err_fire) begin
        reg_err_valid <= 1'b1;
        reg_err_code <= ENUM_ERR_CONFIG;
      end else if (w_batch_err_fire) begin
        reg_err_valid <= 1'b1;
        reg_err_code <= aes_err_type_def'(w_batch_err_code);
      end
      if (w_config_handshake & w_cfg_valid) begin
        reg_context_valid <= 1'b1;
        reg_context_stop <= 1'b0;
        reg_context_mode <= aes_mode_type_def'(i_cfg_mode);
        reg_context_decipher <= i_cfg_decipher;
        reg_feedback_pending <= 1'b0;
        reg_round_keys <= w_cfg_round_keys;
        reg_feedback <= i_cfg_iv;
        reg_ctr_base <= i_cfg_iv;
        reg_ctr_exhausted <= 1'b0;
        reg_cfb_segment_size <= w_cfg_segment_len;
      end
      case ({w_array_input_fire, w_output_handshake})
        2'b10:
          reg_outstanding_batches <= $bits(reg_outstanding_batches)'(
            reg_outstanding_batches + 4'd1);
        2'b01:
          reg_outstanding_batches <= $bits(reg_outstanding_batches)'(
            reg_outstanding_batches - 4'd1);
        default: reg_outstanding_batches <= reg_outstanding_batches;
      endcase
      if (w_array_input_fire) begin
        if (i_batch_last)
          reg_context_stop <= 1'b1;
        if (reg_context_mode == ENUM_MODE_CTR) begin
          reg_ctr_base <= (reg_ctr_base & w_ctr_upper_mask) |
            (w_ctr_sum[127:0] & w_ctr_low_mask);
          if (w_ctr_at_limit)
            reg_ctr_exhausted <= 1'b1;
        end
        if ((reg_context_mode == ENUM_MODE_CBC) &
            reg_context_decipher)
          reg_feedback <= w_last_input_ciphertext;
        if (w_feedback_mode)
          reg_feedback_pending <= 1'b1;
      end else if (w_output_handshake & reg_feedback_pending) begin
        reg_feedback_pending <= 1'b0;
      end
      if (w_output_handshake & w_feedback_mode)
        reg_feedback <= w_feedback_after_output;
      if (w_batch_err_fire &
          (w_batch_err_code == ENUM_ERR_CTR_WRAP))
        reg_context_stop <= 1'b1;
      if (w_output_handshake & reg_context_stop &
          (reg_outstanding_batches == 4'd1)) begin
        reg_context_valid <= 1'b0;
        reg_context_stop <= 1'b0;
        reg_context_mode <= ENUM_MODE_ECB;
        reg_context_decipher <= 1'b0;
        reg_feedback_pending <= 1'b0;
        reg_round_keys <= '0;
        reg_feedback <= '0;
        reg_ctr_base <= '0;
        reg_ctr_exhausted <= 1'b0;
        reg_cfb_segment_size <= '0;
      end else if (reg_context_valid & reg_context_stop &
                   (reg_outstanding_batches == 4'd0) &
                   !w_array_result_valid) begin
        reg_context_valid <= 1'b0;
        reg_context_stop <= 1'b0;
        reg_context_mode <= ENUM_MODE_ECB;
        reg_context_decipher <= 1'b0;
        reg_feedback_pending <= 1'b0;
        reg_round_keys <= '0;
        reg_feedback <= '0;
        reg_ctr_base <= '0;
        reg_ctr_exhausted <= 1'b0;
        reg_cfb_segment_size <= '0;
      end
    end
  end

  // The key schedule is captured only on a valid configuration handshake.
  m_aes128_key_expand u_aes128_key_expand (
    .i_key        (i_cfg_key),
    .o_round_keys (w_cfg_round_keys)
  );

  // The lane array carries raw AES results and sideband through ten round stages.
  m_aes128_lane_array #(
    .PARA_AES_LANE_NUM (PARA_AES_LANE_NUM)
  ) u_aes128_lane_array (
    .i_clk_core              (i_clk_core),
    .i_rst_n_core            (i_rst_n_core),
    .i_clear                 (i_zeroize_req),
    .i_batch_valid           (w_array_input_valid),
    .o_batch_ready           (w_array_batch_ready),
    .i_batch_data            (w_array_input_data),
    .i_sideband_data         (w_array_input_sideband),
    .i_lane_valid            (i_batch_lane_valid),
    .i_batch_last            (i_batch_last),
    .i_round_keys            (reg_round_keys),
    .i_aes_decipher          (w_aes_decipher),
    .i_result_ready          (i_batch_ready),
    .o_result_valid          (w_array_result_valid),
    .o_result_data           (w_array_result_data),
    .o_result_sideband_data  (w_array_result_sideband),
    .o_result_lane_valid     (w_array_result_lane_valid),
    .o_result_last           (w_array_result_last)
  );

endmodule
