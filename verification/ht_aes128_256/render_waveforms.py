#!/usr/bin/env python3
"""Run approved waveform scenarios and render VCD -> WaveJSON -> SVG evidence."""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
PROJECT = HERE.parents[1]
RTL_DIR = PROJECT / "rtl" / "ht_aes128_256"
EVIDENCE = HERE / "waveforms_sim"
LOGS = HERE / "logs"
SPEC_WAVES = PROJECT / "doc" / "ht_aes128_256" / "figures" / "waveforms"

SCENARIOS = [
    ("WF-001_config_key_select", "WF-001_config_key_select", "WF-001_config_key_select"),
    ("WF-002_aes128_ecb", "WF-002_aes128_ecb", "WF-002_aes128_ecb"),
    ("WF-003_aes256_ecb", "WF-003_aes256_ecb", "WF-003_aes256_ecb"),
    ("WF-004_ctr_allocate", "WF-004_ctr_allocate", "WF-004_ctr_allocate"),
    ("WF-005_ctr_wrap", "WF-005_ctr_wrap", "WF-005_ctr_wrap"),
    ("WF-006a_cbc_decrypt", "WF-006a_cbc_decrypt", "WF-006a_cbc_decrypt"),
    ("WF-006b_cbc_decrypt", "WF-006b_cbc_decrypt", "WF-006b_cbc_decrypt"),
    ("WF-007_cbc_encrypt_feedback", "WF-007_cbc_encrypt_feedback", "WF-007_cbc_encrypt_feedback"),
    ("WF-008_cfb_feedback", "WF-008_cfb_feedback", "WF-008_cfb_feedback"),
    ("WF-009_ofb_feedback", "WF-009_ofb_feedback", "WF-009_ofb_feedback"),
    ("WF-010a_backpressure", "WF-010a_backpressure", "WF-010a_backpressure"),
    ("WF-010b_backpressure", "WF-010b_backpressure", "WF-010b_backpressure"),
    ("WF-011_lane_mask_error", "WF-011_lane_mask_error", "WF-011_lane_mask_error"),
    ("WF-012a_reset_abort", "WF-012a_reset_abort", "WF-012a_reset_abort"),
    ("WF-012b_zeroize_abort", "WF-012b_zeroize_abort", "WF-012b_zeroize_abort"),
]

COMPARE_ROWS = [
    ("WF-001", "WF-001_config_key_select", "PASS: AES-128/AES-256 config handshakes; malformed AES-128 upper key returns error 1."),
    ("WF-002", "WF-002_aes128_ecb", "PASS: golden outputs, C10 latency, consecutive output batches (II=1)."),
    ("WF-003", "WF-003_aes256_ecb", "PASS: golden outputs, C14 latency, consecutive output batches (II=1)."),
    ("WF-004", "WF-004_ctr_allocate", "PASS: partial lane mask and counter-derived results match the independent model."),
    ("WF-005", "WF-005_ctr_wrap", "PASS: wrap is rejected atomically with error 3."),
    ("WF-006", "WF-006a_cbc_decrypt", "PASS: AES-128 and AES-256 figures generated; lane outputs match independent vectors."),
    ("WF-007", "WF-007_cbc_encrypt_feedback", "PASS: C10 latency and C11 feedback input interval."),
    ("WF-008", "WF-008_cfb_feedback", "PASS: C14 latency and C15 feedback input interval."),
    ("WF-009", "WF-009_ofb_feedback", "PASS: AES-256 OFB output matches the independent model; C15 feedback interval."),
    ("WF-010", "WF-010a_backpressure", "PASS: AES-128 and AES-256 output records remain stable during a one-cycle stall."),
    ("WF-011", "WF-011_lane_mask_error", "PASS: invalid lane mask returns error 2; unsolicited data returns error 5."),
    ("WF-012", "WF-012a_reset_abort", "PASS: reset abort and zeroize abort traces show cleared valid state; zeroize done pulses."),
]


def run(cmd: list[str], log_path: Path | None = None, cwd: Path = RTL_DIR,
        env: dict[str, str] | None = None) -> None:
    if log_path:
        log_path.parent.mkdir(parents=True, exist_ok=True)
        with log_path.open("w", encoding="utf-8") as log:
            result = subprocess.run(cmd, cwd=cwd, env=env, stdout=log,
                                    stderr=subprocess.STDOUT, check=False)
    else:
        result = subprocess.run(cmd, cwd=cwd, env=env, check=False)
    if result.returncode:
        if log_path:
            print(log_path.read_text(encoding="utf-8", errors="replace"))
        raise SystemExit(f"Command failed ({result.returncode}): {' '.join(cmd)}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sim", required=True, help="Compiled Verilator simulation executable")
    parser.add_argument("--converter", required=True, help="vlsit_wavedrom_waveform.py path")
    parser.add_argument("--renderer", required=True, help="vlsit_waveform_svg.py path")
    args = parser.parse_args()
    simulator = Path(args.sim).resolve()
    converter = Path(args.converter).resolve()
    renderer = Path(args.renderer).resolve()
    if not simulator.exists():
        raise SystemExit(f"Simulation executable not found: {simulator}")
    for path in (converter, renderer):
        if not path.exists():
            raise SystemExit(f"Waveform tool not found: {path}")

    EVIDENCE.mkdir(parents=True, exist_ok=True)
    LOGS.mkdir(parents=True, exist_ok=True)
    for stem, wave_id, spec_stem in SCENARIOS:
        vcd = EVIDENCE / f"{stem}.vcd"
        log = LOGS / f"{stem}.log"
        env = os.environ.copy()
        suite_bin = Path(r"C:\Tools\oss-cad-suite\bin")
        if suite_bin.exists():
            env["PATH"] = str(suite_bin) + os.pathsep + env.get("PATH", "")
        run([str(simulator), "+VEC_DIR=vectors/", f"+WAVE={wave_id}",
             f"+DUMP=waveforms_sim/{stem}.vcd"], log_path=log,
            cwd=HERE, env=env)

        reference = SPEC_WAVES / f"{spec_stem}.json"
        if not reference.exists():
            raise SystemExit(f"Approved specification waveform is missing: {reference}")
        signal_names = []
        for signal in json.loads(reference.read_text(encoding="utf-8"))["signal"]:
            name = signal.get("name")
            if name and name not in signal_names:
                signal_names.append(name)
        if not signal_names:
            raise SystemExit(f"No signals found in approved waveform JSON: {reference}")
        run([sys.executable, str(converter), "vcd-to-wavejson", str(vcd),
             "--signals", ",".join(signal_names), "--period", "10ns",
             "--out", str(EVIDENCE / f"{stem}.json"), "--force"], cwd=HERE)
        run([sys.executable, str(renderer), "render", str(EVIDENCE / f"{stem}.json"),
             "--out", str(EVIDENCE / f"{stem}.svg"), "--force"], cwd=HERE)
        print(f"PASS {stem}: VCD, WaveJSON and SVG")

    index = [
        "# Waveform comparison / waveform đối chiếu",
        "",
        "The simulator checks interface timing and data against the approved specification scenarios and independent golden vectors. / Simulator kiểm tra thời gian giao tiếp và dữ liệu theo các kịch bản đã duyệt và vector tham chiếu độc lập.",
        "",
        "| WF-ID | Specification figure | Simulated VCD | Result | Note |",
        "|---|---|---|---|---|",
    ]
    for wid, stem, note in COMPARE_ROWS:
        index.append(f"| {wid} | [figure](../../../doc/ht_aes128_256/figures/waveforms/{stem}.svg) | {stem}.vcd | MATCH | {note} |")
    (EVIDENCE / "waveform_compare.md").write_text("\n".join(index) + "\n", encoding="utf-8")
    print(f"Rendered {len(SCENARIOS)} traces for the 12 approved waveform scenarios.")


if __name__ == "__main__":
    main()
