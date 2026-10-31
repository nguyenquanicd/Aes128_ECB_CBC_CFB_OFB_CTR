# Single-Block AES-128 Design Notes

## English

This folder describes the iterative AES-128 RTL in `rtl/single_aes128/`. The top module is `aes128`; it supports ECB, CBC, CFB, OFB and CTR, with CFB segment sizes from 1 to 128 bits. The controller accepts one block per operation. Cipher operations and CFB/OFB/CTR decipher operations take 11 clocks; ECB/CBC decipher takes 22 clocks because it performs a key-schedule pass before the inverse-cipher pass.

The `cipher_en` and `decipher_en` inputs are one-cycle start requests accepted when `ready` is high. Inputs are sampled on the start clock. A start while busy is ignored and pulses `err_busy`; illegal mode/segment combinations or simultaneous cipher/decipher requests are rejected with `err_cfg`. `chain_en` selects a chained stream, and the host supplies the IV or CTR block through `init_vector` for each operation. The core does not increment CTR internally.

`rst_n` is asynchronous and active-low. The legacy datapath registers are not all reset, so output data is meaningful only after a completed operation. The single-block core has no standalone MicroSpec file; these notes summarize the implemented interface and the original project README.

The root [README](../../README.md) describes the interface and verification history. `legacy_materials/` preserves older driver, monitor and ModelSim documents. These files are reference material; the two batch specifications are in their own design folders.

## Tiếng Việt

Thư mục này mô tả RTL AES-128 tuần tự tại `rtl/single_aes128/`. Module top là `aes128`; core hỗ trợ ECB, CBC, CFB, OFB và CTR, với CFB segment từ 1 đến 128 bit. Mỗi thao tác xử lý một block. Mã hóa và giải mã CFB/OFB/CTR mất 11 chu kỳ; giải mã ECB/CBC mất 22 chu kỳ do cần một lượt key schedule trước lượt giải mã.

`cipher_en` và `decipher_en` là yêu cầu bắt đầu trong một chu kỳ và chỉ được nhận khi `ready=1`. Input được lấy mẫu tại cạnh bắt đầu. Yêu cầu đến khi core đang bận bị bỏ qua và phát `err_busy`; mode/segment không hợp lệ hoặc bật đồng thời cipher/decipher bị từ chối và phát `err_cfg`. `chain_en` chọn luồng chaining; host cấp IV hoặc block CTR qua `init_vector` cho từng thao tác. Core không tự tăng CTR.

`rst_n` là reset bất đồng bộ active-low. Không phải mọi thanh ghi datapath cũ đều được reset, vì vậy output chỉ có ý nghĩa sau khi một thao tác hoàn tất. Core tuần tự này chưa có file MicroSpec độc lập; tài liệu này tóm tắt interface đã cài đặt và README dự án ban đầu.

[README gốc](../../README.md) mô tả cấu trúc repository. `legacy_materials/` lưu tài liệu driver, monitor và ModelSim cũ để tham khảo. Hai đặc tả batch core được đặt riêng trong thư mục design tương ứng.
