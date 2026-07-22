# Kerio Connect Licensing System — Reverse-Engineering Specification

Source binary: `/opt/kerio/mailserver/mailserver` (~66 MB ELF x86_64)

All addresses are virtual addresses within the ELF binary. Class prefix is `kerio::crypto::` unless noted.

---

## 1. License File Format

**Path:** `/opt/kerio/mailserver/license/license.key`

The file contains two independently signed sections:

```
--LICENSE--
<key-value pairs>
--SIGNATURE--
<256 hex chars (128 bytes) RSA signature>
--END--

--PRODUCT-LICENSE--
<key-value pairs>
--SIGNATURE--
<256 hex chars (128 bytes) RSA signature>
--PRODUCT-END--
```

- Both sections are signed and verified independently.
- Each signature covers only the text between its opening and closing markers (excluding the markers themselves).
- The `--PRODUCT-LICENSE--` section can contain sub-blocks delimited by `Feature-Begin: <name>` / `Feature-End: <name>`, each with their own key-value pairs.

---

## 2. License Field Reference

### Section A (`--LICENSE--`)

| Field | Description | Example |
|---|---|---|
| `Base-ID` | Unique license identifier | `10512-ABL31-8WJ6H` |
| `Product` | Product name | `Kerio MailServer` |
| `License-Expires` | License expiry date | `04 May 2026` |
| `Subscription-Expires` | Maintenance/support expiry | `04 May 2026` |
| `Users` | Maximum number of users | `25` |
| `OS` | Target operating system | `Linux` |
| `Company` | Licensed organization | `HomeLab` |
| `E-Mail` | Registrant email | `foksk76@gmail.com` |
| `Features` | Comma-separated feature list | `AV-SOPHOS` |
| `Antivirus-Expires` | Antivirus module expiry | `04 May 2026` |
| `Add-On-ID` | Add-on identifier | `10512-ABL31-8WJ6H` |

### Section B (`--PRODUCT-LICENSE--`)

All Section A fields, plus:

| Field | Description | Example |
|---|---|---|
| `Product-ID` | Numeric product identifier | `1` |
| `License-Type` | License type | `Trial` |
| `License-Version` | License format version | `2` |
| `Format-Version` | File format version | `1` |
| `Person` | (optional) Registrant name | — |
| `Host-ID` | (optional) Hardware-locked ID | — |
| `Edition` | (optional) Edition name | — |
| `Version` | (optional) Product version | — |
| `Min-Version` | (optional) Minimum version | — |

**Note:** `License-Version` (currently `2`) controls the internal license structure version. `Format-Version` (currently `1`) controls the file format version. These are distinct — `License-Version` affects how fields are parsed, while `Format-Version` affects the overall file structure.

### Feature Sub-blocks (within `--PRODUCT-LICENSE--`)

```
Feature-Begin: <feature-name>
License-Expires: <date>
Subscription-Expires: <date>
Users: <max>
ID: <base-id>
Feature-End: <feature-name>
```

Current feature names observed: `Sophos`, `ActiveSync`, `Kerio Anti-spam`.

### Date Format

All date fields use the format: `"%d %s %d"` (day month-as-string year)

Examples: `04 May 2026`, `31 Dec 2025`

Parsed by `read_date` at `0x1581ab0` using `sscanf(date_string, "%d %s %d", ...)` → `time_t`

### Parsed Field Names (`KLicense::parseMainData`)

Fields recognized by the parser at `0x15826b0`:

```
Product, Product-ID, Version, Edition, Min-Version,
Base-ID, Company, Person, E-Mail, Host-ID,
Features, License-Expires, Subscription-Expires
```

---

## 3. Signature Verification

### 3.1 RSA Public Key (`KLicensePubKey`)

**Constructor:** `0x1581080`

- Allocates 0x104 (260) bytes for `R_RSA_PUBLIC_KEY` struct
- Copies 128 bytes of key modulus into offset 0x00-0x7F
- Sets `bits = 0x400` (1024-bit RSA) at offset 0x80
- Sets flags at offsets 0x101 and 0x103

Key structure:

```c
struct R_RSA_PUBLIC_KEY {
    unsigned int bits;        // 0x400 (1024)
    unsigned char modulus[128];  // 128 bytes key material
    unsigned char exponent[128]; // padded with 0x00
};
```

### 3.2 Verification Algorithm (`KLicense::checkLicenseSignature`)

**Function:** `0x1583f30`

1. Decode the 256 hex chars from `--SIGNATURE--` section into 128 bytes of ciphertext.
2. Compute MD5 hash of the data between `--LICENSE--` and `--SIGNATURE--` markers (via `convertDataToMD5Stream` at `0x1581be0`).
3. RSA public-key decrypt the 128-byte signature using `RSAPublicDecrypt` (`0x15814f0` → `RSAPublicBlock` at `0x1580f10`).
4. Compare the first 16 bytes of the decrypted result against the MD5 digest using `repz cmpsb` with length = 0x10 (16 bytes).
5. If all 16 bytes match → signature valid. Otherwise → invalid.

```
plaintext = RSA_decrypt(signature, publicKey)
MD5_hash  = MD5(data_between_markers)
return (memcmp(plaintext[0..15], MD5_hash) == 0)
```

### 3.3 Functions

| Function | Address | Description |
|---|---|---|
| `RSAPublicDecrypt` | `0x15814f0` | RSA decrypts 128-byte block |
| `RSAPublicBlock` | `0x1580f10` | Core RSA exponentiation (`modpow`) |
| `convertDataToMD5Stream` | `0x1581be0` | Computes MD5 of a stream/string |
| `KLicensePubKey` | `0x1581080` | Constructs RSA public key struct |
| `KLicense::checkLicenseSignature` | `0x1583f30` | Main verification entry point |

---

## 4. Validation Flow

### 4.1 License Loading (`KLicenseManager::load_license`)

**Function:** `0x1582de0`

1. Open the license file as `KFile`.
2. Call `KLicense::findLicenseBeginning(KFile&)` at `0x1583940` — scans for `--LICENSE--` marker.
3. Call `KLicense::loadFrom(string&)` at `0x15838c0` — loads content into `KLicense` object.
4. Call `KLicense::checkLicenseSignature(KLicense*, char*, int)` at `0x1583f30` — verifies signature.
5. Call `KLicenseInternal::checkLicense(KLicense*, char*, int)` — validates business rules.

### 4.2 `KLicenseInternal::list`

**Function:** `0x1581cf0`

Returns a serialized representation of the loaded license.

### 4.3 `KLicense::fixProductID`

**Function:** `0x1581e30`

Normalizes the product ID field after loading. Product ID enum:

| ID | Product |
|---|---|
| 0 | Unknown |
| 1 | Kerio Connect |
| 2 | Kerio Operator |
| 3 | Kerio Control |
| 4 | Kerio WinRoute Firewall |
| 5 | Kerio Control UTM |
| 6 | Kerio Outlook Connector |
| 7 | Kerio Client |
| 8 | Kerio Connect ActiveSync |

### 4.4 Business Rule Validation (`check_license`)

**Function:** `0x15821a0` (`KLicenseManager::check_license`)

**Parameters:** `(KLicense* license, char* error_buffer, int error_buffer_size)`

**Return codes:**

| Code | Condition | Error String |
|---|---|---|
| 0 | License is valid | — |
| 1 | No license found / internal state error | `No license key found` |
| 2 | Product ID mismatch | `Product ID does not match` |
| 2 | Product name mismatch | `Product name does not match` |
| 3 | License expired | `License is expired` |
| 4 | Software Maintenance expired | `The Software Maintenance is expired` |
| 5 | Custom check failure (feature/limit) | `License is OK` (but server enters degraded mode) |

**Execution order** (from disassembly at `0x15821a0`):

1. Load manager's internal license pointer from `this+0x70`
2. If null → RC=1, call `licenseFail`
3. Check `KLicense+0xb0` (internal state) — must be 0
   - If non-zero → RC=1, call `licenseFail`
4. Compare `KLicense+0x18` (int Product ID) vs `manager+0x20` (expected)
   - Mismatch → RC=2 "Product ID does not match"
5. Compare `KLicense+0x10` (string Product name) vs `manager+0x18` (expected)
   - Length mismatch → RC=2 "Product name does not match"
   - Content mismatch (memcmp) → RC=2 "Product name does not match"
6. Compare `KLicense+0x78` (license expiry `time_t`) vs `time()` (current time)
   - Expired → RC=3 "License is expired"
7. Compare `KLicense+0x80` (subscription expiry) vs `read_date(manager+0x38)` (current date)
   - Expired → RC=4 "Software Maintenance is expired"
8. Call custom callback at `KLicense+0x50` (function pointer) with `(license, error_buffer, ecx)`
   - Returns 0 → RC=5 "License is OK" (degraded mode), call `licenseFail`
9. All pass → call `licenseOk` → RC=0

**Important:** Steps 4-5 check **product identity**, not domain. The "Defined domain is different than in license file" check happens in a separate code path (initial_check_license or admin UI).

### 4.5 `initial_check_license`

**Function:** `0x1582450` (`KLicenseManager::initial_check_license`)

**Parameters:** `(KLicense* license, char* error_buffer, int error_buffer_size)`

Extended validation chain (runs after `check_license`):

1. Null-license check → `Cannot check null license`
2. Check internal state (`KLicense` at offset 0xb0 = 0 means valid)
3. Call `checkMinimalVersion` at `0x15819f0` — parses `"%d.%d.%d"` version strings
   - Compares server binary version against `Min-Version` from license
   - Failure: `Product edition does not match` or `Product version doesn't fit required minimal version`
4. Check domain against license — compares configured domain against license domain field
   - Failure: `Defined domain is different than in license file`
5. Call `licenseFail` at `0x157f860` on any failure

### 4.6 `KLicenseManager::isLicenseOk`

**Function:** `0x157f890`

High-level convenience wrapper. Returns boolean indicating overall license health.

### 4.7 `check_promo_license`

**Function:** `0x436bd0`

Validates promotional/trial licenses. Likely checks expiry and feature flags.

---

## 5. Trial License Generation

### 5.1 `KLicenseManager::make_trial_license`

**Function:** `0x1582c20`

Generates a trial license with default parameters. Called during initial setup when no license file exists.

### 5.2 `AutomaticLicenseUpdater::tryLicenseUpdate`

**Function:** `0x1ffc470`

Periodically checks for license updates from the registration server.

### 5.3 `AutomaticLicenseManager::checkLicense`

**Function:** `0x1581650` (`KLicenseInternal::checkLicense`)

Runs the full check chain: expiry → product ID → domain → user count → feature flags.

---

## 6. License Installation

### 6.1 `admin_set_license`

**Function:** `0x1584780` (`KLicenseManager::admin_set_license`)

1. Receive license data from admin UI.
2. Write to `license.key` file.
3. Reload and verify.
4. Error messages:
   - `Cannot write new license file`
   - `Cannot install the new license file`
   - `Cannot load new license file`

### 6.2 `RegistrationManager::installLicense`

**Function:** `0x2005580`

Installs a license downloaded from the registration server:

1. Parse response from `LicenseDownloader`.
2. Write license data to file.
3. Notify `LicenseManager` to reload.
4. Source: `registration.cpp`

### 6.3 `KLicenseInternal::install`

**Function:** `0x157f8d0`

Low-level license installation after download.

---

## 7. Registration Server & Downloader

### 7.1 Endpoints

| URL | Purpose |
|---|---|
| `https://register.kerio.com/registration/LD.php` | License download endpoint |
| `http://trial.kerio.com/challenge/` | Trial activation (HTTP, not HTTPS) |

### 7.2 `LicenseDownloader`

**Constructor:** `0x20160f0`

Parses HTTP headers from registration server responses.

#### HTTP Headers

| Field | Header Name |
|---|---|
| `Header_Kerio_Desc` | `X-Kerio-Desc` |
| `User_Agent_Header` | `User-Agent` |
| `Header_Kerio_Token` | `X-Kerio-Token` |
| `Header_Content_Type` | `Content-Type` |
| `Header_Kerio_Response` | `X-Kerio-Response` |
| `Reg_Data_Content_Type` | `application/x-kerio-registration` |

#### Response Codes (`LicenseDownloader::parse_reply_code`)

- `0x2016bb0` — Parses integer code from HTTP response body.
- Returns numeric status code indicating success/failure type.

#### Supported MIME Types

- `application/x-kerio-license` — Full license file
- `application/x-kerio-registration` — Registration data
- `application/x-kerio-trial` — Trial license request

### 7.3 `ProductRegistration`

**API methods:**

| Method | Description |
|---|---|
| `ProductRegistration.start` | Initiates registration with registration server |
| `ProductRegistration.finish` | Completes registration and receives license |
| `Server.uploadLicense` | Uploads a license file directly |

---

## 8. API Validation States

These string constants appear in JSON API error responses:

| Constant | Meaning |
|---|---|
| `kerio_jsonapi_admin_LicenseExpired` | License expiry date passed |
| `kerio_jsonapi_admin_LicenseSoonExpire` | License expiry within warning window |
| `kerio_jsonapi_admin_LicenseInvalidDomain` | Licensed domain doesn't match server config |
| `kerio_jsonapi_admin_LicenseInvalidEdition` | Product edition mismatch |
| `kerio_jsonapi_admin_LicenseInvalidMinVersion` | Server version below minimum |
| `kerio_jsonapi_admin_LicenseInvalidOS` | Wrong OS (e.g., Linux license on Windows) |
| `kerio_jsonapi_admin_LicenseInvalidUser` | Licensed user doesn't match |
| `kerio_jsonapi_admin_LicenseLimit` | User count limit reached |
| `kerio_jsonapi_admin_LicenseTooManyUsers` | Active users exceed license limit |
| `kerio_jsonapi_admin_LicenseCheckForwardingEnabled` | License check affects mail forwarding |

---

## 9. Internal Data Structures

### 9.1 `KLicense` Object Layout (offsets)

Verified via `check_license` disassembly — field sizes inferred from `mov`/`cmp` operands.

| Offset | Size | Type | Field | Description |
|---|---|---|---|---|
| 0x00-0x07 | 8 | pointer | vtable | C++ vtable pointer |
| 0x10 | 16 | `std::string` | Product name | Product name string (e.g., "Kerio Connect") |
| 0x18 | 4 | `int` | Product ID | Numeric product ID (1=Connect, 2=Operator, etc.) |
| 0x20 | 4 | (padding) | — | — |
| 0x28 | 16 | `std::string` | Raw data | License file content (parsed from markers) |
| 0x38 | 16 | `std::string` | Version | Product version string |
| 0x50 | 16 | `std::string` | Edition | Product edition string |
| 0x58 | 16 | `std::string` | OS | Operating system string |
| 0x70 | 8 | pointer | — | Internal pointer (used by `check_license` to load manager) |
| 0x78 | 8 | `time_t` | License-Expires | License expiry timestamp (Unix epoch) |
| 0x80 | 8 | `time_t` | Subscription-Expires | Subscription expiry timestamp |
| 0x88 | 4 | `int` | Users | Max user count |
| 0x8c | 4 | (padding) | — | — |
| 0x90 | 16 | `std::string` | Company | Company name |
| 0xa0 | 16 | `std::string` | E-Mail | Registrant email |
| 0xb0 | 4 | `int` | Internal state | 0 = valid/unverified, >0 = error code |
| 0xb4 | 4 | (padding) | — | — |
| 0xb8 | 4 | `int` | License type | 0 = none, 1 = standard, 2 = trial |
| 0xbc | 4 | (padding) | — | — |
| 0xc0 | 16 | `std::string` | Product string | Product name (secondary copy) |
| 0xc8 | 4 | `int` | Product ID int | Numeric product ID (secondary copy) |

**Key insight:** `check_license` compares `KLicense+0x18` (int Product ID) against the manager's expected ID, and `KLicense+0x10` (string Product name) against the manager's expected name. These are **not** domain checks — they verify the product type matches.

### 9.2 `KLicenseInternal` — Extends `KLicense`

Constructor: `0x157f6f0` | Destructor: `0x157f7f0`

Adds callback function pointers and state management beyond the base `KLicense` fields:

| Offset | Size | Type | Field | Description |
|---|---|---|---|---|
| 0x50 | 8 | function ptr | Custom callback | Called during `check_license` (RC=5 path) |
| 0x60 | 8 | function ptr | OK callback | Called by `licenseOk` after successful check |
| 0x68 | 8 | function ptr | Fail callback | Called by `licenseFail` after failed check |
| 0x78 | 4 | `int` | Status | 0 = fail, 1 = ok (set by `licenseOk`/`licenseFail`) |

**Callback signatures:**
- `licenseOk(this)` at `0x157f850`: Sets `this+0x78 = 1`, then calls `this+0x60` (OK callback)
- `licenseFail(this)` at `0x157f860`: Sets `this+0x78 = 0`, then calls `this+0x68` (Fail callback)
- `defaultOkFunction()` at `0x157f870`: Returns 1 (default no-op callback)

`setNullLicense` at `0x157f7f0` — initializes all fields to null/expired state.

### 9.3 TinyDB License Variables (database columns)

Stored in the Kerio configuration database:

```
TinydbLicenseVariableId
TinydbLicenseVariableOS
TinydbLicenseVariableUsers
TinydbLicenseVariableCompany
TinydbLicenseVariableProduct
TinydbLicenseVariableTrialID
TinydbLicenseVariableFeatures
TinydbLicenseVariableLicenseType
TinydbLicenseVariableLicenseExpires
TinydbLicenseVariableAntivirusExpires
TinydbLicenseVariableSubscriptionExpires
```

---

## 10. Key Function Index

### Core Validation

| Function | Address | Description |
|---|---|---|
| `KLicensePubKey` | `0x1581080` | Constructs 1024-bit RSA public key |
| `RSAPublicDecrypt` | `0x15814f0` | RSA public decrypt (128 bytes) |
| `RSAPublicBlock` | `0x1580f10` | Core RSA modular exponentiation |
| `convertDataToMD5Stream` | `0x1581be0` | MD5 hash computation |
| `KLicense::checkLicenseSignature` | `0x1583f30` | Signature verification |
| `KLicense::findLicenseBeginning` | `0x1583940` | Scan for `--LICENSE--` marker |
| `KLicense::loadFrom` | `0x15838c0` | Parse file content into object |
| `KLicense::parseMainData` | `0x15826b0` | Parse key-value fields |
| `KLicense::fixProductID` | `0x1581e30` | Normalizes product ID |
| `KLicenseInternal::list` | `0x1581cf0` | Serializes license to string |

### License Management

| Function | Address | Description |
|---|---|---|
| `KLicenseManager::checkMinimalVersion` | `0x15819f0` | Parses `"%d.%d.%d"`, compares major.minor.patch |
| `KLicenseManager::isLicenseOk` | `0x157f890` | High-level license health check |
| `KLicenseManager::check_license` | `0x15821a0` | Full business-rule validation |
| `KLicenseManager::initial_check_license` | `0x1582450` | Extended validation chain (version+domain) |
| `KLicenseManager::load_license` | `0x1582de0` | Load from file |
| `KLicenseManager::admin_set_license` | `0x1584780` | Admin UI license installation |
| `KLicenseManager::make_trial_license` | `0x1582c20` | Generate trial license |
| `KLicenseManager::licenseOk` | `0x157f850` | Sets state=1, calls OK callback |
| `KLicenseManager::licenseFail` | `0x157f860` | Sets state=0, calls Fail callback |
| `KLicenseManager::defaultOkFunction` | `0x157f870` | Default OK callback (returns 1) |
| `KLicenseInternal::setNullLicense` | `0x157f7f0` | Initialize null/expired state |
| `KLicenseInternal::checkLicense` | `0x157f8d0` | Internal install/check |

### Date/Time Parsing

| Function | Address | Description |
|---|---|---|
| `read_date` (static) | `0x1581ab0` | Parses `"%d %s %d"` → `time_t` |
| `getLicenseExpiresLocalTime` | `0x8cc4f0` | Converts expiry to local time string |

### License Lifecycle

| Function | Address | Description |
|---|---|---|
| `load_check_license` | `0x436240` | Top-level load+check entry point |
| `simplifyLicenseCheckResult` | `0x8b41a0` | Normalizes check result codes |
| `check_promo_license` | `0x436bd0` | Validate promotional license |
| `license_hook` | `0x8cf9a0` | TinyDB hook for license config changes |
| `dbfunc_set_license` | `0x8ceea0` | TinyDB function to set license |

### Auto-Update

| Function | Address | Description |
|---|---|---|
| `LicenseDownloader` | `0x20160f0` | Constructor, HTTP header parser |
| `LicenseDownloader::parse_reply_code` | `0x2016bb0` | Parse server response code |
| `RegistrationManager::installLicense` | `0x2005580` | Install downloaded license |
| `AutomaticLicenseUpdater::tryLicenseUpdate` | `0x1ffc470` | Periodic update check |
| `AutomaticLicenseManager::checkLicense` | `0x1581650` | Periodic license verification |
| `getAutoLicenseUpdatePeriod` | `0x8c9fb0` | Reads auto-update interval config |
| `registerAutoLicenseUpdateConfig` | `0x8c9fb0` | Registers config keys for auto-update |
| `licenseUpdateDoneCb` | `0x8ca080` | Callback when async update completes |
| `dbfuncResetLicenseUpdatePeriod` | `0x8c9fe0` | Resets the update timer |

### Cluster Functions

| Function | Address | Description |
|---|---|---|
| `ClusterDir::Slave::ClearUserLicenseDDIndexes` | `0x22198a0` | Clears license indexes on slave |
| `ClusterDir::Master::GetUserLicenseIndex` | `0x2247020` | Gets user license index on master |
| `ClusterDir::Master::ShowTrackedLicensedUsers` | `0x224c8f0` | Lists tracked licensed users |
| `ClusterDir::Master::ShowTrackedLicensedUsersCount` | `0x2246b00` | Counts tracked licensed users |

### Antispam License

| Function | Address | Description |
|---|---|---|
| `SpamModule::isBitDefenderLicensed` | `0x51e540` | Checks BitDefender license status |
| `computeLicenseValidity` (anonymous) | `0x532900` | Computes BitDefender license validity |

---

## 11. User-Facing Error Messages

| Message | Source | Trigger |
|---|---|---|
| `Cannot check null license` | `initial_check_license` | License pointer is null |
| `No license key found` | `licenseFail` | No license file or internal state error |
| `Cannot write new license file` | `admin_set_license` | File write failure |
| `Cannot load new license file` | `admin_set_license` | License parse failure |
| `Cannot install the new license file` | `admin_set_license` | Installation failure |
| `Defined domain is different than in license file` | `initial_check_license` | Domain mismatch (separate from product name) |
| `Product edition does not match` | `checkMinimalVersion` | Edition string mismatch |
| `Product version doesn't fit required minimal version` | `checkMinimalVersion` | Server version < Min-Version |
| `Product ID does not match` | `check_license` | Numeric product ID mismatch (step 4) |
| `Product name does not match` | `check_license` | Product name string mismatch (step 5) |
| `License is expired` | `check_license` | License-Expires < current time (step 6) |
| `The Software Maintenance is expired` | `check_license` | Subscription-Expires < current time (step 7) |
| `License is OK` | `check_license` | Custom callback returned 0 (RC=5, degraded mode) |
| `Failed to upgrade server, invalid license` | Upgrade handler | Invalid license during upgrade |
| `Failed to upgrade server. License has expired` | Upgrade handler | Expired license during upgrade |

---

## 12. Source Paths (from debug strings)

```
/mnt/cache/teamcity/work/Connect92_Engine_EngineLinuxX64release/src/wrmail/registration.cpp
KLicense.cpp
KLicenseInternal.cpp
License.cpp
LicenseDownloader.cpp
AutomaticLicenseUpdate.cpp
AutomaticLicenseUpdater.cpp
TinydbLicenseVariables.cpp
ProductRegistration.cpp
ProductRegistrationImpl.cpp
LicenseManager.cpp
BitDefenderAntispamLicense.cpp
GreylistLicenseMan.cpp
UserLicenseTrackerBase.cpp
UserLicenseTracker.cpp
UserLicenseTrackerMaster.cpp
license_manager.cpp
```

### Exception Classes

| Class | Vtable | Description |
|---|---|---|
| `LicenseParserException` | `0x39b2e38` | Thrown on license file parse errors |

### Global Variables

| Variable | Address | Description |
|---|---|---|
| `license_manager` | `0x39e5088` | Singleton license manager instance |
| `licenseUpdatePeriod` | `0x39aa850` | Auto-update interval config |

---

## 13. Sample License (Lab Reference)

```
--LICENSE--
Base-ID: 10512-ABL31-8WJ6H
Product: Kerio MailServer
License-Expires: 04 May 2026
Subscription-Expires: 04 May 2026
Users: 25
OS: Linux
Company: HomeLab
E-Mail: foksk76@gmail.com
Features: AV-SOPHOS
Antivirus-Expires: 04 May 2026
Add-On-ID: 10512-ABL31-8WJ6H
--SIGNATURE--
58a99f81384141bd80437db5a5174d9f94a999983c6a3db160632802ee2a4496
df3eb0ca5c59e5ee7be09714f11cdc217d4c2ad4bfa79c3f271efa538c858f05
8f93e65c7a8e4587538e5815af7cdec1df4841e2fd42f05126f1c1cd76071e3d
5a59c8860c125ac2a262df8f6d83c17d1cf75ed993a1706bd06a307444216add
--END--

--PRODUCT-LICENSE--
Base-ID: 10512-ABL31-8WJ6H
Product: Kerio Connect
Product-ID: 1
License-Expires: 04 May 2026
Subscription-Expires: 04 May 2026
Users: 25
OS: Linux
Company: HomeLab
E-Mail: foksk76@gmail.com
License-Type: Trial
License-Version: 2
Format-Version: 1
Feature-Begin: Sophos
License-Expires: 04 May 2026
Subscription-Expires: 04 May 2026
Users: 25
ID: 10512-ABL31-8WJ6H
Feature-End: Sophos
Feature-Begin: ActiveSync
License-Expires: 04 May 2026
Subscription-Expires: 04 May 2026
Users: 25
ID: 10512-ABL31-8WJ6H
Feature-End: ActiveSync
Feature-Begin: Kerio Anti-spam
License-Expires: 04 May 2026
Subscription-Expires: 04 May 2026
Users: 25
ID: 10512-ABL31-8WJ6H
Feature-End: Kerio Anti-spam
--SIGNATURE--
0dd49c235bc5ee475efdccab139fe3c72eb2fa99e8cd2b41cd57a3edba8b6933
f22e14b75fc1dbc4ea4731531f5e16b963a76f9c3730dcc956aa36ddb8213b6e
2f8e3216737550615cbc35e5dd9868c504550ed6f3127b9f9c41c8480dbc8ee4
bfec9a44282d1032ef4ec613c0526e5df82bf8aa961e9a587161c38377df01cf
--PRODUCT-END--
```
