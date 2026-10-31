# High-Throughput AES-128/AES-256 Verification

## English

This flow verifies `rtl/ht_aes128_256/` independently against an AES reference model. It covers AES-128 and AES-256, all five modes, CFB segment sizes, configuration errors, CTR wrap, batch masks, C10/C14 latency, throughput, feedback spacing, backpressure, reset and zeroize.

From the repository root:

```sh
make aes128-256-regression
make aes128-256-synth
make aes128-256-verification
```

The root `Makefile` is the only command entry point. It also provides `aes128-256-sim-n1`, `aes128-256-sim-n4`, `aes128-256-evidence`, `aes128-256-synth-n1` and `aes128-256-synth-n4`. Vectors, logs, waveforms and generic Yosys statistics are retained in this folder. The statistics are generic cells, not ASIC area/timing/power.

Latest isolated run: [simulation and synthesis report](runs/20261031_073220/run_report.md). Its logs, waveform evidence, rule-check report and Yosys statistics are under that run folder.

## Tiếng Việt

Flow này kiểm tra độc lập `rtl/ht_aes128_256/` bằng mô hình AES tham chiếu. Phạm vi gồm AES-128/AES-256, năm mode, CFB segment, lỗi cấu hình, CTR wrap, batch mask, latency C10/C14, throughput, khoảng cách feedback, backpressure, reset và zeroize.

Chạy từ repository root:

```sh
make aes128-256-regression
make aes128-256-synth
make aes128-256-verification
```

Root `Makefile` là điểm chạy lệnh duy nhất. File này cũng có các target `aes128-256-sim-n1`, `aes128-256-sim-n4`, `aes128-256-evidence`, `aes128-256-synth-n1` và `aes128-256-synth-n4`. Vector, log, waveform và thống kê Yosys generic được lưu tại đây. Các cell trong thống kê là cell generic, không phải diện tích/timing/công suất ASIC.

Lượt chạy riêng mới nhất: [báo cáo mô phỏng và synthesis](runs/20261031_073220/run_report.md). Log, waveform evidence, rule-check report và thống kê Yosys nằm trong thư mục run đó.
