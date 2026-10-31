# High-Throughput AES-128/AES-256 RTL

## English

Pipelined batch implementation with run-time AES-128/AES-256 selection. The top module is `m_aes128_256_batch_top`; source order is in `filelist.f`, whose entries are relative to this folder. The behavior is defined in the [dual-key-size specification](../../doc/ht_aes128_256/AES128_AES256_ECB_CBC_CFB_OFB_CTR_Design_Specification.md). Verification and lint reports are under `verification/ht_aes128_256/`.

## Tiếng Việt

Đây là batch implementation có pipeline và chọn AES-128/AES-256 khi chạy. Module top là `m_aes128_256_batch_top`; thứ tự source nằm trong `filelist.f`, với đường dẫn tính từ thư mục này. Hành vi được định nghĩa trong [đặc tả hai kích thước khóa](../../doc/ht_aes128_256/AES128_AES256_ECB_CBC_CFB_OFB_CTR_Design_Specification.md). Verification và báo cáo lint nằm trong `verification/ht_aes128_256/`.
