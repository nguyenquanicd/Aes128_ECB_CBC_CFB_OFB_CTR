"""Generate golden vector files for tb/tb_aes128_vec.sv.

usage: python gen_vectors.py [out_dir]        (default: ../vectors)

Vector file = text file, one 128-bit hex word (32 digits) per line:
  line 0            : number of operations N
  per operation (6) : ctrl, key, init_vector, data_in, expected, mask
  ctrl[0]      = 1 for decipher, 0 for cipher
  ctrl[4:1]    = mode            (0 ECB, 1 CBC, 2 CFB, 3 OFB, 4 CTR)
  ctrl[8:5]    = segment_len     (CFB segment code, 0..7)
  ctrl[9]      = chain_en
  ctrl[10]     = new_stream      (drop chain_en for 'gap' cycles before this op)
  ctrl[15:12]  = gap             (clocks with chain_en=0 before a new stream)
  ctrl[19:16]  = idle            (clocks to wait after the previous op finished)
Only the bits of data_out selected by 'mask' are compared (CFB uses the top
'segment' bits; every other mode compares all 128 bits).
Everything is deterministic: the same script always writes the same files.
"""
import os
import random
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "shared"))
import aes_ref as g

ALL = g.MASK128


def op(dec, mode, seg, chain, newstream, gap, idle, key, iv, din, exp, mask):
    ctrl = (dec & 1) | (g.MODE_CODE[mode] << 1) | (seg << 5) | (chain << 9) | (newstream << 10) \
        | (gap << 12) | (idle << 16)
    return [ctrl, key, iv, din, exp, mask]


def stream(mode, dec, key, iv, blocks, seg, gap, idle_fn, chain=1):
    res = g.run_stream(mode, dec, key, iv, blocks, seg)
    return [op(int(dec), mode, seg, chain, int(i == 0), gap, idle_fn(), key, ivop, din, exp, mask)
            for i, (din, exp, mask, ivop) in enumerate(res)]


def emit(ops, path):
    with open(path, 'w') as f:
        f.write('%032x\n' % len(ops))
        for o in ops:
            for w in o:
                f.write('%032x\n' % w)
    return len(ops)


K = g.h2i('2b7e151628aed2a6abf7158809cf4f3c')
IV = g.h2i('000102030405060708090a0b0c0d0e0f')
CTR_IV = g.h2i('f0f1f2f3f4f5f6f7f8f9fafbfcfdfeff')
P = [g.h2i('6bc1bee22e409f96e93d7e117393172a'), g.h2i('ae2d8a571e03ac9c9eb76fac45af8e51'),
     g.h2i('30c81c46a35ce411e5fbc1191a0a52ef'), g.h2i('f69f2445df4f9b17ad2b417be66c3710')]


def r128(rnd):
    return rnd.getrandbits(128)


# --------------------------------------------------------------------------- scenarios
def scen_nist():
    """NIST SP 800-38A (all five modes) + FIPS-197, cipher then decipher of the same data."""
    ops = []
    for mode in ('ECB', 'CBC', 'OFB', 'CTR'):
        iv = CTR_IV if mode == 'CTR' else IV
        enc = g.run_stream(mode, 0, K, iv, P, 7)
        ops += stream(mode, 0, K, iv, P, 7, 2, lambda: 0)
        ops += stream(mode, 1, K, iv, [e[1] for e in enc], 7, 2, lambda: 0)
    pbits = bin(g.b2i(b''.join(g.i2b(x) for x in P)))[2:].zfill(512)
    for seg, nseg in ((7, 4), (3, 16), (0, 16)):       # CFB128, CFB8, CFB1
        s = g.SEG_BITS[seg]
        segs = [int(pbits[i * s:(i + 1) * s], 2) << (128 - s) for i in range(nseg)]
        enc = g.run_stream('CFB', 0, K, IV, segs, seg)
        ops += stream('CFB', 0, K, IV, segs, seg, 2, lambda: 0)
        ops += stream('CFB', 1, K, IV, [e[1] & e[2] for e in enc], seg, 2, lambda: 0)
    fk = g.h2i('000102030405060708090a0b0c0d0e0f')     # FIPS-197 C.1
    fp = g.h2i('00112233445566778899aabbccddeeff')
    ops += stream('ECB', 0, fk, 0, [fp], 7, 2, lambda: 0)
    ops += stream('ECB', 1, fk, 0, [g.h2i('69c4e0d86a7b0430d8cdb78070b4c55a')], 7, 2, lambda: 0)
    return ops


def scen_walk():
    """AESAVS ECBVarTxt128 / ECBVarKey128: every input bit toggles, cipher and decipher."""
    ops = []
    for i in range(128):                                # VarTxt: key 0, plaintext = i+1 leading ones
        pt = (((1 << (i + 1)) - 1) << (127 - i)) & ALL
        ops += stream('ECB', 0, 0, 0, [pt], 7, 2, lambda: 0, chain=0)
    for i in range(128):                                # VarKey: plaintext 0, key = i+1 leading ones
        key = (((1 << (i + 1)) - 1) << (127 - i)) & ALL
        ops += stream('ECB', 0, key, 0, [0], 7, 2, lambda: 0, chain=0)
    for i in range(0, 128, 3):                          # decipher the VarTxt ciphertexts
        pt = (((1 << (i + 1)) - 1) << (127 - i)) & ALL
        ct = g.b2i(g.enc_block(g.i2b(pt), bytes(16)))
        ops += stream('ECB', 1, 0, 0, [ct], 7, 2, lambda: 0, chain=0)
    return ops


def scen_patterns():
    """Corner data patterns in every mode and direction (all-0, all-1, 0x55.., 0xAA.., walking 1/0)."""
    pats = [0, ALL, int('55' * 16, 16), int('aa' * 16, 16), 1, 1 << 127, ALL ^ 1, ALL ^ (1 << 127)]
    ops = []
    for mode in ('ECB', 'CBC', 'OFB', 'CTR', 'CFB'):
        for dec in (0, 1):
            for key, iv in ((0, 0), (ALL, ALL), (int('a5' * 16, 16), int('5a' * 16, 16))):
                seg = 7
                ops += stream(mode, dec, key, iv, pats, seg, 2, lambda: 0)
    return ops


def scen_cfb_segments(rnd):
    """Every CFB segment size, both directions, long streams with random lower (don't-care) bits."""
    ops = []
    for seg in range(8):
        for dec in (0, 1):
            key, iv = r128(rnd), r128(rnd)
            ops += stream('CFB', dec, key, iv, [r128(rnd) for _ in range(24)], seg, 2, lambda: 0)
    return ops


def scen_random(rnd, n_streams, gap_fn, idle_fn, modes=('ECB', 'CBC', 'CFB', 'OFB', 'CTR'), maxblk=6):
    ops = []
    for _ in range(n_streams):
        mode = rnd.choice(modes)
        dec = rnd.randint(0, 1)
        seg = rnd.randint(0, 7) if mode == 'CFB' else 7
        ops += stream(mode, dec, r128(rnd), r128(rnd), [r128(rnd) for _ in range(rnd.randint(1, maxblk))],
                      seg, gap_fn(), idle_fn)
    return ops


def scen_chain0(rnd):
    """chain_en=0 single-shot operations, every mode and direction, after streams of every other mode."""
    ops = []
    for prev in ('CBC', 'CFB', 'OFB', 'CTR', 'ECB'):
        ops += stream(prev, 0, r128(rnd), r128(rnd), [r128(rnd), r128(rnd)], 7, 3, lambda: 0)
        for mode in ('ECB', 'CBC', 'CFB', 'OFB', 'CTR'):
            for dec in (0, 1):
                for _ in range(3):
                    seg = rnd.randint(0, 7) if mode == 'CFB' else 7
                    res = g.run_stream(mode, dec, (key := r128(rnd)), (iv := r128(rnd)), [r128(rnd)], seg)
                    for (din, exp, mask, ivop) in res:
                        ops.append(op(dec, mode, seg, 0, 1, 2, 0, key, ivop, din, exp, mask))
    return ops


def scen_multikey(rnd):
    """A new key (and for CTR a new counter) on every block of a chained ECB/CTR/OFB stream."""
    ops = []
    for mode in ('ECB', 'CTR'):
        for dec in (0, 1):
            for i in range(40):
                key, iv, data = r128(rnd), r128(rnd), r128(rnd)
                res = g.run_stream(mode, dec, key, iv, [data], 7)
                for (din, exp, mask, ivop) in res:
                    ops.append(op(dec, mode, 7, 1, int(i == 0), 2, rnd.randint(0, 2), key, ivop, din, exp, mask))
    return ops


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'vectors')
    os.makedirs(out, exist_ok=True)
    g.self_test()
    sc = {}
    sc['nist'] = scen_nist()
    sc['walk'] = scen_walk()
    sc['patterns'] = scen_patterns()
    sc['cfb_segments'] = scen_cfb_segments(random.Random(101))
    for s in (1, 2, 3):
        rnd = random.Random(200 + s)
        sc['rand_s%d' % s] = scen_random(rnd, 120, lambda: rnd.randint(2, 4), lambda: rnd.randint(0, 3))
    rnd = random.Random(301)
    sc['gap1'] = scen_random(rnd, 80, lambda: 1, lambda: 1)
    rnd = random.Random(302)
    sc['b2b'] = scen_random(rnd, 80, lambda: 2, lambda: 0)
    sc['chain0'] = scen_chain0(random.Random(303))
    sc['multikey'] = scen_multikey(random.Random(304))
    rnd = random.Random(401)
    sc['long'] = scen_random(rnd, 450, lambda: rnd.randint(1, 5), lambda: rnd.randint(0, 4), maxblk=8)
    total = 0
    for name, ops in sc.items():
        n = emit(ops, os.path.join(out, name + '.hex'))
        total += n
        print('%-14s %5d ops' % (name, n))
    print('total %d ops in %s' % (total, os.path.abspath(out)))


if __name__ == '__main__':
    main()
