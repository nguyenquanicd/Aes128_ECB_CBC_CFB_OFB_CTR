#!/usr/bin/env python3
"""Generate deterministic vectors from the independent AES reference model."""

from __future__ import annotations

import random
from pathlib import Path

import aes128_256_ref as ref

HERE = Path(__file__).resolve().parent
VECTORS = HERE / "vectors"


def write_case(name: str, key_size: int, mode: str, decipher: int, seg: int,
               key: bytes, iv: int, inputs: list[int], ctr_width: int = 32) -> None:
    expected = ref.run_stream(mode, decipher, key, iv, inputs, seg, ctr_width)
    key_word = int.from_bytes(key, "big")
    if key_size == 0:
        key_word &= (1 << 128) - 1
    path = VECTORS / f"{name}.vec"
    with path.open("w", encoding="ascii", newline="\n") as stream:
        stream.write(f"{key_size} {ref.MODE_CODE[mode]} {decipher} {seg} {ctr_width}\n")
        stream.write(f"{key_word:064x}\n{iv:032x}\n{len(expected)}\n")
        for data, result, mask in expected:
            stream.write(f"{data:032x} {result:032x} {mask:032x}\n")


def main() -> None:
    ref.self_test()
    VECTORS.mkdir(parents=True, exist_ok=True)
    for old in VECTORS.glob("*.vec"):
        old.unlink()
    plain = [int(x, 16) for x in (
        "00112233445566778899aabbccddeeff",
        "ffeeddccbbaa99887766554433221100",
        "0123456789abcdeffedcba9876543210",
        "0f0e0d0c0b0a09080706050403020100",
    )]
    keys = {
        0: bytes.fromhex("000102030405060708090a0b0c0d0e0f"),
        1: bytes.fromhex("000102030405060708090a0b0c0d0e0f"
                         "101112131415161718191a1b1c1d1e1f"),
    }
    iv = int("000102030405060708090a0b0c0d0e0f", 16)
    ctr_iv = int("a1b2c3d4e5f60718293a4b5c01020300", 16)
    cases: list[str] = []

    for key_size in (0, 1):
        key = keys[key_size]
        for mode in ref.MODE_CODE:
            if mode == "CTR":
                start_iv = ctr_iv
            else:
                start_iv = iv
            for decipher in (0, 1):
                inputs = list(plain)
                if decipher and mode in ("ECB", "CBC"):
                    encrypted = ref.run_stream(mode, 0, key, start_iv, plain)
                    inputs = [item[1] for item in encrypted]
                name = f"reg_k{128 if key_size == 0 else 256}_{mode.lower()}_{'dec' if decipher else 'enc'}"
                write_case(name, key_size, mode, decipher, 7, key, start_iv, inputs)
                cases.append(name)

        # AES KAT files make the standard known-answer checks explicit.
        write_case(f"fips_k{128 if key_size == 0 else 256}_enc", key_size, "ECB", 0, 7,
                   key, 0, [int("00112233445566778899aabbccddeeff", 16)])
        write_case(f"fips_k{128 if key_size == 0 else 256}_dec", key_size, "ECB", 1, 7,
                   key, 0, [int("69c4e0d86a7b0430d8cdb78070b4c55a" if key_size == 0 else
                                "8ea2b7ca516745bfeafc49904b496089", 16)])
        cases.extend([f"fips_k{128 if key_size == 0 else 256}_enc",
                      f"fips_k{128 if key_size == 0 else 256}_dec"])

    # Exercise every legal CFB segment size in both directions and key sizes.
    rng = random.Random(0xA256)
    for key_size in (0, 1):
        for seg in range(8):
            bit_count = ref.SEG_BITS[seg]
            mask = ((1 << bit_count) - 1) << (128 - bit_count)
            data = [rng.getrandbits(128) & mask for _ in range(8)]
            encrypted = ref.run_stream("CFB", 0, keys[key_size], iv, data, seg)
            cipher = [x[1] for x in encrypted]
            for decipher, stream_data in ((0, data), (1, cipher)):
                name = f"cfb_k{128 if key_size == 0 else 256}_s{bit_count}_{'dec' if decipher else 'enc'}"
                write_case(name, key_size, "CFB", decipher, seg, keys[key_size], iv, stream_data)
                cases.append(name)

    # Partial final batch and deterministic random mixed-mode streams.
    for key_size in (0, 1):
        key = keys[key_size]
        vals = [rng.getrandbits(128) for _ in range(6)]
        name = f"partial_ecb_k{128 if key_size == 0 else 256}"
        write_case(name, key_size, "ECB", 0, 7, key, 0, vals)
        cases.append(name)

    # A three-batch file is consumed by the dedicated latency/II=1 test.
    for key_size in (0, 1):
        vals = [rng.getrandbits(128) for _ in range(12)]
        name = f"throughput_k{128 if key_size == 0 else 256}"
        write_case(name, key_size, "ECB", 0, 7, keys[key_size], 0, vals)
        cases.append(name)

    # Partial CTR batch starts near the configured low-field limit but stays legal.
    ctr_partial = [rng.getrandbits(128) for _ in range(3)]
    name = "wf004_ctr_partial"
    write_case(name, 1, "CTR", 0, 7, keys[1],
               int("00112233445566778899aabbfffffffd", 16), ctr_partial, 32)
    cases.append(name)

    # Waveform aliases keep one explicitly named stream for the approved scenarios.
    for key_size, mode, direction, vals in (
        (0, "CBC", 1, None), (1, "CBC", 1, None),
        (0, "CBC", 0, plain[:2]), (1, "CFB", 0, plain[:2]),
        (1, "OFB", 0, plain[:2]),
    ):
        if vals is None:
            enc = ref.run_stream("CBC", 0, keys[key_size], iv, plain)
            vals = [item[1] for item in enc]
        name = f"wf_mode_k{128 if key_size == 0 else 256}_{mode.lower()}_{'dec' if direction else 'enc'}"
        write_case(name, key_size, mode, direction, 7, keys[key_size], iv, vals)
        cases.append(name)

    (VECTORS / "manifest.txt").write_text("\n".join(cases) + "\n", encoding="ascii")
    print(f"Generated {len(cases)} independent vector streams in {VECTORS}")
    print("Golden-data source: aes128_256_ref.py + FIPS 197 and NIST SP 800-38A semantics")


if __name__ == "__main__":
    main()
