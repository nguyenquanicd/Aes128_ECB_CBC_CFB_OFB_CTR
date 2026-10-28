# AES-128 RTL Generation Report

## Scope

Generated synthesizable SystemVerilog from `doc/AES128_ECB_CBC_CFB_OFB_CTR_Design_Specification.md` using the VLSIT default RTL rules. Legacy sources in `rtl/` were left unchanged.

The approved pipeline uses an input capture register followed by ten registered AES round stages per lane. A batch accepted at C0 produces output at C10 (`L_PIPE=10`), with elastic backpressure. The key schedule is computed at configuration and stored as K0 through K10.

The repository reuse scan found no compatible AES round or key-expansion RTL to reuse; the AES datapath modules were generated for this design.

## Generated hierarchy

The compile order is in `filelist.f`; the top is `m_aes128_batch_top`.

| Module | Responsibility |
|---|---|
| `m_aes128_batch_top` | Structural top-level wrapper |
| `m_aes128_batch_core` | Configuration, mode, CTR, feedback, error, and zeroize control |
| `m_aes128_key_expand` | Combinational AES-128 round-key generation |
| `m_aes128_lane_array` | N-lane input/output and batch control |
| `m_aes128_pipe_lane` | Input capture and ten-stage elastic round pipeline for one lane |
| `m_aes128_aes_round` | Forward or inverse AES round transform |

## Checks

- VLSIT rule checker: **PASS**, 0 errors, 3 `HIE-02` warnings. The warnings are on the intended composite core, lane-array, and pipeline-lane modules; only the top is required to contain instances only.
- Verilator lint: **PASS**, 0 errors, 0 warnings.
- Slang lint: **PASS**, 0 errors, 5 `useless-cast` warnings. These are the explicit `$bits(destination)'(...)` width casts required by the RTL arithmetic rule.
- Independent AES reference model: vectors generated for 50 regression streams; the model is self-checked against FIPS 197 and NIST SP 800-38A known-answer vectors.
- Reference-model self-test: **PASS** for FIPS-197, SP 800-38A ECB/CBC/CFB128/CFB8/CFB1/OFB/CTR, and AESAVS VarTxt/VarKey.
- RTL simulation, `PARA_AES_LANE_NUM=1`: **PASS**, 55 streams, 431 input batches, 427 output batches; all 20 assertions exercised, 0 assertion failures.
- RTL simulation, `PARA_AES_LANE_NUM=4`: **PASS**, 55 streams, 315 input batches, 311 output batches; all 20 assertions exercised, 0 assertion failures.
- Waveform simulation: **PASS**, all 11 approved scenarios, including configuration, ECB batches, CTR allocation/wrap, CBC decrypt/encrypt, CFB, OFB, backpressure, reset and zeroize. All 11 WaveJSON files pass WaveDrom lint and all 11 SVGs render.
- Specification evidence check: **PASS**, 8 waveform requirements checked; no IP-level CDC applies because asynchronous source handling belongs to the SoC wrapper.
- RTL defects found while validating the independent vectors: corrected the forward MixColumns `y2` equation and byte-slice indexing in SubBytes and both MixColumns directions in `m_aes128_aes_round.sv`. The FIPS round traces and KAT pass after the corrections.
- Local Windows Icarus 14.0 writes a usable VVP binary but then exits with native status `0xC0000005`; the fresh binary passed simulation. The VLSIT Makefile now records this status and its simulation target validates the emitted binary. No compiler `error:` diagnostics were present.
- The simulation commands were run directly because the installed MSYS `make.exe` failed to initialize (`0xC0000142`) in this environment; Makefile execution itself was not verified here.
- Spec gap scan: 3 integration dependencies remain open: SoC clock target, supported frontend/version options, and target libraries/corners. The functional RTL contract is defined; synthesis PPA and STA signoff remain integration work.
- Code coverage, formal proof, synthesis, STA, and PPA were not run.

## Artifacts

- RTL: the six `.sv` files in this directory.
- Compile list: `filelist.f`.
- Rule report: `rtl_rule_check_report.md`.
- Lint logs: `lint_verilator.log` and `lint_slang.log`.
- Verification sources and results: `../verification/`.
