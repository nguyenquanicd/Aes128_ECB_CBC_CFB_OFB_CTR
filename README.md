# AES-128 IP: ECB, CBC, CFB, OFB, CTR

Iterative AES-128 cipher/decipher core in SystemVerilog. One 128-bit block per operation, five chaining modes,
CFB with 1/2/4/8/16/32/64/128-bit segments. Vietnamese write-up of the original design:
http://nguyenquanicd.blogspot.com/search/label/AES?&max-results=5

## 1. Features

| Item | Value |
|---|---|
| Key / block | 128 bit / 128 bit (key is sampled on the start clock only) |
| Modes | ECB, CBC, CFB (segment 1..128 bit), OFB, CTR |
| Directions | cipher and decipher in every mode |
| Latency (clocks `ready` is low) | **11** cipher (all modes), CFB/OFB/CTR decipher; **22** ECB/CBC decipher |
| Reset | asynchronous, active low; datapath registers (`data_out`, `start_reg`, `end_reg`, cores) have no reset |
| Protection | start while busy and illegal configuration are rejected and flagged (`err_busy`, `err_cfg`) |

ECB/CBC decipher needs round key 10 first, so the cipher core runs one key-schedule pass (11 clocks) before the
decipher core runs (11 clocks). CFB, OFB and CTR use the cipher engine in both directions.

## 2. Architecture

```
                 +------------------------------ aes128 (top) ------------------------------+
 data_in ------>|  start/accept logic (ready gate, config check, err_busy/err_cfg)            |
 key, mode,     |  stream control: stream_active, first_block, mode_reg                       |
 init_vector,   |  chaining registers: start_reg, end_reg      input capture: data_r, seg_r   |
 segment_len    |  input-block mux ---> aes128_cipher_top ---> cipher_out ---+                |
 chain_en       |         |              (cipher core + key expansion)        |-> cout/dout  |--> data_out
 cipher_en      |         +-> key 10 -> aes128_cipher_inv_top (ECB/CBC only) -+  (mode mux)  |--> ready
 decipher_en    |                        (inverse core + inverse key expansion)               |--> err_busy
                +-----------------------------------------------------------------------------+    err_cfg
```

| File | Content |
|---|---|
| `rtl/aes128_pkg.sv` | package: S-box/inverse S-box, MixColumns/InvMixColumns, round constants |
| `rtl/aes128.sv` | top: modes, chaining, handshake, error flags |
| `rtl/aes128_cipher_top.sv`, `aes128_cipher_core.sv`, `aes128_key_expansion.sv` | cipher engine (round key 10 is output for the decipher engine) |
| `rtl/aes128_cipher_inv_top.sv`, `aes128_cipher_core_inv.sv`, `aes128_key_expansion_inv.sv` | decipher engine |
| `rtl/filelist.f` | compile order (package first); run tools from the repository root |

## 3. Interface

| Port | Dir | Description |
|---|---|---|
| `clk`, `rst_n` | in | clock, asynchronous active-low reset |
| `cipher_en`, `decipher_en` | in | 1-clock start pulse. Both high together is rejected (`err_cfg`) |
| `chain_en` | in | 1: chained stream. 0: single-shot operation |
| `data_in[127:0]` | in | block to process (CFB: the segment is left-justified, lower bits are don't care) |
| `key[127:0]` | in | AES key |
| `mode[3:0]` | in | 0 ECB, 1 CBC, 2 CFB, 3 OFB, 4 CTR. Used on the first block of a stream only; 5..15 rejected |
| `init_vector[127:0]` | in | IV (CBC/CFB/OFB) or counter block (CTR, supplied by the host for every block) |
| `segment_len[3:0]` | in | CFB segment: 0=1, 1=2, 2=4, 3=8, 4=16, 5=32, 6=64, 7=128 bit; 8..15 rejected |
| `data_out[127:0]` | out | result; changes only on the clock where `ready` rises. CFB: lower (128-segment) bits are 0 |
| `ready` | out | 1 idle, 0 busy |
| `err_busy` | out | 1-clock pulse: a start arrived while `ready=0` (ignored) |
| `err_cfg` | out | 1-clock pulse: illegal mode / CFB segment / both enables (not started) |

### Protocol
1. Wait for `ready=1`. Present `key`, `mode`, `init_vector`, `segment_len`, `chain_en`, `data_in` and pulse
   `cipher_en` or `decipher_en` for one clock. **All inputs are sampled on that clock only**; they may change afterwards.
2. `ready` falls on the next clock and rises again when the result is in `data_out` (11 or 22 clocks later).
3. A new start can be issued on the first clock where `ready` is 1.
4. Streams: `chain_en=1` on the start clock of every block of a stream; `chain_en=0` for at least one clock between two
   streams. The first block loads `mode` and uses `init_vector`; later blocks ignore `mode`.
   `chain_en=0` makes the operation a single-shot (it is always a first block).
5. Do not change direction inside a CBC/CFB stream. CTR: increment the counter block on `init_vector` for every block.

## 4. Changes in this revision (2026-10-10)

Found by review, golden-model simulation and formal checks on the original RTL:

| # | Problem in the original | Fix |
|---|---|---|
| 1 | CFB decipher wrong from the 2nd block (input shifted twice, low bits from uninitialised `end_reg`) | use `start_reg` as the engine input |
| 2 | `mode` ignored when `chain_en=0` (stale mode of the previous stream) | `mode_reg` loaded on every first block |
| 3 | IV of a `chain_en=0` CBC decipher overwritten by `data_in` | `start_reg` updated only on an accepted start / CBC decipher end |
| 4 | `data_in`, `segment_len` had to be held until `ready`; `end_reg` followed live `data_in` | captured at the start clock; `end_reg` updated only at operation end |
| 5 | `chain_en` had to rise in the same clock as the first start | `stream_active` + combinational `chain_en` |
| 6 | start while busy silently corrupted the result | ignored, `err_busy` |
| 7 | illegal mode/segment processed as another mode | rejected, `err_cfg` |
| 8 | CFB `data_out` low bits carried raw AES output | cleared |
| 9 | functions in `$unit` scope: RTL compiled only if a tool merged the files | `aes128_pkg` package (5 function files removed) |
| 10 | unused `rtl/aes128_sbox_inv.sv` | moved to `tb/ref/aes128_sbox_inv_lut.sv` (independent oracle) |

New output ports `err_busy`, `err_cfg` were appended to the port list. Not changed: latency, algorithms, port order.

## 5. Verification

### How to run

The single `Makefile` in the repository root runs every simulation, the formal proofs and the mutation check on
**Windows and Linux**. It needs GNU make with a POSIX shell (MSYS2 / Git Bash make on Windows), Icarus Verilog,
Python 3 and, for formal, SymbiYosys. The [OSS CAD Suite](https://github.com/YosysHQ/oss-cad-suite-build) provides
all tools; it is found automatically in `C:/Tools/oss-cad-suite` (or pass `OSSCAD=<folder>`). Every comment in the
Makefile explains the command below it. Tool installation on Windows: `../VLSIT_OpenSource_Tools/README.md`.

```
make help                 # all targets
make info                 # detected OS, tools, versions
make quick                # every simulation except the long runs (about 4-5 minutes)
make regress              # quick + long vector run + long random run
make test-prim            # one test: test-prim, test-protocol, test-roundtrip, vec-<name>, simple-<mode>
make vec VEC=rand_s1 ARGS="+JUNK=1 +SCR=31"    # any golden-vector scenario with extra plusargs
make formal               # SymbiYosys proofs
make mutation             # mutation check
make gen-vectors          # regenerate vectors/*.hex with tools/aes_ref.py
make clean                # delete generated files (sim/build, formal results)
```
Windows PowerShell without make: `powershell -ExecutionPolicy Bypass -File sim\run_regression.ps1 -Quick`
(same tests, older runner). Every testbench ends with `$fatal` on failure, so `make` returns a non-zero status.

| Item | Location | Purpose |
|---|---|---|
| Reference model | `tools/aes_ref.py` | pure Python, self-tested against FIPS-197, SP 800-38A, AESAVS |
| Vector generator | `tools/gen_vectors.py` -> `vectors/*.hex` | NIST, AESAVS var-text/var-key, patterns, every CFB segment, random streams, chain_en=0, key changes, long run |
| Vector testbench | `tb/tb_aes128_vec.sv` | plusargs `+JUNK +SCR +EARLY +MID +COVCHK` stress input timing, chain_en timing, stray starts |
| Directed protocol test | `tb/tb_aes128_protocol.sv` | reset, latency, err flags, chain_en, back-to-back, mode-after-mode, reset in the middle of an operation |
| Round-trip random test | `tb/tb_aes128_roundtrip.sv` | decipher(cipher(P))==P, OFB/CTR symmetry, ECB determinism, CBC diffusion |
| Primitive test | `tb/tb_aes128_prim.sv` | exhaustive S-box vs independent LUT, MixColumns, rcon, forward/inverse key expansion (FIPS-197 A.1) |
| Readable examples | `simpleTestcase/*.sv` | one NIST known-answer testbench per mode (generated by `tools/gen_simple_tbs.py`) |
| Protocol checker | `checker/aes128_protocol_checker.sv` | rules C1..C9, used by every testbench and by formal |
| Formal | `formal/` (`run_formal.ps1`) | S-box inverse (exhaustive), inverse key expansion for every key, control/latency/error-flag rules of the top |
| Mutation check | `tools/mutation_check.py` | 18 deliberate RTL defects + the original RTL must all be caught |

Testbench infrastructure (`tb/aes128_tb_common.svh`) drives inputs on the falling edge and compares with `!==`, so a
race or an `X` output can no longer produce a false PASS (the original testbenches did both).

Results of the last runs (Windows, `make`): `make quick` 26/26 tests passed; `make long` 3/3 (9,963 + 2,049 + 2,049
checks); `make formal` 3/3 (`fv_sbox`, `fv_keysched`, `fv_ctrl`); mutation check 19/19 caught (18 mutants + original RTL).

## 6. Known limitations
- ECB/CBC decipher takes 22 clocks (an inverse-key-schedule engine or a cached round key 10 would halve it).
- CTR has no internal counter; direction change inside a CBC/CFB stream is undefined.
- `data_out` and the chaining registers are not reset (undefined until the first operation completes).
- UVM environment in `uvm_comp/` is unfinished (see section 7).

## 7. Repository layout and status

```
rtl/            RTL + filelist.f            tb/            testbenches + common header + tb/ref (LUT oracle)
checker/        protocol checker            simpleTestcase/ readable NIST tests (generated)
vectors/        golden vectors (generated)  formal/        SymbiYosys harnesses (fv_sbox, fv_keysched, fv_ctrl)
tools/          python model, generators,   sim/           Questa scripts + run_regression.ps1; sim/build is generated
                mutation check              uvm_comp/, pat/, doc/   unfinished UVM environment, patterns, documents
Makefile        the one entry point for simulation / formal / mutation, Windows and Linux
```
Generated files (`sim/build/`, Questa `sim/work/`, waveforms, logs, SymbiYosys results) are not tracked: see `.gitignore`.

Verified on Windows: all `make` single targets and `make quick`, the failure exit status, the formal proofs and the
mutation check. Verified on Linux only by dry run (`make -n`) and the missing-tool message, because no Linux
Icarus Verilog was available to run the simulations there.
Not verified: the UVM environment. `uvm_comp/aes_Testbench.sv` and `sim/run_compile.do` were updated for the package
(`rtl/aes128_pkg.sv` is compiled first, the five removed function files are no longer included) but could not be
compiled here (no UVM library, no Questa); that environment was already unfinished (its clock/reset are not connected).
