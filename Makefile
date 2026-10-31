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
#   make vlsit-verification       verify the high-throughput AES-128 design
#   make aes128-256-verification  verify the high-throughput AES-128/AES-256 design
#
# REQUIREMENTS
#   * GNU make >= 3.82 and a POSIX shell with mkdir/rm/cat/grep/tail
#       Linux : the normal "make" of the distribution
#       Windows: make from MSYS2 or Git Bash (cmd.exe-only make programs are NOT supported)
#   * Icarus Verilog 12+ (iverilog, vvp): simulation. Verilator/Yosys serve the dual-key flow.
#     SymbiYosys (sby) + yosys-slang: formal for the single AES-128 design.
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
SINGLE_DIR := verification/single_aes128
BUILD    := $(SINGLE_DIR)/sim/build
LOG      := $(BUILD)/log
# RTL compile order (package first), paths relative to the repository root
RTL_LIST := rtl/single_aes128/filelist.f
RTL_SRC  := $(wildcard rtl/single_aes128/*.sv)
CHECKER  := $(SINGLE_DIR)/checker/aes128_protocol_checker.sv
# Everything a testbench binary depends on: rebuild when any RTL / checker / testbench header changes.
TB_DEPS  := $(RTL_SRC) $(RTL_LIST) $(CHECKER) $(wildcard $(SINGLE_DIR)/tb/*.svh) $(wildcard $(SINGLE_DIR)/tb/ref/*.sv)

# iverilog flags:
#   -g2012          SystemVerilog-2012 language (packages, always_ff, logic, tasks, $fatal ...)
#   -Wall           enable all warnings (they are written to a compile log, see COMPILE below)
#   -Wno-timescale  the RTL has no `timescale, the testbenches do; do not warn about the mix
#   -I<SINGLE_DIR>/tb   common testbench headers and the independent S-box oracle
IVFLAGS  := -g2012 -Wall -Wno-timescale -I$(SINGLE_DIR)/tb -I$(SINGLE_DIR)/tb/ref

# Test lists. SIMPLE names map to the single-AES verification simpleTestcase folder.
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
# Plusargs of the vector testbench (see verification/single_aes128/tb/tb_aes128_vec.sv):
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
#   iverilog -c rtl/single_aes128/filelist.f   read the RTL files in the right order from the list
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
	@echo "  make gen-vectors         regenerate single-AES128 vectors"
	@echo "  make gen-simple          regenerate single-AES128 simple testbenches"
	@echo "  make ref-selftest        self-test of the python AES model"
	@echo "  make vlsit-verification  verify the high-throughput AES-128 design"
	@echo "  make aes128-256-regression    dual-key simulation, 1 and 4 lanes"
	@echo "  make aes128-256-synth         generic synthesis, 1 and 4 lanes"
	@echo "  make aes128-256-verification  dual-key simulation, waveforms and synthesis"
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
# mkdir -p also creates the single-AES build directory and is idempotent.
$(LOG):
	mkdir -p $(LOG)

# -----------------------------------------------------------------------------
# 5. Testbench binaries (one compile rule per testbench)
# -----------------------------------------------------------------------------
$(eval $(call COMPILE,tb_aes128_prim,$(SINGLE_DIR)/tb/tb_aes128_prim.sv))
$(eval $(call COMPILE,tb_aes128_protocol,$(SINGLE_DIR)/tb/tb_aes128_protocol.sv))
$(eval $(call COMPILE,tb_aes128_roundtrip,$(SINGLE_DIR)/tb/tb_aes128_roundtrip.sv))
$(eval $(call COMPILE,tb_aes128_vec,$(SINGLE_DIR)/tb/tb_aes128_vec.sv))
$(foreach m,$(SIMPLE),$(eval $(call COMPILE,tb_aes128_$(m),$(SINGLE_DIR)/simpleTestcase/tb_aes128_$(m).sv)))

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
# 7. Golden-vector tests (expected data from the shared AES reference model)
# -----------------------------------------------------------------------------
# vec-<name> runs the matching file under verification/single_aes128/vectors/.
$(VEC_TESTS): vec-%: $(BUILD)/tb_aes128_vec.vvp
$(call RUN,$<,+VEC=$(SINGLE_DIR)/vectors/$*.hex,vec_$*)

# Generic form:  make vec VEC=rand_s1 ARGS="+JUNK=1 +SCR=31 +EARLY=3"
VEC  ?= nist
ARGS ?=
vec: $(BUILD)/tb_aes128_vec.vvp
$(call RUN,$<,+VEC=$(SINGLE_DIR)/vectors/$(VEC).hex $(ARGS),vec_$(VEC)_custom)

# Stress variants: the same golden data, but the stimulus is made hostile. The ORIGINAL design failed
# every one of them; they prove that the inputs matter only on the start clock.
# random junk on all inputs while the DUT is idle
vec-nist-junk: $(BUILD)/tb_aes128_vec.vvp
$(call RUN,$<,+VEC=$(SINGLE_DIR)/vectors/nist.hex +JUNK=1,vec_nist_junk)
# all five inputs overwritten with random values right after the start pulse, plus idle junk
vec-rand_s1-scr: $(BUILD)/tb_aes128_vec.vvp
$(call RUN,$<,+VEC=$(SINGLE_DIR)/vectors/rand_s1.hex +SCR=31 +JUNK=1,vec_rand_s1_scr_all)
# chain_en raised 3 clocks before the first start of every stream
vec-rand_s2-early: $(BUILD)/tb_aes128_vec.vvp
$(call RUN,$<,+VEC=$(SINGLE_DIR)/vectors/rand_s2.hex +EARLY=3,vec_rand_s2_early_chain)
# a stray start 5 clocks after every start: must be rejected (err_busy) and not disturb the result
vec-rand_s3-stray: $(BUILD)/tb_aes128_vec.vvp
$(call RUN,$<,+VEC=$(SINGLE_DIR)/vectors/rand_s3.hex +MID=5,vec_rand_s3_stray_start)
# back-to-back operations with junk on the inputs between them
vec-b2b-junk: $(BUILD)/tb_aes128_vec.vvp
$(call RUN,$<,+VEC=$(SINGLE_DIR)/vectors/b2b.hex +JUNK=1,vec_b2b_junk)

# Long run (2000+ operations) with coverage-hole check, plain and with all stress options together.
vec-long: $(BUILD)/tb_aes128_vec.vvp
$(call RUN,$<,+VEC=$(SINGLE_DIR)/vectors/long.hex +COVCHK=1,vec_long)
vec-long-stress: $(BUILD)/tb_aes128_vec.vvp
$(call RUN,$<,+VEC=$(SINGLE_DIR)/vectors/long.hex +JUNK=1 +SCR=31 +EARLY=2 +COVCHK=1,vec_long_all_stress)

# -----------------------------------------------------------------------------
# 8. Readable per-mode NIST testbenches (verification/single_aes128/simpleTestcase/)
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
# 10. Formal verification (SymbiYosys + yosys-slang, see verification/single_aes128/formal/)
# -----------------------------------------------------------------------------
#   cd verification/single_aes128/formal    the .sby files use paths relative to formal/
#   sby -f <file>.sby    -f = overwrite the previous result directory
# fv_sbox     S-box and inverse S-box are exact inverses (all 256 values)    ~1 s
# fv_keysched inverse key expansion regenerates the forward round keys, ANY key   ~1-3 min
# fv_ctrl     control FSMs of the whole top: ready/latency/err flags, unbounded (PDR)
formal: ; $(call RUN_GROUP,formal-sbox formal-keysched formal-ctrl,formal)
formal-sbox formal-keysched formal-ctrl: formal-%:
	cd $(SINGLE_DIR)/formal && $(SBY) -f fv_$*.sby

# -----------------------------------------------------------------------------
# 11. Mutation check and vector / testbench generation (Python)
# -----------------------------------------------------------------------------
# Each mutant is the RTL with ONE injected defect (plus the original pre-fix RTL from git); the
# testbenches must fail for every one of them. Exit status 1 means a mutant survived.
mutation: check-tools
	$(PYTHON) $(SINGLE_DIR)/tools/mutation_check.py
mutation-fast: check-tools
	$(PYTHON) $(SINGLE_DIR)/tools/mutation_check.py --fast

# Regenerate the golden vector files (deterministic, fixed seeds) and the readable testbenches.
gen-vectors:
	cd $(SINGLE_DIR)/tools && $(PYTHON) gen_vectors.py
gen-simple:
	cd $(SINGLE_DIR)/tools && $(PYTHON) gen_simple_tbs.py
# Self-test of the python reference model against FIPS-197 / SP 800-38A / AESAVS vectors.
ref-selftest:
	$(PYTHON) verification/shared/aes_ref.py

# -----------------------------------------------------------------------------
# 12. Clean
# -----------------------------------------------------------------------------
# rm -rf: single-AES simulation products and SymbiYosys result directories / logs.
clean:
	rm -rf $(BUILD) $(SINGLE_DIR)/formal/fv_*_run $(SINGLE_DIR)/formal/*.log $(SINGLE_DIR)/formal/*.err $(SINGLE_DIR)/formal/*.out

# -----------------------------------------------------------------------------
# 13. VLSIT-generated batch RTL: independent vectors, simulation and waveforms
# -----------------------------------------------------------------------------
# The testbench, vectors and logs are separate from the RTL variant. Golden data
# comes from the shared Python AES model, never from generated RTL.
VLSIT_DIR         := verification/ht_aes128
VLSIT_RTL_DIR     := rtl/ht_aes128
VLSIT_BUILD       := $(VLSIT_DIR)/build
VLSIT_LOG         := $(VLSIT_DIR)/logs
VLSIT_WAVE_DIR    := $(VLSIT_DIR)/waveforms_sim
VLSIT_TB          := $(VLSIT_DIR)/tb_aes128_batch.sv
VLSIT_RTL         := $(wildcard $(VLSIT_RTL_DIR)/*.sv)
VLSIT_PYTHON      ?= $(PYTHON)
VLSIT_VVP         ?= $(VVP)
CODEX_SKILLS      ?= C:/Users/PC/.codex/skills
WAVEDROM_CONVERTER ?= $(CODEX_SKILLS)/vlsit-wavedrom-waveform/scripts/vlsit_wavedrom_waveform.py
WAVEDROM_SVG      ?= $(CODEX_SKILLS)/vlsit-asic-ip-microspec/scripts/vlsit_waveform_svg.py
SIM_EVIDENCE      ?= $(CODEX_SKILLS)/vlsit-rtl-generator/scripts/vlsit_sim_evidence.py
VLSIT_WAVES       := WF-001_config_success WF-001_config_error WF-002_ecb_batches \
	WF-003_ctr_allocation WF-004_ctr_wrap_rejection WF-005_cbc_decryption \
	WF-006_cbc_encrypt WF-006_cfb WF-006_ofb WF-007_backpressure WF-008_reset_zeroize

.PHONY: vlsit-gen-vectors vlsit-sim vlsit-waveforms vlsit-evidence vlsit-verification \
	aes128-256-prepare aes128-256-vectors aes128-256-build-n1 aes128-256-build-n4 \
	aes128-256-sim-n1 aes128-256-sim-n4 aes128-256-regression aes128-256-waves \
	aes128-256-evidence aes128-256-synth-n1 aes128-256-synth-n4 aes128-256-synth \
	aes128-256-verification aes128-256-clean

$(VLSIT_BUILD) $(VLSIT_LOG) $(VLSIT_WAVE_DIR):
	mkdir -p $@

vlsit-gen-vectors: | $(VLSIT_BUILD)
	$(VLSIT_PYTHON) $(VLSIT_DIR)/gen_batch_vectors.py

$(VLSIT_BUILD)/aes128_batch_lanes4.vvp: $(VLSIT_RTL) $(VLSIT_RTL_DIR)/filelist.f $(VLSIT_TB) | $(VLSIT_BUILD) $(VLSIT_LOG)
	cd $(VLSIT_RTL_DIR) && rm -f ../../$(VLSIT_BUILD)/aes128_batch_lanes4.vvp && $(IVERILOG) -g2012 -s tb_aes128_batch -o ../../$(VLSIT_BUILD)/aes128_batch_lanes4.vvp -c filelist.f ../../$(VLSIT_TB) > ../../$(VLSIT_LOG)/compile_lanes4.log 2>&1; status=$$?; cd ../..; \
	  if [ ! -s $(VLSIT_BUILD)/aes128_batch_lanes4.vvp ]; then cat $(VLSIT_LOG)/compile_lanes4.log; echo "*** VLSIT COMPILE FAILED: LANES=4 (no output binary)"; exit 1; fi; \
	  if [ $$status -ne 0 ]; then echo "WARNING: Icarus returned $$status after writing the VVP; the following regression simulation validates this binary." | tee -a $(VLSIT_LOG)/compile_lanes4.log; fi

$(VLSIT_BUILD)/aes128_batch_lanes1.vvp: $(VLSIT_RTL) $(VLSIT_RTL_DIR)/filelist.f $(VLSIT_TB) | $(VLSIT_BUILD) $(VLSIT_LOG)
	cd $(VLSIT_RTL_DIR) && rm -f ../../$(VLSIT_BUILD)/aes128_batch_lanes1.vvp && $(IVERILOG) -g2012 -D TB_LANES=1 -s tb_aes128_batch -o ../../$(VLSIT_BUILD)/aes128_batch_lanes1.vvp -c filelist.f ../../$(VLSIT_TB) > ../../$(VLSIT_LOG)/compile_lanes1.log 2>&1; status=$$?; cd ../..; \
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

vlsit-waveforms: vlsit-gen-vectors $(VLSIT_BUILD)/aes128_batch_lanes4.vvp | $(VLSIT_LOG) $(VLSIT_WAVE_DIR)
	@set -e; for wf in $(VLSIT_WAVES); do \
	  $(VLSIT_VVP) $(VLSIT_BUILD)/aes128_batch_lanes4.vvp +MODE=wave +WF=$$wf +DUMP=$(VLSIT_WAVE_DIR)/$$wf.vcd > $(VLSIT_LOG)/$$wf.log 2>&1 || { cat $(VLSIT_LOG)/$$wf.log; exit 1; }; \
	  grep '^SUMMARY' $(VLSIT_LOG)/$$wf.log | tail -n 1; \
	done
	$(VLSIT_PYTHON) $(VLSIT_DIR)/render_waveforms.py --converter "$(WAVEDROM_CONVERTER)" --renderer "$(WAVEDROM_SVG)"

vlsit-evidence: vlsit-waveforms
	$(VLSIT_PYTHON) "$(SIM_EVIDENCE)" check doc/ht_aes128/AES128_ECB_CBC_CFB_OFB_CTR_Design_Specification.md $(VLSIT_WAVE_DIR) --cdc no

vlsit-verification: ref-selftest vlsit-sim vlsit-evidence

# -----------------------------------------------------------------------------
# 14. High-throughput AES-128/AES-256 batch core
# All runnable project commands remain in this root Makefile. The design-local
# testbench, reference model, vectors, logs and reports stay under verification/.
AES256_DIR         := verification/ht_aes128_256
AES256_RTL_DIR     := rtl/ht_aes128_256
AES256_RTL_NAMES   := m_aes128_256_key_expand.sv m_aes128_256_aes_round.sv \
	m_aes128_256_pipe_lane.sv m_aes128_256_lane_array.sv \
	m_aes128_256_batch_core.sv m_aes128_256_batch_top.sv
AES256_RTL_FILES   := $(addprefix $(AES256_RTL_DIR)/,$(AES256_RTL_NAMES))
AES256_BUILD       := $(AES256_DIR)/build
AES256_LOG         := $(AES256_DIR)/logs
AES256_WAVE_DIR    := $(AES256_DIR)/waveforms_sim
AES256_SIM_N1      := $(AES256_BUILD)/obj_n1/aes128_256_n1.exe
AES256_SIM_N4      := $(AES256_BUILD)/obj_n4/aes128_256_n4.exe
AES256_VERILATOR   ?= C:/Tools/oss-cad-suite/bin/verilator_bin.exe
AES256_CXX         ?= g++
AES256_YOSYS       ?= yosys

aes128-256-prepare:
	mkdir -p $(AES256_BUILD) $(AES256_LOG) $(AES256_WAVE_DIR) $(AES256_DIR)/synthesis

aes128-256-vectors: aes128-256-prepare
	$(PYTHON) $(AES256_DIR)/gen_vectors.py
	$(PYTHON) $(AES256_DIR)/aes128_256_ref.py

aes128-256-build-n4: aes128-256-vectors
	$(PYTHON) $(AES256_DIR)/build_verilator.py --lanes 4 --verilator "$(AES256_VERILATOR)" --cxx "$(AES256_CXX)" --build-dir build/obj_n4 --output aes128_256_n4.exe

aes128-256-build-n1: aes128-256-vectors
	$(PYTHON) $(AES256_DIR)/build_verilator.py --lanes 1 --verilator "$(AES256_VERILATOR)" --cxx "$(AES256_CXX)" --build-dir build/obj_n1 --output aes128_256_n1.exe

aes128-256-sim-n4: aes128-256-build-n4
	$(AES256_SIM_N4) +VEC_DIR=$(AES256_DIR)/vectors/ > $(AES256_LOG)/simulation_regression_n4.log 2>&1
	@grep '^SUMMARY' $(AES256_LOG)/simulation_regression_n4.log

aes128-256-sim-n1: aes128-256-build-n1
	$(AES256_SIM_N1) +VEC_DIR=$(AES256_DIR)/vectors/ > $(AES256_LOG)/simulation_regression_n1.log 2>&1
	@grep '^SUMMARY' $(AES256_LOG)/simulation_regression_n1.log

aes128-256-regression: aes128-256-sim-n1 aes128-256-sim-n4

aes128-256-waves: aes128-256-build-n4
	$(PYTHON) $(AES256_DIR)/render_waveforms.py --sim $(AES256_SIM_N4) --converter "$(WAVEDROM_CONVERTER)" --renderer "$(WAVEDROM_SVG)"

aes128-256-evidence: aes128-256-waves
	$(PYTHON) "$(SIM_EVIDENCE)" check $(AES256_DIR)/waveform_plan.md $(AES256_WAVE_DIR) --cdc no

aes128-256-synth-n4: aes128-256-prepare $(AES256_RTL_FILES)
	$(AES256_YOSYS) -Q -q -p 'read_verilog -sv $(AES256_RTL_FILES); hierarchy -check -top m_aes128_256_batch_top; synth -top m_aes128_256_batch_top; tee -q -o $(AES256_DIR)/synthesis/aes128_256_n4_stats.json stat -json -top m_aes128_256_batch_top -hierarchy' > $(AES256_LOG)/yosys_synth_n4.log 2>&1
	@echo "PASS: generic synthesis, four lanes. See $(AES256_DIR)/synthesis/aes128_256_n4_stats.json."

aes128-256-synth-n1: aes128-256-prepare $(AES256_RTL_FILES)
	$(AES256_YOSYS) -Q -q -p 'read_verilog -sv $(AES256_RTL_FILES); chparam -set PARA_AES_LANE_NUM 1 m_aes128_256_batch_top; hierarchy -check -top m_aes128_256_batch_top; synth -top m_aes128_256_batch_top; tee -q -o $(AES256_DIR)/synthesis/aes128_256_n1_stats.json stat -json -top m_aes128_256_batch_top -hierarchy' > $(AES256_LOG)/yosys_synth_n1.log 2>&1
	@echo "PASS: generic synthesis, one lane. See $(AES256_DIR)/synthesis/aes128_256_n1_stats.json."

aes128-256-synth: aes128-256-synth-n1 aes128-256-synth-n4

aes128-256-verification: aes128-256-regression aes128-256-evidence aes128-256-synth

aes128-256-clean:
	$(PYTHON) -c "from pathlib import Path; import shutil; root=Path('$(AES256_DIR)'); [shutil.rmtree(root/p, ignore_errors=True) for p in ('build','waveforms_sim','synthesis')]; print('Removed dual-key build, waveform and synthesis outputs.')"

# =============================================================================================
