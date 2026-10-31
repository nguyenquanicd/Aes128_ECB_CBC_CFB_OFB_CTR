# Single-Block AES-128 Verification

## English

This directory contains directed and random testbenches, golden vectors, a protocol checker, formal harnesses and scripts for the iterative AES-128 core. The independent reference model is in `../shared/aes_ref.py`.

From the repository root, run `make quick`, `make regress`, `make formal` or `make mutation`. The PowerShell runner is `sim/run_regression.ps1`. Build products and per-run logs are written under `sim/build/`.

## Tiếng Việt

Thư mục này chứa testbench directed/random, golden vector, protocol checker, formal harness và script cho core AES-128 tuần tự. Mô hình tham chiếu độc lập ở `../shared/aes_ref.py`.

Chạy `make quick`, `make regress`, `make formal` hoặc `make mutation` từ repository root. Script PowerShell nằm tại `sim/run_regression.ps1`. Build và log từng lượt chạy được ghi dưới `sim/build/`.
