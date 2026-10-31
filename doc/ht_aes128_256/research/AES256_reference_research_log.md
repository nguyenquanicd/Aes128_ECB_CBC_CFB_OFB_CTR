# AES-256 Reference Research Log

Review date: 2026-10-28

## Scope

Review public AES-256 hardware references for standardized key expansion, verified implementation practice, and architectural trade-offs. Use NIST FIPS 197-upd1 and SP 800-38A as the normative behavior sources. Do not copy reference RTL or transfer its timing/PPA figures to this design.

## Search method and limits

- Ran the skill search script for GitHub and Gitee; DNS resolution failed in this environment. No repositories were downloaded.
- Manually reviewed primary project documentation, repositories, test-plan material, and license pages through the public web.
- Read the Chinese publisher page and English abstract for Xie and Guo (2013). The publisher page exposed the abstract but not the article body; its linked PDF returned HTTP 403. Treat the reported architectural details as abstract-level evidence with moderate confidence.

## Qualified reference IP

| IP | Qualification evidence | Technical relevance | License | Use here |
|---|---|---|---|---|
| OpenTitan AES HWIP | Official specification states AES-128/192/256 support and Earl Grey 1.0.0 tapeout. The project publishes AES NIST-vector and stress test plans. The repository is Apache-2.0. | Multi-key-size and five-mode support; on-the-fly round-key generation; documented latency and verification plans. Its medium-performance register interface is not the N-wide streaming architecture proposed for this IP. | Apache-2.0 | Review scope and verification practices only; no RTL copied. |
| secworks/aes | Public project states AES-128/256 support, ASIC and multiple FPGA implementations, and provides a FuseSoC testbench target. Repository license is BSD-2-Clause. | Iterative implementation, four S-boxes, key-schedule/resource trade-offs, and reported FPGA/ASIC implementation experience. Its iterative throughput differs from the proposed round-pipelined engine. | BSD-2-Clause | Architecture trade-off reference only; no RTL copied. |

## Chinese-language technical source

Xie Huimin and Guo Donghui, “Reconfigurable serial AES encryption and decryption circuit design,” *Journal of Computer Applications*, 33(02), 450–459 (2013), DOI 10.3724/SP.J.1087.2013.00450.

The Chinese and English abstracts describe a serial AES implementation supporting 128-, 192-, and 256-bit keys. They report composite-field byte inversion, shared MixColumns/InvMixColumns resources, and a shared key-expansion structure. The abstract reports a Xilinx Virtex-V implementation using 1,871 slices and four block RAMs, with a maximum frequency of 173.904 MHz and AES-256 throughput of 1,534 Mb/s. These are results of that FPGA implementation and are not targets or estimates for this ASIC design. The publisher's full article could not be retrieved in this review; the source is not qualified as a reference IP because a public RTL repository, associated testbench, and source license were not verified.

## Normative sources

- NIST FIPS 197-upd1, §§4–6, Appendix A.3, Appendix B.3, and Appendix C.3: AES-256 parameters, key expansion, cipher/inverse cipher, and known-answer example. Project-local converted copy: `doc/shared/references/md_doc/nist_fips_197_upd1.md`.
- NIST SP 800-38A, §§5–7 and applicable appendices: ECB, CBC, CFB, OFB, and CTR behavior. Project-local converted copy: `doc/shared/references/md_doc/nist_sp_800_38a.md`.

## Source links

- [OpenTitan AES HWIP specification](https://opentitan.org/book/hw/ip/aes/)
- [OpenTitan AES verification test plan](https://opentitan.org/book/hw/ip/aes/data/aes_testplan.html)
- [OpenTitan repository and Apache-2.0 licensing](https://github.com/lowRISC/opentitan)
- [secworks AES README](https://github.com/secworks/aes)
- [secworks AES license](https://github.com/secworks/aes/blob/master/LICENSE)
- [Xie and Guo (2013), publisher page](https://www.joca.cn/CN/10.3724/SP.J.1087.2013.00450)
- [NIST FIPS 197](https://csrc.nist.gov/pubs/fips/197/final)
- [NIST SP 800-38A](https://csrc.nist.gov/pubs/sp/800/38/a/final)
