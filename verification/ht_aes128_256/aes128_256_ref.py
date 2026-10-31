#!/usr/bin/env python3
"""Independent AES-128/AES-256 and mode reference for the generated RTL checks.

AES byte transforms reuse the separately maintained, self-tested AES-128 model
in the project. AES-256 key expansion and the generic 14-round block path are
implemented here from FIPS 197. This module does not parse or inspect RTL.
"""

from __future__ import annotations

import sys
from pathlib import Path

SHARED = Path(__file__).resolve().parents[1] / "shared"
sys.path.insert(0, str(SHARED))
import aes_ref as aes128  # noqa: E402

MASK128 = (1 << 128) - 1
MODE_CODE = {"ECB": 0, "CBC": 1, "CFB": 2, "OFB": 3, "CTR": 4}
SEG_BITS = (1, 2, 4, 8, 16, 32, 64, 128)


def expand_key(key: bytes) -> list[bytes]:
    if len(key) == 16:
        return aes128.expand_key(key)
    if len(key) != 32:
        raise ValueError("AES key must be 16 or 32 bytes")
    words = [list(key[4 * i:4 * i + 4]) for i in range(8)]
    rcon = 1
    for idx in range(8, 60):
        temp = list(words[idx - 1])
        if idx % 8 == 0:
            temp = temp[1:] + temp[:1]
            temp = [aes128.SBOX[b] for b in temp]
            temp[0] ^= rcon
            rcon = aes128.xtime(rcon)
        elif idx % 8 == 4:
            temp = [aes128.SBOX[b] for b in temp]
        words.append([words[idx - 8][b] ^ temp[b] for b in range(4)])
    return [bytes(sum(words[4 * r:4 * r + 4], [])) for r in range(15)]


def enc_block(block: bytes, key: bytes) -> bytes:
    if len(block) != 16:
        raise ValueError("AES block must be 16 bytes")
    keys = expand_key(key)
    state = aes128._ark(list(block), list(keys[0]))
    for rnd in range(1, len(keys) - 1):
        state = aes128._ark(aes128._mix(aes128._shift(aes128._sub(state))), list(keys[rnd]))
    state = aes128._ark(aes128._shift(aes128._sub(state)), list(keys[-1]))
    return bytes(state)


def dec_block(block: bytes, key: bytes) -> bytes:
    if len(block) != 16:
        raise ValueError("AES block must be 16 bytes")
    keys = expand_key(key)
    state = aes128._ark(list(block), list(keys[-1]))
    for rnd in range(len(keys) - 2, 0, -1):
        state = aes128._imix(aes128._ark(aes128._isub(aes128._ishift(state)), list(keys[rnd])))
    return bytes(aes128._ark(aes128._isub(aes128._ishift(state)), list(keys[0])))


def run_stream(mode: str, decipher: int, key: bytes, iv: int, blocks: list[int],
               seg: int = 7, ctr_width: int = 32) -> list[tuple[int, int, int]]:
    """Return (input, expected output, compare mask) records in stream order."""
    if mode not in MODE_CODE:
        raise ValueError(mode)
    output: list[tuple[int, int, int]] = []
    if mode == "ECB":
        transform = dec_block if decipher else enc_block
        return [(b, int.from_bytes(transform(b.to_bytes(16, "big"), key), "big"), MASK128)
                for b in blocks]
    if mode == "CBC":
        previous = iv.to_bytes(16, "big")
        for value in blocks:
            current = value.to_bytes(16, "big")
            if decipher:
                plain = bytes(a ^ b for a, b in zip(dec_block(current, key), previous))
                output.append((value, int.from_bytes(plain, "big"), MASK128))
                previous = current
            else:
                cipher = enc_block(bytes(a ^ b for a, b in zip(current, previous)), key)
                output.append((value, int.from_bytes(cipher, "big"), MASK128))
                previous = cipher
        return output
    if mode == "CFB":
        bits = SEG_BITS[seg]
        mask = ((1 << bits) - 1) << (128 - bits)
        feedback = iv
        for value in blocks:
            key_stream = int.from_bytes(enc_block(feedback.to_bytes(16, "big"), key), "big")
            result = (value ^ key_stream) & mask
            output.append((value, result, mask))
            cipher_segment = value & mask if decipher else result
            feedback = ((feedback << bits) & MASK128) | (cipher_segment >> (128 - bits))
        return output
    if mode == "OFB":
        feedback = iv
        for value in blocks:
            feedback = int.from_bytes(enc_block(feedback.to_bytes(16, "big"), key), "big")
            output.append((value, value ^ feedback, MASK128))
        return output
    counter_mask = (1 << ctr_width) - 1
    fixed = iv & (MASK128 ^ counter_mask)
    counter = iv & counter_mask
    for value in blocks:
        stream = int.from_bytes(enc_block((fixed | counter).to_bytes(16, "big"), key), "big")
        output.append((value, value ^ stream, MASK128))
        counter = (counter + 1) & counter_mask
    return output


def self_test() -> None:
    aes128.self_test()
    key128 = bytes.fromhex("000102030405060708090a0b0c0d0e0f")
    plain = bytes.fromhex("00112233445566778899aabbccddeeff")
    cipher128 = bytes.fromhex("69c4e0d86a7b0430d8cdb78070b4c55a")
    assert enc_block(plain, key128) == cipher128
    assert dec_block(cipher128, key128) == plain

    # FIPS 197-upd1 Appendix C.3 AES-256 known-answer test.
    key256 = bytes.fromhex("000102030405060708090a0b0c0d0e0f"
                           "101112131415161718191a1b1c1d1e1f")
    cipher256 = bytes.fromhex("8ea2b7ca516745bfeafc49904b496089")
    assert enc_block(plain, key256) == cipher256
    assert dec_block(cipher256, key256) == plain

    # Confirm stream-mode model symmetry for both key sizes.
    sample = [int("00112233445566778899aabbccddeeff", 16),
              int("ffeeddccbbaa99887766554433221100", 16)]
    for key in (key128, key256):
        for mode in MODE_CODE:
            enc = run_stream(mode, 0, key, int("0123456789abcdeffedcba9876543210", 16), sample)
            dec = run_stream(mode, 1, key, int("0123456789abcdeffedcba9876543210", 16),
                             [record[1] for record in enc])
            assert [record[1] for record in dec] == sample, (len(key), mode)


if __name__ == "__main__":
    self_test()
    print("AES reference PASS: FIPS 197 AES-128/AES-256 KATs and ECB/CBC/CFB/OFB/CTR round trips")
