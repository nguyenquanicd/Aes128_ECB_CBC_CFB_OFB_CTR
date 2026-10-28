"""Convert simulator VCDs into reviewable WaveJSON and SVG evidence."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "verification" / "waveforms_sim"
CLK = "tb_aes128_batch.i_clk_core"
PORT = "tb_aes128_batch."
CORE = PORT + "dut.u_aes128_batch_core."

WAVE_SIGNALS = {
    "WF-001_config_success": [],
    "WF-001_config_error": [],
    "WF-002_ecb_batches": [],
    "WF-003_ctr_allocation": [
        CORE + "reg_ctr_base", CORE + "w_array_input_data",
    ],
    "WF-004_ctr_wrap_rejection": [CORE + "w_ctr_wrap", CORE + "w_batch_err_fire"],
    "WF-005_cbc_decryption": [CORE + "w_array_input_sideband"],
    "WF-006_cbc_encrypt": [CORE + "reg_feedback", CORE + "w_feedback_for_input"],
    "WF-006_cfb": [CORE + "reg_feedback", CORE + "w_feedback_for_input"],
    "WF-006_ofb": [CORE + "reg_feedback", CORE + "w_feedback_for_input"],
    "WF-007_backpressure": [],
    "WF-008_reset_zeroize": [],
}


def run(command: list[str]) -> None:
    print("+", " ".join(command), flush=True)
    subprocess.run(command, cwd=ROOT, check=True)


def find_signal(items: list[object], name: str) -> dict[str, object] | None:
    for item in items:
        if isinstance(item, dict):
            if item.get("name") == name:
                return item
        elif isinstance(item, list):
            found = find_signal(item, name)
            if found is not None:
                return found
    return None


def names_in(items: list[object]) -> list[str]:
    names: list[str] = []
    for item in items:
        if isinstance(item, dict) and "name" in item:
            names.append(str(item["name"]))
        elif isinstance(item, list):
            names.extend(names_in(item[1:] if item and isinstance(item[0], str) else item))
    return names


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--converter", required=True, help="Bundled vlsit_wavedrom_waveform.py")
    parser.add_argument("--renderer", required=True, help="Bundled vlsit_waveform_svg.py")
    args = parser.parse_args()

    for name, signals in WAVE_SIGNALS.items():
        vcd = OUT / f"{name}.vcd"
        wavejson = OUT / f"{name}.json"
        svg = OUT / f"{name}.svg"
        spec_json = ROOT / "doc" / "waveforms" / f"{name}.json"
        spec_names = names_in(json.loads(spec_json.read_text(encoding="utf-8"))["signal"])
        vcd_signals = [PORT + signal for signal in spec_names if signal.startswith(("i_", "o_"))]
        vcd_signals.extend(signals)
        vcd_signals = list(dict.fromkeys(vcd_signals))
        run([
            sys.executable, args.converter, "vcd-to-wavejson", str(vcd),
            "--signals", ",".join(vcd_signals), "--period", "10ns",
            "--out", str(wavejson), "--force",
        ])

        # The VCD converter samples at clock-period boundaries. Draw the clock as
        # WaveDrom's standard positive-edge pulse while retaining that cycle grid.
        document = json.loads(wavejson.read_text(encoding="utf-8"))
        clock = find_signal(document["signal"], "i_clk_core")
        if clock is None:
            raise RuntimeError(f"clock signal missing from {wavejson}")
        slots = len(clock["wave"])
        clock["wave"] = "p" + "." * max(0, slots - 1)
        wavejson.write_text(json.dumps(document, indent=2) + "\n", encoding="utf-8")

        run([sys.executable, args.converter, "lint", str(wavejson)])
        run([sys.executable, args.renderer, "render", str(wavejson), "--out", str(svg), "--force"])

    print(f"Generated and linted {len(WAVE_SIGNALS)} WaveJSON/SVG pairs in {OUT}")


if __name__ == "__main__":
    main()
