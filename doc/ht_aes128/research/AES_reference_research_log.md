# Reference IP Research Log

Review date: 2026-10-27

## Search target

Find an AES IP with public evidence of silicon or FPGA use, documented mode behavior, and a reviewable license. The reference informs architecture and verification scope; it does not supply golden behavior in place of NIST standards and no reference RTL is copied.

## Search results

- `vlsit_ip_search.py search` was attempted for AES references. The tool could not resolve its GitHub/Gitee sources in this environment and returned zero candidates.
- Manual review used the primary OpenTitan documentation. The AES HWIP page documents AES modes and states that the IP was taped out in Earl Grey 1.0. The OpenTitan project history provides the Earl Grey silicon context. The AES verification checklist and theory-of-operation pages were also reviewed.
- OpenTitan is an architecture and verification reference only. Its documented iterative, medium-performance organization does not meet this project's chosen N-lane throughput target by itself.
- The public repository identifies Apache License 2.0. No source RTL was downloaded or copied.

## Qualified reference

| IP | Silicon / FPGA evidence | Useful material | License | Use in this specification |
|---|---|---|---|---|
| OpenTitan AES HWIP | AES documentation states Earl Grey 1.0 tapeout; project history documents production silicon | Supported modes, operational behavior, verification checklist | Apache-2.0 | Reference for security/verification review and known IP behavior; not the throughput architecture or golden model |

## Normative standards

NIST FIPS 197-upd1 and NIST SP 800-38A are the normative behavior sources. The user approved project-local copies and conversion on 2026-10-27. Both original PDFs were obtained from the official NIST publication pages, converted to Markdown, and verified against their PDF page counts and extracted text. The skill's bundled library remains unchanged.

| Standard | Retrieved source PDF | Size | SHA-256 | Project-local conversion |
|---|---|---:|---|---|
| NIST FIPS 197-upd1 | `doc/shared/references/org_doc/NIST.FIPS.197-upd1.pdf` | 1,184,436 bytes | `62c86eb567f13edb8f71826e985da870b04ef6381634f303cdb16e84d47becd1` | `doc/shared/references/md_doc/nist_fips_197_upd1.md` |
| NIST SP 800-38A | `doc/shared/references/org_doc/NIST.SP.800-38A.pdf` | 378,266 bytes | `66821162de1e7130c5fb5eedb22140d8d6d013ec51af4550bb095c2a9481a00e` | `doc/shared/references/md_doc/nist_sp_800_38a.md` |

Conversion verification reported 46 pages for FIPS 197-upd1 and 66 pages for SP 800-38A, with no page exceeding the converter's 5% text-difference threshold. Page 29 of SP 800-38A Appendix D was manually checked against the rendered source page because it contains a structured table; the recheck passed.

## Sources

- [OpenTitan AES HWIP](https://opentitan.org/book/hw/ip/aes/)
- [OpenTitan AES theory of operation](https://opentitan.org/book/hw/ip/aes/doc/theory_of_operation.html)
- [OpenTitan AES verification checklist](https://opentitan.org/book/hw/ip/aes/doc/checklist.html)
- [OpenTitan project history](https://opentitan.org/book/doc/project_governance/history.html)
- [OpenTitan license](https://github.com/lowRISC/opentitan/blob/master/LICENSE)
- [NIST FIPS 197-upd1](https://csrc.nist.gov/pubs/fips/197/final)
- [NIST SP 800-38A](https://csrc.nist.gov/pubs/sp/800/38/a/final)
- [NIST Technical Series copyright and citation terms](https://www.nist.gov/open/copyright-fair-use-and-licensing-statements-srd-data-software-and-technical-series-publications)
- [NIST SP 800-38A](https://csrc.nist.gov/pubs/sp/800/38/a/final)
- [NIST copyright and licensing guidance](https://www.nist.gov/open/copyright-fair-use-and-licensing-statements-srd-data-software-and-technical-series-publications)
