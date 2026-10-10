"""Pure-python AES-128 reference model (ECB / CBC / CFB-s / OFB / CTR).

No third-party packages are needed. The model is independent from the RTL: the
S-box is built from the GF(2^8) inverse + affine map, MixColumns from xtime.

Self-test (run `python aes_ref.py`) checks it against FIPS-197, NIST SP 800-38A
and AESAVS known answers before any vector is generated.
"""

MASK128 = (1 << 128) - 1
SEG_BITS = [1, 2, 4, 8, 16, 32, 64, 128]          # segment_len code -> segment size
MODE_CODE = {'ECB': 0, 'CBC': 1, 'CFB': 2, 'OFB': 3, 'CTR': 4}


# ---------------------------------------------------------------- GF(2^8) / S-box
def xtime(a):
    return (((a << 1) ^ 0x1B) & 0xFF) if a & 0x80 else (a << 1)


def gmul(a, b):
    r = 0
    while b:
        if b & 1:
            r ^= a
        a = xtime(a)
        b >>= 1
    return r


def _build_sbox():
    inv = [0] * 256
    for a in range(1, 256):
        for b in range(1, 256):
            if gmul(a, b) == 1:
                inv[a] = b
                break
    sb = []
    for a in range(256):
        x = inv[a]
        y = x
        for i in range(1, 5):
            y ^= ((x << i) | (x >> (8 - i))) & 0xFF
        sb.append(y ^ 0x63)
    return sb


SBOX = _build_sbox()
ISBOX = [0] * 256
for _i, _v in enumerate(SBOX):
    ISBOX[_v] = _i


# ---------------------------------------------------------------- block cipher
def expand_key(key16):
    w = [list(key16[4 * i:4 * i + 4]) for i in range(4)]
    rc = 1
    for i in range(4, 44):
        t = list(w[i - 1])
        if i % 4 == 0:
            t = t[1:] + t[:1]
            t = [SBOX[b] for b in t]
            t[0] ^= rc
            rc = xtime(rc)
        w.append([w[i - 4][j] ^ t[j] for j in range(4)])
    return [sum(w[4 * r:4 * r + 4], []) for r in range(11)]


def _sub(s):  return [SBOX[b] for b in s]
def _isub(s): return [ISBOX[b] for b in s]


def _shift(s):          # state is column-major: s[4*col + row]
    return [s[((c + r) % 4) * 4 + r] for c in range(4) for r in range(4)]


def _ishift(s):
    o = [0] * 16
    for c in range(4):
        for r in range(4):
            o[((c + r) % 4) * 4 + r] = s[c * 4 + r]
    return o


def mix_column(a):
    return [gmul(a[0], 2) ^ gmul(a[1], 3) ^ a[2] ^ a[3],
            a[0] ^ gmul(a[1], 2) ^ gmul(a[2], 3) ^ a[3],
            a[0] ^ a[1] ^ gmul(a[2], 2) ^ gmul(a[3], 3),
            gmul(a[0], 3) ^ a[1] ^ a[2] ^ gmul(a[3], 2)]


def inv_mix_column(a):
    return [gmul(a[0], 14) ^ gmul(a[1], 11) ^ gmul(a[2], 13) ^ gmul(a[3], 9),
            gmul(a[0], 9) ^ gmul(a[1], 14) ^ gmul(a[2], 11) ^ gmul(a[3], 13),
            gmul(a[0], 13) ^ gmul(a[1], 9) ^ gmul(a[2], 14) ^ gmul(a[3], 11),
            gmul(a[0], 11) ^ gmul(a[1], 13) ^ gmul(a[2], 9) ^ gmul(a[3], 14)]


def _mix(s):  return sum((mix_column(s[c * 4:c * 4 + 4]) for c in range(4)), [])
def _imix(s): return sum((inv_mix_column(s[c * 4:c * 4 + 4]) for c in range(4)), [])
def _ark(s, k): return [a ^ b for a, b in zip(s, k)]


def enc_block(pt, key):
    rk = expand_key(key)
    s = _ark(list(pt), rk[0])
    for r in range(1, 10):
        s = _ark(_mix(_shift(_sub(s))), rk[r])
    return bytes(_ark(_shift(_sub(s)), rk[10]))


def dec_block(ct, key):
    rk = expand_key(key)
    s = _ark(list(ct), rk[10])
    for r in range(9, 0, -1):
        s = _imix(_ark(_isub(_ishift(s)), rk[r]))
    return bytes(_ark(_isub(_ishift(s)), rk[0]))


def i2b(i):  return i.to_bytes(16, 'big')
def b2i(b):  return int.from_bytes(b, 'big')
def h2i(h):  return int(h, 16)


# ---------------------------------------------------------------- modes
def run_stream(mode, dec, key, iv, blocks, seg=7):
    """Reference of one chained stream as the DUT sees it.

    blocks : list of 128-bit input words (CFB: the segment is left-justified)
    returns: list of (din, expected, mask, iv_for_this_op)
             expected is only meaningful under 'mask' (all ones except CFB).
    """
    k = i2b(key)
    out = []
    if mode == 'ECB':
        f = dec_block if dec else enc_block
        for b in blocks:
            out.append((b, b2i(f(i2b(b), k)), MASK128, iv))
    elif mode == 'CBC':
        prev = i2b(iv)
        for b in blocks:
            if not dec:
                c = enc_block(bytes(x ^ y for x, y in zip(i2b(b), prev)), k)
                out.append((b, b2i(c), MASK128, iv))
                prev = c
            else:
                p = bytes(x ^ y for x, y in zip(dec_block(i2b(b), k), prev))
                out.append((b, b2i(p), MASK128, iv))
                prev = i2b(b)
    elif mode == 'CFB':
        s = SEG_BITS[seg]
        mask = ((1 << s) - 1) << (128 - s)
        r = iv
        for b in blocks:
            top = b2i(enc_block(i2b(r), k)) & mask
            res = (b & mask) ^ top
            out.append((b, res, mask, iv))
            cseg = (b & mask) if dec else res
            r = ((r << s) & MASK128) | (cseg >> (128 - s))
    elif mode == 'OFB':
        r = i2b(iv)
        for b in blocks:
            r = enc_block(r, k)
            out.append((b, b ^ b2i(r), MASK128, iv))
    elif mode == 'CTR':
        ctr = iv
        for b in blocks:
            out.append((b, b ^ b2i(enc_block(i2b(ctr), k)), MASK128, ctr))
            ctr = (ctr + 1) & MASK128
    else:
        raise ValueError(mode)
    return out


# ---------------------------------------------------------------- self test
def self_test():
    # FIPS-197 appendix C.1
    assert enc_block(bytes.fromhex('00112233445566778899aabbccddeeff'),
                     bytes.fromhex('000102030405060708090a0b0c0d0e0f')).hex() == '69c4e0d86a7b0430d8cdb78070b4c55a'
    k = h2i('2b7e151628aed2a6abf7158809cf4f3c')
    iv = h2i('000102030405060708090a0b0c0d0e0f')
    p = [h2i('6bc1bee22e409f96e93d7e117393172a'), h2i('ae2d8a571e03ac9c9eb76fac45af8e51'),
         h2i('30c81c46a35ce411e5fbc1191a0a52ef'), h2i('f69f2445df4f9b17ad2b417be66c3710')]
    # SP 800-38A F.1.1 ECB, F.2.1 CBC, F.4.1 OFB, F.5.1 CTR (first/last blocks)
    ecb = run_stream('ECB', 0, k, iv, p)
    assert ecb[0][1] == h2i('3ad77bb40d7a3660a89ecaf32466ef97') and ecb[3][1] == h2i('7b0c785e27e8ad3f8223207104725dd4')
    cbc = run_stream('CBC', 0, k, iv, p)
    assert cbc[0][1] == h2i('7649abac8119b246cee98e9b12e9197d') and cbc[3][1] == h2i('3ff1caa1681fac09120eca307586e1a7')
    ofb = run_stream('OFB', 0, k, iv, p)
    assert ofb[0][1] == h2i('3b3fd92eb72dad20333449f8e83cfb4a') and ofb[3][1] == h2i('304c6528f659c77866a510d9c1d6ae5e')
    ctr = run_stream('CTR', 0, h2i('2b7e151628aed2a6abf7158809cf4f3c'), h2i('f0f1f2f3f4f5f6f7f8f9fafbfcfdfeff'), p)
    assert ctr[0][1] == h2i('874d6191b620e3261bef6864990db6ce') and ctr[3][1] == h2i('1e031dda2fbe03d1792170a0f3009cee')
    # F.3.13 CFB128 and F.3.7 CFB8 (first segments), F.3.1 CFB1 bits
    cfb = run_stream('CFB', 0, k, iv, p, 7)
    assert cfb[0][1] == h2i('3b3fd92eb72dad20333449f8e83cfb4a') and cfb[3][1] == h2i('c04b05357c5d1c0eeac4c66f9ff7f2e6')
    c8 = run_stream('CFB', 0, k, iv, [x << 120 for x in (0x6b, 0xc1, 0xbe, 0xe2)], 3)
    assert [r[1] >> 120 for r in c8] == [0x3b, 0x79, 0x42, 0x4c]
    c1 = run_stream('CFB', 0, k, iv, [int(b) << 127 for b in '0110101111000001'], 0)
    assert ''.join(str(r[1] >> 127) for r in c1) == '0110100010110011'
    # AESAVS ECBVarTxt128 COUNT=0 and ECBVarKey128 COUNT=0
    assert enc_block(bytes.fromhex('80' + '00' * 15), bytes(16)).hex() == '3ad78e726c1ec02b7ebfe92b23d9ec34'
    assert enc_block(bytes(16), bytes.fromhex('80' + '00' * 15)).hex() == '0edd33d3c621e546455bd8ba1418bec8'
    # every mode round-trips
    for m in MODE_CODE:
        blocks = [0x0123456789abcdef0123456789abcdef ^ (i * 0x1111) for i in range(5)]
        e = run_stream(m, 0, k, iv, blocks, 7)
        d = run_stream(m, 1, k, iv, [x[1] for x in e], 7)
        assert [x[1] for x in d] == blocks, m
    return True


if __name__ == '__main__':
    self_test()
    print('aes_ref self-test PASS (FIPS-197, SP 800-38A ECB/CBC/CFB128/CFB8/CFB1/OFB/CTR, AESAVS VarTxt/VarKey)')
