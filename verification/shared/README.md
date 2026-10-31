# Shared Verification Model

## English

`aes_ref.py` is the independent AES-128 reference used by the legacy and high-throughput AES-128 flows. The AES-128/AES-256 model imports it and adds AES-256 key expansion and block operations. Golden data is calculated from the model, not from the RTL under test.

## Tiếng Việt

`aes_ref.py` là mô hình AES-128 độc lập dùng cho core cũ và flow throughput cao AES-128. Model AES-128/AES-256 import file này rồi bổ sung key expansion và phép mã hóa/giải mã AES-256. Dữ liệu kỳ vọng được tính từ model, không lấy từ RTL đang kiểm tra.
