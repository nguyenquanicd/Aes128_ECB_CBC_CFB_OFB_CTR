# AES-128 / AES-256 Waveform Plan

| WF-ID | Function | Scenario | Compared behavior | Specification figure |
|---|---|---|---|---|
| WF-001 | Configuration | AES-128 and AES-256 accepted; malformed AES-128 key rejected | Configuration handshake and error code 1 | [Figure](../../doc/ht_aes128_256/figures/waveforms/WF-001_config_key_select.svg) |
| WF-002 | ECB AES-128 | Three continuous batches | C10 latency and one batch per cycle | [Figure](../../doc/ht_aes128_256/figures/waveforms/WF-002_aes128_ecb.svg) |
| WF-003 | ECB AES-256 | Three continuous batches | C14 latency and one batch per cycle | [Figure](../../doc/ht_aes128_256/figures/waveforms/WF-003_aes256_ecb.svg) |
| WF-004 | CTR | Partial batch allocation | Active counter values and output lane mask | [Figure](../../doc/ht_aes128_256/figures/waveforms/WF-004_ctr_allocate.svg) |
| WF-005 | CTR | Counter wrap rejection | Whole batch rejected with error code 3 | [Figure](../../doc/ht_aes128_256/figures/waveforms/WF-005_ctr_wrap.svg) |
| WF-006 | CBC decrypt | AES-128 and AES-256 | N-lane output compared to independent vectors | [Figure](../../doc/ht_aes128_256/figures/waveforms/WF-006a_cbc_decrypt.svg) |
| WF-007 | CBC encrypt | AES-128 feedback | C10 result and C11 dependent input | [Figure](../../doc/ht_aes128_256/figures/waveforms/WF-007_cbc_encrypt_feedback.svg) |
| WF-008 | CFB | AES-256 feedback | C14 result and C15 dependent input | [Figure](../../doc/ht_aes128_256/figures/waveforms/WF-008_cfb_feedback.svg) |
| WF-009 | OFB | AES-256 feedback | Ordered feedback and golden output | [Figure](../../doc/ht_aes128_256/figures/waveforms/WF-009_ofb_feedback.svg) |
| WF-010 | Backpressure | AES-128 and AES-256 | Output payload held stable for one stalled cycle | [Figure](../../doc/ht_aes128_256/figures/waveforms/WF-010a_backpressure.svg) |
| WF-011 | Lane / protocol errors | Invalid mask and unsolicited data | Error codes 2 and 5; no rejected output | [Figure](../../doc/ht_aes128_256/figures/waveforms/WF-011_lane_mask_error.svg) |
| WF-012 | Reset / zeroize | In-flight reset and zeroize aborts | Valid state cleared; zeroize completion pulse | [Figure](../../doc/ht_aes128_256/figures/waveforms/WF-012a_reset_abort.svg) |

The approved specification contains 12 scenarios and 15 figures. The separate `WF-006b`, `WF-010b`, and `WF-012b` traces are also generated and checked.
