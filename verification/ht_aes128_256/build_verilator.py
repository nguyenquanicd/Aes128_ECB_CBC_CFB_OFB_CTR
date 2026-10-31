#!/usr/bin/env python3
"""Build the timed Verilator testbench, with a direct-C++ fallback for Windows sandboxes."""

from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
RTL_DIR = HERE.parents[1] / "rtl" / "ht_aes128_256"


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--lanes", type=int, choices=(1, 4), required=True)
    parser.add_argument("--verilator", default="verilator")
    parser.add_argument("--cxx", default="g++")
    parser.add_argument("--build-dir", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    build_dir = (HERE / args.build_dir).resolve()
    output = build_dir / args.output
    build_dir.mkdir(parents=True, exist_ok=True)
    log_path = HERE / "logs" / f"verilator_build_n{args.lanes}.log"
    log_path.parent.mkdir(parents=True, exist_ok=True)

    verilator = shutil.which(args.verilator) or args.verilator
    verilator_root = os.environ.get("VERILATOR_ROOT")
    if not verilator_root:
        candidate = Path(verilator).resolve().parent.parent / "share" / "verilator"
        verilator_root = str(candidate)
    env = os.environ.copy()
    env["VERILATOR_ROOT"] = verilator_root

    command = [
        verilator, "--binary", "--trace", "--timing",
        "--top-module", "tb_aes128_256_batch", "-Wno-fatal",
        "--Mdir", str(build_dir), "-o", output.name,
    ]
    if args.lanes == 1:
        command.append("-DTB_LANES=1")
    command.extend(["-f", "filelist.f", str(HERE / "tb_aes128_256_batch.sv")])

    with log_path.open("w", encoding="utf-8") as log:
        result = subprocess.run(command, cwd=RTL_DIR, env=env, stdout=log,
                                stderr=subprocess.STDOUT, check=False)
        if result.returncode == 0 and output.exists():
            log.write(f"PASS: Verilator built {output}\n")
            print(f"PASS: Verilator built {output}")
            return

        # Verilator emits all generated C++ before invoking make; some managed
        # Windows sandboxes deny MSYS2's named-object creation. Compile those
        # exact generated sources directly when that specific build step fails.
        main_cpp = build_dir / "Vtb_aes128_256_batch__main.cpp"
        known_sandbox_error = "NtCreateDirectoryObject" in log_path.read_text(
            encoding="utf-8", errors="replace")
        if not (main_cpp.exists() and known_sandbox_error):
            raise SystemExit(f"Verilator build failed; see {log_path}")

        cxx = shutil.which(args.cxx) or args.cxx
        cxx_path = Path(cxx)
        if not cxx_path.exists() and not shutil.which(args.cxx):
            raise SystemExit(f"C++ compiler not found: {args.cxx}")
        include_dir = Path(verilator_root) / "include"
        generated_cpp = sorted(build_dir.glob("*.cpp"))
        runtime_cpp = [include_dir / name for name in (
            "verilated.cpp", "verilated_timing.cpp", "verilated_threads.cpp",
            "verilated_vcd_c.cpp")]
        if not generated_cpp or not all(path.exists() for path in runtime_cpp):
            raise SystemExit(f"Verilator did not generate the expected C++ sources; see {log_path}")

        compile_command = [
            cxx, "-std=gnu++20", "-O0", "-fcoroutines",
            "-DVERILATOR=1", "-DVM_COVERAGE=0", "-DVM_SC=0", "-DVM_TIMING=1",
            "-DVM_TRACE=1", "-DVM_TRACE_VCD=1", "-DVM_TRACE_FST=0",
            "-DVM_TRACE_SAIF=0", "-DVM_VPI=0", "-DVL_TIME_CONTEXT",
            "-faligned-new", "-fcf-protection=none", "-pthread",
            f"-I{build_dir}", f"-I{include_dir}", f"-I{include_dir / 'vltstd'}",
            *map(str, generated_cpp), *map(str, runtime_cpp),
            "-lpthread", "-latomic", "-o", str(output),
        ]
        tool_bin = Path(verilator).resolve().parent
        env["PATH"] = os.pathsep.join([str(tool_bin), str(include_dir.parent),
                                      str(cxx_path.parent), env.get("PATH", "")])
        log.write("\nDirect C++ fallback after the Windows MSYS2 make sandbox error.\n")
        log.flush()
        result = subprocess.run(compile_command, cwd=RTL_DIR, env=env, stdout=log,
                                stderr=subprocess.STDOUT, check=False)
        if result.returncode or not output.exists():
            raise SystemExit(f"Direct C++ fallback failed; see {log_path}")
        log.write(f"PASS: direct C++ build produced {output}\n")
    print(f"PASS: direct C++ build produced {output}")


if __name__ == "__main__":
    main()
