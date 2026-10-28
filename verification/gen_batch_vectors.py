"""Create AES batch-level vectors from the independent Python reference model."""

from __future__ import annotations

import random
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
import aes_ref as ref  # noqa: E402


def stream(mode: str, decipher: int, seg: int, key: int, iv: int,
           inputs: list[int], name: str) -> dict[str, object]:
    golden = ref.run_stream(mode, decipher, key, iv, inputs, seg)
    return {
        "name": name,
        "mode": ref.MODE_CODE[mode],
        "decipher": decipher,
        "seg": seg,
        "key": key,
        "iv": iv,
        "blocks": [(din, expected, mask) for din, expected, mask, _ in golden],
    }


def write(path: Path, streams: list[dict[str, object]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="ascii", newline="\n") as f:
        f.write(f"{len(streams):08x}\n")
        for item in streams:
            f.write(f"{item['mode']:08x}\n")
            f.write(f"{item['decipher']:08x}\n")
            f.write(f"{item['seg']:08x}\n")
            f.write(f"{len(item['blocks']):08x}\n")
            f.write(f"{item['key']:032x}\n")
            f.write(f"{item['iv']:032x}\n")
            for din, expected, mask in item["blocks"]:
                f.write(f"{din:032x}\n{expected:032x}\n{mask:032x}\n")


def make_streams() -> tuple[list[dict[str, object]], dict[str, list[dict[str, object]]]]:
    key = ref.h2i("2b7e151628aed2a6abf7158809cf4f3c")
    iv = ref.h2i("000102030405060708090a0b0c0d0e0f")
    ctr_iv = ref.h2i("f0f1f2f3f4f5f6f7f8f9fafbfcfdfeff")
    plain = [
        ref.h2i("6bc1bee22e409f96e93d7e117393172a"),
        ref.h2i("ae2d8a571e03ac9c9eb76fac45af8e51"),
        ref.h2i("30c81c46a35ce411e5fbc1191a0a52ef"),
        ref.h2i("f69f2445df4f9b17ad2b417be66c3710"),
    ]
    regression: list[dict[str, object]] = []
    waves: dict[str, list[dict[str, object]]] = {}

    # FIPS 197 Appendix C.1 AES-128 encryption and decryption known-answer pair.
    fips_key = ref.h2i("000102030405060708090a0b0c0d0e0f")
    fips_plain = ref.h2i("00112233445566778899aabbccddeeff")
    fips_cipher = ref.b2i(ref.enc_block(ref.i2b(fips_plain), ref.i2b(fips_key)))
    regression.append(stream("ECB", 0, 7, fips_key, 0, [fips_plain], "FIPS-197-ECB-ENC"))
    regression.append(stream("ECB", 1, 7, fips_key, 0, [fips_cipher], "FIPS-197-ECB-DEC"))

    # SP 800-38A vectors exercise all five modes in both directions.
    for mode in ("ECB", "CBC", "CFB", "OFB", "CTR"):
        initial = ctr_iv if mode == "CTR" else iv
        cipher = ref.run_stream(mode, 0, key, initial, plain, 7)
        cipher_blocks = [entry[1] for entry in cipher]
        for decipher, blocks in ((0, plain), (1, cipher_blocks)):
            regression.append(stream(mode, decipher, 7, key, initial, blocks,
                                     f"SP800-38A-{mode}-{'DEC' if decipher else 'ENC'}"))

    # CFB segment sizes 1, 2, 4, 8, 16, 32, 64 and 128; both directions.
    rng = random.Random(0xA128)
    for seg in range(8):
        count = 16 if seg <= 3 else 8
        segment_bits = ref.SEG_BITS[seg]
        seg_mask = ((1 << segment_bits) - 1) << (128 - segment_bits)
        segment_inputs = [((rng.getrandbits(128) & seg_mask) |
                           (rng.getrandbits(128) & (ref.MASK128 ^ seg_mask)))
                          for _ in range(count)]
        cipher = ref.run_stream("CFB", 0, key, iv, segment_inputs, seg)
        cipher_inputs = [entry[1] for entry in cipher]
        regression.append(stream("CFB", 0, seg, key, iv, segment_inputs,
                                 f"CFB-{segment_bits}-ENC"))
        regression.append(stream("CFB", 1, seg, key, iv, cipher_inputs,
                                 f"CFB-{segment_bits}-DEC"))

    # A non-divisible ECB stream checks partial final batches and sustained II=1.
    throughput_data = [rng.getrandbits(128) for _ in range(13)]
    regression.append(stream("ECB", 0, 7, key, 0, throughput_data, "ECB-THROUGHPUT-13"))
    pressure_stream = stream("ECB", 0, 7, key, 0,
                             [rng.getrandbits(128) for _ in range(64)],
                             "ECB-BACKPRESSURE-64")

    # The low 32-bit CTR field may consume ...fffffffd, ...fffffffe, ...ffffffff.
    near_wrap = 0xA1B2C3D4E5F60718293A4B5CFFFFFFFD
    regression.append(stream("CTR", 0, 7, key, near_wrap,
                             [0, 0x11112222333344445555666677778888,
                              ref.MASK128], "CTR-LOW32-LAST-THREE"))
    ctr_limit = stream("CTR", 0, 7, key,
                       0x00112233445566778899AABBFFFFFFFE,
                       [0x0123456789ABCDEF0011223344556677,
                        0x8899AABBCCDDEEFF0011223344556677],
                       "CTR-LOW32-LAST-TWO")

    # Deterministic pseudo-random streams cover reconfiguration and mixed ordering.
    modes = ("ECB", "CBC", "CFB", "OFB", "CTR")
    for idx in range(20):
        mode = modes[idx % len(modes)]
        decipher = (idx // len(modes)) & 1
        seg = rng.randrange(8) if mode == "CFB" else 7
        nblocks = 1 + rng.randrange(11)
        in_words = [rng.getrandbits(128) for _ in range(nblocks)]
        stream_key = rng.getrandbits(128)
        stream_iv = rng.getrandbits(128)
        if mode in ("ECB", "CBC") and decipher:
            # Encrypt the independent plaintext stream first, then verify decipher.
            encrypted = ref.run_stream(mode, 0, stream_key, stream_iv, in_words, seg)
            in_words = [entry[1] for entry in encrypted]
        regression.append(stream(mode, decipher, seg, stream_key, stream_iv, in_words,
                                 f"RANDOM-{idx:02d}-{mode}"))

    # Figure-specific traces use the exact scenario labels approved in Section 10.3.
    waves["WF-002_ecb_batches"] = [stream("ECB", 0, 7, key, 0, plain + plain[:2], "WF-002")]
    ctr_data = [rng.getrandbits(128) for _ in range(4)]
    waves["WF-003_ctr_allocation"] = [stream("CTR", 0, 7, key, ctr_iv, ctr_data, "WF-003")]

    cbc_cipher = [entry[1] for entry in ref.run_stream("CBC", 0, key, iv, plain, 7)]
    waves["WF-005_cbc_decryption"] = [stream("CBC", 1, 7, key, iv, cbc_cipher, "WF-005")]

    for mode, stem in (("CBC", "WF-006_cbc_encrypt"),
                       ("CFB", "WF-006_cfb"), ("OFB", "WF-006_ofb")):
        seg = 7
        data = [plain[0], plain[1]]
        waves[stem] = [stream(mode, 0, seg, key, iv, data, stem)]

    # Two valid counters ending at ...ffffffff are allowed; the following request is rejected.
    waves["WF-004_ctr_wrap_rejection"] = [stream(
        "CTR", 0, 7, key, 0x00112233445566778899AABBFFFFFFFE,
        [plain[0], plain[1], plain[2]], "WF-004")]
    waves["ctr_limit"] = [ctr_limit]
    waves["fips_kat"] = regression[:2]
    waves["wf001_latency"] = [stream("ECB", 0, 7, key, 0, [plain[0]], "L_PIPE-10")]
    waves["backpressure"] = [pressure_stream]

    # WF-007 uses one ECB block to hold a complete output record during a one-cycle stall.
    waves["WF-007_backpressure"] = [stream("ECB", 0, 7, key, 0, [plain[0]], "WF-007")]

    return regression, waves


def main() -> None:
    out_dir = Path(__file__).resolve().parent / "vectors"
    if len(sys.argv) > 1:
        out_dir = Path(sys.argv[1]).resolve()
    ref.self_test()
    regression, waves = make_streams()
    write(out_dir / "regression.vec", regression)
    for stem, items in waves.items():
        write(out_dir / f"{stem}.vec", items)
    print(f"generated {len(regression)} independent reference streams: {out_dir / 'regression.vec'}")
    for stem, items in waves.items():
        print(f"generated {stem}: {len(items[0]['blocks'])} blocks")


if __name__ == "__main__":
    main()
