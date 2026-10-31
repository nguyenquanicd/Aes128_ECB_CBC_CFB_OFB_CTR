# Waveform comparison / waveform đối chiếu

The simulator checks interface timing and data against the approved specification scenarios and independent golden vectors. / Simulator kiểm tra thời gian giao tiếp và dữ liệu theo các kịch bản đã duyệt và vector tham chiếu độc lập.

| WF-ID | Specification figure | Simulated VCD | Result | Note |
|---|---|---|---|---|
| WF-001 | [figure](../../../../../doc/ht_aes128_256/figures/waveforms/WF-001_config_key_select.svg) | WF-001_config_key_select.vcd | MATCH | PASS: AES-128/AES-256 config handshakes; malformed AES-128 upper key returns error 1. |
| WF-002 | [figure](../../../../../doc/ht_aes128_256/figures/waveforms/WF-002_aes128_ecb.svg) | WF-002_aes128_ecb.vcd | MATCH | PASS: golden outputs, C10 latency, consecutive output batches (II=1). |
| WF-003 | [figure](../../../../../doc/ht_aes128_256/figures/waveforms/WF-003_aes256_ecb.svg) | WF-003_aes256_ecb.vcd | MATCH | PASS: golden outputs, C14 latency, consecutive output batches (II=1). |
| WF-004 | [figure](../../../../../doc/ht_aes128_256/figures/waveforms/WF-004_ctr_allocate.svg) | WF-004_ctr_allocate.vcd | MATCH | PASS: partial lane mask and counter-derived results match the independent model. |
| WF-005 | [figure](../../../../../doc/ht_aes128_256/figures/waveforms/WF-005_ctr_wrap.svg) | WF-005_ctr_wrap.vcd | MATCH | PASS: wrap is rejected atomically with error 3. |
| WF-006 | [figure](../../../../../doc/ht_aes128_256/figures/waveforms/WF-006a_cbc_decrypt.svg) | WF-006a_cbc_decrypt.vcd | MATCH | PASS: AES-128 and AES-256 figures generated; lane outputs match independent vectors. |
| WF-007 | [figure](../../../../../doc/ht_aes128_256/figures/waveforms/WF-007_cbc_encrypt_feedback.svg) | WF-007_cbc_encrypt_feedback.vcd | MATCH | PASS: C10 latency and C11 feedback input interval. |
| WF-008 | [figure](../../../../../doc/ht_aes128_256/figures/waveforms/WF-008_cfb_feedback.svg) | WF-008_cfb_feedback.vcd | MATCH | PASS: C14 latency and C15 feedback input interval. |
| WF-009 | [figure](../../../../../doc/ht_aes128_256/figures/waveforms/WF-009_ofb_feedback.svg) | WF-009_ofb_feedback.vcd | MATCH | PASS: AES-256 OFB output matches the independent model; C15 feedback interval. |
| WF-010 | [figure](../../../../../doc/ht_aes128_256/figures/waveforms/WF-010a_backpressure.svg) | WF-010a_backpressure.vcd | MATCH | PASS: AES-128 and AES-256 output records remain stable during a one-cycle stall. |
| WF-011 | [figure](../../../../../doc/ht_aes128_256/figures/waveforms/WF-011_lane_mask_error.svg) | WF-011_lane_mask_error.vcd | MATCH | PASS: invalid lane mask returns error 2; unsolicited data returns error 5. |
| WF-012 | [figure](../../../../../doc/ht_aes128_256/figures/waveforms/WF-012a_reset_abort.svg) | WF-012a_reset_abort.vcd | MATCH | PASS: reset abort and zeroize abort traces show cleared valid state; zeroize done pulses. |

