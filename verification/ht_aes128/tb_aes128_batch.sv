`timescale 1ns/1ps

`ifndef TB_LANES
`define TB_LANES 4
`endif

module tb_aes128_batch;
  localparam integer LANES = `TB_LANES;
  localparam integer BLOCK_W = 128;
  localparam integer DATA_W = LANES * BLOCK_W;
  localparam integer ASSERT_COUNT = 20;
  localparam integer SCORE_DEPTH = 4096;

  logic i_clk_core = 1'b0;
  logic i_rst_n_core = 1'b1;
  logic i_cfg_valid = 1'b0;
  wire o_cfg_ready;
  logic [127:0] i_cfg_key = '0;
  logic [2:0] i_cfg_mode = '0;
  logic i_cfg_decipher = 1'b0;
  logic [127:0] i_cfg_iv = '0;
  logic [3:0] i_cfg_cfb_segment_size = '0;
  logic i_batch_valid = 1'b0;
  wire o_batch_ready;
  logic [DATA_W-1:0] i_batch_data = '0;
  logic [LANES-1:0] i_batch_lane_valid = '0;
  logic i_batch_last = 1'b0;
  wire o_batch_valid;
  logic i_batch_ready = 1'b1;
  wire [DATA_W-1:0] o_batch_data;
  wire [LANES-1:0] o_batch_lane_valid;
  wire o_batch_last;
  wire o_err_valid;
  logic i_err_ready = 1'b0;
  wire [3:0] o_err_code;
  logic i_zeroize_req = 1'b0;
  wire o_zeroize_done;

  m_aes128_batch_top #(
    .PARA_AES_LANE_NUM (32'(LANES)),
    .PARA_CTR_WIDTH    (32'd32)
  ) dut (
    .i_clk_core             (i_clk_core),
    .i_rst_n_core           (i_rst_n_core),
    .i_cfg_valid            (i_cfg_valid),
    .o_cfg_ready             (o_cfg_ready),
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

  always #5 i_clk_core = ~i_clk_core;

  logic [DATA_W-1:0] expected_data_q [0:SCORE_DEPTH-1];
  logic [DATA_W-1:0] compare_mask_q [0:SCORE_DEPTH-1];
  logic [LANES-1:0] expected_lanes_q [0:SCORE_DEPTH-1];
  logic expected_last_q [0:SCORE_DEPTH-1];
  integer accepted_cycle_q [0:SCORE_DEPTH-1];
  integer score_wr = 0;
  integer score_rd = 0;
  integer accepted_wr = 0;
  integer cycle_count = 0;
  integer input_handshakes = 0;
  integer output_handshakes = 0;
  integer failed_checks = 0;
  integer assertion_hits [0:ASSERT_COUNT-1];
  integer assertion_fails [0:ASSERT_COUNT-1];
  integer assertion_required [0:ASSERT_COUNT-1];
  integer k;
  integer stream_count_total = 0;
  integer random_seed = 32'h0000a128;
  integer trace_enable = 0;
  integer random_ready_enable = 0;
  integer random_ready_holdoff = 0;
  integer latency_check_enable = 0;
  integer ii_check_enable = 0;
  integer feedback_check_enable = 0;
  integer previous_input_cycle = -1;
  integer previous_output_cycle = -1;
  integer previous_feedback_input_cycle = -1;
  logic cfg_wait_prev = 1'b0;
  logic batch_wait_prev = 1'b0;
  logic output_stall_prev = 1'b0;
  logic error_stall_prev = 1'b0;
  logic abort_prev = 1'b0;
  logic [127:0] cfg_key_prev;
  logic [2:0] cfg_mode_prev;
  logic cfg_decipher_prev;
  logic [127:0] cfg_iv_prev;
  logic [3:0] cfg_segment_prev;
  logic [DATA_W-1:0] batch_data_prev;
  logic [LANES-1:0] batch_mask_prev;
  logic batch_last_prev;
  logic [DATA_W-1:0] output_data_prev;
  logic [LANES-1:0] output_mask_prev;
  logic output_last_prev;
  logic [3:0] error_code_prev;
  logic output_valid_prev = 1'b0;
  logic wave_dump_started = 1'b0;
  logic batch_expect_output = 1'b0;
  logic reset_seen = 1'b0;

  function automatic logic f_lane_mask_is_prefix(input logic [LANES-1:0] mask_value);
    logic valid_prefix;
    begin
      valid_prefix = (mask_value != '0);
      for (int lane_idx = 1; lane_idx < LANES; lane_idx++) begin
        if (mask_value[lane_idx] & ~mask_value[lane_idx-1])
          valid_prefix = 1'b0;
      end
      f_lane_mask_is_prefix = valid_prefix;
    end
  endfunction

  task automatic check_assertion(
    input integer assertion_id,
    input logic condition,
    input string detail
  );
    begin
      assertion_hits[assertion_id] = assertion_hits[assertion_id] + 1;
      if (condition !== 1'b1) begin
        assertion_fails[assertion_id] = assertion_fails[assertion_id] + 1;
        failed_checks = failed_checks + 1;
        $display("ASSERT FAIL @cycle %0d: A%02d %s (%s)",
                 cycle_count, assertion_id, assertion_label(assertion_id), detail);
      end
    end
  endtask

  function automatic string assertion_label(input integer assertion_id);
    begin
      case (assertion_id)
        0: assertion_label = "REQ-IF-001 config stable until handshake";
        1: assertion_label = "REQ-IF-002 batch stable until handshake";
        2: assertion_label = "REQ-IF-003 output stable while stalled";
        3: assertion_label = "REQ-ERR-003 error record stable while stalled";
        4: assertion_label = "REQ-IF-001 config and batch are not accepted together";
        5: assertion_label = "REQ-IF-004 accepted lane mask is a nonzero prefix";
        6: assertion_label = "REQ-IF-004 output lane mask matches accepted batch";
        7: assertion_label = "REQ-IF-005 last marker is preserved";
        8: assertion_label = "REQ-FUNC-003 ordered independent golden scoreboard";
        9: assertion_label = "REQ-PERF-004 no-stall latency is L_PIPE=10";
        10: assertion_label = "REQ-PERF-001 independent input/output II=1";
        11: assertion_label = "REQ-PERF-003 feedback interval is 11 cycles";
        12: assertion_label = "REQ-ERR-001 illegal configuration reports code 1";
        13: assertion_label = "REQ-ERR-001 illegal lane mask reports code 2";
        14: assertion_label = "REQ-FUNC-007 CTR wrap rejects a whole batch";
        15: assertion_label = "REQ-SEC-001 zeroize clears output and error valid";
        16: assertion_label = "REQ-SEC-001 zeroize done is one cycle";
        17: assertion_label = "REQ-RESET-002 reset clears pending valid state";
        18: assertion_label = "REQ-IF-001 reconfiguration blocked while context active";
        default: assertion_label = "REQ-IF-006 control outputs are known values";
      endcase
    end
  endfunction

  task automatic enqueue_expected(
    input logic [DATA_W-1:0] expected_value,
    input logic [DATA_W-1:0] compare_mask,
    input logic [LANES-1:0] lane_mask,
    input logic last_value
  );
    begin
      if (score_wr >= SCORE_DEPTH) begin
        failed_checks = failed_checks + 1;
        $display("ERROR: scoreboard capacity exceeded");
      end else begin
        expected_data_q[score_wr] = expected_value;
        compare_mask_q[score_wr] = compare_mask;
        expected_lanes_q[score_wr] = lane_mask;
        expected_last_q[score_wr] = last_value;
        accepted_cycle_q[score_wr] = -1;
        score_wr = score_wr + 1;
      end
    end
  endtask

  task automatic configure_message(
    input logic [2:0] mode_value,
    input logic decipher_value,
    input logic [3:0] cfb_code,
    input logic [127:0] key_value,
    input logic [127:0] iv_value
  );
    integer timeout_count;
    logic handshake_seen;
    begin
      timeout_count = 0;
      handshake_seen = 1'b0;
      @(negedge i_clk_core);
      i_cfg_mode = mode_value;
      i_cfg_decipher = decipher_value;
      i_cfg_cfb_segment_size = cfb_code;
      i_cfg_key = key_value;
      i_cfg_iv = iv_value;
      i_cfg_valid = 1'b1;
      while (!handshake_seen && (timeout_count < 200)) begin
        @(posedge i_clk_core);
        if (o_cfg_ready === 1'b1)
          handshake_seen = 1'b1;
        else begin
          @(negedge i_clk_core);
          timeout_count = timeout_count + 1;
        end
      end
      if (!handshake_seen) begin
        failed_checks = failed_checks + 1;
        $display("ERROR: configuration ready timeout");
      end else begin
        #1;
        if (trace_enable != 0)
          $display("TRACE CFG mode=%0d dec=%0d key=%h K0=%h K1=%h",
                   mode_value, decipher_value, key_value,
                   dut.u_aes128_batch_core.reg_round_keys[127:0],
                   dut.u_aes128_batch_core.reg_round_keys[255:128]);
        @(negedge i_clk_core);
        i_cfg_valid = 1'b0;
      end
    end
  endtask

  task automatic send_batch(
    input logic [DATA_W-1:0] data_value,
    input logic [LANES-1:0] lane_mask,
    input logic last_value,
    input logic [DATA_W-1:0] expected_value,
    input logic [DATA_W-1:0] compare_mask
  );
    integer timeout_count;
    logic handshake_seen;
    begin
      enqueue_expected(expected_value, compare_mask, lane_mask, last_value);
      batch_expect_output = 1'b1;
      timeout_count = 0;
      handshake_seen = 1'b0;
      // Callers enter on a falling edge; reusing it allows back-to-back II=1 batches.
      i_batch_data = data_value;
      i_batch_lane_valid = lane_mask;
      i_batch_last = last_value;
      i_batch_valid = 1'b1;
      while (!handshake_seen && (timeout_count < 2000)) begin
        @(posedge i_clk_core);
        if (o_batch_ready === 1'b1)
          handshake_seen = 1'b1;
        else begin
          @(negedge i_clk_core);
          timeout_count = timeout_count + 1;
        end
      end
      if (!handshake_seen) begin
        failed_checks = failed_checks + 1;
        $display("ERROR: batch ready timeout");
      end else begin
        if (trace_enable != 0)
          $display("TRACE INPUT @%0t mode=%0d data=%h mask=%b last=%0d",
                   $time, i_cfg_mode, data_value, lane_mask, last_value);
        @(negedge i_clk_core);
        i_batch_valid = 1'b0;
        i_batch_data = '0;
        i_batch_lane_valid = '0;
        i_batch_last = 1'b0;
        batch_expect_output = 1'b0;
      end
    end
  endtask

  task automatic send_rejected_batch(
    input logic [DATA_W-1:0] data_value,
    input logic [LANES-1:0] lane_mask,
    input logic last_value
  );
    integer timeout_count;
    logic handshake_seen;
    begin
      timeout_count = 0;
      handshake_seen = 1'b0;
      batch_expect_output = 1'b0;
      @(negedge i_clk_core);
      i_batch_data = data_value;
      i_batch_lane_valid = lane_mask;
      i_batch_last = last_value;
      i_batch_valid = 1'b1;
      while (!handshake_seen && (timeout_count < 2000)) begin
        @(posedge i_clk_core);
        if (o_batch_ready === 1'b1)
          handshake_seen = 1'b1;
        else begin
          @(negedge i_clk_core);
          timeout_count = timeout_count + 1;
        end
      end
      if (!handshake_seen) begin
        failed_checks = failed_checks + 1;
        $display("ERROR: rejected-batch handshake timeout");
      end else begin
        @(negedge i_clk_core);
        i_batch_valid = 1'b0;
        i_batch_data = '0;
        i_batch_lane_valid = '0;
        i_batch_last = 1'b0;
      end
    end
  endtask

  task automatic wait_for_outputs;
    integer timeout_count;
    begin
      timeout_count = 0;
      while ((score_rd != score_wr) && (timeout_count < 3000)) begin
        @(posedge i_clk_core);
        #1;
        timeout_count = timeout_count + 1;
      end
      if (score_rd != score_wr) begin
        failed_checks = failed_checks + 1;
        $display("ERROR: output scoreboard timeout rd=%0d wr=%0d", score_rd, score_wr);
      end
    end
  endtask

  task automatic wait_context_idle;
    integer timeout_count;
    begin
      timeout_count = 0;
      while ((o_cfg_ready !== 1'b1) && (timeout_count < 3000)) begin
        @(posedge i_clk_core);
        #1;
        timeout_count = timeout_count + 1;
      end
      if (o_cfg_ready !== 1'b1) begin
        failed_checks = failed_checks + 1;
        $display("ERROR: context did not return to idle");
      end
    end
  endtask

  task automatic wait_for_error(input logic [3:0] code_value);
    integer timeout_count;
    begin
      timeout_count = 0;
      while ((o_err_valid !== 1'b1) && (timeout_count < 200)) begin
        @(posedge i_clk_core);
        #1;
        timeout_count = timeout_count + 1;
      end
      if (o_err_valid !== 1'b1) begin
        failed_checks = failed_checks + 1;
        $display("ERROR: error-valid timeout, expected code %0d", code_value);
      end else if (o_err_code !== code_value) begin
        failed_checks = failed_checks + 1;
        $display("ERROR: error code got %0d expected %0d", o_err_code, code_value);
      end
    end
  endtask

  task automatic consume_error;
    begin
      @(negedge i_clk_core);
      i_err_ready = 1'b1;
      @(posedge i_clk_core);
      @(negedge i_clk_core);
      i_err_ready = 1'b0;
    end
  endtask

  task automatic reset_dut;
    begin
      @(negedge i_clk_core);
      i_cfg_valid = 1'b0;
      i_batch_valid = 1'b0;
      i_batch_data = '0;
      i_batch_lane_valid = '0;
      i_batch_last = 1'b0;
      i_err_ready = 1'b0;
      i_zeroize_req = 1'b0;
      i_batch_ready = 1'b1;
      random_ready_enable = 0;
      i_rst_n_core = 1'b0;
      repeat (2) @(posedge i_clk_core);
      #1;
      check_assertion(17, !o_batch_valid && !o_err_valid && !o_zeroize_done,
                      "reset clears pending valid state");
      @(negedge i_clk_core);
      i_rst_n_core = 1'b1;
      repeat (2) @(posedge i_clk_core);
      #1;
    end
  endtask

  task automatic zeroize_and_check;
    begin
      @(negedge i_clk_core);
      i_zeroize_req = 1'b1;
      @(posedge i_clk_core);
      #1;
      check_assertion(15, !o_batch_valid && !o_err_valid,
                      "accepted zeroize clears pending result and error");
      check_assertion(16, o_zeroize_done,
                      "zeroize done asserts immediately after sampling edge");
      @(negedge i_clk_core);
      i_zeroize_req = 1'b0;
      @(posedge i_clk_core);
      #1;
      check_assertion(16, !o_zeroize_done,
                      "zeroize done deasserts after one cycle");
      score_rd = score_wr;
      accepted_wr = score_wr;
      repeat (12) begin
        @(posedge i_clk_core);
        #1;
        if (o_batch_valid)
          check_assertion(15, 1'b0, "stale output appeared after zeroize");
      end
    end
  endtask

  task automatic read_vector_file(input string path, input logic keep_context_open);
    integer fd;
    integer got;
    integer stream_idx;
    integer block_idx;
    integer group_size;
    integer lane_idx;
    integer left_count;
    logic [31:0] stream_count;
    logic [31:0] mode_word;
    logic [31:0] decipher_word;
    logic [31:0] segment_word;
    logic [31:0] block_count;
    logic [127:0] stream_key;
    logic [127:0] stream_iv;
    logic [127:0] block_data [0:3];
    logic [127:0] block_expected [0:3];
    logic [127:0] block_compare_mask [0:3];
    logic [DATA_W-1:0] batch_data;
    logic [DATA_W-1:0] batch_expected;
    logic [DATA_W-1:0] batch_compare_mask;
    logic [LANES-1:0] batch_mask;
    logic batch_last_value;
    begin
      fd = $fopen(path, "r");
      if (fd == 0) begin
        failed_checks = failed_checks + 1;
        $display("ERROR: cannot open vector file %s", path);
      end else begin
        got = $fscanf(fd, "%h", stream_count);
        if (got != 1) begin
          failed_checks = failed_checks + 1;
          $display("ERROR: invalid vector header in %s", path);
        end
        for (stream_idx = 0; stream_idx < stream_count; stream_idx++) begin
          got = $fscanf(fd, "%h %h %h %h %h %h",
                        mode_word, decipher_word, segment_word, block_count,
                        stream_key, stream_iv);
          if (got != 6) begin
            failed_checks = failed_checks + 1;
            $display("ERROR: malformed stream header %0d in %s", stream_idx, path);
          end else begin
            configure_message(mode_word[2:0], decipher_word[0],
                              segment_word[3:0], stream_key, stream_iv);
            block_idx = 0;
            while (block_idx < block_count) begin
              if (((mode_word == 32'd1) && !decipher_word[0]) ||
                  (mode_word == 32'd2) || (mode_word == 32'd3))
                group_size = 1;
              else if ((block_count - block_idx) > LANES)
                group_size = LANES;
              else
                group_size = block_count - block_idx;
              left_count = block_count - block_idx;
              if (group_size > left_count)
                group_size = left_count;
              batch_data = '0;
              batch_expected = '0;
              batch_compare_mask = '0;
              batch_mask = '0;
              for (lane_idx = 0; lane_idx < group_size; lane_idx++) begin
                got = $fscanf(fd, "%h %h %h", block_data[lane_idx],
                              block_expected[lane_idx],
                              block_compare_mask[lane_idx]);
                if (got != 3) begin
                  failed_checks = failed_checks + 1;
                  $display("ERROR: truncated vector stream %0d block %0d", stream_idx, block_idx + lane_idx);
                end else begin
                  batch_data[lane_idx*BLOCK_W +: BLOCK_W] = block_data[lane_idx];
                  batch_expected[lane_idx*BLOCK_W +: BLOCK_W] = block_expected[lane_idx];
                  batch_compare_mask[lane_idx*BLOCK_W +: BLOCK_W] = block_compare_mask[lane_idx];
                  batch_mask[lane_idx] = 1'b1;
                end
              end
              batch_last_value = (block_idx + group_size == block_count) && !keep_context_open;
              send_batch(batch_data, batch_mask, batch_last_value,
                         batch_expected, batch_compare_mask);
              block_idx = block_idx + group_size;
            end
            wait_for_outputs();
            if (!keep_context_open)
              wait_context_idle();
          end
        end
        $fclose(fd);
        stream_count_total = stream_count_total + stream_count;
      end
    end
  endtask

  task automatic wait_asserted_output;
    integer timeout_count;
    begin
      timeout_count = 0;
      while ((o_batch_valid !== 1'b1) && (timeout_count < 100)) begin
        @(posedge i_clk_core);
        #1;
        timeout_count = timeout_count + 1;
      end
      if (o_batch_valid !== 1'b1) begin
        failed_checks = failed_checks + 1;
        $display("ERROR: output-valid timeout");
      end
    end
  endtask

  task automatic test_invalid_config;
    begin
      i_err_ready = 1'b0;
      configure_message(3'd5, 1'b0, 4'd7,
                        128'h2b7e151628aed2a6abf7158809cf4f3c, 128'd0);
      wait_for_error(4'd1);
      check_assertion(12, o_err_valid && (o_err_code == 4'd1),
                      "illegal mode consumed; error 1 presented");
      repeat (3) begin
        @(posedge i_clk_core);
        #1;
      end
      check_assertion(3, o_err_valid && (o_err_code == 4'd1),
                      "error held while err_ready is low");
      consume_error();
      wait_context_idle();
    end
  endtask

  task automatic test_invalid_lane;
    logic [DATA_W-1:0] ignored_data;
    logic [LANES-1:0] invalid_mask;
    begin
      configure_message(3'd0, 1'b0, 4'd7,
                        128'h2b7e151628aed2a6abf7158809cf4f3c, 128'd0);
      ignored_data = '0;
      invalid_mask = '0;
      if (LANES >= 2)
        invalid_mask[1] = 1'b1;
      send_rejected_batch(ignored_data, invalid_mask, 1'b0);
      wait_for_error(4'd2);
      check_assertion(13, o_err_valid && (o_err_code == 4'd2),
                      "non-prefix lane mask reports code 2");
      repeat (12) begin
        @(posedge i_clk_core);
        #1;
        if (o_batch_valid)
          check_assertion(13, 1'b0, "invalid lane mask produced a result");
      end
      consume_error();
      zeroize_and_check();
      wait_context_idle();
    end
  endtask

  task automatic test_ctr_boundary;
    logic [DATA_W-1:0] rejected_data;
    begin
      i_batch_ready = 1'b1;
      read_vector_file("verification/ht_aes128/vectors/ctr_limit.vec", 1'b1);
      rejected_data = '0;
      send_rejected_batch(rejected_data, {{(LANES-1){1'b0}}, 1'b1}, 1'b0);
      wait_for_error(4'd3);
      check_assertion(14, o_err_valid && (o_err_code == 4'd3),
                      "counter request after maximum is rejected atomically");
      consume_error();
      wait_context_idle();
    end
  endtask

  task automatic test_cfg_blocked;
    begin
      configure_message(3'd0, 1'b0, 4'd7,
                        128'h2b7e151628aed2a6abf7158809cf4f3c, 128'd0);
      @(negedge i_clk_core);
      i_cfg_valid = 1'b1;
      i_cfg_mode = 3'd1;
      i_cfg_key = 128'h000102030405060708090a0b0c0d0e0f;
      repeat (3) begin
        @(posedge i_clk_core);
        #1;
        check_assertion(18, !o_cfg_ready,
                        "configuration remains blocked while message context is live");
      end
      @(negedge i_clk_core);
      i_zeroize_req = 1'b1;
      @(posedge i_clk_core);
      #1;
      check_assertion(15, !o_batch_valid && !o_err_valid,
                      "zeroize clears the active message context");
      check_assertion(16, o_zeroize_done,
                      "zeroize done asserts after clearing the blocked context");
      @(negedge i_clk_core);
      i_zeroize_req = 1'b0;
      @(posedge i_clk_core);
      if (o_cfg_ready !== 1'b1) begin
        failed_checks = failed_checks + 1;
        $display("ERROR: blocked configuration did not handshake after zeroize");
      end
      @(negedge i_clk_core);
      i_cfg_valid = 1'b0;
      reset_dut();
    end
  endtask

  task automatic test_zeroize_pending;
    logic [DATA_W-1:0] input_data;
    logic [DATA_W-1:0] expected_value;
    logic [DATA_W-1:0] compare_mask;
    logic [LANES-1:0] lane_mask;
    logic [LANES-1:0] invalid_mask;
    begin
      i_batch_ready = 1'b0;
      i_err_ready = 1'b0;
      configure_message(3'd0, 1'b0, 4'd7,
                        128'h2b7e151628aed2a6abf7158809cf4f3c, 128'd0);
      input_data = '0;
      expected_value = '0;
      compare_mask = '0;
      lane_mask = '0;
      invalid_mask = '0;
      if (LANES >= 2)
        invalid_mask[1] = 1'b1;
      input_data[127:0] = 128'h6bc1bee22e409f96e93d7e117393172a;
      expected_value[127:0] = 128'h3ad77bb40d7a3660a89ecaf32466ef97;
      compare_mask[127:0] = {128{1'b1}};
      lane_mask[0] = 1'b1;
      send_batch(input_data, lane_mask, 1'b0, expected_value, compare_mask);
      wait_asserted_output();
      send_rejected_batch(input_data, invalid_mask, 1'b0);
      wait_for_error(4'd2);
      check_assertion(2, o_batch_valid && !i_batch_ready,
                      "pending batch is stalled before zeroize");
      check_assertion(3, o_err_valid && (o_err_code == 4'd2),
                      "pending error is held before zeroize");
      zeroize_and_check();
      wait_context_idle();
      i_batch_ready = 1'b1;
      i_err_ready = 1'b0;
    end
  endtask

  task automatic test_latency_and_throughput;
    begin
      i_batch_ready = 1'b1;
      random_ready_enable = 0;
      latency_check_enable = 1;
      read_vector_file("verification/ht_aes128/vectors/wf001_latency.vec", 1'b0);
      latency_check_enable = 0;
      wait_context_idle();

      ii_check_enable = 1;
      read_vector_file("verification/ht_aes128/vectors/WF-002_ecb_batches.vec", 1'b0);
      ii_check_enable = 0;
      wait_context_idle();
    end
  endtask

  task automatic test_feedback_interval;
    begin
      i_batch_ready = 1'b1;
      random_ready_enable = 0;
      previous_feedback_input_cycle = -1;
      feedback_check_enable = 1;
      read_vector_file("verification/ht_aes128/vectors/WF-006_ofb.vec", 1'b0);
      feedback_check_enable = 0;
      wait_context_idle();
    end
  endtask

  task automatic test_input_backpressure;
    begin
      random_ready_enable = 1;
      random_ready_holdoff = 15;
      read_vector_file("verification/ht_aes128/vectors/backpressure.vec", 1'b0);
      random_ready_enable = 0;
      i_batch_ready = 1'b1;
      wait_for_outputs();
      wait_context_idle();
    end
  endtask

  task automatic run_regression;
    begin
      for (integer idx = 0; idx < ASSERT_COUNT; idx++)
        assertion_required[idx] = 1;
      reset_dut();
      random_ready_enable = 1;
      read_vector_file("verification/ht_aes128/vectors/regression.vec", 1'b0);
      random_ready_enable = 0;
      i_batch_ready = 1'b1;
      wait_for_outputs();
      wait_context_idle();
      test_input_backpressure();
      test_invalid_config();
      test_invalid_lane();
      test_ctr_boundary();
      test_cfg_blocked();
      test_zeroize_pending();
      test_latency_and_throughput();
      test_feedback_interval();
      reset_dut();
    end
  endtask

  task automatic start_wave_dump(input string path);
    begin
      if (path != "") begin
        $dumpfile(path);
        $dumpvars(0, tb_aes128_batch);
        wave_dump_started = 1'b1;
      end
    end
  endtask

  task automatic run_wave_case(input string wave_name, input string dump_path);
    logic [DATA_W-1:0] rejected_data;
    logic [LANES-1:0] rejected_lane_mask;
    begin
      for (integer idx = 0; idx < ASSERT_COUNT; idx++)
        assertion_required[idx] = 0;
      i_batch_ready = 1'b1;
      i_err_ready = 1'b0;
      if (wave_name == "WF-001_config_success") begin
        assertion_required[4] = 1;
        assertion_required[19] = 1;
        start_wave_dump(dump_path);
        configure_message(3'd0, 1'b0, 4'd7,
                          128'h000102030405060708090a0b0c0d0e0f, 128'd0);
        repeat (2) @(posedge i_clk_core);
      end else if (wave_name == "WF-001_config_error") begin
        assertion_required[3] = 1;
        assertion_required[12] = 1;
        start_wave_dump(dump_path);
        test_invalid_config();
      end else if (wave_name == "WF-002_ecb_batches") begin
        assertion_required[5] = 1;
        assertion_required[6] = 1;
        assertion_required[7] = 1;
        assertion_required[8] = 1;
        start_wave_dump(dump_path);
        read_vector_file("verification/ht_aes128/vectors/WF-002_ecb_batches.vec", 1'b0);
      end else if (wave_name == "WF-003_ctr_allocation") begin
        assertion_required[5] = 1;
        assertion_required[6] = 1;
        assertion_required[8] = 1;
        start_wave_dump(dump_path);
        read_vector_file("verification/ht_aes128/vectors/WF-003_ctr_allocation.vec", 1'b0);
      end else if (wave_name == "WF-004_ctr_wrap_rejection") begin
        assertion_required[14] = 1;
        start_wave_dump(dump_path);
        configure_message(3'd4, 1'b0, 4'd7,
                          128'h2b7e151628aed2a6abf7158809cf4f3c,
                          128'h00112233445566778899aabbfffffffe);
        rejected_data = '0;
        rejected_lane_mask = '0;
        for (integer lane_idx = 0; lane_idx < 3; lane_idx++)
          if (lane_idx < LANES)
            rejected_lane_mask[lane_idx] = 1'b1;
        send_rejected_batch(rejected_data, rejected_lane_mask, 1'b1);
        wait_for_error(4'd3);
        check_assertion(14, o_err_valid && (o_err_code == 4'd3),
                        "batch crossing the CTR limit is rejected atomically");
        repeat (2) @(posedge i_clk_core);
        consume_error();
      end else if (wave_name == "WF-005_cbc_decryption") begin
        assertion_required[5] = 1;
        assertion_required[6] = 1;
        assertion_required[7] = 1;
        assertion_required[8] = 1;
        start_wave_dump(dump_path);
        read_vector_file("verification/ht_aes128/vectors/WF-005_cbc_decryption.vec", 1'b0);
      end else if (wave_name == "WF-006_cbc_encrypt") begin
        assertion_required[5] = 1;
        assertion_required[6] = 1;
        assertion_required[7] = 1;
        assertion_required[8] = 1;
        assertion_required[11] = 1;
        start_wave_dump(dump_path);
        feedback_check_enable = 1;
        read_vector_file("verification/ht_aes128/vectors/WF-006_cbc_encrypt.vec", 1'b0);
        feedback_check_enable = 0;
      end else if (wave_name == "WF-006_cfb") begin
        assertion_required[5] = 1;
        assertion_required[6] = 1;
        assertion_required[7] = 1;
        assertion_required[8] = 1;
        assertion_required[11] = 1;
        start_wave_dump(dump_path);
        feedback_check_enable = 1;
        read_vector_file("verification/ht_aes128/vectors/WF-006_cfb.vec", 1'b0);
        feedback_check_enable = 0;
      end else if (wave_name == "WF-006_ofb") begin
        assertion_required[5] = 1;
        assertion_required[6] = 1;
        assertion_required[7] = 1;
        assertion_required[8] = 1;
        assertion_required[11] = 1;
        start_wave_dump(dump_path);
        feedback_check_enable = 1;
        read_vector_file("verification/ht_aes128/vectors/WF-006_ofb.vec", 1'b0);
        feedback_check_enable = 0;
      end else if (wave_name == "WF-007_backpressure") begin
        assertion_required[2] = 1;
        assertion_required[5] = 1;
        assertion_required[6] = 1;
        assertion_required[8] = 1;
        start_wave_dump(dump_path);
        i_batch_ready = 1'b0;
        begin : wf007_send
          logic [DATA_W-1:0] input_data;
          logic [DATA_W-1:0] expected_value;
          logic [DATA_W-1:0] compare_mask;
          logic [LANES-1:0] lane_mask;
          input_data = '0;
          expected_value = '0;
          compare_mask = '0;
          lane_mask = '0;
          input_data[127:0] = 128'h6bc1bee22e409f96e93d7e117393172a;
          expected_value[127:0] = 128'h3ad77bb40d7a3660a89ecaf32466ef97;
          compare_mask[127:0] = {128{1'b1}};
          lane_mask[0] = 1'b1;
          configure_message(3'd0, 1'b0, 4'd7,
                            128'h2b7e151628aed2a6abf7158809cf4f3c, 128'd0);
          send_batch(input_data, lane_mask, 1'b1,
                     expected_value, compare_mask);
        end
        wait_asserted_output();
        repeat (1) @(posedge i_clk_core);
        @(negedge i_clk_core);
        i_batch_ready = 1'b1;
        wait_for_outputs();
      end else if (wave_name == "WF-008_reset_zeroize") begin
        assertion_required[2] = 1;
        assertion_required[3] = 1;
        assertion_required[15] = 1;
        assertion_required[16] = 1;
        // Start capture after both pending records are visible, as the spec figure does.
        i_batch_ready = 1'b0;
        configure_message(3'd0, 1'b0, 4'd7,
                          128'h2b7e151628aed2a6abf7158809cf4f3c, 128'd0);
        begin : wf008_setup
          logic [DATA_W-1:0] input_data;
          logic [DATA_W-1:0] expected_value;
          logic [DATA_W-1:0] compare_mask;
          logic [LANES-1:0] lane_mask;
          logic [LANES-1:0] invalid_mask;
          input_data = '0;
          expected_value = '0;
          compare_mask = '0;
          lane_mask = '0;
          invalid_mask = '0;
          if (LANES >= 2)
            invalid_mask[1] = 1'b1;
          input_data[127:0] = 128'h6bc1bee22e409f96e93d7e117393172a;
          expected_value[127:0] = 128'h3ad77bb40d7a3660a89ecaf32466ef97;
          compare_mask[127:0] = {128{1'b1}};
          lane_mask[0] = 1'b1;
          send_batch(input_data, lane_mask, 1'b0, expected_value, compare_mask);
          wait_asserted_output();
          send_rejected_batch(input_data, invalid_mask, 1'b0);
          wait_for_error(4'd2);
        end
        start_wave_dump(dump_path);
        zeroize_and_check();
      end else begin
        failed_checks = failed_checks + 1;
        $display("ERROR: unknown waveform case %s", wave_name);
      end
    end
  endtask

  always @(negedge i_clk_core) begin
    if (random_ready_enable != 0) begin
      if (random_ready_holdoff > 0) begin
        i_batch_ready = 1'b0;
        random_ready_holdoff = random_ready_holdoff - 1;
      end else begin
        i_batch_ready = ($urandom(random_seed) % 4 != 0);
      end
    end
  end

  always @(posedge i_clk_core) begin
    cycle_count = cycle_count + 1;
    if (!i_rst_n_core) begin
      reset_seen = 1'b1;
      cfg_wait_prev = 1'b0;
      batch_wait_prev = 1'b0;
      output_stall_prev = 1'b0;
      error_stall_prev = 1'b0;
      output_valid_prev = 1'b0;
      abort_prev = 1'b1;
    end else begin
      if (cfg_wait_prev)
        check_assertion(0,
          i_cfg_valid && (i_cfg_key == cfg_key_prev) &&
          (i_cfg_mode == cfg_mode_prev) &&
          (i_cfg_decipher == cfg_decipher_prev) &&
          (i_cfg_iv == cfg_iv_prev) &&
          (i_cfg_cfb_segment_size == cfg_segment_prev),
          "configuration fields changed before accepted");
      cfg_wait_prev = i_cfg_valid && !o_cfg_ready;
      if (cfg_wait_prev) begin
        cfg_key_prev = i_cfg_key;
        cfg_mode_prev = i_cfg_mode;
        cfg_decipher_prev = i_cfg_decipher;
        cfg_iv_prev = i_cfg_iv;
        cfg_segment_prev = i_cfg_cfb_segment_size;
      end

      if (batch_wait_prev)
        check_assertion(1,
          i_batch_valid && (i_batch_data == batch_data_prev) &&
          (i_batch_lane_valid == batch_mask_prev) &&
          (i_batch_last == batch_last_prev),
          "batch payload changed before accepted");
      batch_wait_prev = i_batch_valid && !o_batch_ready;
      if (batch_wait_prev) begin
        batch_data_prev = i_batch_data;
        batch_mask_prev = i_batch_lane_valid;
        batch_last_prev = i_batch_last;
      end

      if (output_stall_prev && !abort_prev)
        check_assertion(2,
          o_batch_valid && (o_batch_data == output_data_prev) &&
          (o_batch_lane_valid == output_mask_prev) &&
          (o_batch_last == output_last_prev),
          "output record changed while valid and not ready");
      output_stall_prev = o_batch_valid && !i_batch_ready;
      if (output_stall_prev) begin
        output_data_prev = o_batch_data;
        output_mask_prev = o_batch_lane_valid;
        output_last_prev = o_batch_last;
      end

      if (error_stall_prev && !abort_prev)
        check_assertion(3,
          o_err_valid && (o_err_code == error_code_prev),
          "error record changed while not accepted");
      error_stall_prev = o_err_valid && !i_err_ready;
      if (error_stall_prev)
        error_code_prev = o_err_code;
      abort_prev = i_zeroize_req;

      if (reset_seen)
        check_assertion(19,
          ((^{o_cfg_ready, o_batch_ready, o_batch_valid, o_err_valid,
              o_err_code, o_zeroize_done}) !== 1'bx),
          "unknown or high-impedance control output");

      if (i_cfg_valid && o_cfg_ready) begin
        check_assertion(4, !(i_batch_valid && o_batch_ready),
                        "configuration and batch handshakes coincide");
      end
      if (i_batch_valid && o_batch_ready) begin
        input_handshakes = input_handshakes + 1;
        if (batch_expect_output) begin
          check_assertion(5, f_lane_mask_is_prefix(i_batch_lane_valid),
                          "accepted mask must be nonzero contiguous prefix");
          if (accepted_wr < SCORE_DEPTH) begin
            accepted_cycle_q[accepted_wr] = cycle_count;
            accepted_wr = accepted_wr + 1;
          end
        end
        if (ii_check_enable != 0) begin
          if (previous_input_cycle >= 0)
            check_assertion(10, cycle_count - previous_input_cycle == 1,
                            "independent batches should be accepted one per cycle");
          previous_input_cycle = cycle_count;
        end
        if (feedback_check_enable != 0) begin
          if (previous_feedback_input_cycle >= 0)
            check_assertion(11, cycle_count - previous_feedback_input_cycle == 11,
                            "dependent feedback batch must wait for C11");
          previous_feedback_input_cycle = cycle_count;
        end
      end

      if (o_batch_valid && i_batch_ready) begin
        output_handshakes = output_handshakes + 1;
        if (trace_enable != 0)
          $display("TRACE OUTPUT @%0t got=%h lanes=%b last=%0d",
                   $time, o_batch_data, o_batch_lane_valid, o_batch_last);
        if (trace_enable != 0) begin
          for (integer trace_idx = 0; trace_idx < 10; trace_idx++)
            $display("TRACE ROUND[%0d]=%h KEY=%h",
                     trace_idx,
                     dut.u_aes128_batch_core.u_aes128_lane_array.u_aes128_pipe_lane_0.reg_stage_data[trace_idx],
                     dut.u_aes128_batch_core.u_aes128_lane_array.u_aes128_pipe_lane_0.w_round_key[trace_idx]);
        end
        if (score_rd >= score_wr) begin
          check_assertion(8, 1'b0, "output with no expected queued batch");
        end else begin
          check_assertion(6,
            o_batch_lane_valid == expected_lanes_q[score_rd],
            "output active-lane mask differs from accepted batch");
          check_assertion(7,
            o_batch_last == expected_last_q[score_rd],
            "output last marker differs from accepted batch");
          check_assertion(8,
            ((o_batch_data & compare_mask_q[score_rd]) ===
             (expected_data_q[score_rd] & compare_mask_q[score_rd])),
            $sformatf("ordered data mismatch at output %0d", score_rd));
          if ((o_batch_data & compare_mask_q[score_rd]) !==
              (expected_data_q[score_rd] & compare_mask_q[score_rd]))
            $display("DATA TRACE output=%0d got=%h expected=%h mask=%h lanes=%b expected_lanes=%b",
                     score_rd, o_batch_data, expected_data_q[score_rd],
                     compare_mask_q[score_rd], o_batch_lane_valid,
                     expected_lanes_q[score_rd]);
          if (ii_check_enable != 0) begin
            if (previous_output_cycle >= 0)
              check_assertion(10, cycle_count - previous_output_cycle == 1,
                              "independent output batches should be one per cycle");
            previous_output_cycle = cycle_count;
          end
          score_rd = score_rd + 1;
        end
      end

      if (o_err_valid && !i_err_ready && !error_stall_prev)
        error_code_prev = o_err_code;
      output_valid_prev = o_batch_valid;
    end
    #1;
    if (latency_check_enable != 0 && o_batch_valid && !output_valid_prev) begin
      if (score_rd < score_wr && accepted_cycle_q[score_rd] >= 0)
        check_assertion(9,
          cycle_count - accepted_cycle_q[score_rd] == 10,
          "valid output must assert after exactly ten cycles");
    end
    output_valid_prev = o_batch_valid;
  end

  initial begin : p_tb_main
    string mode_arg;
    string dump_arg;
    string wave_arg;
    string vector_arg;
    integer seed_arg;
    integer never_exercised;
    integer total_assertion_fails;
    if ($value$plusargs("SEED=%d", seed_arg))
      random_seed = seed_arg;
    if ($test$plusargs("TRACE"))
      trace_enable = 1;
    mode_arg = "regression";
    wave_arg = "";
    dump_arg = "";
    vector_arg = "verification/ht_aes128/vectors/regression.vec";
    void'($value$plusargs("MODE=%s", mode_arg));
    void'($value$plusargs("WF=%s", wave_arg));
    void'($value$plusargs("DUMP=%s", dump_arg));
    void'($value$plusargs("VEC=%s", vector_arg));
    for (integer idx = 0; idx < ASSERT_COUNT; idx++) begin
      assertion_hits[idx] = 0;
      assertion_fails[idx] = 0;
      assertion_required[idx] = 0;
    end
    $display("SIM-BRANCH: synchronous single-clock IP (CDC wrapper outside this RTL)");
    $display("CONFIG: LANES=%0d CTR_WIDTH=32 SEED=%0d MODE=%s", LANES, random_seed, mode_arg);
    if (mode_arg == "regression") begin
      run_regression();
    end else if (mode_arg == "vectors") begin
      assertion_required[5] = 1;
      assertion_required[6] = 1;
      assertion_required[7] = 1;
      assertion_required[8] = 1;
      assertion_required[19] = 1;
      reset_dut();
      read_vector_file(vector_arg, 1'b0);
    end else if (wave_arg != "") begin
      reset_dut();
      run_wave_case(wave_arg, dump_arg);
    end else begin
      failed_checks = failed_checks + 1;
      $display("ERROR: unsupported MODE=%s WF=%s", mode_arg, wave_arg);
    end
    wait_for_outputs();
    repeat (2) @(posedge i_clk_core);
    #1;
    never_exercised = 0;
    total_assertion_fails = failed_checks;
    $display("--- assertion hit/fail table ---");
    for (integer idx = 0; idx < ASSERT_COUNT; idx++) begin
      if (assertion_required[idx] != 0) begin
        $display("ASSERT %02d hits=%0d failures=%0d | %s",
                 idx, assertion_hits[idx], assertion_fails[idx], assertion_label(idx));
        if (assertion_hits[idx] == 0)
          never_exercised = never_exercised + 1;
      end
      total_assertion_fails = total_assertion_fails + assertion_fails[idx];
    end
    if ((total_assertion_fails != 0) || (never_exercised != 0)) begin
      $display("assertion failures: %0d, assertions never exercised: %0d",
               total_assertion_fails, never_exercised);
      $fatal(1, "AES batch simulation failed");
    end else begin
      $display("SUMMARY PASS: streams=%0d input_batches=%0d output_batches=%0d LANES=%0d",
               stream_count_total, input_handshakes, output_handshakes, LANES);
      $display("assertion failures: 0, assertions never exercised: 0");
      $finish_and_return(0);
    end
  end

  initial begin : p_watchdog
    #2000000;
    $fatal(1, "global simulation watchdog expired");
  end
endmodule
