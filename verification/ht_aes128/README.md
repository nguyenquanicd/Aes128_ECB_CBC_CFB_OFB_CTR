# High-Throughput AES-128 Verification

## English

This directory verifies `rtl/ht_aes128/`. The SystemVerilog testbench checks all five modes, both directions, CFB segment sizes, lane masks, CTR overflow, ordering, latency, throughput, backpressure, reset, zeroize and error handling. Golden vectors use the independent model at `../shared/aes_ref.py`.

From the repository root, run `make vlsit-verification`. The testbench and generated vectors are in this directory; `logs/` and `waveforms_sim/` retain run evidence. Lint and RTL-rule reports are in `reports/`.

## Tiếng Việt

Thư mục này kiểm tra `rtl/ht_aes128/`. Testbench SystemVerilog kiểm tra năm mode, hai chiều mã hóa/giải mã, các CFB segment, lane mask, CTR overflow, thứ tự dữ liệu, latency, throughput, backpressure, reset, zeroize và báo lỗi. Golden vector dùng model độc lập ở `../shared/aes_ref.py`.

Chạy `make vlsit-verification` từ repository root. Testbench và vector được lưu tại đây; `logs/` và `waveforms_sim/` lưu bằng chứng chạy. Báo cáo lint và RTL rule ở `reports/`.
