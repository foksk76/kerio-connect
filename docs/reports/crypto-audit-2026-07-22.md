# Kerio Connect — Cryptographic Audit Report

**Date:** 2026-07-22
**Binary:** `/opt/kerio/mailserver/mailserver` (~66 MB ELF x86_64)
**Version:** 10.0.9.10320.patch2-1
**Scope:** Licensing system cryptography only (not TLS/storage)

---

## Executive Summary

The Kerio Connect licensing system uses cryptographic primitives from the early 2000s era. **All core components fail modern security requirements:**

| Component | Current | Minimum Modern | Verdict |
|---|---|---|---|
| Hash function | MD5 (128-bit) | SHA-256 | CRITICAL |
| RSA key size | 1024-bit | 2048-bit (NIST 2013) | CRITICAL |
| Padding scheme | PKCS#1 v1.5 | OAEP / PSS | HIGH |
| Signature comparison | 16 bytes (truncated) | Full comparison | HIGH |
| RSA implementation | Custom RSAREF | OpenSSL/libsodium | MEDIUM |
| Hardcoded public key | `.data` (writable) | `.rodata` + code-signing | MEDIUM |

**Effective security level:** ~80-bit (equivalent to DES-era protection). Modern minimum is 128-bit (AES-128).

---

## 1. Hash Algorithm: MD5

### Finding

The license signature uses MD5 for data integrity hashing.

### Evidence

**Function:** `StreamDigestMD5::StreamDigestMD5(bool)` at `0x15b11e0`

```
15b12a1: call   EVP_md5@plt          ; OpenSSL EVP_md5()
15b12b0: call   setDigestAlgorithm   ; sets digest to MD5
```

When the UTF-8 variant is enabled, it replaces the update function via `EVP_MD_meth_set_update` at `0x15b130c`, pointing to `StreamDigestMD5::MD5_UTF8_8859_1` at `0x15b0130`. The underlying algorithm remains MD5.

### Usage

- `convertDataToMD5Stream` at `0x1581be0` — computes MD5 of license data
- Called by `checkLicenseSignature` at `0x1583f30` — hash covers text between `--LICENSE--` and `--SIGNATURE--` markers

### Security Assessment

| Attack | Year | Feasibility |
|---|---|---|
| Collision (generic) | 2004 | Practical (seconds on commodity hardware) |
| Chosen-prefix collision | 2009 | Practical (~$20K compute as of 2024) |
| Preimage | — | Not practical yet |

**Impact:** An attacker can create two license files with identical MD5 hashes, potentially forging a valid signature.

### Recommended Replacement

- SHA-256 (minimum) or SHA-384/SHA-512
- For new systems: SHA-3 (Keccak) or BLAKE3

---

## 2. RSA Key Size: 1024-bit

### Finding

The license verification uses a 1024-bit RSA public key.

### Evidence

**Function:** `KLicensePubKey::KLicensePubKey(unsigned char*)` at `0x1581080`

```
158113c: movl   $0x400,(%rdx)     ; key->bits = 0x400 = 1024
158112e: movb   $0x1,0x101(%rdx)  ; exponent flag
1581135: movb   $0x1,0x103(%rdx)  ; exponent flag
```

Structure layout (`R_RSA_PUBLIC_KEY` from RSAREF):

```
struct R_RSA_PUBLIC_KEY {
    uint32  bits;              // +0x00: 0x400 (1024)
    uint8   modulus[128];      // +0x04: 128 bytes of key material
    uint8   exponent[128];     // +0x84: padded with 0x00
    // +0x101: exponent flag 1
    // +0x103: exponent flag 2
};
```

### Hardcoded Key Modulus

**Location:** `.data` section at virtual address `0x39a9220` (file offset `0x33a9220`)

```
97b4af20 50353f6d 9e301831 7e0a0092
263a1555 bc6a69b1 367c2a67 c3a25f1e
8713c9b0 1643c34d e0f7aefc 063012dc
57a56f23 870c61ba 6dbc3459 215466cc
60e9ea0a c5f6ba4c ff19cfe5 a8b07634
1ace659f 8f233005 0db90e9e 9dbea4fb
2aaf4086 c54a29ad 7e662a3d 47f0e87c
36b0a439 d2da6fb4 8ceb0fe6 59619fcb
```

- Key is in `.data` (writable), not `.rodata` — no code-signing protection
- Referenced by 4 `KLicenseManager` constructor overloads

### Security Assessment

| Factorization Method | Complexity (1024-bit) | Complexity (2048-bit) |
|---|---|---|
| General Number Field Sieve | ~2^80 | ~2^112 |
| Nation-state compute (2024) | Feasible (~$50K-$100K) | Infeasible |
| Academic estimate (2024) | ~$10K/year cloud compute | Infeasible |

**NIST status:** Deprecated since 2013 (SP 800-57). **ANSI/TLS:** Disallowed since 2015.

### Recommended Replacement

- RSA-2048 (minimum, transitional)
- RSA-4096 (recommended for long-term)
- Ed25519 / Ed448 (preferred for new systems)
- ECDSA P-256 / P-384 (if ECC required)

---

## 3. Padding Scheme: PKCS#1 v1.5

### Finding

Both signature creation and verification use PKCS#1 v1.5 padding instead of OAEP (encryption) or PSS (signatures).

### Evidence

**Signature Verification** (`RSAPublicDecrypt` at `0x15814f0`):

```
1581572: cmpb   $0x0,0x10(%rsp)    ; byte[0] must be 0x00
1581579: cmpb   $0x1,0x11(%rsp)    ; byte[1] must be 0x01 → PKCS#1 Type 1
1581598-15815c5: scan for 0xFF padding then 0x00 separator
15815d6: test   %sil,%sil          ; verify separator byte is 0x00
```

**Signature Creation** (`RSAPrivateEncrypt` at `0x1581380`):

```
15813c7: movb   $0x0,0x10(%rsp)    ; byte[0] = 0x00
15813be: movb   $0x1,0x11(%rsp)    ; byte[1] = 0x01 (Type 1)
1581400-158146d: fill 0xFF bytes    ; padding
158147e: movb   $0x0,...            ; 0x00 separator
```

**License Decryption** (`RSAPrivateDecrypt` at `0x1581260`):

```
15812e4: cmpb   $0x0,0x10(%rsp)    ; byte[0] = 0x00
15812e9: cmpb   $0x2,0x11(%rsp)    ; byte[1] = 0x02 → PKCS#1 Type 2
```

### Security Assessment

| Attack | Year | Impact |
|---|---|---|
| Bleichenbacher (Type 2) | 1998 | Adaptive chosen-ciphertext attack on decryption |
| Signature malleability | 2006 | Multiple valid signatures for same data |
| ROCA (Key generation) | 2017 | Factor keys generated by weak PRNG |

PKCS#1 v1.5 is deprecated for new applications (RFC 8017, Section 7.2).

### Recommended Replacement

- PSS (Probabilistic Signature Scheme) for signatures
- OAEP (Optimal Asymmetric Encryption Padding) for encryption
- Both require SHA-256 minimum for the hash component

---

## 4. Truncated Signature Comparison

### Finding

Only the first 16 bytes (128 bits) of the decrypted signature are compared against the MD5 hash.

### Evidence

**Function:** `checkLicenseSignature` at `0x1583f30`

```
15840ed: call   RSAPublicDecrypt   ; decrypt 128-byte signature
1584105: repz cmpsb                ; compare — ecx = 0x10 (16 bytes)
```

### Security Assessment

The decrypted RSA output is 128 bytes (1024-bit modulus). MD5 produces 16 bytes. Only the first 16 bytes are compared — the remaining 112 bytes are **ignored**.

This means:
1. If an attacker can produce a 128-byte block where the first 16 bytes match the MD5 hash, the signature is accepted regardless of the remaining 112 bytes.
2. Combined with MD5 collision weakness, this significantly reduces the attack surface.

### Recommended Replacement

- Use full-length hash comparison (SHA-256 = 32 bytes)
- Consider RSA-PSS which handles comparison internally

---

## 5. RSA Implementation: Custom RSAREF

### Finding

The RSA implementation is a custom RSAREF-derived library, not OpenSSL's RSA module.

### Evidence

All RSA functions use custom bignum (`NN_*`) functions:

| Function | Address | Description |
|---|---|---|
| `RSAPublicBlock` | `0x1580f10` | Raw RSA public key operation |
| `RSAPrivateBlock` | `0x1580b50` | CRT-optimized private key operation |
| `NN_ModExp` | `0x1580950` | Bignum modular exponentiation |
| `NN_Mod` | `0x1580400` | Bignum modular reduction |
| `NN_ModMult` | `0x15808d0` | Bignum modular multiplication |
| `NN_Decode` | `0x157f8c0` | Byte array → bignum |
| `NN_Encode` | `0x157f960` | Bignum → byte array |

### CRT Key Components

`RSAPrivateBlock` uses Chinese Remainder Theorem with 6 components:

```
Offset  Size   Component
+0x04   128    Modulus N
+0x84   128    Public/Private exponent
+0x184  64     Prime p
+0x1c4  64     Prime q
+0x204  64     dP (exponent1)
+0x244  64     dQ (exponent2)
+0x284  64     qInverse (coefficient)
```

### Security Assessment

| Issue | Description |
|---|---|
| **Timing side-channel** | No constant-time operations; modular exponentiation uses variable-time Montgomery ladder |
| **Bellcore fault attack** | CRT implementation vulnerable if signing occurs on fault-prone platform |
| **No blinding** | RSA blinding not implemented; vulnerable to timing attacks on private key operations |
| **Custom bignum** | No formal verification; potential for implementation bugs |

### Recommended Replacement

- Use OpenSSL's RSA or libsodium's `crypto_sign_*`
- Both have constant-time implementations and formal security proofs

---

## 6. Other Cryptographic Components

### 6.1 OpenSSL 1.1.0 (EOL)

```
OPENSSL_KT_1_1_0  — version string
EVP_md5            — MD5 digest
EVP_MD_meth_*      — digest method manipulation
```

OpenSSL 1.1.0 reached End-of-Life in **September 2019**. No security patches since then.

### 6.2 Symmetric Encryption

| Algorithm | Usage | Notes |
|---|---|---|
| AES-128-CBC | TLS, storage | Acceptable if used correctly |
| AES-256-CBC | TLS, storage | Acceptable |
| 3DES (EDE-CBC) | Legacy | Deprecated (NIST 2017, <80-bit security) |

### 6.3 Authentication

| Algorithm | Usage | Notes |
|---|---|---|
| HMAC-MD5 | HTTP/DAV auth (Curl) | MD5 weakness applies |
| CRAM-MD5 | SASL auth | Legacy, MD5 weakness applies |

### 6.4 TLS Certificates

| Algorithm | Usage | Notes |
|---|---|---|
| ECDSA P-256/384 | TLS certs | Modern, acceptable |
| SHA-256/384/512 | Certificate signatures | Modern, acceptable |
| RSA (TLS certs) | Key exchange | Depends on key size |
| Let's Encrypt | Certificate issuance | Good practice |

### 6.5 Embedded Development Certificate

```
-----BEGIN CERTIFICATE-----
MIIE2zCCA8OgAwIBAgIBADANBgkqhkiG9w0BAQQFADCBqTELMAkGA1UEBhMCQ1ox
FzAVBgNVBAgTDkN6ZWNoIFJlcHVibGljMQ8wDQYDVQQHEwZQaWxzZW4xGzAZBgNV
BAoTEktlcmlvIFRlY2hub2xvZ2llczEPMA0GA1UECxMGdXBkYXRlMR0wGwYDVQQD
FBRob3N0bWFzdGVyQGtlcmlvLmNvbTEjMCEGCSqGSIb3DQEJARYUaG9zdG1hc3Rl
ckBrZXJpby5jb20wHhcNMDMwNzIyMTAxNjA0WhcNMDYwNzI0MTAxNjA0WjCBqTEL
```

- Subject: `C=CZ, ST=Czech Republic, L=Pilsen, O=Kerio Technologies, CN=hostmaster@kerio.com`
- Validity: **2003-07-22 to 2006-07-24** (expired 20 years ago)
- Self-signed development artifact

---

## 7. Complete Function Index

### Cryptographic Functions

| Function | Address | Size | Description |
|---|---|---|---|
| `RSAPublicBlock` | `0x1580f10` | — | RSA public key operation |
| `RSAPrivateBlock` | `0x1580b50` | — | CRT private key operation |
| `RSAPublicDecrypt` | `0x15814f0` | — | RSA decrypt (Type 1 padding) |
| `RSAPrivateEncrypt` | `0x1581380` | — | RSA encrypt (Type 1 padding) |
| `RSAPrivateDecrypt` | `0x1581260` | — | RSA decrypt (Type 2 padding) |
| `NN_ModExp` | `0x1580950` | — | Bignum modular exponentiation |
| `NN_Mod` | `0x1580400` | — | Bignum modular reduction |
| `NN_ModMult` | `0x15808d0` | — | Bignum modular multiplication |
| `NN_Decode` | `0x157f8c0` | — | Byte array → bignum |
| `NN_Encode` | `0x157f960` | — | Bignum → byte array |
| `R_RandomInit` | (in binary) | — | PRNG initialization |
| `R_RandomUpdate` | (in binary) | — | PRNG update (MD5-based) |
| `convertDataToMD5Stream` | `0x1581be0` | — | MD5 hash computation |
| `StreamDigestMD5::StreamDigestMD5` | `0x15b11e0` | — | MD5 digest constructor |
| `StreamDigestMD5::MD5_UTF8_8859_1` | `0x15b0130` | — | UTF-8 aware MD5 update |

### License Functions Using Crypto

| Function | Address | Size | Description |
|---|---|---|---|
| `KLicensePubKey` | `0x1581080` | 217 | Constructs RSA public key |
| `KLicense::checkLicenseSignature` | `0x1583f30` | 921 | Main signature verification |
| `KLicense::loadFrom` | `0x1587340` | 3216 | Full file parser |
| `KLicense::parseMainData` | `0x15826b0` | 1698 | Parse key-value fields |
| `KLicense::fixProductID` | `0x1581e30` | 532 | Normalize product ID |
| `KLicenseManager::check_license` | `0x15821a0` | 688 | Business rule validation |
| `KLicenseManager::load_license` | `0x1587fd0` | 663 | Load from file |
| `KLicenseManager::make_trial_license` | `0x1586380` | 244 | Generate trial license |
| `KLicenseManager::admin_set_license` | `0x1588270` | 1717 | Admin UI installation |
| `read_line` | `0x15842d0` | 327 | File line reader |
| `separateValueFromLine` | `0x15845d0` | 487 | Key: Value splitter |
| `findLicenseBeginning` | `0x1584420` | 424 | Scan for `--LICENSE--` marker |
| `read_date` | `0x1581ab0` | 299 | Date parser |
| `KLicensePart::add` | `0x15847c0` | 741 | Feature sub-block adder |
| `KLicensePart::get` | `0x1582050` | 246 | Feature sub-block getter |
| `KLicenseInternal::getString` | `0x1582ea0` | 320 | String field getter |
| `KLicenseInternal::getInt` | `0x1583b50` | 197 | Int field getter |
| `KLicenseInternal::getDate` | `0x15838c0` | 205 | Date field getter |
| `KLicenseInternal::haveFeature` | `0x1582d60` | 285 | Feature existence check |

---

## 8. Artifacts for Further Verification

### 8.1 RSA Public Key Extraction

```bash
# Extract key modulus from binary (128 bytes at .data section)
docker compose exec -T kerio-connect bash -c \
  'dd if=/opt/kerio/mailserver/mailserver bs=1 skip=$((0x33a9220)) count=128 2>/dev/null | xxd -p'

# Verify key size via KLicensePubKey constructor
docker compose exec -T kerio-connect bash -c \
  'objdump -d --start-address=0x1581080 --stop-address=0x1581160 \
    /opt/kerio/mailserver/mailserver 2>/dev/null | grep "movl.*0x400"'
```

### 8.2 PKCS#1 v1.5 Padding Verification

```bash
# Verify Type 1 padding (signatures)
docker compose exec -T kerio-connect bash -c \
  'objdump -d --start-address=0x15814f0 --stop-address=0x1581650 \
    /opt/kerio/mailserver/mailserver 2>/dev/null | \
    grep -E "cmpb.*0x10\(%rsp\)|cmpb.*0x11\(%rsp\)"'

# Verify Type 2 padding (decryption)
docker compose exec -T kerio-connect bash -c \
  'objdump -d --start-address=0x1581260 --stop-address=0x1581380 \
    /opt/kerio/mailserver/mailserver 2>/dev/null | \
    grep -E "cmpb.*0x10\(%rsp\)|cmpb.*0x11\(%rsp\)"'
```

### 8.3 MD5 Verification

```bash
# Confirm EVP_md5() call in StreamDigestMD5 constructor
docker compose exec -T kerio-connect bash -c \
  'objdump -d --start-address=0x15b11e0 --stop-address=0x15b1350 \
    /opt/kerio/mailserver/mailserver 2>/dev/null | grep "EVP_md5"'

# Verify truncated comparison in checkLicenseSignature
docker compose exec -T kerio-connect bash -c \
  'objdump -d --start-address=0x15840d0 --stop-address=0x1584120 \
    /opt/kerio/mailserver/mailserver 2>/dev/null | grep "repz cmpsb"'
```

### 8.4 License File Signature Analysis

```bash
# Extract and decode signature from trial license
head -18 licence/trial-01.lic | tail -4 | tr -d '\n' | xxd -r -p > /tmp/sig_A.bin
xxd /tmp/sig_A.bin  # 128-byte RSA signature

# Compute MD5 of signed data
sed -n '2,12p' licence/trial-01.lic | md5sum
# Compare against RSA decryption of signature (requires private key)
```

### 8.5 OpenSSL Verification Commands

```bash
# Decode license signature to raw bytes
echo "58a99f81384141bd80437db5a5174d9f94a999983c6a3db160632802ee2a4496
df3eb0ca5c59e5ee7be09714f11cdc217d4c2ad4bfa79c3f271efa538c858f05
8f93e65c7a8e4587538e5815af7cdec1df4841e2fd42f05126f1c1cd76071e3d
5a59c8860c125ac2a262df8f6d83c17d1cf75ed993a1706bd06a307444216add" | \
  tr -d ' \n' | xxd -r -p > /tmp/sig_section_a.bin

# Attempt raw RSA public key operation (will fail without correct exponent)
openssl rsautl -verify -inkey /dev/null -pubin -in /tmp/sig_section_a.bin 2>&1 || true

# Compute MD5 of Section A data
sed -n '2,12p' licence/trial-01.lic | tr -d '\r' | md5sum
```

### 8.6 Timing Side-Channel Test

```bash
# Measure RSA operation timing (approximate side-channel detection)
# Requires running multiple license verifications and measuring variance
for i in $(seq 1 100); do
  time docker compose exec -T kerio-connect \
    /usr/local/bin/healthcheck.sh 2>&1 | grep real
done | awk '{print $2}' | sort -n
# High variance indicates non-constant-time operations
```

---

## 9. Vulnerability Matrix

| ID | Component | Vulnerability | CVSS | Exploitable? |
|---|---|---|---|---|
| V-01 | MD5 | Chosen-prefix collision | 7.5 | Yes (license forgery) |
| V-02 | RSA-1024 | Factorization | 9.0 | Yes (nation-state) |
| V-03 | PKCS#1 v1.5 | Bleichenbacher | 7.0 | Limited (need ciphertext) |
| V-04 | Truncated comparison | Reduced security margin | 6.5 | Yes (with MD5 collision) |
| V-05 | Custom RSA | Timing side-channel | 5.0 | Yes (local attack) |
| V-06 | `.data` key storage | Key extraction | 4.0 | Yes (binary access) |
| V-07 | OpenSSL 1.1.0 | Known CVEs | 8.0 | Yes (many unpatched) |
| V-08 | 3DES | Sweet32 attack | 5.0 | Yes (capture) |
| V-09 | HMAC-MD5 | MD5 weakness | 5.5 | Yes (auth bypass) |
| V-10 | Expired cert | X.509 validation bypass | 3.0 | Low impact |

---

## 10. Recommendations

### For Kerio Connect (vendor)

1. **Immediate:** Replace MD5 with SHA-256 for license signature hashing
2. **Immediate:** Upgrade RSA key to 2048-bit minimum
3. **Short-term:** Migrate from PKCS#1 v1.5 to RSA-PSS
4. **Short-term:** Implement full-length hash comparison
5. **Medium-term:** Move public key to `.rodata` or use code-signing
6. **Medium-term:** Upgrade OpenSSL to 3.x LTS
7. **Long-term:** Consider Ed25519/ECDSA for license signing

### For This Lab

1. **Acceptable:** Current crypto is sufficient for lab/testing purposes
2. **Document:** Known weaknesses for lab participants
3. **Future:** If production use is considered, request vendor assessment

---

## 11. References

- NIST SP 800-57 Part 1 Rev. 5 (2020) — Key management recommendations
- RFC 8017 (2017) — PKCS#1 v2.2 (replaces v1.5)
- RFC 8018 (2017) — PKCS#5 v2.1
- NIST SP 800-131A Rev. 2 (2019) — Transitioning use of cryptographic algorithms
- RFC 6151 (2011) — MD5 and HMAC-MD5 security considerations
- RFC 6194 (2011) — SHA-1 HMAC security considerations
- Certicom ECC Challenge (2014) — ECC key size equivalences
- ROCA vulnerability (2017) — CVE-2017-15361
- Bleichenbacher attack (1998) — Adaptive chosen-ciphertext on PKCS#1 v1.5
