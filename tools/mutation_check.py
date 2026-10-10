"""Mutation check: prove that the testbenches can actually catch bugs.

Each mutant is the current RTL with ONE deliberate defect. A mutant is "killed" when at least
one testbench reports a failure (or a compile error / timeout). A surviving mutant means a hole
in the verification. The original (pre-fix) RTL from git is also run as a negative control.

usage (from the repository root, iverilog in PATH):
    python tools/mutation_check.py [--only m05] [--skip-original] [--fast]

Takes a few minutes. Results are printed as a table; exit code 1 if any mutant survives.
"""
import argparse
import os
import re
import shutil
import subprocess
import sys
import time

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
BUILD = os.path.join(ROOT, 'sim', 'build', 'mutants')

RTL_ORDER = ['aes128_pkg.sv', 'aes128_cipher_core.sv', 'aes128_cipher_core_inv.sv', 'aes128_key_expansion.sv',
             'aes128_key_expansion_inv.sv', 'aes128_cipher_top.sv', 'aes128_cipher_inv_top.sv', 'aes128.sv']

# (name, file, regex-or-literal pattern, replacement, description)
MUTANTS = [
    ('m01_cfb_dec_double_shift', 'aes128.sv', r"            cipher_input_block\[127:0\] = start_reg\[127:0\];",
     "            cipher_input_block[127:0] = {start_reg[119:0], end_reg[127:120]};", 'CFB decipher shifts twice (the original bug)'),
    ('m02_mode_needs_chain', 'aes128.sv', r"    else if \(start_process & first_block\)",
     "    else if (start_process & first_block & chain_en)", 'mode_reg loaded only with chain_en (the original bug)'),
    ('m03_no_data_capture', 'aes128.sv', r"assign data_e\[127:0\] = start_process\? data_in\[127:0\]: data_r\[127:0\];",
     "assign data_e[127:0] = data_in[127:0];", 'data_in not captured at start'),
    ('m04_no_seg_capture', 'aes128.sv', r"    case \(seg_r\[3:0\]\)",
     "    case (segment_len[3:0])", 'CFB result mask uses the live segment_len instead of the captured one'),
    ('m05_no_busy_gate', 'aes128.sv', r"assign start_process = start_req & ready & ~cfg_bad;",
     "assign start_process = start_req & ~cfg_bad;", 'start accepted while busy'),
    ('m06_no_segment_check', 'aes128.sv', r"                   \| \(\(mode_req\[3:0\] == AES128CFB\) & \(segment_len\[3:0\] > CFB128b\)\);",
     "                   ;", 'illegal CFB segment accepted'),
    ('m07_no_mode_check', 'aes128.sv', r"                   \| \(mode_req\[3:0\] > AES128CTR\)\n", "\n", 'illegal mode accepted'),
    ('m08_err_busy_missing', 'aes128.sv', r"      err_busy <= start_req & ~ready;", "      err_busy <= 1'b0;", 'err_busy never asserted'),
    ('m09_cfb_mask_removed', 'aes128.sv', r"\(data_r\[127:0\] \^ cipher_out\[127:0\]\) & cfb_seg_mask\[127:0\];",
     "(data_r[127:0] ^ cipher_out[127:0]);", 'CFB low bits not cleared'),
    ('m10_first_block_registered', 'aes128.sv', r"assign first_block = ~stream_active \| ~chain_en;",
     "assign first_block = ~stream_active;", 'chain_en=0 after a stream is not a first block'),
    ('m11_cbc_dec_prev_missing', 'aes128.sv', r"    else if \(end_decipher & \(mode_reg\[3:0\] == AES128CBC\)\) begin",
     "    else if (1'b0) begin", 'CBC decipher never updates the previous ciphertext'),
    ('m12_ofb_end_reg_missing', 'aes128.sv', r"        AES128OFB: end_reg\[127:0\] <= cipher_out\[127:0\];",
     "        AES128OFB: ;", 'OFB feedback register never updated'),
    ('m13_ctr_uses_data', 'aes128.sv', r"        AES128CTR: cipher_input_block\[127:0\] = init_vector\[127:0\];",
     "        AES128CTR: cipher_input_block[127:0] = data_e[127:0];", 'CTR counter block replaced by data'),
    ('m14_ready_early', 'aes128.sv', r"        AES128ECB: set_ready = end_decipher;",
     "        AES128ECB: set_ready = end_cipher;", 'ECB decipher reports ready after the key pass'),
    ('m15_chain_never_ends', 'aes128.sv', r"    else if \(~chain_en\)\n      stream_active <= 1'b0;",
     "    else if (1'b0)\n      stream_active <= 1'b0;", 'a stream never ends'),
    ('m16_rcon_wrong', 'aes128_pkg.sv', r"aes128_rcon\[31:0\] = 32'h0800_0000;", "aes128_rcon[31:0] = 32'h0900_0000;", 'wrong round constant'),
    ('m17_mixcol_wrong', 'aes128_pkg.sv', r"mixcol\[31:24\] = mul2\(mixcol_in\[31:24\]\) \^ mul3\(mixcol_in\[23:16\]\)",
     "mixcol[31:24] = mul2(mixcol_in[31:24]) ^ mul2(mixcol_in[23:16])", 'wrong MixColumns coefficient'),
    ('m18_cbc_iv_missing', 'aes128.sv', r"        AES128CBC: cipher_input_block\[127:0\] = data_e\[127:0\] \^ init_vector\[127:0\];",
     "        AES128CBC: cipher_input_block[127:0] = data_e[127:0];", 'CBC first block ignores the IV'),
]


def run(cmd, timeout, cwd=ROOT):
    try:
        p = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, timeout=timeout, errors='replace')
        return p.returncode, p.stdout + p.stderr, False
    except subprocess.TimeoutExpired as e:
        return -1, (e.stdout or '') if isinstance(e.stdout, str) else '', True


def tb_sets(rtl_files, fast):
    """(label, tb sources, top, plusargs list) in cheap-to-expensive order."""
    chk = os.path.join(ROOT, 'checker', 'aes128_protocol_checker.sv')
    tb = lambda n: os.path.join(ROOT, 'tb', n)
    sets = [
        ('protocol', [chk, tb('tb_aes128_protocol.sv')], 'tb_aes128_protocol', [[]]),
        ('vec', [chk, tb('tb_aes128_vec.sv')], 'tb_aes128_vec', [
            ['+VEC=vectors/nist.hex'], ['+VEC=vectors/chain0.hex'], ['+VEC=vectors/rand_s3.hex', '+MID=5'],
            ['+VEC=vectors/rand_s1.hex', '+SCR=31', '+JUNK=1'], ['+VEC=vectors/rand_s2.hex', '+EARLY=3']]),
        ('prim', [tb('tb_aes128_prim.sv')], 'tb_aes128_prim', [[]]),
    ]
    if not fast:
        sets.append(('roundtrip', [chk, tb('tb_aes128_roundtrip.sv')], 'tb_aes128_roundtrip', [['+N=60', '+SEED=7']]))
    return sets


def evaluate(name, rtl_files, outdir, fast, extra_inc=()):
    """Return (killed, by) ."""
    os.makedirs(outdir, exist_ok=True)
    for label, srcs, top, runs in tb_sets(rtl_files, fast):
        vvp = os.path.join(outdir, top + '.vvp')
        cmd = ['iverilog', '-g2012', '-Wno-timescale', '-I', os.path.join(ROOT, 'tb'), '-I', os.path.join(ROOT, 'tb', 'ref'),
               '-s', top, '-o', vvp] + rtl_files + srcs
        rc, out, to = run(cmd, 300)
        if rc != 0 or not os.path.exists(vvp):
            return True, '%s: does not compile' % label
        for pa in runs:
            rc, out, to = run(['vvp', vvp] + pa, 400)
            if to:
                return True, '%s %s: timeout' % (label, ' '.join(pa))
            if 'TEST_RESULT: PASS' not in out:
                return True, '%s %s' % (label, ' '.join(pa))
    return False, ''


def make_mutant(m, outroot):
    name, fname, pat, rep, desc = m
    d = os.path.join(outroot, name)
    shutil.rmtree(d, ignore_errors=True)
    os.makedirs(d)
    for f in RTL_ORDER:
        shutil.copy(os.path.join(ROOT, 'rtl', f), os.path.join(d, f))
    path = os.path.join(d, fname)
    txt = open(path, 'rb').read().decode('utf-8').replace('\r\n', '\n')
    new, n = re.subn(pat, rep, txt, count=1)
    if n != 1:
        raise SystemExit('mutant %s: pattern not found (RTL changed?): %s' % (name, pat))
    open(path, 'wb').write(new.encode('utf-8'))
    return [os.path.join(d, f) for f in RTL_ORDER]


def make_original(outroot):
    """Pre-fix RTL from git HEAD wrapped so that the new testbenches (named ports) can drive it."""
    d = os.path.join(outroot, 'original_git_HEAD')
    shutil.rmtree(d, ignore_errors=True)
    os.makedirs(d)
    names = ['aes128_sbox.sv', 'aes128_mul.sv', 'aes128_mul_inv.sv', 'aes128_rcon.sv', 'aes128_rcon_inv.sv',
             'aes128_cipher_core.sv', 'aes128_cipher_core_inv.sv', 'aes128_cipher_inv_top.sv', 'aes128_cipher_top.sv',
             'aes128_key_expansion.sv', 'aes128_key_expansion_inv.sv', 'aes128.sv']
    rc, out, _ = run(['git', 'rev-parse', '--verify', 'HEAD'], 30)
    if rc != 0:
        return None
    files = []
    for n in names:
        rc, txt, _ = run(['git', 'show', 'HEAD:rtl/' + n], 30)
        if rc != 0 or not txt.strip():
            return None
        if n == 'aes128.sv':
            txt = txt.replace('module aes128 (', 'module aes128_orig (', 1)
        p = os.path.join(d, n)
        open(p, 'w', newline='\n').write(txt)
        files.append(p)
    shim = os.path.join(d, 'aes128_shim.sv')
    open(shim, 'w', newline='\n').write(
        "module aes128 (input clk, input rst_n, input cipher_en, input decipher_en, input chain_en,\n"
        "  input [127:0] data_in, input [127:0] key, input [3:0] mode, input [127:0] init_vector,\n"
        "  input [3:0] segment_len, output [127:0] data_out, output ready, output err_busy, output err_cfg);\n"
        "  assign err_busy = 1'b0; assign err_cfg = 1'b0;\n"
        "  aes128_orig u (.clk(clk), .rst_n(rst_n), .cipher_en(cipher_en), .decipher_en(decipher_en), .chain_en(chain_en),\n"
        "    .data_in(data_in), .key(key), .mode(mode), .init_vector(init_vector), .segment_len(segment_len),\n"
        "    .data_out(data_out), .ready(ready));\nendmodule\n")
    files.append(shim)
    return files


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--only', default='')
    ap.add_argument('--skip-original', action='store_true')
    ap.add_argument('--fast', action='store_true', help='skip the random round-trip testbench')
    a = ap.parse_args()
    if shutil.which('iverilog') is None:
        raise SystemExit('iverilog not found in PATH (activate the OSS CAD Suite first)')
    os.makedirs(BUILD, exist_ok=True)
    rows = []
    t0 = time.time()
    if not a.skip_original and not a.only:
        f = make_original(BUILD)
        if f:
            k, by = evaluate('original', f, os.path.join(BUILD, 'original_git_HEAD', 'b'), a.fast)
            rows.append(('original RTL (git HEAD)', 'pre-fix design, negative control', k, by))
            print('%-34s %-9s %s' % (rows[-1][0], 'KILLED' if k else 'SURVIVED', by), flush=True)
        else:
            print('original RTL not available from git, skipped')
    for m in MUTANTS:
        if a.only and a.only not in m[0]:
            continue
        files = make_mutant(m, BUILD)
        k, by = evaluate(m[0], files, os.path.join(BUILD, m[0], 'b'), a.fast)
        rows.append((m[0], m[4], k, by))
        print('%-34s %-9s %s' % (m[0], 'KILLED' if k else 'SURVIVED', by), flush=True)
    killed = sum(1 for r in rows if r[2])
    print('\n%d / %d mutants killed in %d s' % (killed, len(rows), time.time() - t0))
    sys.exit(0 if killed == len(rows) else 1)


if __name__ == '__main__':
    main()
