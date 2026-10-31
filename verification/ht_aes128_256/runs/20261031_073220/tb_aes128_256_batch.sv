`timescale 1ns/1ps

module tb_aes128_256_batch;
  localparam integer LPARA_AES_BLOCK_W = 128;
`ifndef TB_LANES
  localparam integer LPARA_AES_LANE_NUM = 4;
`else
  localparam integer LPARA_AES_LANE_NUM = `TB_LANES;
`endif
  localparam integer LPARA_AES_BATCH_W = LPARA_AES_BLOCK_W * LPARA_AES_LANE_NUM;
  localparam integer LPARA_MAX_BLOCKS = 256;

  logic i_clk_core = 1'b0;
  logic i_rst_n_core = 1'b0;
  logic i_cfg_valid = 1'b0;
  wire o_cfg_ready;
  logic i_cfg_key_size = 1'b0;
  logic [255:0] i_cfg_key = '0;
  logic [2:0] i_cfg_mode = '0;
  logic i_cfg_decipher = 1'b0;
  logic [127:0] i_cfg_iv = '0;
  logic [3:0] i_cfg_cfb_segment_size = '0;
  logic i_batch_valid = 1'b0;
  wire o_batch_ready;
  logic [LPARA_AES_BATCH_W-1:0] i_batch_data = '0;
  logic [LPARA_AES_LANE_NUM-1:0] i_batch_lane_valid = '0;
  logic i_batch_last = 1'b0;
  wire o_batch_valid;
  logic i_batch_ready = 1'b1;
  wire [LPARA_AES_BATCH_W-1:0] o_batch_data;
  wire [LPARA_AES_LANE_NUM-1:0] o_batch_lane_valid;
  wire o_batch_last;
  wire o_err_valid;
  logic i_err_ready = 1'b0;
  wire [3:0] o_err_code;
  logic i_zeroize_req = 1'b0;
  wire o_zeroize_done;

  integer cycle_count = 0;
  integer assertion_count = 0;
  integer assertion_failures = 0;
  logic wave_dump_enabled = 1'b0;

  m_aes128_256_batch_top #(
    .PARA_AES_LANE_NUM (LPARA_AES_LANE_NUM),
    .PARA_CTR_WIDTH    (32)
  ) u_dut (
    .i_clk_core             (i_clk_core),
    .i_rst_n_core           (i_rst_n_core),
    .i_cfg_valid            (i_cfg_valid),
    .o_cfg_ready            (o_cfg_ready),
    .i_cfg_key_size         (i_cfg_key_size),
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
  always @(posedge i_clk_core) begin
    if (!i_rst_n_core)
      cycle_count = 0;
    else
      cycle_count = cycle_count + 1;
  end

  task automatic check_named(input string name, input logic condition, input string detail);
    begin
      assertion_count = assertion_count + 1;
      if (condition !== 1'b1) begin
        assertion_failures = assertion_failures + 1;
        $display("ASSERT FAIL cycle=%0d [%0s] %0s", cycle_count, name, detail);
      end else begin
        $display("ASSERT PASS cycle=%0d [%0s]", cycle_count, name);
      end
    end
  endtask

  task automatic reset_dut;
    begin
      @(negedge i_clk_core);
      i_rst_n_core = 1'b0;
      i_cfg_valid = 1'b0;
      i_batch_valid = 1'b0;
      i_batch_ready = 1'b1;
      i_err_ready = 1'b0;
      i_zeroize_req = 1'b0;
      repeat (2) @(negedge i_clk_core);
      i_rst_n_core = 1'b1;
      @(negedge i_clk_core);
      #0.1;
      check_named("RESET_OUTPUTS_CLEAR", !o_batch_valid && !o_err_valid && !o_zeroize_done,
                  "reset release must leave output/error/done inactive");
    end
  endtask

  task automatic configure_message(
    input logic key_size,
    input logic [255:0] key_value,
    input logic [2:0] mode_value,
    input logic decipher_value,
    input logic [127:0] iv_value,
    input logic [3:0] segment_value,
    output integer accepted_cycle
  );
    integer timeout_count;
    begin
      timeout_count = 0;
      accepted_cycle = -1;
      i_cfg_key_size = key_size;
      i_cfg_key = key_value;
      i_cfg_mode = mode_value;
      i_cfg_decipher = decipher_value;
      i_cfg_iv = iv_value;
      i_cfg_cfb_segment_size = segment_value;
      i_cfg_valid = 1'b1;
      while ((accepted_cycle < 0) && (timeout_count < 20)) begin
        #0.1;
        if (o_cfg_ready === 1'b1) begin
          @(posedge i_clk_core);
          #0.1;
          accepted_cycle = cycle_count;
          @(negedge i_clk_core);
          i_cfg_valid = 1'b0;
        end else begin
          @(negedge i_clk_core);
          timeout_count = timeout_count + 1;
        end
      end
      check_named("CONFIG_HANDSHAKE", accepted_cycle >= 0,
                  "configuration must complete within 20 cycles");
    end
  endtask

  task automatic drive_batch(
    input logic [LPARA_AES_BATCH_W-1:0] data_value,
    input logic [LPARA_AES_LANE_NUM-1:0] lane_mask,
    input logic last_value,
    output integer accepted_cycle
  );
    integer timeout_count;
    begin
      timeout_count = 0;
      accepted_cycle = -1;
      i_batch_data = data_value;
      i_batch_lane_valid = lane_mask;
      i_batch_last = last_value;
      i_batch_valid = 1'b1;
      while ((accepted_cycle < 0) && (timeout_count < 100)) begin
        #0.1;
        if (o_batch_ready === 1'b1) begin
          @(posedge i_clk_core);
          #0.1;
          accepted_cycle = cycle_count;
          @(negedge i_clk_core);
          i_batch_valid = 1'b0;
          i_batch_data = '0;
          i_batch_lane_valid = '0;
          i_batch_last = 1'b0;
        end else begin
          @(negedge i_clk_core);
          timeout_count = timeout_count + 1;
        end
      end
      check_named("BATCH_HANDSHAKE", accepted_cycle >= 0,
                  "input batch must be accepted within 100 cycles");
    end
  endtask

  task automatic wait_output(input integer timeout_cycles, output integer output_cycle);
    integer timeout_count;
    begin
      timeout_count = 0;
      output_cycle = -1;
      while ((o_batch_valid !== 1'b1) && (timeout_count < timeout_cycles)) begin
        @(negedge i_clk_core);
        timeout_count = timeout_count + 1;
      end
      #0.1;
      if (o_batch_valid === 1'b1)
        output_cycle = cycle_count;
      check_named("OUTPUT_VALID_TIMEOUT", output_cycle >= 0,
                  "result batch must become valid within the specified bound");
    end
  endtask

  task automatic wait_error(input logic [3:0] expected_code, input string check_name);
    integer timeout_count;
    begin
      timeout_count = 0;
      while ((o_err_valid !== 1'b1) && (timeout_count < 20)) begin
        @(negedge i_clk_core);
        timeout_count = timeout_count + 1;
      end
      #0.1;
      check_named(check_name, o_err_valid && (o_err_code == expected_code),
                  "error valid/code mismatch or response timeout");
    end
  endtask

  task automatic consume_error;
    begin
      @(negedge i_clk_core);
      i_err_ready = 1'b1;
      @(posedge i_clk_core);
      #0.1;
      @(negedge i_clk_core);
      i_err_ready = 1'b0;
    end
  endtask

  task automatic read_vector_file(input string path, input logic concurrent_mode,
                                  input logic stall_output);
    integer fd;
    integer rc;
    integer key_size;
    integer mode_value;
    integer decipher_value;
    integer segment_value;
    integer ctr_width;
    integer block_count;
    integer block_idx;
    integer lane_idx;
    integer chunk_count;
    integer batch_idx;
    integer input_cycle;
    integer first_input_cycle;
    integer output_cycle;
    integer first_output_cycle;
    logic [255:0] key_value;
    logic [127:0] iv_value;
    logic [127:0] data_mem [0:LPARA_MAX_BLOCKS-1];
    logic [127:0] expected_mem [0:LPARA_MAX_BLOCKS-1];
    logic [127:0] mask_mem [0:LPARA_MAX_BLOCKS-1];
    logic [LPARA_AES_BATCH_W-1:0] batch_data;
    logic [LPARA_AES_LANE_NUM-1:0] batch_mask;
    logic [LPARA_AES_BATCH_W-1:0] expected_batch;
    logic [LPARA_AES_BATCH_W-1:0] compare_batch;
    logic [LPARA_AES_BATCH_W-1:0] expected_batch_mem [0:2];
    logic [LPARA_AES_BATCH_W-1:0] compare_batch_mem [0:2];
    logic [LPARA_AES_LANE_NUM-1:0] expected_lane_mask;
    logic [LPARA_AES_LANE_NUM-1:0] expected_lane_mask_mem [0:2];
    logic expected_last;
    logic [LPARA_AES_BATCH_W-1:0] held_data;
    logic [LPARA_AES_LANE_NUM-1:0] held_mask;
    logic held_last;
    integer cfg_cycle;
    integer exp_latency;
    integer effective_lanes;
    integer measured_latency;
    integer previous_output_cycle;
    begin
      fd = $fopen(path, "r");
      if (fd == 0) begin
        $display("ERROR: cannot open independent vector file %0s", path);
        assertion_failures = assertion_failures + 1;
      end else begin
        rc = $fscanf(fd, "%d %d %d %d %d\n", key_size, mode_value,
                     decipher_value, segment_value, ctr_width);
        rc = $fscanf(fd, "%h\n", key_value);
        rc = $fscanf(fd, "%h\n", iv_value);
        rc = $fscanf(fd, "%d\n", block_count);
        if ((rc != 1) || (block_count <= 0) || (block_count > LPARA_MAX_BLOCKS)) begin
          $display("ERROR: malformed vector header in %0s", path);
          assertion_failures = assertion_failures + 1;
          $fclose(fd);
        end else begin
          for (block_idx = 0; block_idx < block_count; block_idx = block_idx + 1) begin
            rc = $fscanf(fd, "%h %h %h\n", data_mem[block_idx],
                         expected_mem[block_idx], mask_mem[block_idx]);
            if (rc != 3) begin
              $display("ERROR: malformed vector record %0d in %0s", block_idx, path);
              assertion_failures = assertion_failures + 1;
            end
          end
          $fclose(fd);

          configure_message(1'(key_size), key_value, 3'(mode_value),
                            1'(decipher_value), iv_value, 4'(segment_value), cfg_cycle);
          exp_latency = (key_size == 1) ? 14 : 10;
          effective_lanes = LPARA_AES_LANE_NUM;
          previous_output_cycle = -1;
          if ((mode_value == 1 && (decipher_value == 0)) ||
              (mode_value == 2) || (mode_value == 3))
            effective_lanes = 1;

          if (concurrent_mode) begin
            first_input_cycle = -1;
            for (batch_idx = 0; batch_idx < 3; batch_idx = batch_idx + 1) begin
              chunk_count = effective_lanes;
              batch_data = '0;
              expected_batch = '0;
              compare_batch = '0;
              expected_lane_mask = '0;
              batch_mask = '0;
              for (lane_idx = 0; lane_idx < chunk_count; lane_idx = lane_idx + 1) begin
                block_idx = batch_idx * chunk_count + lane_idx;
                batch_data[lane_idx*128 +: 128] = data_mem[block_idx];
                expected_batch[lane_idx*128 +: 128] = expected_mem[block_idx];
                compare_batch[lane_idx*128 +: 128] = mask_mem[block_idx];
                batch_mask[lane_idx] = 1'b1;
                expected_lane_mask[lane_idx] = 1'b1;
              end
              expected_batch_mem[batch_idx] = expected_batch;
              compare_batch_mem[batch_idx] = compare_batch;
              expected_lane_mask_mem[batch_idx] = expected_lane_mask;
              @(negedge i_clk_core);
              i_batch_data = batch_data;
              i_batch_lane_valid = batch_mask;
              i_batch_last = (batch_idx == 2);
              i_batch_valid = 1'b1;
              #0.1;
              check_named("THROUGHPUT_INPUT_READY", o_batch_ready,
                          "independent-mode pipeline must accept consecutive batches");
              @(posedge i_clk_core);
              #0.1;
              input_cycle = cycle_count;
              if (batch_idx == 0)
                first_input_cycle = input_cycle;
              else
                check_named("INPUT_II_ONE", input_cycle == first_input_cycle + batch_idx,
                            "input batches were not accepted on consecutive cycles");
            end
            @(negedge i_clk_core);
            i_batch_data = '0;
            i_batch_lane_valid = '0;
            i_batch_last = 1'b0;
            i_batch_valid = 1'b0;
            first_output_cycle = -1;
            for (batch_idx = 0; batch_idx < 3; batch_idx = batch_idx + 1) begin
              if (batch_idx == 0)
                wait_output(exp_latency + 8, output_cycle);
              else begin
                @(negedge i_clk_core);
                output_cycle = cycle_count;
                #0.1;
                check_named("OUTPUT_II_ONE", o_batch_valid,
                            "output valid must remain asserted for consecutive results");
              end
              if (batch_idx == 0) begin
                first_output_cycle = output_cycle;
                measured_latency = output_cycle - first_input_cycle;
                check_named((key_size == 1) ? "LATENCY_AES256_C14" : "LATENCY_AES128_C10",
                            measured_latency == exp_latency,
                            "first result did not appear at the specified C10/C14 boundary");
              end else begin
                check_named("OUTPUT_II_ONE", output_cycle == first_output_cycle + batch_idx,
                            "output batches were not consecutive after pipeline fill");
              end
              expected_last = (batch_idx == 2);
              check_named("THROUGHPUT_OUTPUT_META",
                          (o_batch_lane_valid == expected_lane_mask_mem[batch_idx]) &&
                          (o_batch_last == expected_last),
                          "throughput output mask or last marker mismatch");
              for (lane_idx = 0; lane_idx < LPARA_AES_LANE_NUM; lane_idx = lane_idx + 1) begin
                if (lane_idx < chunk_count) begin
                  check_named("THROUGHPUT_GOLDEN_DATA",
                              ((o_batch_data[lane_idx*128 +: 128] ^
                                expected_batch_mem[batch_idx][lane_idx*128 +: 128]) &
                               compare_batch_mem[batch_idx][lane_idx*128 +: 128]) == 128'b0,
                              "independent Python golden result mismatch");
                end else begin
                  check_named("INACTIVE_LANES_ZERO",
                              o_batch_data[lane_idx*128 +: 128] == 128'b0,
                              "unused lanes must be zero");
                end
              end
            end
            @(posedge i_clk_core);
            #0.1;
          end else begin
            block_idx = 0;
            while (block_idx < block_count) begin
              chunk_count = block_count - block_idx;
              if (chunk_count > effective_lanes)
                chunk_count = effective_lanes;
              batch_data = '0;
              expected_batch = '0;
              compare_batch = '0;
              batch_mask = '0;
              expected_lane_mask = '0;
              for (lane_idx = 0; lane_idx < chunk_count; lane_idx = lane_idx + 1) begin
                batch_data[lane_idx*128 +: 128] = data_mem[block_idx + lane_idx];
                expected_batch[lane_idx*128 +: 128] = expected_mem[block_idx + lane_idx];
                compare_batch[lane_idx*128 +: 128] = mask_mem[block_idx + lane_idx];
                batch_mask[lane_idx] = 1'b1;
                expected_lane_mask[lane_idx] = 1'b1;
              end
              expected_last = (block_idx + chunk_count == block_count);
              drive_batch(batch_data, batch_mask, expected_last, input_cycle);
              if (block_idx == 0)
                first_input_cycle = input_cycle;
              else if ((effective_lanes == 1) &&
                       ((mode_value == 1 && decipher_value == 0) ||
                        (mode_value == 2) || (mode_value == 3))) begin
                check_named((key_size == 1) ? "FEEDBACK_INTERVAL_AES256_C15"
                                            : "FEEDBACK_INTERVAL_AES128_C11",
                            input_cycle == previous_output_cycle + 1,
                            "dependent feedback block must be accepted one cycle after prior result");
              end
              if (stall_output)
                i_batch_ready = 1'b0;
              wait_output(exp_latency + 80, output_cycle);
              if (block_idx == 0) begin
                measured_latency = output_cycle - first_input_cycle;
                check_named((key_size == 1) ? "LATENCY_AES256_C14" : "LATENCY_AES128_C10",
                            measured_latency == exp_latency,
                            "first result did not appear at the specified C10/C14 boundary");
              end
              check_named("OUTPUT_LANE_MASK",
                          o_batch_lane_valid == expected_lane_mask,
                          "output lane-valid mask mismatch");
              check_named("OUTPUT_LAST_PRESERVED", o_batch_last == expected_last,
                          "output last marker does not match input stream end");
              for (lane_idx = 0; lane_idx < LPARA_AES_LANE_NUM; lane_idx = lane_idx + 1) begin
                if (lane_idx < chunk_count) begin
                  check_named("GOLDEN_AES_MODE_DATA",
                              ((o_batch_data[lane_idx*128 +: 128] ^
                                expected_batch[lane_idx*128 +: 128]) &
                               compare_batch[lane_idx*128 +: 128]) == 128'b0,
                              "RTL result differs from the independent AES/mode model");
                end else begin
                  check_named("INACTIVE_LANES_ZERO",
                              o_batch_data[lane_idx*128 +: 128] == 128'b0,
                              "unused output lanes must be zero");
                end
              end
              if (stall_output) begin
                held_data = o_batch_data;
                held_mask = o_batch_lane_valid;
                held_last = o_batch_last;
                repeat (1) begin
                  @(negedge i_clk_core);
                  check_named("OUTPUT_STABLE_UNDER_BACKPRESSURE",
                              o_batch_valid && (o_batch_data == held_data) &&
                              (o_batch_lane_valid == held_mask) && (o_batch_last == held_last),
                              "output record changed while ready was low");
                end
                i_batch_ready = 1'b1;
                @(posedge i_clk_core);
                #0.1;
              end
              previous_output_cycle = output_cycle;
              block_idx = block_idx + chunk_count;
            end
          end
          $display("VECTOR PASS %0s key_size=%0d mode=%0d decipher=%0d blocks=%0d",
                   path, key_size, mode_value, decipher_value, block_count);
        end
      end
    end
  endtask

  task automatic run_error_protocol_checks;
    integer cfg_cycle;
    integer input_cycle;
    integer output_cycle;
    logic [255:0] key_value;
    logic [LPARA_AES_BATCH_W-1:0] one_data;
    logic [LPARA_AES_LANE_NUM-1:0] one_mask;
    integer wait_idx;
    begin
      key_value = {128'h1, 128'h000102030405060708090a0b0c0d0e0f};
      configure_message(1'b0, key_value, 3'd0, 1'b0, '0, 4'd7, cfg_cycle);
      wait_error(4'd1, "AES128_HIGH_KEY_REJECTED");
      consume_error();

      // An invalid lane mask is consumed and reported without producing data.
      key_value = {128'b0, 128'h000102030405060708090a0b0c0d0e0f};
      configure_message(1'b0, key_value, 3'd0, 1'b0, '0, 4'd7, cfg_cycle);
      one_data = '0;
      one_mask = '0;
      one_data[127:0] = 128'h00112233445566778899aabbccddeeff;
      one_mask = (LPARA_AES_LANE_NUM > 2) ? LPARA_AES_LANE_NUM'(5) : '0;
      drive_batch(one_data, one_mask, 1'b0, input_cycle);
      wait_error(4'd2, "NONPREFIX_MASK_ERROR_CODE_2");
      check_named("INVALID_MASK_NO_RESULT", !o_batch_valid,
                  "rejected lane mask must not generate an output batch");
      consume_error();
      reset_dut();

      // Invalid data while idle is accepted and reports protocol error 5.
      @(negedge i_clk_core);
      i_batch_data = '0;
      i_batch_lane_valid = {{(LPARA_AES_LANE_NUM-1){1'b0}}, 1'b1};
      i_batch_last = 1'b0;
      i_batch_valid = 1'b1;
      #0.1;
      check_named("IDLE_STRAY_ACCEPTED", o_batch_ready,
                  "idle data is consumed so the IP can report protocol error 5");
      @(posedge i_clk_core);
      #0.1;
      @(negedge i_clk_core);
      i_batch_valid = 1'b0;
      i_batch_lane_valid = '0;
      wait_error(4'd5, "IDLE_PROTOCOL_ERROR_CODE_5");
      consume_error();
      reset_dut();

      // CTR rejects an entire batch if a selected lane would wrap the low field.
      key_value = {128'b0, 128'h000102030405060708090a0b0c0d0e0f};
      configure_message(1'b0, key_value, 3'd4, 1'b0,
                        128'h00112233445566778899aabbffffffff, 4'd7, cfg_cycle);
      one_data = '0;
      one_mask = '0;
      one_mask = LPARA_AES_LANE_NUM'(1);
      if (LPARA_AES_LANE_NUM > 1) begin
        one_mask = LPARA_AES_LANE_NUM'(3);
        drive_batch(one_data, one_mask, 1'b1, input_cycle);
        wait_error(4'd3, "CTR_BATCH_WRAP_ERROR_CODE_3");
      end else begin
        drive_batch(one_data, one_mask, 1'b0, input_cycle);
        wait_output(40, output_cycle);
        drive_batch(one_data, one_mask, 1'b1, input_cycle);
        wait_error(4'd3, "CTR_EXHAUSTION_ERROR_CODE_3");
      end
      check_named("CTR_WRAP_ATOMIC_REJECT", !o_batch_valid,
                  "a wrapping CTR batch must not return a partial result");
      consume_error();
      reset_dut();

      // Data after a consumed final batch is likewise accepted as error 5.
      configure_message(1'b0, key_value, 3'd0, 1'b0, '0, 4'd7, cfg_cycle);
      one_data = '0;
      one_mask = '0;
      one_mask[0] = 1'b1;
      drive_batch(one_data, one_mask, 1'b1, input_cycle);
      wait_output(40, output_cycle);
      @(posedge i_clk_core);
      #0.1;
      @(negedge i_clk_core);
      i_batch_valid = 1'b1;
      i_batch_lane_valid = one_mask;
      i_batch_last = 1'b0;
      #0.1;
      check_named("AFTER_LAST_STRAY_ACCEPTED", o_batch_ready,
                  "post-final data is accepted for explicit protocol reporting");
      @(posedge i_clk_core);
      #0.1;
      @(negedge i_clk_core);
      i_batch_valid = 1'b0;
      i_batch_lane_valid = '0;
      wait_error(4'd5, "AFTER_LAST_PROTOCOL_ERROR_CODE_5");
      consume_error();

      // Abort in-flight work: zeroize drops valid state and pulses done once.
      configure_message(1'b1,
                        256'h000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f,
                        3'd0, 1'b0, '0, 4'd7, cfg_cycle);
      one_data = '0;
      one_mask = '0;
      one_mask[0] = 1'b1;
      drive_batch(one_data, one_mask, 1'b1, input_cycle);
      repeat (2) @(negedge i_clk_core);
      i_zeroize_req = 1'b1;
      @(posedge i_clk_core);
      #0.1;
      check_named("ZEROIZE_DONE_ONE_CYCLE", o_zeroize_done,
                  "done must assert after the request sampling edge");
      check_named("ZEROIZE_CLEARS_PENDING_RESULT", !o_batch_valid && !o_err_valid,
                  "zeroize must clear output/error valid records");
      @(negedge i_clk_core);
      i_zeroize_req = 1'b0;
      @(posedge i_clk_core);
      #0.1;
      check_named("ZEROIZE_DONE_PULSE", !o_zeroize_done,
                  "zeroize done must be a one-cycle pulse");
      repeat (18) @(negedge i_clk_core);
      check_named("ZEROIZE_NO_STALE_RESULT", !o_batch_valid,
                  "aborted pipeline work must not reappear after zeroize");

      // Reset asynchronously clears a result held under backpressure.
      configure_message(1'b0, key_value, 3'd0, 1'b0, '0, 4'd7, cfg_cycle);
      i_batch_ready = 1'b0;
      one_data = '0;
      one_mask = '0;
      one_mask[0] = 1'b1;
      drive_batch(one_data, one_mask, 1'b1, input_cycle);
      wait_output(40, output_cycle);
      @(negedge i_clk_core);
      i_rst_n_core = 1'b0;
      #0.1;
      check_named("RESET_ABORTS_STALLED_OUTPUT", !o_batch_valid && !o_err_valid,
                  "asynchronous reset assertion must clear pending valid state");
      i_batch_ready = 1'b1;
      repeat (2) @(negedge i_clk_core);
      i_rst_n_core = 1'b1;
      repeat (2) @(negedge i_clk_core);
    end
  endtask

  task automatic run_manifest;
    integer manifest_fd;
    integer scan_count;
    integer case_count;
    string vector_dir;
    string filename;
    string path;
    begin
      vector_dir = "vectors/";
      if ($value$plusargs("VEC_DIR=%s", vector_dir)) begin end
      manifest_fd = $fopen({vector_dir, "manifest.txt"}, "r");
      if (manifest_fd == 0) begin
        $display("ERROR: cannot open vector manifest in %0s", vector_dir);
        assertion_failures = assertion_failures + 1;
      end else begin
        case_count = 0;
        while (!$feof(manifest_fd)) begin
          filename = "";
          scan_count = $fscanf(manifest_fd, "%s\n", filename);
          if (scan_count == 1) begin
            path = {vector_dir, filename, ".vec"};
            if ((filename == "throughput_k128") || (filename == "throughput_k256"))
              read_vector_file(path, 1'b1, 1'b0);
            else
              read_vector_file(path, 1'b0, 1'b0);
            case_count = case_count + 1;
          end
        end
        $fclose(manifest_fd);
        check_named("REFERENCE_VECTOR_MANIFEST", case_count >= 50,
                    "regression manifest must include broad mode/key-size coverage");
      end
    end
  endtask

  task automatic run_backpressure(input string path);
    begin
      read_vector_file(path, 1'b0, 1'b1);
    end
  endtask

  task automatic run_wave_case(input string wave_name, input string vector_dir);
    string path;
    integer cfg_cycle;
    integer in_cycle;
    integer out_cycle;
    logic [255:0] key_value;
    logic [LPARA_AES_BATCH_W-1:0] data_value;
    logic [LPARA_AES_LANE_NUM-1:0] mask_value;
    begin
      if ((wave_name == "WF-001_config_key_select")) begin
        key_value = {128'b0, 128'h000102030405060708090a0b0c0d0e0f};
        configure_message(1'b0, key_value, 3'd0, 1'b0, '0, 4'd7, cfg_cycle);
        data_value = '0; mask_value = '0; mask_value[0] = 1'b1;
        drive_batch(data_value, mask_value, 1'b1, in_cycle);
        wait_output(40, out_cycle);
        @(posedge i_clk_core); #0.1;
        key_value = 256'h000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f;
        configure_message(1'b1, key_value, 3'd0, 1'b0, '0, 4'd7, cfg_cycle);
        data_value = '0; mask_value = '0; mask_value[0] = 1'b1;
        drive_batch(data_value, mask_value, 1'b1, in_cycle);
        wait_output(50, out_cycle);
        @(posedge i_clk_core); #0.1;
        key_value = {128'h1, 128'h000102030405060708090a0b0c0d0e0f};
        configure_message(1'b0, key_value, 3'd0, 1'b0, '0, 4'd7, cfg_cycle);
        wait_error(4'd1, "WF_AES128_UPPER_KEY_REJECT");
      end else if (wave_name == "WF-004_ctr_allocate") begin
        path = {vector_dir, "wf004_ctr_partial.vec"};
        read_vector_file(path, 1'b0, 1'b0);
      end else if (wave_name == "WF-005_ctr_wrap") begin
        key_value = {128'b0, 128'h000102030405060708090a0b0c0d0e0f};
        configure_message(1'b0, key_value, 3'd4, 1'b0,
                          128'h00112233445566778899aabbffffffff, 4'd7, cfg_cycle);
        data_value = '0;
        if (LPARA_AES_LANE_NUM > 1) begin
          mask_value = LPARA_AES_LANE_NUM'(3);
          drive_batch(data_value, mask_value, 1'b1, in_cycle);
          wait_error(4'd3, "WF_CTR_WRAP_ERROR");
        end else begin
          mask_value = LPARA_AES_LANE_NUM'(1);
          drive_batch(data_value, mask_value, 1'b0, in_cycle);
          wait_output(40, out_cycle);
          drive_batch(data_value, mask_value, 1'b1, in_cycle);
          wait_error(4'd3, "WF_CTR_EXHAUSTED_ERROR");
        end
      end else if ((wave_name == "WF-006a_cbc_decrypt") ||
                   (wave_name == "WF-006b_cbc_decrypt")) begin
        path = {vector_dir, "wf_mode_k128_cbc_dec.vec"};
        if (wave_name == "WF-006b_cbc_decrypt")
          path = {vector_dir, "wf_mode_k256_cbc_dec.vec"};
        read_vector_file(path, 1'b0, 1'b0);
      end else if (wave_name == "WF-007_cbc_encrypt_feedback") begin
        path = {vector_dir, "wf_mode_k128_cbc_enc.vec"};
        read_vector_file(path, 1'b0, 1'b0);
      end else if (wave_name == "WF-008_cfb_feedback") begin
        path = {vector_dir, "wf_mode_k256_cfb_enc.vec"};
        read_vector_file(path, 1'b0, 1'b0);
      end else if (wave_name == "WF-009_ofb_feedback") begin
        path = {vector_dir, "wf_mode_k256_ofb_enc.vec"};
        read_vector_file(path, 1'b0, 1'b0);
      end else if ((wave_name == "WF-010a_backpressure") ||
                   (wave_name == "WF-010b_backpressure")) begin
        path = {vector_dir, "fips_k128_enc.vec"};
        if (wave_name == "WF-010b_backpressure")
          path = {vector_dir, "fips_k256_enc.vec"};
        run_backpressure(path);
      end else if (wave_name == "WF-011_lane_mask_error") begin
        key_value = {128'b0, 128'h000102030405060708090a0b0c0d0e0f};
        configure_message(1'b0, key_value, 3'd0, 1'b0, '0, 4'd7, cfg_cycle);
        data_value = '0;
        mask_value = (LPARA_AES_LANE_NUM > 2) ? LPARA_AES_LANE_NUM'(5) : '0;
        drive_batch(data_value, mask_value, 1'b0, in_cycle);
        wait_error(4'd2, "WF_INVALID_LANE_MASK");
        consume_error();
        reset_dut();
        @(negedge i_clk_core);
        i_batch_valid = 1'b1;
        i_batch_lane_valid = {{(LPARA_AES_LANE_NUM-1){1'b0}},1'b1};
        #0.1;
        check_named("WF_IDLE_PROTOCOL_READY", o_batch_ready,
                    "idle stray data is accepted for protocol error reporting");
        @(posedge i_clk_core); #0.1;
        @(negedge i_clk_core); i_batch_valid = 1'b0; i_batch_lane_valid = '0;
        wait_error(4'd5, "WF_IDLE_PROTOCOL_ERROR");
      end else if ((wave_name == "WF-012a_reset_abort") ||
                   (wave_name == "WF-012b_zeroize_abort")) begin
        key_value = {128'b0, 128'h000102030405060708090a0b0c0d0e0f};
        configure_message(1'b0, key_value, 3'd0, 1'b0, '0, 4'd7, cfg_cycle);
        data_value = '0; mask_value = '0; mask_value[0] = 1'b1;
        if (wave_name == "WF-012a_reset_abort") begin
          i_batch_ready = 1'b0;
          drive_batch(data_value, mask_value, 1'b1, in_cycle);
          repeat (3) @(negedge i_clk_core);
          i_rst_n_core = 1'b0;
          #0.1;
          check_named("WF_RESET_ABORT_CLEAR", !o_batch_valid,
                      "reset must abort in-flight work and clear valid state");
          repeat (2) @(negedge i_clk_core);
          i_rst_n_core = 1'b1; i_batch_ready = 1'b1;
        end else begin
          drive_batch(data_value, mask_value, 1'b1, in_cycle);
          repeat (2) @(negedge i_clk_core);
          i_zeroize_req = 1'b1;
          @(posedge i_clk_core); #0.1;
          check_named("WF_ZEROIZE_DONE", o_zeroize_done && !o_batch_valid,
                      "zeroize completes and clears in-flight result");
          @(negedge i_clk_core); i_zeroize_req = 1'b0;
        end
      end else if (wave_name == "WF-002_aes128_ecb") begin
        path = {vector_dir, "throughput_k128.vec"};
        read_vector_file(path, 1'b1, 1'b0);
      end else if (wave_name == "WF-003_aes256_ecb") begin
        path = {vector_dir, "throughput_k256.vec"};
        read_vector_file(path, 1'b1, 1'b0);
      end else begin
        $display("ERROR: unknown waveform scenario %0s", wave_name);
        assertion_failures = assertion_failures + 1;
      end
    end
  endtask

  integer argc;
  integer case_index;
  integer dump_enabled;
  string manifest_mode;
  string vector_dir;
  string selected_wave;
  string dump_path;
  initial begin
    argc = 0;
    selected_wave = "";
    vector_dir = "vectors/";
    dump_path = "";
    if ($value$plusargs("WAVE=%s", selected_wave)) begin end
    if ($value$plusargs("VEC_DIR=%s", vector_dir)) begin end
    if ($value$plusargs("DUMP=%s", dump_path)) begin
      wave_dump_enabled = 1'b1;
      $dumpfile(dump_path);
      $dumpvars(0, tb_aes128_256_batch);
    end
    reset_dut();
    if (selected_wave != "") begin
      run_wave_case(selected_wave, vector_dir);
      repeat (3) @(negedge i_clk_core);
    end else begin
      run_manifest();
      run_error_protocol_checks();
      check_named("MINIMUM_NAMED_ASSERTIONS", assertion_count >= 20,
                  "the testbench must exercise at least 20 named checks");
    end
    $display("SUMMARY lanes=%0d assertions=%0d failures=%0d scenario=%0s",
             LPARA_AES_LANE_NUM, assertion_count, assertion_failures,
             selected_wave == "" ? "regression" : selected_wave);
    if (assertion_failures != 0)
      $fatal(1, "AES-128/AES-256 simulation failed");
    $finish;
  end
endmodule
