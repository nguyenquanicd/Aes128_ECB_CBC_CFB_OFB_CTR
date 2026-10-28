# Simulation waveform evidence / Bằng chứng waveform mô phỏng

The planned scenarios below were generated from the VLSIT-approved specification figures. Each row has a VCD trace, a WaveJSON file, and a rendered SVG. The VCDs contain concrete reference vectors; invalid-cycle bus values may differ from the symbolic values in the specification figures. Reset setup is performed by the testbench before most waveform captures.

| Waveform ID | Specification figure | Simulated waveform | Result | Note |
|---|---|---|---|---|
| WF-001 | `doc/waveforms/WF-001_config_success.svg` | `WF-001_config_success.vcd` / `.json` / `.svg` | MATCH | Valid configuration is accepted; no error is raised. `WF-001_config_error` is also simulated separately. |
| WF-002 | `doc/waveforms/WF-002_ecb_batches.svg` | `WF-002_ecb_batches.vcd` / `.json` / `.svg` | MATCH | Full and partial batches preserve lane order; measured latency is 10 cycles and independent II is 1. |
| WF-003 | `doc/waveforms/WF-003_ctr_allocation.svg` | `WF-003_ctr_allocation.vcd` / `.json` / `.svg` | MATCH | Consecutive CTR values are assigned to active lanes; inactive lanes are not counted. |
| WF-004 | `doc/waveforms/WF-004_ctr_wrap_rejection.svg` | `WF-004_ctr_wrap_rejection.vcd` / `.json` / `.svg` | MATCH | A batch that crosses the configured low-field limit is rejected atomically with error code 3. |
| WF-005 | `doc/waveforms/WF-005_cbc_decryption.svg` | `WF-005_cbc_decryption.vcd` / `.json` / `.svg` | MATCH | CBC decryption restores the NIST SP 800-38A plaintext blocks in order. |
| WF-006 | `doc/waveforms/WF-006_cbc_encrypt.svg` | `WF-006_cbc_encrypt.vcd` / `.json` / `.svg` | MATCH | CBC encrypt, CFB, and OFB feedback modes accept dependent blocks at the 11-cycle interval. Separate CFB/OFB traces are included. |
| WF-007 | `doc/waveforms/WF-007_backpressure.svg` | `WF-007_backpressure.vcd` / `.json` / `.svg` | MATCH | Output valid, data, lane mask, and last marker remain stable during the one-cycle stall. |
| WF-008 | `doc/waveforms/WF-008_reset_zeroize.svg` | `WF-008_reset_zeroize.vcd` / `.json` / `.svg` | MATCH | Zeroize clears pending output and error records and pulses done for one cycle. |

All 11 generated WaveJSON files pass the bundled WaveDrom lint; all 11 SVG files render successfully. The extra traces are `WF-001_config_error`, `WF-006_cfb`, and `WF-006_ofb`.

## Tiếng Việt

Các tình huống trong bảng được tạo theo waveform figure đã duyệt trong specification. Mỗi dòng có VCD, WaveJSON và SVG. VCD dùng vector dữ liệu cụ thể; giá trị bus ở chu kỳ invalid có thể khác giá trị ký hiệu trong hình đặc tả. Testbench thực hiện reset trước hầu hết lần capture waveform.

Cả 11 file WaveJSON đều qua WaveDrom lint đi kèm; cả 11 SVG render thành công. Các trace bổ sung gồm `WF-001_config_error`, `WF-006_cfb` và `WF-006_ofb`.
