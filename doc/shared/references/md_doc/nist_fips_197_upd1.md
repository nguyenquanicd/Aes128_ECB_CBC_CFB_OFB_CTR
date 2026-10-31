---
protocol: "FIPS 197"
revision: "FIPS 197-upd1 (updated 2023-05-09)"
source: "https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.197-upd1.pdf"
license: "NIST federal publication; public domain in the U.S.; worldwide reuse under NIST terms; credit NIST"
redistribution: "allowed"
retrieved: 2026-10-27
source_sha256: "62c86eb567f13edb8f71826e985da870b04ef6381634f303cdb16e84d47becd1"
converter: "vlsit_pdf_to_md.py (PyMuPDF)"
---

# FIPS 197 - revision FIPS 197-upd1 (updated 2023-05-09)

> **Key notes (written by the converter operator, not part of the source):**
> - Use §§4–6 and Appendix C.1 for the AES-128 primitive and known-answer example. The 2023 update states no technical change to the AES algorithm.

> The text between the markers below is the source text, converted without rewording.

<!-- BEGIN VERBATIM SOURCE -->

<!-- page 1 -->

# FIPS 197

Federal Information Processing Standards Publication

# Advanced Encryption Standard (AES)

Category: Computer Security
Subcategory: Cryptography

Information Technology Laboratory
National Institute of Standards and Technology
Gaithersburg, MD 20899-8900

This publication is available free of charge from:
https://doi.org/10.6028/NIST.FIPS.197-upd1

Published November 26, 2001; Updated May 9, 2023

U.S. Department of Commerce
Donald L. Evans, Secretary

Technology Administration
Phillip J. Bond, Under Secretary for Technology

National Institute of Standards and Technology

Karen H. Brown, Acting Director

<!-- page 2 -->

### Foreword

The Federal Information Processing Standards Publication Series of the National Institute of Standards and
Technology is the offcial series of publications relating to standards and guidelines developed under 15
U.S.C. 278g-3, and issued by the Secretary of Commerce under 40 U.S.C. 11331.

Comments concerning this Federal Information Processing Standard publication are welcomed and should
be submitted using the contact information in the “Inquiries and comments” clause of the announcement
section.

James A. St. Pierre, Acting Director
Information Technology Laboratory

<!-- page 3 -->

FIPS 197
ADVANCED ENCRYPTION STANDARD (AES)

### Abstract

In 2000, NIST announced the selection of the Rijndael block cipher family as the winner of the
Advanced Encryption Standard (AES) competition. Block ciphers are the foundation for many
cryptographic services, especially those that provide assurance of the confdentiality of data.

Three members of the Rijndael family are specifed in this Standard: AES-128, AES-192, and
AES-256. Each of them transforms data in blocks of 128 bits, and the numerical suffx indicates
the bit length of the associated cryptographic keys.

Keywords: AES; block cipher; confdentiality; cryptography; encryption; Rijndael.

ii

<!-- page 4 -->

FIPS 197
ADVANCED ENCRYPTION STANDARD (AES)

### Federal Information

### Processing Standards Publication 197

### Published: November 26, 2001

Updated: May 9, 2023

## Announcing the

## ADVANCED ENCRYPTION STANDARD (AES)

Federal Information Processing Standards Publications (FIPS) are developed by NIST under 15
U.S.C. 278g-3 and issued by the Secretary of Commerce under 40 U.S.C. 11331.

1. Name of Standard. Advanced Encryption Standard (AES) (FIPS 197).

2. Category of Standard. Computer Security Standard, Cryptography.

3. Explanation. The Advanced Encryption Standard (AES) specifes a FIPS-approved cryp­
tographic algorithm that can be used to protect electronic data. The AES algorithm is a
symmetric block cipher that can encrypt (encipher) and decrypt (decipher) digital information.

The AES algorithm is capable of using cryptographic keys of 128, 192, and 256 bits to encrypt
and decrypt data in blocks of 128 bits.

4. Approving Authority. Secretary of Commerce.

5. Maintenance Agency. Department of Commerce, National Institute of Standards and Tech­
nology, Information Technology Laboratory (ITL).

6. Applicability. Federal Information Processing Standards apply to information systems used
or operated by federal agencies, a contractor of an agency, or other organization on behalf of
an agency. They do not apply to national security systems as defned in 44 U.S.C. 3552.

This Standard may be used by federal agencies to protect information when they have deter-
mined that encryption is appropriate, in accordance with applicable Offce of Management
and Budget and agency policies. Federal agencies may also use alternative methods that NIST
has indicated are appropriate for this purpose.

This Standard may be adopted and used by non-Federal Government organizations.

7. Specifcations. Federal Information Processing Standard (FIPS) 197, Advanced Encryption
Standard (AES) (affxed).

8. Implementations. The algorithm specifed in this Standard may be implemented in software,
frmware, hardware, or any combination thereof. The specifc implementation may depend
on several factors, such as the application, the environment, the technology used, etc. The
algorithm shall be used in conjunction with a FIPS-approved or NIST-recommended mode
of operation. Object Identifers (OIDs) and any associated parameters for AES used in

iii

<!-- page 5 -->

FIPS 197
ADVANCED ENCRYPTION STANDARD (AES)

these modes are available at the Computer Security Objects Register (CSOR), located at
https://csrc.nist.gov/projects/csor.

NIST has developed a validation program to test implementations for conformance to the
algorithms in this Standard. Information about the validation program is available at https:
//nist.gov/cmvp. Examples for each key size are available at https://csrc.nist.gov/projects/aes.

9. Implementation Schedule. This Standard became effective on May 26, 2002.

10. Patents. Implementations of the algorithm specifed in this Standard may be covered by U.S.
and foreign patents.

11. Export Control. Certain cryptographic devices and technical data regarding them are subject
to federal export controls. Exports of cryptographic modules implementing this Standard and
technical data regarding them must comply with all federal laws and regulations and must
be licensed by the Bureau of Industry and Security of the U.S. Department of Commerce.
Information about export regulations is available at https://www.bis.doc.gov.

12. Qualifcations. NIST will continue to follow developments in the analysis of the AES
algorithm. As with its other cryptographic algorithm standards, NIST will formally reevaluate
this Standard every fve years.

Both this Standard and possible threats reducing the security provided through the use of this
Standard will undergo review by NIST as appropriate, taking into account newly available
analysis and technology. In addition, the awareness of any breakthrough in technology or
any mathematical weakness of the algorithm will cause NIST to reevaluate this Standard and
provide necessary revisions.

13. Where to Obtain Copies. This publication is available by accessing https://csrc.nist.gov/
publications. Other computer security publications are available at the same website.

14. Inquiries and Comments. Inquiries and comments about this FIPS may be submitted to
fps-197-comments@nist.gov.

15. How to Cite This Publication. NIST has assigned NIST FIPS 197-upd1 as the publication
identifer for this FIPS, per the NIST Technical Series Publication Identifer Syntax. NIST
recommends that it be cited as follows:

National Institute of Standards and Technology (2001) Advanced Encryption
Standard (AES). (Department of Commerce, Washington, D.C.), Federal Infor­
mation Processing Standards Publication (FIPS) NIST FIPS 197-upd1, updated
May 9, 2023. https://doi.org/10.6028/NIST.FIPS.197-upd1

iv

<!-- page 6 -->

FIPS 197
ADVANCED ENCRYPTION STANDARD (AES)

### Federal Information

### Processing Standards Publication 197

## Specifcation for the

## ADVANCED ENCRYPTION STANDARD (AES)

### Table of Contents

1 Introduction
1

2 Defnitions
2

2.1 Terms and Acronyms . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
2

2.2 List of Functions . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
3

2.3 Algorithm Parameters and Symbols . . . . . . . . . . . . . . . . . . . . . .
4

3 Notation and Conventions
5

3.1 Inputs and Outputs . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
5

3.2 Bytes . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
5

3.3 Indexing of Byte Sequences . . . . . . . . . . . . . . . . . . . . . . . . . . .
5

3.4 The State . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
6

3.5 Arrays of Words . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
7

4 Mathematical Preliminaries
8

4.1 Addition in GF(28) . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
8

4.2 Multiplication in GF(28) . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
8

4.3 Multiplication of Words by a Fixed Matrix . . . . . . . . . . . . . . . . . .
9

4.4 Multiplicative Inverses in GF(28) . . . . . . . . . . . . . . . . . . . . . . . .
10

5 Algorithm Specifcations
11

5.1 CIPHER() . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
12
5.1.1
SUBBYTES() . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
13
5.1.2
SHIFTROWS() . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
14
5.1.3
MIXCOLUMNS() . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
15
5.1.4
ADDROUNDKEY() . . . . . . . . . . . . . . . . . . . . . . . . . . . .
16
5.2 KEYEXPANSION() . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
17

v

<!-- page 7 -->

FIPS 197
ADVANCED ENCRYPTION STANDARD (AES)

5.3 INVCIPHER() . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
18
5.3.1
INVSHIFTROWS() . . . . . . . . . . . . . . . . . . . . . . . . . . . .
22
5.3.2
INVSUBBYTES() . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
23
5.3.3
INVMIXCOLUMNS() . . . . . . . . . . . . . . . . . . . . . . . . . . .
24
5.3.4
Inverse of ADDROUNDKEY() . . . . . . . . . . . . . . . . . . . . . .
24
5.3.5
EQINVCIPHER() . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
24

6 Implementation Considerations
26

6.1 Key Length Requirements . . . . . . . . . . . . . . . . . . . . . . . . . . . .
26

6.2 Keying Restrictions . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
26

6.3 Parameter Extensions . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
26

6.4 Implementation Suggestions Regarding Various Platforms . . . . . . . . .
26

6.5 Modes of Operation . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
27

References
28

Appendix A — Key Expansion Examples
29

A.1 Expansion of a 128-bit Key . . . . . . . . . . . . . . . . . . . . . . . . . . .
29

A.2 Expansion of a 192-bit Key . . . . . . . . . . . . . . . . . . . . . . . . . . .
30

A.3 Expansion of a 256-bit Key . . . . . . . . . . . . . . . . . . . . . . . . . . .
32

Appendix B — Cipher Example
34

Appendix C — Example Vectors
36

Appendix D — Change Log (Informative)
37

vi

<!-- page 8 -->

FIPS 197
ADVANCED ENCRYPTION STANDARD (AES)

### List of Tables

Table 1
Hexadecimal representation of 4-bit sequences . . . . . . . . . . . . . .
5
Table 2
Indices for bytes and bits . . . . . . . . . . . . . . . . . . . . . . . . . .
6
Table 3
Key-Block-Round Combinations . . . . . . . . . . . . . . . . . . . . . . . 11
Table 4
SBOX(): substitution values for the byte xy (in hexadecimal format) . . .
14
Table 5
Round constants . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
17
Table 6
INVSBOX(): substitution values for the byte xy (in hexadecimal format)
23

### List of Figures

Figure 1
State array input and output . . . . . . . . . . . . . . . . . . . . . . . .
7
Figure 2
Illustration of SUBBYTES() . . . . . . . . . . . . . . . . . . . . . . . .
13
Figure 3
Illustration of SHIFTROWS() . . . . . . . . . . . . . . . . . . . . . . .
15
Figure 4
Illustration of MIXCOLUMNS() . . . . . . . . . . . . . . . . . . . . . .
16
Figure 5
Illustration of ADDROUNDKEY() . . . . . . . . . . . . . . . . . . . . .
16
Figure 6
KEYEXPANSION() of AES-128 to generate the words w[i] for 4 ≤ i < 44,
where l ranges over the multiples of 4 between 0 and 36 . . . . . . . . . . . . .
19
Figure 7
KEYEXPANSION() of AES-192 to generate the words w[i] for 6 ≤ i < 52,
where l ranges over the multiples of 6 between 0 and 42 . . . . . . . . . . . . .
20
Figure 8
KEYEXPANSION() of AES-256 to generate the words w[i] for 8 ≤ i < 60,
where l ranges over the multiples of 8 between 0 and 48 . . . . . . . . . . . . . . 21
Figure 9
Illustration of INVSHIFTROWS() . . . . . . . . . . . . . . . . . . . . .
23

### List of Algorithms

Algorithm 1
Pseudocode for CIPHER() . . . . . . . . . . . . . . . . . . . . . . .
12
Algorithm 2
Pseudocode for KEYEXPANSION() . . . . . . . . . . . . . . . . . .
18
Algorithm 3
Pseudocode for INVCIPHER() . . . . . . . . . . . . . . . . . . . . .
22
Algorithm 4
Pseudocode for EQINVCIPHER() . . . . . . . . . . . . . . . . . . .
25
Algorithm 5
Pseudocode for KEYEXPANSIONEIC() . . . . . . . . . . . . . . .
25

vii

<!-- page 9 -->

FIPS 197
ADVANCED ENCRYPTION STANDARD (AES)

## 1. Introduction

A block is a sequence of bits of a given fxed length. A block cipher is a family of permutations
of blocks that is parameterized by a sequence of bits called the key.

In 1997, NIST initiated the Advanced Encryption Standard (AES) development effort [1] and
called for the public to submit candidate algorithms for block ciphers. Block ciphers are the
foundation for many cryptographic services, especially those that provide assurance of the
confdentiality of data. In 2000, NIST announced the selection of Rijndael [2, 3] for the AES.

This Standard specifes three instantiations of Rijndael: AES-128, AES-192, and AES-256, where
the suffx indicates the bit length of the key. The block size (i.e., the length of the data inputs and
outputs) is 128 bits in each case. Rijndael supports additional block sizes and key lengths that are
not adopted in this Standard.

This Standard is organized as follows:

• Section 2 defnes the terms, acronyms, algorithm parameters, symbols, and functions in
this Standard.

• Section 3 describes the notation and conventions for the ordering and indexing of bits,
bytes, and words.

• Section 4 explains some mathematical components of the AES specifcations: fnite feld
arithmetic and multiplication by a fxed matrix of fnite feld elements.

• Section 5 specifes AES-128, AES-192, and AES-256.

• Section 6 provides implementation guidelines on key length requirements, keying restric­
tions, parameter extensions, and implementation suggestions regarding various platforms.

• Appendix A gives examples of the key expansion routines for AES-128, AES-192, and
AES-256.

• Appendix B gives a step-by-step example of an invocation of AES-128.

• Appendix C gives a reference to the NIST website for extensive example vectors for
AES-128, AES-192, and AES-256.

• Appendix D summarizes the updates to the original version of this publication.

1

<!-- page 10 -->

FIPS 197
ADVANCED ENCRYPTION STANDARD (AES)

## 2. Defnitions

### 2.1 Terms and Acronyms

The following defnitions are used in this Standard:

AES
Advanced Encryption Standard.

Affne
A transformation consisting of multiplication by a matrix, followed
transformation
by the addition of a vector.

Array
A fxed-size data structure that stores a collection of elements, where
each element is identifed by its integer index or indices.

Bit
A binary digit: 0 or 1.

Block
A sequence of bits of a given fxed length. In this Standard, blocks
consist of 128 bits, sometimes represented as arrays of bytes or words.

Block cipher
A family of permutations of blocks that is parameterized by the key.

Byte
A sequence of eight bits.

Equivalent inverse
An alternative specifcation of the inverse of CIPHER() with a struc­
cipher
ture similar to that of CIPHER() and with a modifed key schedule as
input.

Key
The parameter of a block cipher that determines the selection of a
permutation from the block cipher family.

Key schedule
The sequence of round keys that are generated from the key by

KEYEXPANSION().

Rijndael
The block cipher that NIST selected as the winner of the AES com­
petition.

Round
A sequence of transformations of the state that is iterated Nr times in
the specifcations of CIPHER(), INVCIPHER(), and EQINVCIPHER().
The sequence consists of four transformations, except for one itera­
tion, in which one of the transformations is omitted.

Round key
One of the Nr + 1 arrays of four words that are derived from the
block cipher key using the key expansion routine; each round key
is an input to an instance of ADDROUNDKEY() in the AES block
cipher.

State
Intermediate result of the AES block cipher that is represented as a
two-dimensional array of bytes with four rows and Nb columns.

S-box
A non-linear substitution table used in SUBBYTES() and KEYEX­

PANSION() to perform a one-to-one substitution of a byte value.

Word
A group of 32 bits that is treated either as a single entity or as an array
of 4 bytes.

2

<!-- page 11 -->

FIPS 197
ADVANCED ENCRYPTION STANDARD (AES)

### 2.2 List of Functions

The following functions are specifed in this Standard:

ADDROUNDKEY()
The transformation of the state in which a round key is combined
with the state.
AES-128()
The block cipher specifed in this Standard with 128-bit keys.

AES-192()
The block cipher specifed in this Standard with 192-bit keys.

AES-256()
The block cipher specifed in this Standard with 256-bit keys.

CIPHER()
The transformation of blocks that underlies AES-128, AES-192,
and AES-256; the key schedule and the number of rounds are
parameters of the transformation.

EQINVCIPHER()
The inverse of CIPHER() in which dw replaces w as the key schedule
parameter.

INVCIPHER()
The inverse of CIPHER().

INVMIXCOLUMNS()
The inverse of MIXCOLUMNS().

INVSBOX()
The inverse of SBOX().

INVSHIFTROWS()
The inverse of SHIFTROWS().

INVSUBBYTES()
The inverse of SUBBYTES().

KEYEXPANSION()
The routine that generates the round keys from the key.

KEYEXPANSIONEIC()
The routine that generates the modifed round keys for the equiva­
lent inverse cipher.

MIXCOLUMNS()
The transformation of the state that takes all of the columns of the
state and mixes their data (independently of one another) to produce
new columns.
ROTWORD()
The transformation of words in which the four bytes of the word
are permuted cyclically.

SBOX()
The transformation of bytes defned by the S-box.

SHIFTROWS()
The transformation of the state in which the last three rows are
cyclically shifted by different offsets.

SUBBYTES()
The transformation of the state that applies the S-box independently
to each byte of the state.

SUBWORD()
The transformation of words in which the S-box is applied to each
of the four bytes of the word.

XTIMES()
The transformation of bytes in which the polynomial representation
of the input byte is multiplied by x, modulo m(x), to produce the
polynomial representation of the output byte.

3

<!-- page 12 -->

FIPS 197
ADVANCED ENCRYPTION STANDARD (AES)

### 2.3 Algorithm Parameters and Symbols

b−1
The multiplicative inverse of the element b in GF(28).

b˜
The input to the affne transformation in the AES S-box.

dw
Word array for the key schedule that is input to the equivalent

inverse cipher.

GF(2)
Finite feld with two elements.

GF(28)
Finite feld with 256 elements.

in
The data input to CIPHER() or INVCIPHER(), represented as an
array of 16 bytes indexed from 0 to 15.

m(x)
The modulus specifed in this standard for the polynomial represen­
tation of bytes as elements of GF(28).

key
The array of Nk words that comprise the key for AES-128, AES­
192, or AES-256.

Nb
The number of columns comprising the state, where each column
is a 32-bit word. For this Standard, Nb = 4.

Nk
The number of 32-bit words comprising the key. Nk is assigned
to 4, 6, and 8 for AES-128, AES-192, and AES-256, respectively.
(see Section 6.3).

Nr
The number of rounds. Nr is assigned to 10, 12, and 14 for AES­
128, AES-192, and AES-256, respectively.
out
The data output of CIPHER() or INVCIPHER(), represented as an
array of 16 bytes indexed from 0 to 15.

Rcon
Word array for the round constant.
state
The state, represented as a two-dimensional array of 16 bytes, with
rows and columns indexed from 0 to 3.
u[i]
For a one-dimensional array u of words or bytes, the element in the
array that is indexed by a non-negative integer i.

u[i..i + 3]
For an array u of words, the sequence u[i],u[i + 1],u[i + 2],u[i + 3].

w
Word array for the key schedule.

⊕
Either the exclusive-OR operation on bits, the bitwise exclusive-OR
operation on bytes, or the bitwise exclusive-OR operation on words.

•
 

Multiplication in GF 28 .

∗
Integer multiplication.
←
Assignment of a variable in pseudocode.

{}
Delimiters for a byte in hexadecimal or binary notation.

4

<!-- page 13 -->

FIPS 197
ADVANCED ENCRYPTION STANDARD (AES)

## 3. Notation and Conventions

### 3.1 Inputs and Outputs

A bit is a binary digit — 0 or 1. A block is a sequence of 128 bits; the data input and output for
the AES block ciphers are blocks. Another input to the AES block ciphers, called the key, is a bit
sequence that is typically established beforehand and maintained across many invocations of the
block cipher. The lengths of the keys for AES-128, AES-192, and AES-256 are 128 bits, 192 bits,
and 256 bits, respectively.

### 3.2 Bytes

The basic processing unit in the AES algorithms is the byte — a sequence of eight bits.

 

A byte value is denoted by the concatenation of the eight bits between braces e.g., {10100011} .
When the bits of a byte are denoted by an indexed variable, the convention in this Standard is for
 

the indices to decrease from left to right i.e., {b7 b6 b5 b4 b3 b2 b1 b0} .

It is also convenient to denote byte values using hexadecimal notation. The 16 hexadecimal
characters represent sequences of four bits, as listed in Table 1. A byte is represented by an
ordered pair of hexadecimal characters, where the left character in the pair represents the four
left-most bits(i.e., b7,b6,b5,b4), and the right character in the pair represents the four right-most
bits (i.e., b3,b2,b1,b0). For example, the hexadecimal form of the byte {10100011} is {a3}.

Table 1. Hexadecimal representation of 4-bit sequences

Sequence
0000 0001 0010 0011 0100 0101 0110 0111
Character
0
1
2
3
4
5
6
7
Sequence
1000 1001 1010 1011 1100 1101 1110 1111
Character
8
9
a
b
c
d
e
f

### 3.3 Indexing of Byte Sequences

In order to unambiguously represent the data and key inputs as sequences of bytes, the following
indexing convention is adopted in this Standard. Given a sequence of 8k bits,

r0 r1 r2 ... r(8k−3) r(8k−2) r(8k−1)
(3.1)

(for some positive integer k), the bytes aj for 0 ≤ j ≤ k − 1 are defned as follows:

a j = {r8 j r(8 j+1) ... r(8 j+7)}.
(3.2)

Thus, for example, the data block

r0 r1 r2 ... r125 r126 r127
(3.3)

5

<!-- page 14 -->

FIPS 197
ADVANCED ENCRYPTION STANDARD (AES)

is represented by the byte sequence

a0 a1 a2 ... a13 a14 a15,
(3.4)

where

a0 ={r0 r1 ... r7};
a1 ={r8 r9 ... r15};

(3.5)

. . .
a15 ={r120 r121 ... r127}.

As described in Section 3.2, the bits within any individual byte are indexed in decreasing order
from left to right. This ordering is more natural for the fnite feld arithmetic on bytes that is
described in Section 4. The two types of bit indices for byte sequences are illustrated in Table 2.

Table 2. Indices for bytes and bits

Bit index in sequence
0 1 2 3 4 5 6 7
8 9 10 11 12 13 14 15
. . .

Byte index
0
1
. . .

Bit index in byte
7 6 5 4 3 2 1 0
7 6
5
4
3
2
1
0
. . .

### 3.4 The State

Internally, the algorithms for the AES block ciphers are performed on a two-dimensional (four­
by-four) array of bytes called the state. In the state array, denoted by s, each individual byte has
two indices: a row index r in the range 0 ≤ r < 4 and a column index c in the range 0 ≤ c < 4.
An individual byte of the state is denoted by either sr,c or s[r,c].

In the specifcations for the AES block cipher algorithms in Section 5, the frst step is to copy the
input array of bytes in0, in1, ..., in15 to the state array s as follows:

s[r,c] = in[r + 4c]
for 0 ≤ r < 4 and 0 ≤ c < 4.
(3.6)

A sequence of transformations is then applied to the state array, after which its fnal value is
copied to the output array of bytes out0, out1, ..., out15 as follows:

out[r + 4c] = s[r,c]
for 0 ≤ r < 4 and 0 ≤ c < 4.
(3.7)

The correspondence between the indices of the input and output with the indices of the state array
is illustrated in Fig. 1.

6

<!-- page 15 -->

FIPS 197
ADVANCED ENCRYPTION STANDARD (AES)

input bytes
state array
output bytes

in0
in4
in8
in12
s0,0
s0,1
s0,2
s0,3
out0
out4
out8
out12
in1
in5
in9
in13
s1,0
s1,1
s1,2
s1,3
out1
out5
out9
out13
→
→
in2
in6
in10
in14
s2,0
s2,1
s2,2
s2,3
out2
out6
out10
out14
in3
in7
in11
in15
s3,0
s3,1
s3,2
s3,3
out3
out7
out11
out15

Figure 1. State array input and output

### 3.5 Arrays of Words

A word is a sequence of four bytes; a block consists of four words. The four columns of state
array s are interpreted as an array v of four words as follows, in the notation of Fig. 1:

⎞
⎛
⎞
⎛
⎞
⎛
⎞
⎛

s0,0
s1,0
s2,0

s0,1
s1,1
s2,1

s0,2
s1,2
s2,2

s0,3
s1,3
s2,3

⎟
⎟
⎠, v1 =

⎟
⎟
⎠, v2 =

⎟
⎟
⎠, v3 =

⎟
⎟
⎠.

v0 =

⎜
⎜
⎝

⎜
⎜
⎝

⎜
⎜
⎝

⎜
⎜
⎝

(3.8)

s3,0
s3,1
s3,2
s3,3

Thus, the column index c of s becomes the index for v, and the row index r of s becomes the
index for the four bytes in each word.

Given a one-dimensional array u of words, u[i] denotes the word that is indexed by i, and the
sequence of four words u[i],u[i + 1],u[i + 2],u[i + 3] is denoted by u[i..i + 3].

7

<!-- page 16 -->

FIPS 197
ADVANCED ENCRYPTION STANDARD (AES)

## 4. Mathematical Preliminaries

For some transformations of the AES algorithms specifed in Sec. 5, each byte in the state array
is interpreted as one of the 256 elements of a fnite feld, also known as a Galois Field, denoted
by GF(28). 1

In order to defne addition and multiplication in GF(28), each byte {b7 b6 b5 b4 b3 b2 b1 b0} is
interpreted as a polynomial, denoted by b(x), as follows:

7
6
5
4
3
2
b(x) = b7 x + b6 x + b5 x + b4 x + b3 x + b2 x + b1 x + b0.
(4.1)

For example, {01100011} is represented by the polynomial x6 + x5 + x + 1.

### 4.1 Addition in GF(28)

In order to add two elements in the fnite feld GF(28), the coeffcients of the polynomials that
represent the elements are added modulo 2 (i.e., with the exclusive-OR operation, denoted by ⊕),
so that 1⊕ 1 = 0, 1⊕ 0 = 1, and 0 ⊕ 0 = 0.

Equivalently, two bytes can be added by applying the exclusive-OR operation to each pair of corre­
sponding bits in the bytes. Thus, the sum of {a7 a6 a5 a4 a3 a2 a1 a0} and {b7 b6 b5 b4 b3 b2 b1 b0}
is {a7 ⊕ b7 a6 ⊕ b6 a5 ⊕ b5 a4 ⊕ b4 a3 ⊕ b3 a2 ⊕ b2 a1 ⊕ b1 a0 ⊕ b0}. (In Section 5.1.4, this
defnition is extended to words.)

For example, the following three representations of addition are equivalent:

6
4
2
7
7
6
4
2
(x + x + x + x + 1)+(x + x + 1) = x + x + x + x
(polynomial)
{01010111}⊕{10000011} = {11010100}
(binary)
{57}⊕{83} = {d4}
(hexadecimal).

(4.2)

Because the coeffcients of the polynomials are reduced modulo 2, the coeffcient 1 is equivalent
to the coeffcient –1, so addition is equivalent to subtraction. For example, x4 + x2 represents the

4 − x2
4 + x
4 − x2
same fnite feld element as x
, −x
2, and −x
. Similarly, the sum of any element
with itself is the zero element.

4.2 Multiplication in GF(28)
 

The symbol • denotes multiplication in GF 28 . Conceptually, this multiplication is defned
on two bytes in two steps: 1) the two polynomials that represent the bytes are multiplied as
polynomials, and 2) the resulting polynomial is reduced modulo the following fxed polynomial:

8
4
3
m(x) = x + x + x + x + 1.
(4.3)

Within both steps, the individual coeffcients of the polynomials are reduced modulo 2.

1Information about the properties of fnite felds can be found in textbooks, such as Michael Artin’s Algebra [4].

8

<!-- page 17 -->

FIPS 197
ADVANCED ENCRYPTION STANDARD (AES)

Thus, if b(x) and c(x) represent bytes b and c, then b • c is represented by the following modular
reduction of their product as polynomials:

b(x)c(x)
mod m(x).
(4.4)

The modular reduction by m(x) may be applied to intermediate steps in the calculation of b(x)c(x);
consequently, it is useful to consider the special case that c(x) = x (i.e., c = {02}). In particular,
the product b •{02} can be expressed as a function of b, denoted by XTIMES(b), as follows:

(

{b6 b5 b4 b3 b2 b1 b0 0}
if b7 = 0
XTIMES(b) = {b6 b5 b4 b3 b2 b1 b0 0}⊕{0 0 0 1 1 0 1 1} if b7 = 1.
(4.5)

Multiplication by higher powers of x (such as {04}, {08}, and {10}) can be implemented by the
repeated application of XTIMES(). For example, let b = {57}:

{57} •{01} = {57}
{57} •{02} = XTIMES({57}) = {ae}
{57} •{04} = XTIMES({ae}) = {47}
{57} •{08} = XTIMES({47}) = {8e}
{57} •{10} = XTIMES({8e}) = {07}
{57} •{20} = XTIMES({07}) = {0e}
{57} •{40} = XTIMES({0e}) = {1c}
{57} •{80} = XTIMES({1c}) = {38}.

(4.6)

These products facilitate the computation of any multiple of {57}. For example, because {13} =
{10}⊕{02}⊕{01}, it follows that

{57} •{13} = {57} • ({01}⊕{02}⊕{10})

= {57}⊕{ae}⊕{07}
= {fe}.

(4.7)

### 4.3 Multiplication of Words by a Fixed Matrix

Two transformations – MIXCOLUMNS() and INVMIXCOLUMNS() – in the algorithms for the
AES block ciphers can be expressed in terms of matrix multiplication. In particular, a distinct
fxed matrix is specifed for each transformation. For both matrices, each of the 16 entries of the
matrix is a byte of a single specifed word, denoted here by [a0,a1,a2,a3].

Given an input word [b0,b1,b2,b3] to the transformation, the output word [d0,d1,d2,d3] is
determined by fnite feld arithmetic as follows:

9

<!-- page 18 -->

FIPS 197
ADVANCED ENCRYPTION STANDARD (AES)

d0 = (a0 • b0) ⊕ (a3 • b1) ⊕ (a2 • b2) ⊕ (a1 • b3)
d1 = (a1 • b0) ⊕ (a0 • b1) ⊕ (a3 • b2) ⊕ (a2 • b3)
d2 = (a2 • b0) ⊕ (a1 • b1) ⊕ (a0 • b2) ⊕ (a3 • b3)
d3 = (a3 • b0) ⊕ (a2 • b1) ⊕ (a1 • b2) ⊕ (a0 • b3).

(4.8)

The matrix form of Eq. (4.8) is

⎤
⎡
⎤
⎡
⎤
⎡

d0
a0 a3 a2 a1
b0
⎢⎢⎣

a1 a0 a3 a2
a2 a1 a0 a3

b1
b2

d1
d2

⎥⎥⎦=

⎥⎥⎦.

⎢⎢⎣

⎢⎢⎣
⎥⎥⎦

(4.9)

d3
a3 a2 a1 a0
b3

### 4.4 Multiplicative Inverses in GF(28)

For a byte b 6= {00}, its multiplicative inverse is the unique byte, denoted by b−1, such that

b • b−1 = {01}.
(4.10)

The defnition of the SUBBYTES() transformation in the specifcations of the AES block cipher
involves multiplicative inverses in GF(28), which can be calculated as follows:

b−1 = b254 .
(4.11)

Alternatively, let b(x) be the polynomial that represents b. The extended Euclidean algorithm [5]
can be applied to b(x) and m(x) to fnd polynomials a(x) and c(x) such that

b(x)a(x)+ m(x)c(x) = 1.
(4.12)

It follows that a(x) is the polynomial that represents b−1.

10

<!-- page 19 -->

FIPS 197
ADVANCED ENCRYPTION STANDARD (AES)

## 5. Algorithm Specifcations

The general function for executing AES-128, AES-192, or AES-256 is denoted by CIPHER(); its
inverse is denoted by INVCIPHER().2

The core of the algorithms for CIPHER() and INVCIPHER() is a sequence of fxed transformations
of the state called a round. Each round requires an additional input called the round key; the round
key is a block that is usually represented as a sequence of four words (i.e., 16 bytes).

An expansion routine, denoted by KEYEXPANSION(), takes the block cipher key as input and
generates the round keys as output. In particular, the input to KEYEXPANSION() is represented as
an array of words, denoted by key, and the output is an expanded array of words, denoted by w,
called the key schedule.

The block ciphers AES-128, AES-192, and AES-256 differ in three respects: 1) the length of the
key; 2) the number of rounds, which determines the size of the required key schedule; and 3)
the specifcation of the recursion within KEYEXPANSION(). For each algorithm, the number of
rounds is denoted by Nr, and the number of words of the key is denoted by Nk. (The number of
words in the state is denoted by Nb for Rijndael in general; in this Standard, Nb = 4.) The specifc
values of Nk, Nb, and Nr are given in Table 3. No other confgurations of Rijndael conform to
this Standard.

For implementation issues relating to the key length, block size, and number of rounds, see
Section 6.3.

Table 3. Key-Block-Round Combinations

Key length

Block size

Number of rounds

Nk (in bits)

Nb (in bits)

Nr

AES-128

4

128

4

128

10

AES-192

6

192

4

128

12

AES-256

8

256

4

128

14

The three inputs to CIPHER() are: 1) the data input in, which is a block represented as a linear
array of 16 bytes; 2) the number of rounds Nr for the instance; and 3) the round keys. Thus,

AES-128(in,key) = CIPHER(in,10, KEYEXPANSION(key))
AES-192(in,key) = CIPHER(in,12, KEYEXPANSION(key))
AES-256(in,key) = CIPHER(in,14, KEYEXPANSION(key))

.

(5.1)

The inverse permutations are defned by replacing CIPHER() with INVCIPHER() in Eq. 5.1.

2Informally, these functions are sometimes called “encryption” and “decryption,” but neutral terminology is appro
priate because there are other applications of block ciphers besides encryption.

­

11

<!-- page 20 -->

FIPS 197
ADVANCED ENCRYPTION STANDARD (AES)

The specifcations of CIPHER(), KEYEXPANSION(), and INVCIPHER() are given in Sections 5.1,
5.2, and 5.3, respectively.

### 5.1 CIPHER()

The rounds in the specifcation of CIPHER() are composed of the following four byte-oriented
transformations on the state:

• SUBBYTES() applies a substitution table (S-box) to each byte.

• SHIFTROWS() shifts rows of the state array by different offsets.

• MIXCOLUMNS() mixes the data within each column of the state array.

• ADDROUNDKEY() combines a round key with the state.

The four transformations are specifed in Sections 5.1.1–5.1.4. In those specifcations, the
transformed bit, byte, or block is denoted by appending the symbol 0 as a superscript on the
 
0
0
0
0 
original variable i.e., by bi, b , si, j, or s .

The round keys for ADDROUNDKEY() are generated by KEYEXPANSION(), which is specifed in
Section 5.2. In particular, the key schedule is represented as an array w of 4 ∗ (Nr + 1) words.

CIPHER() is specifed in the pseudocode in Alg. 1.

Algorithm 1 Pseudocode for CIPHER()

1: procedure CIPHER(in, Nr, w)
2:
state ← in
. See Sec. 3.4
3:
state ← ADDROUNDKEY(state,w[0..3])
. See Sec. 5.1.4
4:
for round from 1 to Nr − 1 do
5:
state ← SUBBYTES(state)
. See Sec. 5.1.1
6:
state ← SHIFTROWS(state)
. See Sec. 5.1.2
7:
state ← MIXCOLUMNS(state)
. See Sec. 5.1.3
8:
state ← ADDROUNDKEY(state,w[4 ∗ round..4 ∗ round + 3])
9:
end for
10:
state ← SUBBYTES(state)
11:
state ← SHIFTROWS(state)
12:
state ← ADDROUNDKEY(state,w[4 ∗ Nr..4 ∗ Nr + 3])
13:
return state
. See Sec. 3.4
14: end procedure

The frst step (Line 2) is to copy the input into the state array using the conventions from Sec. 3.4.
After an initial round key addition (Line 3), the state array is transformed by Nr applications of
the round function (Lines 4–12); the fnal round (Lines 10–12) differs in that the MIXCOLUMNS()
transformation is omitted. The fnal state is then returned as the output (Line 13), as described in
Section 3.4.

12

<!-- page 21 -->

FIPS 197
ADVANCED ENCRYPTION STANDARD (AES)

5.1.1 SUBBYTES()

SUBBYTES() is an invertible, non-linear transformation of the state in which a substitution table,
called an S-box, is applied independently to each byte in the state. The AES S-box is denoted by
SBOX().

Let b denote an input byte to SBOX(), and let c denote the constant byte {01100011}. The
output byte b

0 = SBOX(b) is constructed by composing the following two transformations:

1. Defne an intermediate value b˜, as follows, where b−1 is the multiplicative inverse of b, as
described in Section 4.4:

(

{00}
if b = {00}
b−1
if b = {00}.
˜b =
(5.2)

2. Apply the following affne transformation of the bits of b˜ to produce the bits of b
0 :

b0
˜
i = bi ⊕ b˜ (i+4) mod 8 ⊕ b˜ (i+5) mod 8 ⊕ b˜ (i+6) mod 8 ⊕ b˜ (i+7) mod 8 ⊕ ci.
(5.3)

The matrix form of Eq. (5.3) is given by Eq. (5.4) below:

⎡
⎤
⎡
⎡
⎤
⎤
⎡⎤
˜b0
b0

0
1 0 0 0 1 1 1 1
1 1 0 0 0 1 1 1
1 1 1 0 0 0 1 1
1 1 1 1 0 0 0 1
1 1 1 1 1 0 0 0
0 1 1 1 1 1 0 0
0 0 1 1 1 1 1 0

1
⎢⎢⎢⎢⎢⎢⎢⎢⎢⎢⎣

b0

˜b1
˜b2
˜b3
˜b4
˜b5
˜b6

1
0
0
0
1
1

⎥⎥⎥⎥⎥⎥⎥⎥⎥⎥⎦

1
b0

⎢⎢⎢⎢⎢⎢⎢⎢⎢⎣

⎥⎥⎥⎥⎥⎥⎥⎥⎥⎦

⎢⎢⎢⎢⎢⎢⎢⎢⎢⎣

⎥⎥⎥⎥⎥⎥⎥⎥⎥⎦

⎢⎢⎢⎢⎢⎢⎢⎢⎢⎣

⎥⎥⎥⎥⎥⎥⎥⎥⎥⎦

2
b0

+
.

=

3
b0

(5.4)

4
b0

5
b0

6

b0
0
0
0
1
1
1
1
1
˜
0
7
b7

Figure 2 illustrates how SUBBYTES() transforms the state.

Figure 2. Illustration of SUBBYTES()

The AES S-box is presented in hexadecimal form in Table 4. For example, if sr,c = {53}, then

13

<!-- page 22 -->

FIPS 197
ADVANCED ENCRYPTION STANDARD (AES)

Table 4. SBOX(): substitution values for the byte xy (in hexadecimal format)

y
0
1
2
3
4
5
6
7
8
9
a
b
c
d
e
f

76
c0
15
75
84
cf
a8
d2
73
db
79
08
8a
9e
df
16

ab
72
31
b2
2f
58
9f
f3
19
0b
e4
ae
8b
1d
28
bb

d7
a4
d8
27
e3
4c
3c
ff
5d
5e
95
7a
bd
c1
55
54

fe
9c
71
eb
29
4a
50
10
64
de
91
65
4b
86
ce
b0

2b
af
f1
e2
b3
39
7f
21
3d
14
62
ea
1f
b9
e9
0f

67
a2
e5
80
d6
be
02
da
7e
b8
ac
f4
74
57
87
2d

01
d4
a5
12
3b
cb
f9
b6
a7
ee
d3
56
dd
35
1e
99

30
ad
34
07
52
6a
45
bc
c4
46
c2
6c
e8
61
9b
41

c5
f0
cc
9a
a0
5b
85
f5
17
88
5c
a9
c6
0e
94
68

6f
47
f7
05
5a
b1
33
38
44
90
24
4e
b4
f6
8e
42

6b
59
3f
96
6e
fc
4d
9d
97
2a
06
d5
a6
03
d9
e6

f2
fa
36
18
1b
20
43
92
5f
22
49
8d
1c
48
69
bf

7b
7d
26
c3
1a
ed
fb
8f
ec
dc
0a
6d
2e
66
11
0d

77
c9
93
23
2c
00
aa
40
13
4f
3a
37
25
b5
98
89

7c
82
fd
c7
83
d1
ef
a3
0c
81
32
c8
78
3e
f8
a1

63
ca
b7
04
09
53
d0
51
cd
60
e0
e7
ba
70
e1
8c

0
1
2
3
4
5
6
7
8
9
a
b
c
d
e
f

x

the substitution value would be determined by the intersection of the row with index ‘5’ and the
column with index ‘3’ in Table 4, so that s0 = {ed}.
r,c

5.1.2 SHIFTROWS()

SHIFTROWS() is a transformation of the state in which the bytes in the last three rows of the state
are cyclically shifted. The number of positions by which the bytes are shifted depends on the row
index r, as follows:

0s = sr,(c+r) mod 4
for 0 ≤ r < 4 and 0 ≤ c < 4.
r,c
(5.5)

SHIFTROWS() is illustrated in Figure 3. In that representation of the state, the effect is to move
each byte by r positions to the left in the row, cycling the left-most r bytes around to the right end
of the row. The frst row, where r = 0, is unchanged.

14

<!-- page 23 -->

FIPS 197
ADVANCED ENCRYPTION STANDARD (AES)

Figure 3. Illustration of SHIFTROWS()

5.1.3 MIXCOLUMNS()

MIXCOLUMNS() is a transformation of the state that multiplies each of the four columns of the
state by a single fxed matrix, as described in Section 4.3, with its entries taken from the following
word:

[a0,a1,a2,a3] = [{02},{01},{01},{03}].
(5.6)

Thus,

⎡
⎤
⎡
⎤
⎡
⎤
0 s0,c
02 03 01 01
s0,c
⎢⎢⎢⎣

0 s
⎢⎢⎣

01
01
03 01 01 02
s3,c

⎥⎥⎦
02 03 01
s1,c
1,c
0
for 0 ≤ c < 4,
01 02 03
s2,c
s2,c
0 s3,c

⎥⎥⎥⎦ =

⎢⎢⎣
⎥⎥⎦

(5.7)

so that the individual output bytes are defned as follows:

0s
= ({02} • s0,c) ⊕ ({03} • s1,c) ⊕ s2,c ⊕ s3,c
0,c
0s
= s0,c ⊕ ({02} • s1,c) ⊕ ({03} • s2,c) ⊕ s3,c
1,c
0s
= s0,c ⊕ s1,c ⊕ ({02} • s2,c) ⊕ ({03} • s3,c)
2,c
0s
= ({03} • s0,c) ⊕ s1,c ⊕ s2,c ⊕ ({02} • s3,c).
3,c

(5.8)

Figure 4 illustrates MIXCOLUMNS().

15

<!-- page 24 -->

FIPS 197
ADVANCED ENCRYPTION STANDARD (AES)

Figure 4. Illustration of MIXCOLUMNS()

5.1.4 ADDROUNDKEY()

ADDROUNDKEY() is a transformation of the state in which a round key is combined with the
state by applying the bitwise XOR operation. In particular, each round key consists of four words
from the key schedule (described in Section 5.2), each of which is combined with a column of the
state as follows:

0
0
0
0
[s0,c,s1,c,s2,c,s3,c] = [s0,c,s1,c,s2,c,s3,c] ⊕ [w(4∗round+c)] for 0 ≤ c < 4
(5.9)

where round is a value in the range 0 ≤ round ≤ Nr, and w[i] is the array of key schedule words
described in Section 5.2. In the specifcation of CIPHER(), ADDROUNDKEY() is invoked Nr + 1
times — once prior to the frst application of the round function (see Alg. 1) and once within each
of the Nr rounds, when 1 ≤ round ≤ Nr.

The action of this transformation is illustrated in Fig. 5, where l = 4 ∗ round. The byte address
within words of the key schedule was described in Sec. 3.5.

Figure 5. Illustration of ADDROUNDKEY()

16

<!-- page 25 -->

FIPS 197
ADVANCED ENCRYPTION STANDARD (AES)

### 5.2 KEYEXPANSION()

KEYEXPANSION() is a routine that is applied to the key to generate 4 ∗ (Nr + 1) words. Thus,
four words are generated for each of the Nr + 1 applications of ADDROUNDKEY() within the
specifcation of CIPHER(), as described in Section 5.1.4. The output of the routine consists of a
linear array of words, denoted by w[i], where i is in the range 0 ≤ i < 4 ∗ (Nr + 1).

KEYEXPANSION() invokes 10 fxed words denoted by Rcon[ j] for 1 ≤ j ≤ 10. These 10 words
are called the round constants. For AES-128, a distinct round constant is called in the generation
of each of the 10 round keys. For AES-192 and AES-256, the key expansion routine calls the
frst eight and seven of these same constants, respectively. The values of Rcon[ j] are given in
hexadecimal notation in Table 5:

Table 5. Round constants

j
Rcon[ j]
j
Rcon[ j]

1 [01,00,00,00]
6
[20,00,00,00]
2 [02,00,00,00]
7
[40,00,00,00]
3 [04,00,00,00]
8
[80,00,00,00]
4 [08,00,00,00]
9
[1b,00,00,00]
5 [10,00,00,00] 10 [36,00,00,00]

j−1
The value of the left-most byte of Rcon[ j] in polynomial form is x
. Note that for j > 0, these
bytes may be generated by successively applying XTIMES() to the byte represented by x j−1 (see
Eq. 4.5).

Two transformations on words are called within KEYEXPANSION(): ROTWORD() and SUB­
WORD(). Given an input word represented as a sequence [a0,a1,a2,a3] of four bytes,

ROTWORD([a0,a1,a2,a3]) = [a1,a2,a3,a0],
(5.10)

and

SUBWORD([a0,...,a3]) = [SBOX(a0), SBOX(a1), SBOX(a2), SBOX(a3)].
(5.11)

The expansion of the key proceeds according to the pseudocode in Alg. 2. The frst Nk words of
the expanded key are the key itself. Every subsequent word w[i] is generated recursively from the
preceding word, w[i − 1], and the word Nk positions earlier, w[i − Nk], as follows:

• If i is a multiple of Nk, then w[i] = w[i − Nk] ⊕ SUBWORD(ROTWORD(w[i − 1])) ⊕
Rcon[i/Nk].

• For AES-256, if i + 4 is a multiple of 8, then w[i] = w[i − Nk] ⊕ SUBWORD(w[i − 1]).

• For all other cases, w[i] = w[i − Nk] ⊕ w[i − 1].

17

<!-- page 26 -->

FIPS 197
ADVANCED ENCRYPTION STANDARD (AES)

Algorithm 2 Pseudocode for KEYEXPANSION()

1: procedure KEYEXPANSION(key)
2:
i ← 0
3:
while i ≤ Nk − 1 do
4:
w[i] ← key[4 ∗ i..4 ∗ i + 3]
5:
i ← i + 1
6:
end while
. When the loop concludes, i = Nk.
7:
while i ≤ 4 ∗ Nr + 3 do
8:
temp ← w[i − 1]
9:
if i mod Nk = 0 then
10:
temp ← SUBWORD(ROTWORD(temp)) ⊕ Rcon[i/Nk]
11:
else if Nk > 6 and i mod Nk = 4 then
12:
temp ← SUBWORD(temp)
13:
end if
14:
w[i] ← w[i − Nk] ⊕temp
15:
i ← i + 1
16:
end while
17:
return w
18: end procedure

Figures 6, 7, and 8 illustrate KEYEXPANSION() for AES-128, AES-192, and AES-256.

### 5.3 INVCIPHER()

To implement INVCIPHER(), the transformations in the specifcation of CIPHER() (Section 5.1)
are inverted and executed in reverse order. The inverted transformations of the state — denoted
by INVSHIFTROWS(), INVSUBBYTES(), INVMIXCOLUMNS(), and ADDROUNDKEY() — are
described in Sections 5.3.1–5.3.4.

INVCIPHER() is described in the pseudocode in Alg. 3, where the array w denotes the key
schedule, as described in Section 5.2.

18

<!-- page 27 -->

FIPS 197
ADVANCED ENCRYPTION STANDARD (AES)

Figure 6. KEYEXPANSION() of AES-128 to generate the words w[i] for 4 ≤ i < 44, where l
ranges over the multiples of 4 between 0 and 36

19

<!-- page 28 -->

FIPS 197
ADVANCED ENCRYPTION STANDARD (AES)

Figure 7. KEYEXPANSION() of AES-192 to generate the words w[i] for 6 ≤ i < 52, where l
ranges over the multiples of 6 between 0 and 42

20

<!-- page 29 -->

FIPS 197
ADVANCED ENCRYPTION STANDARD (AES)

Figure 8. KEYEXPANSION() of AES-256 to generate the words w[i] for 8 ≤ i < 60, where l
ranges over the multiples of 8 between 0 and 48

21

<!-- page 30 -->

FIPS 197
ADVANCED ENCRYPTION STANDARD (AES)

Algorithm 3 Pseudocode for INVCIPHER()

1: procedure INVCIPHER(in, Nr, w)
2:
state ← in
. See Sec. 3.4
3:
state ← ADDROUNDKEY(state,w[4 ∗ Nr..4 ∗ Nr + 3])
. See Sec. 5.1.4
4:
for round from Nr − 1 downto 1 do
5:
state ← INVSHIFTROWS(state)
. See Sec. 5.3.1
6:
state ← INVSUBBYTES(state)
. See Sec. 5.3.2
7:
state ← ADDROUNDKEY(state,w[4 ∗ round..4 ∗ round + 3])
8:
state ← INVMIXCOLUMNS(state)
. See Sec. 5.3.3
9:
end for
10:
state ← INVSHIFTROWS(state)
11:
state ← INVSUBBYTES(state)
12:
state ← ADDROUNDKEY(state,w[0..3])
13:
return state
14: end procedure

5.3.1 INVSHIFTROWS()

INVSHIFTROWS() is the inverse of the SHIFTROWS(). In particular, the bytes in the last three
rows of the state are cyclically shifted as follows:

0sr,c = sr,(c−r) mod 4
for 0 ≤ r < 4 and 0 ≤ c < 4.
(5.12)

INVSHIFTROWS() is illustrated in Figure 9. In that representation of the state, the effect is to
move each byte by r positions to the right in the row, cycling the right-most r bytes around to the
left end of the row. The frst row, where r = 0, is unchanged.

22

<!-- page 31 -->

FIPS 197
ADVANCED ENCRYPTION STANDARD (AES)

Figure 9. Illustration of INVSHIFTROWS()

5.3.2 INVSUBBYTES()

INVSUBBYTES() is the inverse of SUBBYTES(), in which the inverse of SBOX(), denoted by
INVSBOX(), is applied to each byte of the state. INVSBOX() is derived from Table 4 by switching
the roles of inputs and outputs, as presented in Table 6:

Table 6. INVSBOX(): substitution values for the byte xy (in hexadecimal format)

y

0
1
2
3
4
5
6
7
8
9
a
b
c
d
e
f

fb
cb
4e
25
92
84
06
6b
73
6e
1b
f4
5f
ef
61
7d

d7
e9
c3
d1
b6
9d
45
8a
e6
df
be
5a
ec
9c
99
0c

f3
de
fa
8b
65
8d
b3
13
b4
75
18
cd
80
c9
53
21

81
c4
42
6d
5d
a7
b8
01
f0
1c
aa
78
27
93
83
55

9e
44
0b
49
cc
57
05
03
ce
e8
0e
fe
59
9f
3c
63

a3
43
95
a2
5c
46
58
bd
cf
37
62
c0
10
7a
bb
14

40
8e
4c
5b
a4
15
e4
af
f2
f9
b7
db
12
e5
eb
69

bf
34
ee
76
d4
5e
f7
c1
97
e2
6f
9a
b1
2d
c8
e1

38
87
3d
b2
16
da
0a
02
ea
85
89
20
31
0d
b0
26

a5
ff
23
24
98
b9
d3
0f
dc
35
c5
79
c7
4a
f5
d6

36
2f
c2
d9
68
ed
bc
3f
67
ad
29
d2
07
b5
2a
77

30
9b
a6
28
86
fd
8c
ca
4f
e7
1d
c6
88
19
ae
ba

d5
82
32
66
64
50
00
8f
41
22
71
4b
33
a9
4d
7e

6a
39
94
a1
f6
48
ab
1e
11
74
1a
3e
a8
7f
3b
04

09
e3
7b
2e
f8
70
d8
2c
91
ac
f1
56
dd
51
e0
2b

52
7c
54
08
72
6c
90
d0
3a
96
47
fc
1f
60
a0
17

0
1
2
3
4
5
6
7
8
9
a
b
c
d
e
f

x

23

<!-- page 32 -->

FIPS 197
ADVANCED ENCRYPTION STANDARD (AES)

5.3.3 INVMIXCOLUMNS()

INVMIXCOLUMNS() is the inverse of MIXCOLUMNS(). In particular, INVMIXCOLUMNS()
multiplies each of the four columns of the state by a single fxed matrix, as described in Section 4.3,
with its entries taken from the following word:

[a0,a1,a2,a3] = [{0e},{09},{0d},{0b}].
(5.13)

Thus,

⎤
⎡
⎤
⎡
⎤
s0

⎡

0,c
0e 0b 0d 09
⎢⎢⎣
⎥⎥⎦

s0,c
s1,c
s2,c

s0

09 0e 0b 0d
0d 09 0e 0b
for 0 ≤ c < 4.
s0

1,c

⎥⎥⎦
⎥⎥⎦=

⎢⎢⎣

⎢⎢⎣

(5.14)

2,c
s0

3,c
0b 0d 09 0e
s3,c

As a result of this matrix multiplication, the four bytes in a column are replaced by the following:

0s
= ({0e} • s0,c) ⊕ ({0b} • s1,c) ⊕ ({0d} • s2,c) ⊕ ({09} • s3,c)
0,c
0s
= ({09} • s0,c) ⊕ ({0e} • s1,c) ⊕ ({0b} • s2,c) ⊕ ({0d} • s3,c)
1,c
0s
= ({0d} • s0,c) ⊕ ({09} • s1,c) ⊕ ({0e} • s2,c) ⊕ ({0b} • s3,c)
2,c
0s
= ({0b} • s0,c) ⊕ ({0d} • s1,c) ⊕ ({09} • s2,c) ⊕ ({0e} • s3,c).
3,c

(5.15)

5.3.4 Inverse of ADDROUNDKEY()

ADDROUNDKEY(), described in Section 5.1.4, is its own inverse.

5.3.5 EQINVCIPHER()

Several properties of the AES algorithm allow for an alternative specifcation of the inverse of
CIPHER(), called the equivalent inverse cipher, denoted by EQINVCIPHER(). In the specifcation
of EQINVCIPHER(), the transformations of the round function of the cipher in Alg. 1 are directly
replaced by their inverses in EQINVCIPHER(), in the same order. The effciency of this structure
in comparison to the specifcation of INVCIPHER() in Alg. 3 is explained in the Rijndael proposal
document [2].

The pseudocode for the equivalent inverse cipher, given in Alg. 4, uses a modifed key schedule,
denoted by the word array dw. The routine to generate dw is an extension of KEYEXPANSION(),
denoted by KEYEXPANSIONEIC(), whose pseudocode is given in Alg. 5.

24

<!-- page 33 -->

FIPS 197
ADVANCED ENCRYPTION STANDARD (AES)

Algorithm 4 Pseudocode for EQINVCIPHER()

1: procedure EQINVCIPHER(in, Nr, dw)
2:
state ← in
3:
state ← ADDROUNDKEY(state,dw[4 ∗ Nr..4 ∗ Nr + 3])
4:
for round from Nr − 1 downto 1 do
5:
state ← INVSUBBYTES(state)
6:
state ← INVSHIFTROWS(state)
7:
state ← INVMIXCOLUMNS(state)
8:
state ← ADDROUNDKEY(state,dw[4 ∗ round..4 ∗ round + 3])
9:
end for
10:
state ← INVSUBBYTES(state)
11:
state ← INVSHIFTROWS(state)
12:
state ← ADDROUNDKEY(state,dw[0..3])
13:
return state
14: end procedure

Algorithm 5 Pseudocode for KEYEXPANSIONEIC()

1: procedure KEYEXPANSIONEIC(key)
2:
i ← 0
3:
while i ≤ Nk − 1 do
4:
w[i] ← key[4i..4i + 3]
5:
dw[i] ← w[i]
6:
i ← i + 1
7:
end while
. When the loop concludes, i = Nk.
8:
while i ≤ 4 ∗ Nr + 3 do
9:
temp ← w[i − 1]
10:
if i mod Nk = 0 then
11:
temp ← SUBWORD(ROTWORD(temp)) ⊕ Rcon[i/Nk]
12:
else if Nk > 6 and i mod Nk = 4 then
13:
temp ← SUBWORD(temp)
14:
end if
15:
w[i] ← w[i − Nk] ⊕temp
16:
dw[i] ← w[i]
17:
i ← i + 1
18:
end while
19:
for round from 1 to Nr − 1 do
20:
i ← 4 ∗ round
21:
dw[i..i + 3] ← INVMIXCOLUMNS(dw[i..i + 3])
. Note change of type.
22:
end for
23:
return dw
24: end procedure

The frst and last round keys in dw are the same as in w; the modifcation of the other round keys
is described in Lines 19–22. The comment in Line 21 refers to the input to INVMIXCOLUMNS():
the one-dimensional array of words is converted to a two-dimensional array of bytes, as in Fig. 1.

25

<!-- page 34 -->

FIPS 197
ADVANCED ENCRYPTION STANDARD (AES)

## 6. Implementation Considerations

### 6.1 Key Length Requirements

An implementation of the AES algorithm shall support at least one of the three key lengths
specifed in Sec. 5: 128, 192, or 256 bits (i.e., Nk = 4, 6, or 8, respectively). Implementations
may optionally support two or three key lengths, which may promote the interoperability of
algorithm implementations.

### 6.2 Keying Restrictions

When a cryptographic key has been generated appropriately (see NIST Special Publication 800­
133, Rev. 2 [6] for guidelines), no restriction is imposed when the resulting key is used for the
AES algorithm.

### 6.3 Parameter Extensions

In Table 3, this Standard explicitly defnes the allowed values for the key length (Nk), block
size (Nb), and number of rounds (Nr). However, future revisions of this Standard could include
changes or additions to the allowed values for those parameters. Therefore, implementers may
choose to design their AES implementations with future fexibility in mind.

### 6.4 Implementation Suggestions Regarding Various Platforms

Implementation variations are possible that may, in many cases, offer performance or other
advantages. Given the same input key and data (plaintext or ciphertext), any implementation that
produces the same output (ciphertext or plaintext) as the algorithm specifed in this Standard is an
equivalent implementation of the AES algorithm.

The AES proposal document [2] and other resources located on the AES page [7] include
suggestions on how to effciently implement the AES algorithm on a variety of platforms.
Suggested implementations are intended to explain the inner workings of the AES algorithm but
do not provide protection against various implementation attacks.

A physical implementation may leak key-dependent information through side channels, such
as the time taken to perform a computation, or when faults are injected into the computation.
When such attacks are non-invasive, they can be effective even when there are mechanisms to

detect physical tampering of the device. For example, cache-timing attacks may affect AES
implementations on software platforms that use a cache to accelerate the access to data from main
memory.

Protecting implementations of the AES algorithm against implementation attacks where applicable
should be considered. Such considerations are outside of the scope of this document but are taken
into account when testing for conformance to the algorithm in this Standard according to the
validation program developed by NIST (see https://nist.gov/cmvp).

26

<!-- page 35 -->

FIPS 197
ADVANCED ENCRYPTION STANDARD (AES)

### 6.5 Modes of Operation

Block cipher modes of operation are cryptographic functions that feature a block cipher to provide
information services, such as confdentiality and authentication. NIST-recommended modes of
operation are specifed in the 800-38 series of NIST Special Publications. Further information is
available at https://csrc.nist.gov/Projects/block-cipher-techniques/BCM.

27

<!-- page 36 -->

FIPS 197
ADVANCED ENCRYPTION STANDARD (AES)

### References

[1] James Nechvatal, Elaine Barker, Lawrence Bassham, William Burr, Morris Dworkin, James

Foti, and Edward Roback. Report on the Development of the Advanced Encryption Standard
(AES). Journal of Research of NIST (NIST JRES), May 2001. https://doi.org/10.6028/jres.
106.023.

[2] Joan Daemen and Vincent Rijmen.
AES Proposal:
Rijndael Document
Version 2.
AES Algorithm Submission, September 1999.
Available at
https://csrc.nist.gov/csrc/media/projects/cryptographic-standards-and-guidelines/
documents/aes-development/rijndael-ammended.pdf.

[3] Joan Daemen and Vincent Rijmen. The Design of Rijndael - The Advanced Encryption

Standard (AES), Second Edition. Information Security and Cryptography. Springer, 2020.
https://doi.org/10.1007/978-3-662-60769-5.

[4] Michael Artin. Algebra. Pearson Modern Classic. Pearson, second edition, 2017.

[5] Alfred J. Menezes, Scott A. Vanstone, and Paul C. Van Oorschot. Handbook of Applied Cryp­

tography. CRC Press, Inc., USA, 1st edition, 1997. https://doi.org/10.1201/9780429466335.

[6] Elaine Barker, Allen Roginsky, and Richard Davis. Recommendation for Cryptographic

Key Generation. (National Institute of Standards and Technology, Gaithersburg, MD), NIST
Special Publication (SP) 800-133, Rev. 2, June 2020. https://doi.org/10.6028/NIST.SP.
800-133r2.

[7] National Institute of Standards and Technology. AES Development, 2022. Available at

https://csrc.nist.gov/projects/aes.

[8] National Institute of Standards and Technology. Cryptographic Standards and Guide­

lines: Examples with Intermediate Values, 2022. Available at https://csrc.nist.gov/projects/
cryptographic-standards-and-guidelines/example-values.

[9] National Institute of Standards and Technology. Crypto Publications Review Board, 2022.

Available at https://csrc.nist.gov/projects/crypto-publication-review-project.

[10] Nicky Mouha. Review of the Advanced Encryption Standard. (National Institute of

Standards and Technology, Gaithersburg, MD), NIST Interagency Report (IR) 8319. https:
//doi.org/10.6028/NIST.IR.8319.

28

<!-- page 37 -->

FIPS 197
ADVANCED ENCRYPTION STANDARD (AES)

### Appendix A — Key Expansion Examples

This appendix shows the development of the key schedule for each key size. Note that multi-byte
values are presented using the notation described in Sec. 3. The intermediate values produced
during the development of the key schedule (see Sec. 5.2) are given in the following table (all
values are in hexadecimal format with the exception of the index column (i)).

### A.1 Expansion of a 128-bit Key

This section contains the key expansion of the following key:

Key = 2b 7e 15 16 28 ae d2 a6 ab f7 15 88 09 cf 4f 3c

for Nk = 4, which results in

w0 = 2b7e1516
w1 = 28aed2a6
w2 = abf71588
w3 = 09cf4f3c

w[i] =
temp ⊕
w[i − Nk]

Rcon[i/Nk] After XOR

After
SUBWORD()

i
(dec)
temp
After
ROTWORD()

with Rcon
w[i − Nk]

4
09cf4f3c
cf4f3c09
8a84eb01
01000000
8b84eb01
2b7e1516 a0fafe17

5
a0fafe17
28aed2a6 88542cb1

6
88542cb1
abf71588 23a33939

7
23a33939
09cf4f3c 2a6c7605

8
2a6c7605
6c76052a
50386be5
02000000
52386be5
a0fafe17 f2c295f2

9
f2c295f2
88542cb1 7a96b943

10
7a96b943
23a33939 5935807a

11
5935807a
2a6c7605 7359f67f

12
7359f67f
59f67f73
cb42d28f
04000000
cf42d28f
f2c295f2 3d80477d

13
3d80477d
7a96b943 4716fe3e

14
4716fe3e
5935807a 1e237e44

15
1e237e44
7359f67f 6d7a883b

16
6d7a883b
7a883b6d
dac4e23c
08000000
d2c4e23c
3d80477d ef44a541

17
ef44a541
4716fe3e a8525b7f

18
a8525b7f
1e237e44 b671253b

19
b671253b
6d7a883b db0bad00

20
db0bad00
0bad00db
2b9563b9
10000000
3b9563b9
ef44a541 d4d1c6f8

21
d4d1c6f8
a8525b7f 7c839d87

22
7c839d87
b671253b caf2b8bc

23
caf2b8bc
db0bad00 11f915bc

29

<!-- page 38 -->

FIPS 197
ADVANCED ENCRYPTION STANDARD (AES)

24
11f915bc
f915bc11
99596582
20000000
b9596582
d4d1c6f8 6d88a37a

25
6d88a37a
7c839d87 110b3efd

26
110b3efd
caf2b8bc dbf98641

27
dbf98641
11f915bc ca0093fd

28
ca0093fd
0093fdca
63dc5474
40000000
23dc5474
6d88a37a 4e54f70e

29
4e54f70e
110b3efd 5f5fc9f3

30
5f5fc9f3
dbf98641 84a64fb2

31
84a64fb2
ca0093fd 4ea6dc4f

32
4ea6dc4f
a6dc4f4e
2486842f
80000000
a486842f
4e54f70e ead27321

33
ead27321
5f5fc9f3 b58dbad2

34
b58dbad2
84a64fb2 312bf560

35
312bf560
4ea6dc4f 7f8d292f

36
7f8d292f
8d292f7f
5da515d2
1b000000
46a515d2
ead27321 ac7766f3

37
ac7766f3
b58dbad2 19fadc21

38
19fadc21
312bf560 28d12941

39
28d12941
7f8d292f 575c006e

40
575c006e
5c006e57
4a639f5b
36000000
7c639f5b
ac7766f3 d014f9a8

41
d014f9a8
19fadc21 c9ee2589

42
c9ee2589
28d12941 e13f0cc8

43
e13f0cc8
575c006e b6630ca6

### A.2 Expansion of a 192-bit Key

This section contains the key expansion of the following key:

Key = 8e

80
73
90
b0
79
f7
e5

da
62
0e
f8

64
ea

52
d2

c8
52
10
2c
f3
6b
2b
7b

for Nk = 6, which results in

=
=

8e73b0f7
809079e5
w1
w4

=
=

da0e6452
62f8ead2
w2
w5

=
=

c810f32b
522c6b7b

w0
w3

w[i] =
temp ⊕
w[i − Nk]

i
(dec)
temp
After
ROTWORD()

After
SUBWO R D() Rcon[i/Nk] After

XOR
Rcon
w[i − Nk]

with

6
522c6b7b
2c6b7b52
717f2100
01000000
707f2100
8e73b0f7 fe0c91f7

7
fe0c91f7
da0e6452 2402f5a5

8
2402f5a5
c810f32b ec12068e
30

<!-- page 39 -->

FIPS 197
ADVANCED ENCRYPTION STANDARD (AES)

ec12068e

809079e5

6c827f6b

9

6c827f6b

62f8ead2

0e7a95b9

10

5c56fec2

522c6b7b

0e7a95b9

11

4db7b4bd

56fec25c

b1bb254a

02000000

b3bb254a

fe0c91f7

5c56fec2

12

69b54118

2402f5a5

4db7b4bd

13

85a74796

ec12068e

69b54118

14

e92538fd

6c827f6b

85a74796

15

e75fad44

0e7a95b9

e92538fd

16

bb095386

5c56fec2

e75fad44

17

485af057

4db7b4bd

bb095386

095386bb

01ed44ea

04000000

05ed44ea

18

21efb14f

69b54118

485af057

19

a448f6d9

85a74796

21efb14f

20

4d6dce24

e92538fd

a448f6d9

21

aa326360

e75fad44

4d6dce24

22

113b30e6

bb095386

aa326360

23

a25e7ed5

3b30e611

e2048e82

08000000

ea048e82

485af057

113b30e6

24

83b1cf9a

21efb14f

a25e7ed5

25

27f93943

a448f6d9

83b1cf9a

26

6a94f767

4d6dce24

27f93943

27

c0a69407

aa326360

6a94f767

28

d19da4e1

113b30e6

c0a69407

29

ec1786eb

a25e7ed5

d19da4e1

9da4e1d1

5e49f83e

10000000

4e49f83e

30

6fa64971

83b1cf9a

ec1786eb

31

485f7032

27f93943

6fa64971

32

22cb8755

6a94f767

485f7032

33

e26d1352

c0a69407

22cb8755

34

33f0b7b3

d19da4e1

e26d1352

35

40beeb28

ec1786eb

33f0b7b3

f0b7b333
8ca96dc3
20000000
aca96dc3

36

2f18a259

6fa64971

40beeb28

37

6747d26b

485f7032

2f18a259

38

458c553e

22cb8755

6747d26b

39

a7e1466c

e26d1352

458c553e

40

a7e1466c

33f0b7b3

9411f1df

41

9411f1df

11f1df94
82a19e22
40000000
c2a19e22

40beeb28

821f750a

42

821f750a

2f18a259

ad07d753

43

31

<!-- page 40 -->

FIPS 197
ADVANCED ENCRYPTION STANDARD (AES)

ca400538

6747d26b

ad07d753

44

8fcc5006

458c553e

ca400538

45

282d166a

a7e1466c

8fcc5006

46

bc3ce7b5

9411f1df

282d166a

47

e98ba06f

821f750a

3ce7b5bc
eb94d565
80000000
6b94d565

bc3ce7b5

48

448c773c

ad07d753

e98ba06f

49

8ecc7204

ca400538

448c773c

50

51
8ecc7204
8fcc5006 01002202

### A.3 Expansion of a 256-bit Key

This section contains the key expansion of the following key:

Key = 60 3d eb 10 15 ca 71 be 2b 73 ae f0 85 7d 77 81

1f 35 2c 07 3b 61 08 d7 2d 98 10 a3 09 14 df f4

for Nk = 8, which results in

w0 = 603deb10
w1 = 15ca71be
w2 = 2b73aef0
w3 = 857d7781
w4 = 1f352c07
w5 = 3b6108d7
w6 = 2d9810a3
w7 = 0914dff4

w[i] =
temp ⊕
w[i − Nk]

After
SU BWO R D() Rcon[i/Nk] After XOR

i
(dec)
temp
After
RO TWO R D()

with Rcon
w[i − Nk]

8
0914dff4
14dff409
fa9ebf01
01000000
fb9ebf01
603deb10 9ba35411

9
9ba35411
15ca71be 8e6925af

10
8e6925af
2b73aef0 a51a8b5f

11
a51a8b5f
857d7781 2067fcde

12
2067fcde
b785b01d
1f352c07 a8b09c1a

13
a8b09c1a
3b6108d7 93d194cd

14
93d194cd
2d9810a3 be49846e

15
be49846e
0914dff4 b75d5b9a

16
b75d5b9a
5d5b9ab7
4c39b8a9
02000000
4e39b8a9
9ba35411 d59aecb8

17
d59aecb8
8e6925af 5bf3c917

18
5bf3c917
a51a8b5f fee94248

19
fee94248
2067fcde de8ebe96

20
de8ebe96
1d19ae90
a8b09c1a b5a9328a

21
b5a9328a
93d194cd 2678a647

22
2678a647
be49846e 98312229

32

<!-- page 41 -->

FIPS 197
ADVANCED ENCRYPTION STANDARD (AES)

98312229
b75d5b9a 2f6c79b3

23

2f6c79b3
6c79b32f
50b66d15
04000000
54b66d15
d59aecb8 812c81ad

24

812c81ad
5bf3c917 dadf48ba

25

dadf48ba
fee94248 24360af2

26

24360af2
de8ebe96 fab8b464

27

fab8b464
2d6c8d43
b5a9328a 98c5bfc9

28

98c5bfc9
2678a647 bebd198e

29

bebd198e
98312229 268c3ba7

30

268c3ba7
2f6c79b3 09e04214

31

09e04214
e0421409
e12cfa01
08000000
e92cfa01
812c81ad 68007bac

32

68007bac
dadf48ba b2df3316

33

b2df3316
24360af2 96e939e4

34

96e939e4
fab8b464 6c518d80

35

6c518d80
50d15dcd
98c5bfc9 c814e204

36

c814e204
bebd198e 76a9fb8a

37

76a9fb8a
268c3ba7 5025c02d

38

5025c02d
09e04214 59c58239

39

59c58239
c5823959
a61312cb
10000000
b61312cb
68007bac de136967

40

de136967
b2df3316 6ccc5a71

41

6ccc5a71
96e939e4 fa256395

42

fa256395
6c518d80 9674ee15

43

9674ee15
90922859
c814e204 5886ca5d

44

5886ca5d
76a9fb8a 2e2f31d7

45

2e2f31d7
5025c02d 7e0af1fa

46

7e0af1fa
59c58239 27cf73c3

47

27cf73c3
cf73c327
8a8f2ecc
20000000
aa8f2ecc
de136967 749c47ab

48

749c47ab
6ccc5a71 18501dda

49

18501dda
fa256395 e2757e4f

50

e2757e4f
9674ee15 7401905a

51

7401905a
927c60be
5886ca5d cafaaae3

52

cafaaae3
2e2f31d7 e4d59b34

53

e4d59b34
7e0af1fa 9adf6ace

54

9adf6ace
27cf73c3 bd10190d

55

bd10190d
10190dbd
cad4d77a
40000000
8ad4d77a
749c47ab fe4890d1

56

fe4890d1
18501dda e6188d0b

57

e6188d0b
e2757e4f 046df344

58

046df344
7401905a 706c631e

59

33

<!-- page 42 -->

FIPS 197
ADVANCED ENCRYPTION STANDARD (AES)

### Appendix B — Cipher Example

The following diagram shows the values in the state array as the cipher progresses for a block
length and a key length of 16 bytes each (i.e., Nb = 4 and Nk = 4).

Input = 32 43 f6 a8 88 5a 30 8d 31 31 98 a2 e0 37 07 34
Key
= 2b 7e 15 16 28 ae d2 a6 ab f7 15 88 09 cf 4f 3c

The Round Key values are taken from the Key Expansion example in Appendix A.1.

Round
Start of
After
After
After
Round Key
Number
Round
SubBytes
ShiftRows
MixColumns
Value

32 88 31 e0
43 5a 31 37
f6 30 98 07
a8 8d a2 34

2b 28 ab 09
7e ae f7 cf
15 d2 15 4f
16 a6 88 3c

input

19 a0 9a e9
3d f4 c6 f8
e3 e2 8d 48
be 2b 2a 08

d4 e0 b8 1e
27 bf b4 41
11 98 5d 52
ae f1 e5 30

d4 e0 b8 1e
bf b4 41 27
5d 52 11 98
30 ae f1 e5

04 e0 48 28
66 cb f8 06
81 19 d3 26
e5 9a 7a 4c

a0 88 23 2a
fa 54 a3 6c
fe 2c 39 76
17 b1 39 05

1

a4 68 6b 02
9c 9f 5b 6a
7f 35 ea 50
f2 2b 43 49

49 45 7f 77
de db 39 02
d2 96 87 53
89 f1 1a 3b

49 45 7f 77
db 39 02 de
87 53 d2 96
3b 89 f1 1a

58 1b db 1b
4d 4b e7 6b
ca 5a ca b0
f1 ac a8 e5

f2 7a 59 73
c2 96 35 59
95 b9 80 f6
f2 43 7a 7f

2

3d 47 1e 6d
80 16 23 7a
47 fe 7e 88
7d 3e 44 3b

aa 61 82 68
8f dd d2 32
5f e3 4a 46
03 ef d2 9a

ac ef 13 45
73 c1 b5 23
cf 11 d6 5a
7b df b5 b8

ac ef 13 45
c1 b5 23 73
d6 5a cf 11
b8 7b df b5

75 20 53 bb
ec 0b c0 25
09 63 cf d0
93 33 7c dc

3

48 67 4d d6
6c 1d e3 5f
4e 9d b1 58
ee 0d 38 e7

52 85 e3 f6
50 a4 11 cf
2f 5e c8 6a
28 d7 07 94

52 85 e3 f6
a4 11 cf 50
c8 6a 2f 5e
94 28 d7 07

0f 60 6f 5e
d6 31 c0 b3
da 38 10 13
a9 bf 6b 01

ef a8 b6 db
44 52 71 0b
a5 5b 25 ad
41 7f 3b 00

4

e0 c8 d9 85
92 63 b1 b8
7f 63 35 be
e8 c0 50 01

e1 e8 35 97
4f fb c8 6c
d2 fb 96 ae
9b ba 53 7c

e1 e8 35 97
fb c8 6c 4f
96 ae d2 fb
7c 9b ba 53

25 bd b6 4c
d1 11 3a 4c
a9 d1 33 c0
ad 68 8e b0

d4 7c ca 11
d1 83 f2 f9
c6 9d b8 15
f8 87 bc bc

5

34

<!-- page 43 -->

FIPS 197
ADVANCED ENCRYPTION STANDARD (AES)

f1 c1 7c 5d
00 92 c8 b5
6f 4c 8b d5
55 ef 32 0c

a1 78 10 4c
63 4f e8 d5
a8 29 3d 03
fc df 23 fe

a1 78 10 4c
4f e8 d5 63
3d 03 a8 29
fe fc df 23

4b 2c 33 37
86 4a 9d d2
8d 89 f4 18
6d 80 e8 d8

6d 11 db ca
88 0b f9 00
a3 3e 86 93
7a fd 41 fd

6

14 46 27 34
15 16 46 2a
b5 15 56 d8
bf ec d7 43

4e 5f 84 4e
54 5f a6 a6
f7 c9 4f dc
0e f3 b2 4f

26 3d e8 fd
0e 41 64 d2
2e b7 72 8b
17 7d a9 25

f7 27 9b 54
ab 83 43 b5
31 a9 40 3d
f0 ff d3 3f

f7 27 9b 54
83 43 b5 ab
40 3d 31 a9
3f f0 ff d3

7

5a 19 a3 7a
41 49 e0 8c
42 dc 19 04
b1 1f 65 0c

be d4 0a da
83 3b e1 64
2c 86 d4 f2
c8 c0 4d fe

be d4 0a da
3b e1 64 83
d4 f2 2c 86
fe c8 c0 4d

00 b1 54 fa
51 c8 76 1b
2f 89 6d 99
d1 ff cd ea

ea b5 31 7f
d2 8d 2b 8d
73 ba f5 29
21 d2 60 2f

8

ea 04 65 85
83 45 5d 96
5c 33 98 b0
f0 2d ad c5

87 f2 4d 97
ec 6e 4c 90
4a c3 46 e7
8c d8 95 a6

87 f2 4d 97
6e 4c 90 ec
46 e7 4a c3
a6 8c d8 95

47 40 a3 4c
37 d4 70 9f
94 e4 3a 42
ed a5 a6 bc

ac 19 28 57
77 fa d1 5c
66 dc 29 00
f3 21 41 6e

9

eb 59 8b 1b
40 2e a1 c3
f2 38 13 42
1e 84 e7 d2

e9 cb 3d af
09 31 32 2e
89 07 7d 2c
72 5f 94 b5

e9 cb 3d af
31 32 2e 09
7d 2c 89 07
b5 72 5f 94

d0 c9 e1 b6
14 ee 3f 63
f9 25 0c 0c
a8 89 c8 a6

10

39 02 dc 19
25 dc 11 6a
84 09 85 0b
1d fb 97 32

output

35

<!-- page 44 -->

FIPS 197
ADVANCED ENCRYPTION STANDARD (AES)

### Appendix C — Example Vectors

The NIST Computer Security Resource Center provides a website with “examples with interme­
diate values” for AES [8].

36

<!-- page 45 -->

FIPS 197
ADVANCED ENCRYPTION STANDARD (AES)

### Appendix D — Change Log (Informative)

The original FIPS 197 (November 26, 2001) was reviewed and updated under the auspices of
NIST’s Crypto Publication Review Board [9]. Public comments and analyses of the security of
the AES that are described in NIST IR 8319 [10] were the basis for the decision to maintain the
technical specifcations of the Standard.

The following is a summary of the editorial changes to the original FIPS 197 in the May 9, 2023
update, NIST FIPS 197-upd1:

1. The formatting of many elements of the publication was improved, and the text was revised
for clarity.

2. The following items were added to the front matter: title page, foreword, abstract, and
keywords. Offcials’ names and affliations on the title page refect the original publication.

3. The announcement sections were updated to refect current statutes, regulations, standards,
guidelines, and validation programs.

4. Section 1 was revised to 1) add and update references to the AES development effort and 2)
explicitly name AES-128, AES-192, and AES-256.

5. The material in the previous Section 2.2 (Algorithm Parameters, Symbols and Functions)
was split into two new sections: 2.2 (List of Functions) and 2.3 (Algorithm Parameters and
Symbols).

6. The terms, functions, and symbols from the specifcations are comprehensively included in
the lists in Sections 2.1–2.3.

7. The description of the indexing convention was removed from Section 3.1.

8. Table 1 was revised, and the text in the previous Section 3.2 on the polynomial interpretation
of bytes was revised and moved to Section 4.

9. A general defnition of the indexing of byte sequences was added to Section 3.3 before
specializing to the example of a block, and Table 2 was revised.

10. The heading for Section 3.5 was changed to focus on word arrays, and notation for them
was included in the text. The column words of the state were presented in a vertical format,
with an improved description of the indices.

11. A reference for additional information on fnite felds [4] was included in a footnote within
Section 4, and the headings for Sections 4.1 and 4.2 were revised to explicitly mention
GF(28).

12. Section 4.2 was revised to provide an explicit, general description of fnite feld multiplica­
tion. The previous Section 4.2.1 was incorporated into the revised Section 4.2 by replacing
the original example of modular polynomial reduction with an illustration of fnite feld
multiplication using xtime.

13. The heading of Section 4.3 was revised to focus on multiplication by a fxed matrix, and the
text of the section was simplifed by removing the secondary interpretation as polynomial

37

<!-- page 46 -->

FIPS 197
ADVANCED ENCRYPTION STANDARD (AES)

reduction. The descriptions of MIXCOLUMNS() and INVMIXCOLUMNS() in Sections 5.1.3
and 5.3.3 were revised accordingly, to refer back to this construction.

14. The text on multiplicative inverses in GF(28) from the previous Section 4.2 was revised
and moved to the new Section 4.4.

15. The discussion of the algorithm specifcations in Section 5 was expanded to elaborate on the
relationships among its components. A new brief explanation of Nb as a Rijndael parameter
enabled the replacement of Nb with its constant value 4 in the rest of the Standard.

16. The pseudocode for the cipher, the key expansion routine, and the inverse cipher in Sections
5.1, 5.2, and 5.3 was reformatted, and some of the text in these sections was revised for
clarity.

17. The descriptions of SHIFTROWS() in Section 5.1.2 and INVSHIFTROWS() in Section 5.3.2
were improved, and a mistake in the latter was corrected.

18. Illustrations of the three instances of KEYEXPANSION() in the new Figs. 6, 7, and 8 were
added to Section 5.2. The text in the section was also revised, including an explicit display
of the round constants in the new Fig. 5.

19. A separate algorithm for the modifed key expansion routine for the equivalent inverse
cipher was added to Section 5.3.5 instead of only the supplementary lines. The description
of the equivalent inverse cipher was simplifed in favor of the citation of an updated
reference [3].

20. Section 6.2 was revised to include a reference to NIST Special Publication 800-133,
Rev. 2 [6].

21. Section 6.4 was revised to expand the discussion of implementation attacks.

22. The References section is no longer labeled as an appendix. The references were updated
to replace withdrawn publications and correct citation information and URLs.

23. The examples in Appendix C were removed in favor of a reference to the detailed example
vectors that are now maintained at [8].

24. Appendix D was created to summarize the changes in this update to FIPS 197.

38

<!-- END VERBATIM SOURCE -->
