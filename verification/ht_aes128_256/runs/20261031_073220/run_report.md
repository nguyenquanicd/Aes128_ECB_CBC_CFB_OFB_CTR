# AES-128/AES-256 Simulation and Synthesis Report

## English

Run date: 2026-10-31. Top: `m_aes128_256_batch_top`. The RTL was not changed.

### Simulation

The independent reference model passed its FIPS 197 AES-128/AES-256 known-answer tests and its ECB, CBC, CFB, OFB, and CTR round-trip checks.

| Configuration | Regression result | Assertion failures |
|---|---:|---:|
| 1 lane | PASS; 2,301 assertions | 0 |
| 4 lanes | PASS; 3,056 assertions | 0 |

The 12 approved waveform scenarios produced 15 VCD, WaveJSON, and SVG traces. The waveform index reports `MATCH` for all 12 plan entries. The official evidence check against `verification/ht_aes128_256/waveform_plan.md` passed with 0 errors and 0 warnings.

The checker expects a five-column waveform table. The project flow uses `waveform_plan.md`, which has that format. Calling the same checker directly on the four-column waveform table inside the full specification reports `no figure` even though the figure links are present. No specification or installed skill source was changed.

The testbench reports an aggregate assertion count and fails on failed checks; it also requires at least 20 named checks. It does not track hit counts for every named check, so this run does not claim per-check assertion coverage.

### Generic synthesis

Yosys 0.69+274 completed `hierarchy -check` and `synth` for both configurations. `PARA_CTR_WIDTH=32`; the lane count is 1 or 4.

| Metric | 1 lane | 4 lanes |
|---|---:|---:|
| Generic mapped cells | 348,403 | 1,192,540 |
| Sequential cells | 5,823 | 17,088 |
| Hierarchical wire bits | 527,406 | 1,850,476 |
| Memories after synthesis | 0 | 0 |

Yosys reported that eight RTL arrays were converted to registers. These are generic Yosys statistics, not standard-cell area or ASIC PPA. No Liberty library, process corner, SDC constraints, STA, placement, or power analysis was used.

### Rule check and lint

- VLSIT RTL rule check: 6 files, 0 errors, 3 `HIE-02` warnings. The warnings identify internal core/lane/pipe modules that contain both logic and child instances; the structural top itself contains only the core instance.
- Verilator lint: 0 errors, 3 `UNUSEDSIGNAL` warnings for the upper bits of the lane-ready, lane-valid, and lane-last vectors. The lane array uses lane 0 for the shared lockstep handshake and carries per-lane data/mask separately.
- The Verilator C++ build emitted two `STDOUT_FILENO`/`STDERR_FILENO` redefinition warnings from the tool headers; both simulation executables built and ran successfully.

### Environment and rerun

The root Makefile target `make aes128-256-verification` could not start in this Windows sandbox: MSYS2 `make` exits immediately with `NtCreateDirectoryObject(...): 0xC0000022`. The same Verilator, simulation, waveform, evidence, and Yosys steps were run directly, with outputs isolated in this run folder. Verilator's generated C++ was compiled using the existing builder fallback and the installed UCRT64 `g++`.

In a supported GNU Make shell, run from the repository root:

```sh
make aes128-256-verification
```

The individual root Makefile targets are `aes128-256-regression`, `aes128-256-evidence`, and `aes128-256-synth`.

The reorganized repository has one root Makefile, three RTL filelists with existing source paths, and 18 bilingual README files. A static scan found no broken local Markdown links (134 checked).

## Tiếng Việt

Ngày chạy: 2026-10-31. Top: `m_aes128_256_batch_top`. Không sửa RTL.

### Mô phỏng

Mô hình tham chiếu độc lập PASS các known-answer test AES-128/AES-256 của FIPS 197 và các kiểm tra round-trip cho ECB, CBC, CFB, OFB, CTR.

| Cấu hình | Kết quả regression | Assertion lỗi |
|---|---:|---:|
| 1 lane | PASS; 2.301 assertion | 0 |
| 4 lane | PASS; 3.056 assertion | 0 |

12 kịch bản waveform đã duyệt tạo ra 15 bộ VCD, WaveJSON và SVG. Index waveform ghi `MATCH` cho đủ 12 mục. Official evidence check với `verification/ht_aes128_256/waveform_plan.md` PASS, 0 lỗi và 0 cảnh báo.

Checker yêu cầu bảng waveform có năm cột; project flow dùng `waveform_plan.md` đúng định dạng này. Nếu gọi trực tiếp checker với bảng waveform bốn cột trong spec đầy đủ, công cụ báo `no figure` dù các liên kết hình vẫn có. Không sửa spec hoặc skill đã cài.

Testbench báo tổng số assertion và dừng khi check thất bại; nó cũng yêu cầu tối thiểu 20 named check. Testbench chưa thống kê hit riêng cho từng check, nên kết quả này không khẳng định assertion coverage theo từng check.

### Tổng hợp generic

Yosys 0.69+274 hoàn tất `hierarchy -check` và `synth` cho cả hai cấu hình. `PARA_CTR_WIDTH=32`; số lane là 1 hoặc 4.

| Chỉ số | 1 lane | 4 lane |
|---|---:|---:|
| Cell generic sau mapping | 348.403 | 1.192.540 |
| Cell tuần tự | 5.823 | 17.088 |
| Bit dây theo hierarchy | 527.406 | 1.850.476 |
| Memory sau synthesis | 0 | 0 |

Yosys báo tám mảng RTL được chuyển thành thanh ghi. Đây là thống kê generic của Yosys, không phải diện tích standard-cell hay PPA ASIC. Flow chưa dùng thư viện Liberty, process corner, SDC, STA, placement hoặc phân tích công suất.

### Rule check và lint

- VLSIT RTL rule check: 6 file, 0 lỗi, 3 cảnh báo `HIE-02`. Cảnh báo áp dụng cho các module core/lane/pipe nội bộ có cả logic và module con; structural top chỉ chứa instance của core.
- Verilator lint: 0 lỗi, 3 cảnh báo `UNUSEDSIGNAL` ở các bit trên của vector lane-ready, lane-valid và lane-last. Lane array dùng lane 0 cho handshake lockstep chung; data/mask từng lane vẫn đi riêng.
- Build C++ của Verilator có hai cảnh báo định nghĩa lại `STDOUT_FILENO`/`STDERR_FILENO` trong header tool. Cả hai executable mô phỏng đều build và chạy thành công.

### Môi trường và chạy lại

Target `make aes128-256-verification` trong Makefile gốc không khởi động được trong Windows sandbox này: MSYS2 `make` thoát ngay với `NtCreateDirectoryObject(...): 0xC0000022`. Các bước Verilator, mô phỏng, waveform, evidence và Yosys tương đương đã chạy trực tiếp; mọi output được cô lập trong thư mục run này. C++ do Verilator sinh ra được build bằng fallback sẵn có và `g++` UCRT64 đã cài.

Trong môi trường GNU Make được hỗ trợ, chạy từ repository root:

```sh
make aes128-256-verification
```

Các target riêng trong root Makefile là `aes128-256-regression`, `aes128-256-evidence` và `aes128-256-synth`.

Repository sau khi sắp xếp có một Makefile gốc, ba filelist RTL với đường dẫn nguồn hợp lệ và 18 README song ngữ. Kiểm tra tĩnh không tìm thấy liên kết Markdown nội bộ bị hỏng (134 liên kết đã kiểm tra).
