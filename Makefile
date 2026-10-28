# =============================================================================
# AES-128 IP (ECB/CBC/CFB/OFB/CTR) - the ONE Makefile for simulation, formal,
# mutation check and vector generation. Works on Windows and Linux.
# =============================================================================
#
# QUICK START (run everything from the repository root, the folder of this file)
#
#   make help                 list every target
#   make info                 show the detected OS, tools and versions
#   make quick                all simulations except the long runs (about 4 minutes)
#   make regress              EVERYTHING: quick + long vector run + long random run
#   make test-protocol        one directed testbench
#   make vec-nist             one golden-vector scenario (NIST SP 800-38A + FIPS-197)
#   make vec VEC=rand_s1 ARGS="+JUNK=1 +SCR=31"      any scenario with any plusargs
#   make formal               formal proofs (SymbiYosys)
#   make mutation             prove that the testbenches catch 18 deliberate RTL bugs
#   make vlsit-verification   build and simulate the generated batch RTL (LANES=1 and 4),
#                             then create and check its specification waveform evidence
#
# REQUIREMENTS
#   * GNU make >= 3.82 and a POSIX shell with mkdir/rm/cat/grep/tail
#       Linux : the normal "make" of the distribution
#       Windows: make from MSYS2 or Git Bash (cmd.exe-only make programs are NOT supported)
#   * Icarus Verilog 12+ (iverilog, vvp): simulation. SymbiYosys (sby) + yosys-slang: formal.
#     The OSS CAD Suite (https://github.com/YosysHQ/oss-cad-suite-build) contains all of them.
#   * Python 3 (no extra packages): vector generation and mutation check.
#
# WINDOWS (PowerShell) EXAMPLE
#   C:\Users\PC\Tools\msys64\usr\bin\make.exe quick
#   or, after adding MSYS2's usr\bin to PATH:   make quick
#   The OSS CAD Suite is found automatically in C:/Tools/oss-cad-suite; for another
#   location use:   make quick OSSCAD=D:/tools/oss-cad-suite
#
# LINUX EXAMPLE
#   make quick                                   # iverilog/vvp already in PATH
#   make quick OSSCAD=$HOME/oss-cad-suite        # tools taken from an unpacked OSS CAD Suite
#
# EXIT STATUS: every test target returns non-zero when a test fails, so the
# Makefile can be used in CI. Each testbench ends with $fatal on failure, and
# vvp then exits with code 1 - no log parsing is needed, which is why the same
# commands work with the Windows and the Linux shell.
# =============================================================================

.DEFAULT_GOAL := help

# -----------------------------------------------------------------------------
# 1. Host detection and tool locations
# -----------------------------------------------------------------------------
# $(OS) is set to Windows_NT by Windows itself; on Linux/macOS it is empty.
ifeq ($(OS),Windows_NT)
  HOST := windows
  # default folder of the Windows build of the OSS CAD Suite (override on the command line)
  OSSCAD ?= C:/Tools/oss-cad-suite
else
  HOST := linux
  OSSCAD ?=
endif

# If an OSS CAD Suite folder is given and exists, put its bin/ and lib/ in PATH for the recipes.
#  - Under MSYS2/Git Bash the PATH is a POSIX list (entries separated by ':'), so the Windows
#    folder is first converted with cygpath ("C:/Tools/x" -> "/c/Tools/x"); on Linux cygpath does not
#    exist and the folder is used unchanged.
#  - PATHSEP is ';' only for a native Windows PATH, otherwise ':'.
ifneq ($(strip $(OSSCAD)),)
  ifneq ($(wildcard $(OSSCAD)/bin),)
    OSSCAD_P := $(or $(shell cygpath -u "$(OSSCAD)" 2>/dev/null),$(OSSCAD))
    PATHSEP  := $(if $(findstring ;,$(PATH)),;,:)
    export PATH := $(OSSCAD_P)/bin$(PATHSEP)$(OSSCAD_P)/lib$(PATHSEP)$(PATH)
  endif
endif

# Tool names. Override on the command line if needed, e.g. make IVERILOG=iverilog-12
IVERILOG ?= iverilog
VVP      ?= vvp
SBY      ?= sby
# Python: the OSS CAD Suite brings its own python3.exe on Windows (the Windows "python"
# command is often only a Microsoft Store stub); on Linux use python3.
ifeq ($(HOST),windows)
  PYTHON ?= $(if $(wildcard $(OSSCAD)/lib/python3.exe),$(OSSCAD)/lib/python3.exe,python)
else
  PYTHON ?= python3
endif

# -----------------------------------------------------------------------------
# 2. Paths and compiler flags
# -----------------------------------------------------------------------------
# (comments are on their own lines: a trailing comment would leave spaces in the variable value)
# BUILD: all generated simulation files (git-ignored); LOG: one log file per executed test
BUILD    := sim/build
LOG      := $(BUILD)/log
# RTL compile order (package first), paths relative to the repository root
RTL_LIST := rtl/filelist.f
RTL_SRC  := $(wildcard rtl/*.sv)
CHECKER  := checker/aes128_protocol_checker.sv
# Everything a testbench binary depends on: rebuild when any RTL / checker / testbench header changes.
TB_DEPS  := $(RTL_SRC) $(RTL_LIST) $(CHECKER) $(wildcard tb/*.svh) $(wildcard tb/ref/*.sv)

# iverilog flags:
#   -g2012          SystemVerilog-2012 language (packages, always_ff, logic, tasks, $fatal ...)
#   -Wall           enable all warnings (they are written to a compile log, see COMPILE below)
#   -Wno-timescale  the RTL has no `timescale, the testbenches do; do not warn about the mix
#   -Itb -Itb/ref   include directories: tb/aes128_tb_common.svh and tb/ref/aes128_sbox_inv_lut.sv
IVFLAGS  := -g2012 -Wall -Wno-timescale -Itb -Itb/ref

# Test lists. SIMPLE names map to simpleTestcase/tb_aes128_<name>.sv
SIMPLE        := ecb cbc cfb_cipher cfb_decipher ofb ctr
VEC_PLAIN     := nist walk patterns cfb_segments rand_s1 rand_s2 rand_s3 gap1 b2b chain0 multikey
VEC_STRESS    := vec-nist-junk vec-rand_s1-scr vec-rand_s2-early vec-rand_s3-stray vec-b2b-junk
UNIT_TESTS    := test-prim test-protocol
RANDOM_TESTS  := test-roundtrip test-roundtrip-2
VEC_TESTS     := $(addprefix vec-,$(VEC_PLAIN))
SIMPLE_TESTS  := $(addprefix simple-,$(SIMPLE))
QUICK_TESTS   := $(UNIT_TESTS) $(RANDOM_TESTS) $(VEC_TESTS) $(VEC_STRESS) $(SIMPLE_TESTS)
LONG_TESTS    := test-roundtrip-long vec-long vec-long-stress

# Plusargs of the round-trip testbench: +N = number of random streams, +SEED = random seed.
# Plusargs of the vector testbench (see the header of tb/tb_aes128_vec.sv):
#   +VEC=<file>  vector file        +JUNK=1  random inputs while idle
#   +SCR=<mask>  scramble inputs after the start pulse (31 = all five inputs)
#   +EARLY=<n>   raise chain_en n clocks before the first start of a stream
#   +MID=<k>     stray start k clocks after every start (must be rejected, err_busy)
#   +COVCHK=1    fail if a mode/direction/CFB-segment coverage bin is empty

.PHONY: help info check-tools quick regress unit random vectors stress simple long \
        $(UNIT_TESTS) $(RANDOM_TESTS) test-roundtrip-long vec $(VEC_TESTS) $(VEC_STRESS) \
        vec-long vec-long-stress $(SIMPLE_TESTS) \
        formal formal-sbox formal-keysched formal-ctrl mutation mutation-fast \
        gen-vectors gen-simple ref-selftest clean

# -----------------------------------------------------------------------------
# 3. Helper macros
# -----------------------------------------------------------------------------
# COMPILE(top, sources): build/<top>.vvp from the RTL list + checker + the given testbench source(s).
#   iverilog -s <top>            elaborate <top> as the top-level module
#   iverilog -o <file>           output file (a vvp program)
#   iverilog -c rtl/filelist.f   read the RTL files in the right order from the list
# stderr is written to a compile log; the log is printed only if the compilation fails (iverilog
# prints many harmless "sorry: constant selects in always_*" notes for the RTL).
define COMPILE
$(BUILD)/$(1).vvp: $(2) $(TB_DEPS) | $(LOG)
	$(IVERILOG) $(IVFLAGS) -s $(1) -o $$@ -c $(RTL_LIST) $(CHECKER) $(2) 2> $(LOG)/$(1).compile.log \
	  || { cat $(LOG)/$(1).compile.log; echo "*** COMPILE FAILED: $(1)"; exit 1; }
endef

# RUN(vvp-file, plusargs, test-name): run one simulation.
#   vvp <file> <plusargs>   executes the compiled testbench; +name=value are read by $value$plusargs
#   > log 2>&1              the full output goes to build/log/<test-name>.log
#   || { cat ...; exit 1; } on failure (non-zero exit status) print the log and stop this target
#   grep/tail               on success print the one-line SUMMARY of the testbench
define RUN
	@echo "--- $(3)"
	$(VVP) $(1) $(2) > $(LOG)/$(3).log 2>&1 \
	  || { cat $(LOG)/$(3).log; echo "*** FAILED: $(3)"; exit 1; }
	@grep '^SUMMARY' $(LOG)/$(3).log | tail -n 1
endef

# RUN_GROUP(list-of-targets, group-name): run several targets one after another, do not stop at
# the first failure, print a summary and return non-zero if anything failed.
define RUN_GROUP
	@pass=0; fail=0; failed=""; \
	for t in $(1); do \
	  if $(MAKE) --no-print-directory $$t; then pass=$$((pass+1)); \
	  else fail=$$((fail+1)); failed="$$failed $$t"; fi; \
	done; \
	echo ""; echo "=== $(2): $$pass passed, $$fail failed ==="; \
	if [ $$fail -ne 0 ]; then echo "FAILED:$$failed"; exit 1; fi
endef

# -----------------------------------------------------------------------------
# 4. Help / environment
# -----------------------------------------------------------------------------
help:
	@echo "AES-128 IP Makefile  (host: $(HOST))"
	@echo ""
	@echo "Groups"
	@echo "  make quick               unit + random + vectors + stress + simple (no long runs)"
	@echo "  make regress             quick + long vector run + long random run"
	@echo "  make unit | random | vectors | stress | simple | long"
	@echo "Single tests"
	@echo "  make test-prim           primitives: S-box (exhaustive), MixColumns, rcon, key expansion"
	@echo "  make test-protocol       directed protocol test (reset, latency, err flags, chain_en ...)"
	@echo "  make test-roundtrip      random decipher(cipher(x))==x   [N=300 SEED=1]"
	@echo "  make vec-<name>          golden-vector scenario: $(VEC_PLAIN)"
	@echo "  make vec VEC=<name> ARGS=\"+JUNK=1\"   any scenario with extra plusargs"
	@echo "  make simple-<mode>       readable NIST tests: $(SIMPLE)"
	@echo "Other"
	@echo "  make formal              sby proofs (formal-sbox formal-keysched formal-ctrl)"
	@echo "  make mutation            18 mutants + original RTL must all be caught (mutation-fast: skip round trip)"
	@echo "  make gen-vectors         regenerate vectors/*.hex (python reference model)"
	@echo "  make gen-simple          regenerate simpleTestcase/*.sv"
	@echo "  make ref-selftest        self-test of the python AES model"
	@echo "  make vlsit-verification  simulate generated batch RTL (LANES=1/4) and check waveform evidence"
	@echo "  make info | check-tools  show / verify the tool installation"
	@echo "  make clean               delete generated files"
	@echo "Variables: OSSCAD=<oss-cad-suite folder> PYTHON=<python> IVERILOG VVP SBY N SEED VEC ARGS"

# Show what was detected (useful when something is not found).
info:
	@echo "host      : $(HOST)"
	@echo "OSSCAD    : $(if $(strip $(OSSCAD)),$(OSSCAD),(not set))   used: $(if $(strip $(OSSCAD)),$(if $(wildcard $(OSSCAD)/bin),yes,no),no)"
	@echo "PYTHON    : $(PYTHON)"
	@echo "PATH      : $(PATH)"
	-@$(IVERILOG) -V 2>&1 | head -n 1
	-@$(SBY) --version 2>&1 | head -n 1
	-@$(PYTHON) --version 2>&1

# Fail with a clear message if a mandatory tool is missing (command -v is POSIX).
check-tools:
	@command -v $(IVERILOG) >/dev/null 2>&1 || { echo "iverilog not found: install Icarus Verilog or set OSSCAD=<folder>"; exit 1; }
	@command -v $(VVP)      >/dev/null 2>&1 || { echo "vvp not found"; exit 1; }
	@command -v $(PYTHON)   >/dev/null 2>&1 || echo "note: python not found (only needed for gen-*, mutation)"
	@command -v $(SBY)      >/dev/null 2>&1 || echo "note: sby not found (only needed for 'make formal')"
	@echo "tools OK"

# Create the build and log directories once (order-only prerequisite of every compile rule).
# mkdir -p also creates sim/build itself and does not fail if the directory already exists.
$(LOG):
	mkdir -p $(LOG)

# -----------------------------------------------------------------------------
# 5. Testbench binaries (one compile rule per testbench)
# -----------------------------------------------------------------------------
$(eval $(call COMPILE,tb_aes128_prim,tb/tb_aes128_prim.sv))
$(eval $(call COMPILE,tb_aes128_protocol,tb/tb_aes128_protocol.sv))
$(eval $(call COMPILE,tb_aes128_roundtrip,tb/tb_aes128_roundtrip.sv))
$(eval $(call COMPILE,tb_aes128_vec,tb/tb_aes128_vec.sv))
$(foreach m,$(SIMPLE),$(eval $(call COMPILE,tb_aes128_$(m),simpleTestcase/tb_aes128_$(m).sv)))

# -----------------------------------------------------------------------------
# 6. Unit / directed / random tests
# -----------------------------------------------------------------------------
# Primitives (aes128_pkg functions, key expansion modules): no DUT, no checker needed.
test-prim: $(BUILD)/tb_aes128_prim.vvp
	$(call RUN,$<,,prim)

# Directed protocol test: reset values, exact latency (11/22), err_busy/err_cfg, chain_en rules,
# back-to-back start, any mode after any mode, reset in the middle of an operation.
test-protocol: $(BUILD)/tb_aes128_protocol.vvp
	$(call RUN,$<,,protocol)

# Constrained-random round trip. +N = streams, +SEED = random seed (see N and SEED below).
N    ?= 300
SEED ?= 1
test-roundtrip: $(BUILD)/tb_aes128_roundtrip.vvp
	$(call RUN,$<,+N=$(N) +SEED=$(SEED),roundtrip_n$(N)_seed$(SEED))

test-roundtrip-2: $(BUILD)/tb_aes128_roundtrip.vvp
	$(call RUN,$<,+N=300 +SEED=2,roundtrip_seed2)

# Long random run (1500 streams); part of "make regress" only.
test-roundtrip-long: $(BUILD)/tb_aes128_roundtrip.vvp
	$(call RUN,$<,+N=1500 +SEED=3,roundtrip_seed3_long)

# -----------------------------------------------------------------------------
# 7. Golden-vector tests (expected data from tools/aes_ref.py, files in vectors/)
# -----------------------------------------------------------------------------
# vec-<name> runs vectors/<name>.hex exactly as generated (protocol-correct stimulus).
$(VEC_TESTS): vec-%: $(BUILD)/tb_aes128_vec.vvp
	$(call RUN,$<,+VEC=vectors/$*.hex,vec_$*)

# Generic form:  make vec VEC=rand_s1 ARGS="+JUNK=1 +SCR=31 +EARLY=3"
VEC  ?= nist
ARGS ?=
vec: $(BUILD)/tb_aes128_vec.vvp
	$(call RUN,$<,+VEC=vectors/$(VEC).hex $(ARGS),vec_$(VEC)_custom)

# Stress variants: the same golden data, but the stimulus is made hostile. The ORIGINAL design failed
# every one of them; they prove that the inputs matter only on the start clock.
# random junk on all inputs while the DUT is idle
vec-nist-junk: $(BUILD)/tb_aes128_vec.vvp
	$(call RUN,$<,+VEC=vectors/nist.hex +JUNK=1,vec_nist_junk)
# all five inputs overwritten with random values right after the start pulse, plus idle junk
vec-rand_s1-scr: $(BUILD)/tb_aes128_vec.vvp
	$(call RUN,$<,+VEC=vectors/rand_s1.hex +SCR=31 +JUNK=1,vec_rand_s1_scr_all)
# chain_en raised 3 clocks before the first start of every stream
vec-rand_s2-early: $(BUILD)/tb_aes128_vec.vvp
	$(call RUN,$<,+VEC=vectors/rand_s2.hex +EARLY=3,vec_rand_s2_early_chain)
# a stray start 5 clocks after every start: must be rejected (err_busy) and not disturb the result
vec-rand_s3-stray: $(BUILD)/tb_aes128_vec.vvp
	$(call RUN,$<,+VEC=vectors/rand_s3.hex +MID=5,vec_rand_s3_stray_start)
# back-to-back operations with junk on the inputs between them
vec-b2b-junk: $(BUILD)/tb_aes128_vec.vvp
	$(call RUN,$<,+VEC=vectors/b2b.hex +JUNK=1,vec_b2b_junk)

# Long run (2000+ operations) with coverage-hole check, plain and with all stress options together.
vec-long: $(BUILD)/tb_aes128_vec.vvp
	$(call RUN,$<,+VEC=vectors/long.hex +COVCHK=1,vec_long)
vec-long-stress: $(BUILD)/tb_aes128_vec.vvp
	$(call RUN,$<,+VEC=vectors/long.hex +JUNK=1 +SCR=31 +EARLY=2 +COVCHK=1,vec_long_all_stress)

# -----------------------------------------------------------------------------
# 8. Readable per-mode NIST testbenches (simpleTestcase/)
# -----------------------------------------------------------------------------
$(SIMPLE_TESTS): simple-%: $(BUILD)/tb_aes128_%.vvp
	$(call RUN,$<,,simple_$*)

# -----------------------------------------------------------------------------
# 9. Groups
# -----------------------------------------------------------------------------
unit:    ; $(call RUN_GROUP,$(UNIT_TESTS),unit)
random:  ; $(call RUN_GROUP,$(RANDOM_TESTS),random)
vectors: ; $(call RUN_GROUP,$(VEC_TESTS),vectors)
stress:  ; $(call RUN_GROUP,$(VEC_STRESS),stress)
simple:  ; $(call RUN_GROUP,$(SIMPLE_TESTS),simple)
long:    ; $(call RUN_GROUP,$(LONG_TESTS),long)
quick: check-tools
	$(call RUN_GROUP,$(QUICK_TESTS),quick regression)
regress: check-tools
	$(call RUN_GROUP,$(QUICK_TESTS) $(LONG_TESTS),full regression)

# -----------------------------------------------------------------------------
# 10. Formal verification (SymbiYosys + yosys-slang, see formal/)
# -----------------------------------------------------------------------------
#   cd formal            the .sby files use paths relative to formal/
#   sby -f <file>.sby    -f = overwrite the previous result directory
# fv_sbox     S-box and inverse S-box are exact inverses (all 256 values)    ~1 s
# fv_keysched inverse key expansion regenerates the forward round keys, ANY key   ~1-3 min
# fv_ctrl     control FSMs of the whole top: ready/latency/err flags, unbounded (PDR)
formal: ; $(call RUN_GROUP,formal-sbox formal-keysched formal-ctrl,formal)
formal-sbox formal-keysched formal-ctrl: formal-%:
	cd formal && $(SBY) -f fv_$*.sby

# -----------------------------------------------------------------------------
# 11. Mutation check and vector / testbench generation (Python)
# -----------------------------------------------------------------------------
# Each mutant is the RTL with ONE injected defect (plus the original pre-fix RTL from git); the
# testbenches must fail for every one of them. Exit status 1 means a mutant survived.
mutation: check-tools
	$(PYTHON) tools/mutation_check.py
mutation-fast: check-tools
	$(PYTHON) tools/mutation_check.py --fast

# Regenerate the golden vector files (deterministic, fixed seeds) and the readable testbenches.
gen-vectors:
	cd tools && $(PYTHON) gen_vectors.py
gen-simple:
	cd tools && $(PYTHON) gen_simple_tbs.py
# Self-test of the python reference model against FIPS-197 / SP 800-38A / AESAVS vectors.
ref-selftest:
	$(PYTHON) tools/aes_ref.py

# -----------------------------------------------------------------------------
# 12. Clean
# -----------------------------------------------------------------------------
# rm -rf: sim/build (binaries, logs, mutants) and the SymbiYosys result directories / logs.
clean:
	rm -rf $(BUILD) formal/fv_*_run formal/*.log formal/*.err formal/*.out

# -----------------------------------------------------------------------------
# 13. VLSIT-generated batch RTL: independent vectors, simulation and waveforms
# -----------------------------------------------------------------------------
# The testbench is kept outside rtl_vlsit_generated/filelist.f. Golden data comes
# from tools/aes_ref.py through verification/gen_batch_vectors.py, never from RTL.
VLSIT_BUILD       := verification/build
VLSIT_LOG         := verification/logs
VLSIT_TB          := verification/tb_aes128_batch.sv
VLSIT_RTL         := $(wildcard rtl_vlsit_generated/*.sv)
VLSIT_PYTHON      ?= $(PYTHON)
VLSIT_VVP         ?= $(VVP)
CODEX_SKILLS      ?= C:/Users/PC/.codex/skills
WAVEDROM_CONVERTER ?= $(CODEX_SKILLS)/vlsit-wavedrom-waveform/scripts/vlsit_wavedrom_waveform.py
WAVEDROM_SVG      ?= $(CODEX_SKILLS)/vlsit-asic-ip-microspec/scripts/vlsit_waveform_svg.py
SIM_EVIDENCE      ?= $(CODEX_SKILLS)/vlsit-rtl-generator/scripts/vlsit_sim_evidence.py
VLSIT_WAVES       := WF-001_config_success WF-001_config_error WF-002_ecb_batches \
	WF-003_ctr_allocation WF-004_ctr_wrap_rejection WF-005_cbc_decryption \
	WF-006_cbc_encrypt WF-006_cfb WF-006_ofb WF-007_backpressure WF-008_reset_zeroize

.PHONY: vlsit-gen-vectors vlsit-sim vlsit-waveforms vlsit-evidence vlsit-verification

$(VLSIT_BUILD) $(VLSIT_LOG) verification/waveforms_sim:
	mkdir -p $@

vlsit-gen-vectors: | $(VLSIT_BUILD)
	$(VLSIT_PYTHON) verification/gen_batch_vectors.py

$(VLSIT_BUILD)/aes128_batch_lanes4.vvp: $(VLSIT_RTL) rtl_vlsit_generated/filelist.f $(VLSIT_TB) | $(VLSIT_BUILD) $(VLSIT_LOG)
	cd rtl_vlsit_generated && rm -f ../$(VLSIT_BUILD)/aes128_batch_lanes4.vvp && $(IVERILOG) -g2012 -s tb_aes128_batch -o ../$(VLSIT_BUILD)/aes128_batch_lanes4.vvp -c filelist.f ../$(VLSIT_TB) > ../$(VLSIT_LOG)/compile_lanes4.log 2>&1; status=$$?; cd ..; \
	  if [ ! -s $(VLSIT_BUILD)/aes128_batch_lanes4.vvp ]; then cat $(VLSIT_LOG)/compile_lanes4.log; echo "*** VLSIT COMPILE FAILED: LANES=4 (no output binary)"; exit 1; fi; \
	  if [ $$status -ne 0 ]; then echo "WARNING: Icarus returned $$status after writing the VVP; the following regression simulation validates this binary." | tee -a $(VLSIT_LOG)/compile_lanes4.log; fi

$(VLSIT_BUILD)/aes128_batch_lanes1.vvp: $(VLSIT_RTL) rtl_vlsit_generated/filelist.f $(VLSIT_TB) | $(VLSIT_BUILD) $(VLSIT_LOG)
	cd rtl_vlsit_generated && rm -f ../$(VLSIT_BUILD)/aes128_batch_lanes1.vvp && $(IVERILOG) -g2012 -D TB_LANES=1 -s tb_aes128_batch -o ../$(VLSIT_BUILD)/aes128_batch_lanes1.vvp -c filelist.f ../$(VLSIT_TB) > ../$(VLSIT_LOG)/compile_lanes1.log 2>&1; status=$$?; cd ..; \
	  if [ ! -s $(VLSIT_BUILD)/aes128_batch_lanes1.vvp ]; then cat $(VLSIT_LOG)/compile_lanes1.log; echo "*** VLSIT COMPILE FAILED: LANES=1 (no output binary)"; exit 1; fi; \
	  if [ $$status -ne 0 ]; then echo "WARNING: Icarus returned $$status after writing the VVP; the following regression simulation validates this binary." | tee -a $(VLSIT_LOG)/compile_lanes1.log; fi

vlsit-sim: vlsit-gen-vectors $(VLSIT_BUILD)/aes128_batch_lanes1.vvp $(VLSIT_BUILD)/aes128_batch_lanes4.vvp | $(VLSIT_LOG)
	$(VLSIT_VVP) $(VLSIT_BUILD)/aes128_batch_lanes1.vvp +MODE=regression > $(VLSIT_LOG)/run_lanes1.log 2>&1 \
	  || { cat $(VLSIT_LOG)/run_lanes1.log; echo "*** VLSIT SIMULATION FAILED: LANES=1"; exit 1; }
	$(VLSIT_VVP) $(VLSIT_BUILD)/aes128_batch_lanes4.vvp +MODE=regression > $(VLSIT_LOG)/run_lanes4.log 2>&1 \
	  || { cat $(VLSIT_LOG)/run_lanes4.log; echo "*** VLSIT SIMULATION FAILED: LANES=4"; exit 1; }
	@grep '^SUMMARY' $(VLSIT_LOG)/run_lanes1.log | tail -n 1
	@grep '^SUMMARY' $(VLSIT_LOG)/run_lanes4.log | tail -n 1
	@grep -F 'assertion failures: 0, assertions never exercised: 0' $(VLSIT_LOG)/run_lanes1.log | tail -n 1
	@grep -F 'assertion failures: 0, assertions never exercised: 0' $(VLSIT_LOG)/run_lanes4.log | tail -n 1

vlsit-waveforms: vlsit-gen-vectors $(VLSIT_BUILD)/aes128_batch_lanes4.vvp | $(VLSIT_LOG) verification/waveforms_sim
	@set -e; for wf in $(VLSIT_WAVES); do \
	  $(VLSIT_VVP) $(VLSIT_BUILD)/aes128_batch_lanes4.vvp +MODE=wave +WF=$$wf +DUMP=verification/waveforms_sim/$$wf.vcd > $(VLSIT_LOG)/$$wf.log 2>&1 || { cat $(VLSIT_LOG)/$$wf.log; exit 1; }; \
	  grep '^SUMMARY' $(VLSIT_LOG)/$$wf.log | tail -n 1; \
	done
	$(VLSIT_PYTHON) verification/render_waveforms.py --converter "$(WAVEDROM_CONVERTER)" --renderer "$(WAVEDROM_SVG)"

vlsit-evidence: vlsit-waveforms
	$(VLSIT_PYTHON) "$(SIM_EVIDENCE)" check doc/AES128_ECB_CBC_CFB_OFB_CTR_Design_Specification.md verification/waveforms_sim --cdc no

vlsit-verification: ref-selftest vlsit-sim vlsit-evidence

# =============================================================================================
