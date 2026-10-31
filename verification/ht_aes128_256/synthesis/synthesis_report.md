# Generic Synthesis Report

## English

Tool: Yosys 0.69+274. Top: `m_aes128_256_batch_top`. Both runs use `PARA_CTR_WIDTH=32`. The RTL passed hierarchy checking and the full generic `synth` flow, including ABC mapping to Yosys generic gates.

| Metric | 1 lane | 4 lanes |
|---|---:|---:|
| Generic mapped cells | 348,403 | 1,192,540 |
| Generic sequential cells | 5,823 | 17,088 |
| Generic wire bits | 527,406 | 1,850,476 |
| Memories after synthesis | 0 | 0 |

The mapped cells are generic Yosys primitives, not standard cells. They cannot be used as ASIC area, timing, or power estimates. The flow has no target liberty, process corner, clock constraints, or physical design settings. Yosys converted RTL arrays into registers; these are synthesis transformations, not errors. The 4-lane count is about 3.42 times the 1-lane count in this generic flow; this is a structural comparison, not an ASIC area ratio. See `aes128_256_n1_stats.json` and `aes128_256_n4_stats.json` for hierarchical cell breakdowns and `../logs/yosys_full_n4.log.gz` for the complete 4-lane tool log.

## Tiếng Việt

Công cụ: Yosys 0.69+274. Top: `m_aes128_256_batch_top`. Cả hai lượt chạy dùng `PARA_CTR_WIDTH=32`. RTL đã qua kiểm tra hierarchy và toàn bộ luồng generic `synth`, gồm ABC mapping sang cổng generic của Yosys.

| Chỉ số | 1 lane | 4 lane |
|---|---:|---:|
| Cell generic sau mapping | 348.403 | 1.192.540 |
| Cell tuần tự generic | 5.823 | 17.088 |
| Bit dây generic | 527.406 | 1.850.476 |
| Memory sau tổng hợp | 0 | 0 |

Các cell trên là primitive generic của Yosys, không phải standard cell. Không thể dùng các số này để suy ra diện tích, timing hoặc công suất ASIC. Luồng chưa có liberty mục tiêu, process corner, ràng buộc clock hay thiết lập physical design. Yosys chuyển các mảng RTL thành thanh ghi; đây là bước biến đổi tổng hợp, không phải lỗi. Số cell của 4 lane gấp khoảng 3,42 lần 1 lane trong luồng generic này; đây là so sánh cấu trúc, không phải tỷ lệ diện tích ASIC. Xem `aes128_256_n1_stats.json` và `aes128_256_n4_stats.json` để biết phân rã cell theo hierarchy, cùng `../logs/yosys_full_n4.log.gz` để xem log 4 lane đầy đủ.
