# Kerio Connect — Trial License File Analysis

License file: `licence/trial-01.lic` (56 lines, 2560 bytes)
Saved from container: `/opt/kerio/mailserver/license/license.key`

---

## 1. File Structure

```
--LICENSE--                          Строка 1
<key-value pairs>                    Строки 2-12
--SIGNATURE--                        Строка 13
<256 hex chars (128 bytes RSA)>      Строки 14-17
--END--                              Строка 18
                                     Строка 19 (пустая)
--PRODUCT-LICENSE--                  Строка 20
<key-value pairs>                    Строки 21-32
<Feature-Begin: name> ... <Feature-End: name>  Строки 33-50
--SIGNATURE--                        Строка 51
<256 hex chars (128 bytes RSA)>      Строки 52-55
--PRODUCT-END--                      Строка 56
```

Total: 56 lines, 2 sections, 2 RSA signatures.

---

## 2. Section A (`--LICENSE--`)

| Line | Field | Value | Description |
|---|---|---|---|
| 2 | `Base-ID` | `10512-ABL31-8WJ6H` | Unique license identifier |
| 3 | `Product` | `Kerio MailServer` | Product name (legacy) |
| 4 | `License-Expires` | `04 May 2026` | License expiration date |
| 5 | `Subscription-Expires` | `04 May 2026` | Subscription expiration date |
| 6 | `Users` | `25` | Maximum number of users |
| 7 | `OS` | `Linux` | Target operating system |
| 8 | `Company` | `HomeLab` | Organization name |
| 9 | `E-Mail` | `foksk76@gmail.com` | Registrant email |
| 10 | `Features` | `AV-SOPHOS` | Enabled features (comma-separated) |
| 11 | `Antivirus-Expires` | `04 May 2026` | Antivirus license expiration |
| 12 | `Add-On-ID` | `10512-ABL31-8WJ6H` | Add-on identifier |

---

## 3. Section B (`--PRODUCT-LICENSE--`)

| Line | Field | Value | Description |
|---|---|---|---|
| 21 | `Base-ID` | `10512-ABL31-8WJ6H` | Unique license identifier |
| 22 | `Product` | `Kerio Connect` | Product name |
| 23 | `Product-ID` | `1` | Numeric product ID (1 = Kerio Connect) |
| 24 | `License-Expires` | `04 May 2026` | License expiration date |
| 25 | `Subscription-Expires` | `04 May 2026` | Subscription expiration date |
| 26 | `Users` | `25` | Maximum number of users |
| 27 | `OS` | `Linux` | Target operating system |
| 28 | `Company` | `HomeLab` | Organization name |
| 29 | `E-Mail` | `foksk76@gmail.com` | Registrant email |
| 30 | `License-Type` | `Trial` | License type |
| 31 | `License-Version` | `2` | License format version |
| 32 | `Format-Version` | `1` | File format version |

### Optional fields (absent in this license)

| Field | Description | Present |
|---|---|---|
| `Person` | Individual name | No |
| `Host-ID` | Hardware-bound ID | No |
| `Edition` | Product edition | No |
| `Version` | Product version | No |
| `Min-Version` | Minimum server version | No |

---

## 4. Feature Blocks

### 4.1 Sophos (lines 33-38)

| Line | Field | Value |
|---|---|---|
| 33 | `Feature-Begin` | `Sophos` |
| 34 | `License-Expires` | `04 May 2026` |
| 35 | `Subscription-Expires` | `04 May 2026` |
| 36 | `Users` | `25` |
| 37 | `ID` | `10512-ABL31-8WJ6H` |
| 38 | `Feature-End` | `Sophos` |

### 4.2 ActiveSync (lines 39-44)

| Line | Field | Value |
|---|---|---|
| 39 | `Feature-Begin` | `ActiveSync` |
| 40 | `License-Expires` | `04 May 2026` |
| 41 | `Subscription-Expires` | `04 May 2026` |
| 42 | `Users` | `25` |
| 43 | `ID` | `10512-ABL31-8WJ6H` |
| 44 | `Feature-End` | `ActiveSync` |

### 4.3 Kerio Anti-spam (lines 45-50)

| Line | Field | Value |
|---|---|---|
| 45 | `Feature-Begin` | `Kerio Anti-spam` |
| 46 | `License-Expires` | `04 May 2026` |
| 47 | `Subscription-Expires` | `04 May 2026` |
| 48 | `Users` | `25` |
| 49 | `ID` | `10512-ABL31-8WJ6H` |
| 50 | `Feature-End` | `Kerio Anti-spam` |

---

## 5. RSA Signatures

### Section A signature (lines 14-17)

```
58a99f81384141bd80437db5a5174d9f94a999983c6a3db160632802ee2a4496
df3eb0ca5c59e5ee7be09714f11cdc217d4c2ad4bfa79c3f271efa538c858f05
8f93e65c7a8e4587538e5815af7cdec1df4841e2fd42f05126f1c1cd76071e3d
5a59c8860c125ac2a262df8f6d83c17d1cf75ed993a1706bd06a307444216add
```

- Algorithm: RSA1024
- Hash: MD5
- Verification: `KLicense::checkLicenseSignature` at `0x1583f30`
- Decryption: `RSAPublicDecrypt` at `0x15814f0`
- Hash computation: `convertDataToMD5Stream` at `0x1581be0`

### Section B signature (lines 52-55)

```
0dd49c235bc5ee475efdccab139fe3c72eb2fa99e8cd2b41cd57a3edba8b6933
f22e14b75fc1dbc4ea4731531f5e16b963a76f9c3730dcc956aa36ddb8213b6e
2f8e3216737550615cbc35e5dd9868c504550ed6f3127b9f9c41c8480dbc8ee4
bfec9a44282d1032ef4ec613c0526e5df82bf8aa961e9a587161c38377df01cf
```

Same algorithm, different private key for product license section.

---

## 6. Date Format

All dates use format: `"%d %s %d"` (day month-string year)

| Date | Parsed Value |
|---|---|
| `04 May 2026` | day=4, month="May", year=2026 |
| Parsed by: | `read_date` at `0x1581ab0` |
| Returns: | `time_t` (Unix timestamp) |

---

## 7. License Validation Flow

### 7.1 `check_license` Execution Order

| Step | Check | Offset | Result |
|---|---|---|---|
| 1 | License file exists | — | ✅ PASS |
| 2 | Internal state (0xb0) == 0 | `KLicenseInternal` | ✅ PASS |
| 3 | Product ID (0x18) == expected | `KLicense` | ✅ PASS (1 = Kerio Connect) |
| 4 | Product name (0x10) == expected | `KLicense` | ✅ PASS ("Kerio Connect") |
| 5 | License-Expires vs time() | `read_date` | ❌ FAIL (RC=3) |
| 6 | Subscription-Expires vs read_date() | `read_date` | ❌ FAIL (RC=4) |
| 7 | Custom callback (0x50) | — | Not reached |

### 7.2 Expected Return Codes

| Code | Constant | Message | This License |
|---|---|---|---|
| 0 | — | License is valid | No (expired) |
| 1 | — | No license key found | No (file exists) |
| 2 | — | Product ID does not match | No (ID=1) |
| 3 | `LicenseExpired` | License is expired | **YES** |
| 4 | — | Software Maintenance is expired | **YES** (after RC=3) |
| 5 | — | License is OK (degraded) | No |

---

## 8. License Metadata

| Property | Value |
|---|---|
| License ID | `10512-ABL31-8WJ6H` |
| Product | Kerio Connect |
| Product ID | 1 |
| License Type | Trial |
| License Version | 2 |
| Format Version | 1 |
| OS | Linux |
| Max Users | 25 |
| Company | HomeLab |
| Email | foksk76@gmail.com |
| Issue Date | ~04 Mar 2026 (estimated) |
| Expiration | 04 May 2026 |
| Duration | ~60 days (trial) |
| Features | Sophos, ActiveSync, Kerio Anti-spam |
| Antivirus | Sophos (expires 04 May 2026) |

---

## 9. Current Status

| Check | Status | Detail |
|---|---|---|
| License file | ✅ Present | `licence/trial-01.lic` |
| Signature valid | ✅ Valid | RSA1024+MD5 verified |
| Product match | ✅ Match | Product-ID=1, name="Kerio Connect" |
| License expired | ❌ Expired | 04 May 2026 < 22 Jul 2026 |
| Subscription expired | ❌ Expired | 04 May 2026 < 22 Jul 2026 |
| SMTP available | ❌ Blocked | 421 4.3.2 Server license expired |
| Email sending | ❌ Blocked | All outbound email rejected |

---

## 10. TinyDB Storage

When loaded, the license is stored in TinyDB with these variables:

| Variable | Value |
|---|---|
| `TinydbLicenseVariableId` | `10512-ABL31-8WJ6H` |
| `TinydbLicenseVariableOS` | `Linux` |
| `TinydbLicenseVariableUsers` | `25` |
| `TinydbLicenseVariableCompany` | `HomeLab` |
| `TinydbLicenseVariableProduct` | `Kerio Connect` |
| `TinydbLicenseVariableTrialID` | (not set) |
| `TinydbLicenseVariableFeatures` | `AV-SOPHOS` |
| `TinydbLicenseVariableLicenseType` | `Trial` |
| `TinydbLicenseVariableLicenseExpires` | `04 May 2026` |
| `TinydbLicenseVariableAntivirusExpires` | `04 May 2026` |
| `TinydbLicenseVariableSubscriptionExpires` | `04 May 2026` |

---

## 11. Related Functions

### File Parsing

| Function | Address | Size | Role |
|---|---|---|---|
| `read_line` | `0x15842d0` | 327 | Read one line from file stream |
| `separateValueFromLine` | `0x15845d0` | 487 | Split `Key: Value` on `:` delimiter |
| `findLicenseBeginning` | `0x1584420` | 424 | Scan for `--LICENSE--` marker |
| `loadFrom` | `0x1587340` | 3216 | Full file parser (sections + signatures + key-value) |
| `parseMainData` | `0x15826b0` | 1698 | Parse key-value fields (21 recognized keys) |
| `checkLicenseSignature` | `0x1583f30` | 921 | Verify RSA1024+MD5 signature |
| `convertDataToMD5Stream` | `0x1581be0` | — | Compute MD5 hash |
| `RSAPublicDecrypt` | `0x15814f0` | — | RSA decrypt |
| `RSAPublicBlock` | `0x1580f10` | — | Core RSA modpow |

### Feature Sub-block Handling

| Function | Address | Size | Role |
|---|---|---|---|
| `KLicensePart::add` | `0x15847c0` | 741 | Add key-value to feature sub-block |
| `KLicensePart::get` | `0x1582050` | 246 | Retrieve field from feature sub-block |
| `KLicensePart::set` | `0x1584ae0` | 323 | Set fields from map |
| `KLicenseInternal::getString` | `0x1582ea0` | 320 | Get field value (string) |
| `KLicenseInternal::getInt` | `0x1583b50` | 197 | Get field value (int) |
| `KLicenseInternal::getDate` | `0x15838c0` | 205 | Get field value (time_t) |
| `KLicenseInternal::haveFeature` | `0x1582d60` | 285 | Check if feature exists |

### Validation & Management

| Function | Address | Size | Role |
|---|---|---|---|
| `KLicense::fixProductID` | `0x1581e30` | 532 | Normalize product ID |
| `KLicense::setData` | `0x1584e20` | 504 | Set internal data from parsed values |
| `KLicenseInternal::list` | `0x1581cf0` | 155 | Serialize license to string |
| `KLicenseManager::check_license` | `0x15821a0` | 688 | 9-step validation |
| `KLicenseManager::load_license` | `0x1587fd0` | 663 | Load from file |
| `KLicenseManager::make_trial_license` | `0x1586380` | 244 | Generate trial license |
| `KLicenseManager::admin_set_license` | `0x1588270` | 1717 | Install via Admin UI |
| `read_date` | `0x1581ab0` | 299 | Parse date format `"%d %s %d"` |
| `convertDataToMD5Stream` | `0x1581be0` | MD5 hash computation |
