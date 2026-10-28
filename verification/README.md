# AES batch verification / Kiểm chứng AES batch

## English

This directory contains the independent testbench for `rtl_vlsit_generated/`. Golden vectors are generated from `tools/aes_ref.py`, which self-checks against FIPS 197 and NIST SP 800-38A. The testbench checks all five modes, encryption/decryption, CFB segment sizes, lane masks, CTR overflow, backpressure, reset, zeroize, error reporting, ordering, latency, and throughput.

Run from the repository root:

```sh
make vlsit-sim          # regress with PARA_AES_LANE_NUM=1 and 4
make vlsit-waveforms    # run the 11 approved waveform scenarios; write VCD, WaveJSON and SVG
make vlsit-evidence     # also check waveform evidence against the design specification
```

The directed/random regression passed with 55 streams for both lane settings: `LANES=1` processed 431 input batches and `LANES=4` processed 315. All 20 protocol and data assertions were exercised with zero failures. Eleven waveform scenarios also passed. The local Windows Icarus 14.0 compiler may return a native process error after writing its VVP file; the Makefile removes stale binaries, records the compiler status, and verifies the new file by running the simulation.

`tb_aes128_batch.sv` is outside the RTL file list. `vectors/` holds reviewable input and expected-data records. `logs/` holds compile and run logs. `waveforms_sim/` holds generated traces and rendered diagrams. Expected data does not come from the DUT or generated RTL.

The RTL simulation is synchronous to one clock. The specification assigns asynchronous source handling to a SoC wrapper, so there is no IP-level CDC model. The evidence check uses `--cdc no` for that reason. Code coverage, formal proof, synthesis, STA, and PPA were not run.

## Tiếng Việt

Thư mục này chứa testbench độc lập cho `rtl_vlsit_generated/`. Vector chuẩn được tạo từ `tools/aes_ref.py`; model tự kiểm tra theo FIPS 197 và NIST SP 800-38A. Testbench kiểm tra năm mode, mã hóa/giải mã, các kích thước segment CFB, lane mask, CTR overflow, backpressure, reset, zeroize, báo lỗi, thứ tự dữ liệu, latency và throughput.

Chạy tại thư mục gốc dự án:

```sh
make vlsit-sim          # regression với PARA_AES_LANE_NUM=1 và 4
make vlsit-waveforms    # chạy 11 waveform đã duyệt; tạo VCD, WaveJSON và SVG
make vlsit-evidence     # kiểm tra waveform evidence theo design specification
```

Regression directed/random đã pass với 55 stream cho cả hai cấu hình lane: `LANES=1` xử lý 431 batch đầu vào, `LANES=4` xử lý 315 batch. Cả 20 assertion protocol và dữ liệu đều được chạy, không có lỗi. Mười một waveform cũng pass. Icarus 14.0 trên Windows tại máy hiện tại có thể trả lỗi native sau khi đã ghi file VVP; Makefile xóa binary cũ, ghi lại trạng thái compiler và xác minh binary mới bằng mô phỏng.

File `tb_aes128_batch.sv` nằm ngoài RTL file list. Thư mục `vectors/` lưu dữ liệu vào và giá trị kỳ vọng để kiểm tra; `logs/` lưu log biên dịch và mô phỏng; `waveforms_sim/` lưu trace và hình waveform. Giá trị kỳ vọng không lấy từ DUT hoặc RTL được tạo.

Mô phỏng IP dùng một clock đồng bộ. Specification giao việc xử lý nguồn bất đồng bộ cho SoC wrapper nên không có mô hình CDC ở cấp IP. Vì vậy lệnh kiểm tra evidence dùng `--cdc no`. Chưa chạy code coverage, formal proof, synthesis, STA hoặc PPA.
