# AES RTL Project

## English

This repository contains three AES RTL implementations. Each implementation has its own RTL, specification or design notes, and verification assets. The high-throughput designs use independent golden models and keep testbench code outside the RTL filelists.

| Design | RTL | Description | Specification / notes | Verification |
|---|---|---|---|---|
| Single-block AES-128 | `rtl/single_aes128/` | Iterative AES-128 core with ECB, CBC, CFB, OFB and CTR | [Design notes](doc/single_aes128/README.md) | [Single AES-128 verification](verification/single_aes128/README.md) |
| High-throughput AES-128 | `rtl/ht_aes128/` | Pipelined, parameterized batch core for AES-128 | [AES-128 specification](doc/ht_aes128/AES128_ECB_CBC_CFB_OFB_CTR_Design_Specification.md) | [HT AES-128 verification](verification/ht_aes128/README.md) |
| High-throughput AES-128/AES-256 | `rtl/ht_aes128_256/` | Pipelined batch core with run-time AES-128/AES-256 selection | [AES-128/AES-256 specification](doc/ht_aes128_256/AES128_AES256_ECB_CBC_CFB_OFB_CTR_Design_Specification.md) | [Dual-key verification](verification/ht_aes128_256/README.md) |

## Repository layout

```text
doc/
  single_aes128/       Single-block AES-128 design notes and legacy documents
  ht_aes128/           AES-128 batch specification, figures, waveforms, research
  ht_aes128_256/       Dual-key specification, figures, waveforms, research
  shared/references/   Local NIST FIPS 197 and SP 800-38A copies
rtl/
  single_aes128/       Iterative AES-128 RTL
  ht_aes128/           High-throughput AES-128 RTL
  ht_aes128_256/       High-throughput AES-128/AES-256 RTL
verification/
  single_aes128/       Legacy core tests, formal harnesses and simulation scripts
  ht_aes128/           Batch testbench, vectors, logs and waveform evidence
  ht_aes128_256/       Dual-key testbench, vectors, logs, waveforms and synthesis
  shared/              Independent AES reference model used by the flows
  legacy_uart_apb/     Preserved UART/APB files unrelated to the AES designs
Makefile              Main entry point for the AES-128 flows
```

## Commands

Run commands from the repository root. GNU Make and the listed tools must be available.

```sh
make quick                    # Single-block AES-128 simulation suite
make regress                  # Single-block AES-128 full regression
make formal                   # Single-block AES-128 formal checks
make vlsit-verification       # High-throughput AES-128 simulation and waveform checks
make aes128-256-regression    # Dual-key simulation, 1 and 4 lanes
make aes128-256-synth         # Dual-key generic synthesis, 1 and 4 lanes
make aes128-256-verification  # Dual-key regression, waveforms and synthesis
```

The root `Makefile` is the single command entry point for all three designs. Generic synthesis statistics are not ASIC area, timing or power results; a target library, corner and timing constraints are required for those measurements.

## Tiếng Việt

Repository này có ba cách cài đặt AES RTL. Mỗi design có RTL, đặc tả hoặc tài liệu mô tả và tài nguyên verification riêng. Các design throughput cao dùng mô hình tham chiếu độc lập; testbench không nằm trong filelist RTL.

| Design | RTL | Mô tả | Đặc tả / tài liệu | Verification |
|---|---|---|---|---|
| AES-128 một block | `rtl/single_aes128/` | Core AES-128 tuần tự, hỗ trợ ECB, CBC, CFB, OFB và CTR | [Tài liệu design](doc/single_aes128/README.md) | [Verification AES-128 đơn](verification/single_aes128/README.md) |
| AES-128 throughput cao | `rtl/ht_aes128/` | Batch core AES-128 có pipeline và số lane cấu hình được | [Đặc tả AES-128](doc/ht_aes128/AES128_ECB_CBC_CFB_OFB_CTR_Design_Specification.md) | [Verification HT AES-128](verification/ht_aes128/README.md) |
| AES-128/AES-256 throughput cao | `rtl/ht_aes128_256/` | Batch core pipeline, chọn AES-128 hoặc AES-256 khi chạy | [Đặc tả AES-128/AES-256](doc/ht_aes128_256/AES128_AES256_ECB_CBC_CFB_OFB_CTR_Design_Specification.md) | [Verification hai kích thước khóa](verification/ht_aes128_256/README.md) |

## Cấu trúc repository

```text
doc/
  single_aes128/       Tài liệu AES-128 một block và tài liệu cũ
  ht_aes128/           Đặc tả, hình, waveform và nghiên cứu cho batch AES-128
  ht_aes128_256/       Đặc tả, hình, waveform và nghiên cứu cho batch AES-128/AES-256
  shared/references/   Bản NIST FIPS 197 và SP 800-38A lưu trong dự án
rtl/
  single_aes128/       RTL AES-128 tuần tự
  ht_aes128/           RTL AES-128 throughput cao
  ht_aes128_256/       RTL AES-128/AES-256 throughput cao
verification/
  single_aes128/       Test, formal harness và script mô phỏng core cũ
  ht_aes128/           Testbench batch, vector, log và waveform
  ht_aes128_256/       Testbench hai key size, vector, log, waveform và synthesis
  shared/              Mô hình AES tham chiếu độc lập dùng chung
  legacy_uart_apb/     Tệp UART/APB cũ, không thuộc các AES design
Makefile              Điểm chạy chính cho các flow AES-128
```

## Lệnh chạy

Chạy lệnh từ thư mục gốc repository. Cần GNU Make và các tool tương ứng.

```sh
make quick                    # Bộ simulation AES-128 tuần tự
make regress                  # Regression đầy đủ AES-128 tuần tự
make formal                   # Formal check AES-128 tuần tự
make vlsit-verification       # Simulation và waveform check AES-128 throughput cao
make aes128-256-regression    # Simulation dual-key, 1 và 4 lane
make aes128-256-synth         # Yosys generic synthesis, 1 và 4 lane
make aes128-256-verification  # Regression, waveform và synthesis dual-key
```

Root `Makefile` là điểm chạy lệnh duy nhất cho cả ba design. Số liệu synthesis generic không phải diện tích, timing hay công suất ASIC; cần thư viện cell, corner và ràng buộc timing cho các phép đo đó.
