# SecuritySpec

This document summarizes the security design, threat model, and operational guidelines for Anchor (MVP).

## Security goals
- **Confidentiality**: User sensitive content (journal body, buddy contact, triggers) is encrypted at rest using AES-GCM.
- **Integrity**: Use authenticated encryption (AES-GCM) to detect tampering.
- **Availability**: App should survive offline use, and local backups/export should be available to the user.
- **Minimum privilege**: App asks for the minimum permissions required and clearly explains them.

## Threat model (high level)
- **Threats considered**
  - Device loss/theft: attacker could access device storage.
  - Malicious backup: attacker intercepts cloud backup.
  - Insider leaks: developer mistake resulting in plaintext upload.
- **Threats out of scope**
  - Compromised device running arbitrary code (rooted/jailbroken).
  - Attacks against the OS which can access Keychain/Secure Enclave.

## Key management
- **Symmetric key**:
  - Generated using `CryptoKit.SymmetricKey(size: .bits256)` on first run and stored in Keychain as opaque data.
  - Key alias/tag: `com.anchor.symmetric.v1` (see `KeychainHelper`).
  - Use `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` for storage accessibility.
- **Key rotation**:
  - Provide a manual "rotate keys" maintenance flow (v2). Rotation steps:
    1. Generate new key.
    2. Re-encrypt all entries with the new key in a background transaction.
    3. Delete old key after successful re-encryption.
  - For MVP, document rotation in `Docs/SecuritySpec.md` and implement manual rotation later.
- **Secure Enclave**:
  - Consider Secure Enclave for unlocking private keys or wrapping symmetric keys in future versions.

## Encryption algorithm
- **Algorithm**: AES-GCM (via Apple CryptoKit).
- **Usage**: Encrypt each sensitive field (e.g., `bodyEncrypted`) with AES-GCM. Store combined sealed box bytes (`sealed.combined`) in Core Data Binary Data.
- **Associated data**: Consider including metadata (entity id, field name) as authenticated associated data (AAD) if needed.

## Storage & backups
- **Local storage**: Core Data persistent store contains:
  - Plaintext non-sensitive primitives (dates, numeric mood/craving) for charts.
  - Ciphertext (Binary Data) for sensitive text fields.
- **iCloud/CloudKit**:
  - When enabling CloudKit, only ciphertext should be synced. Do not upload plaintext.
  - Inform users in the UI that enabling iCloud stores encrypted data in their private iCloud DB.
- **Data export**:
  - Exports can be provided as decrypted JSON (explicit user action) or as encrypted blobs. The app must clearly warn users when exporting decrypted data.
  - Deletion should securely remove Core Data records and optionally delete keys if the user requests full wipe.

## App permissions & privacy
- **Minimum permissions**:
  - Notifications: for daily check-in reminders (opt-in).
  - HealthKit: optional, explicit opt-in (for sleep/step integr).
  - Microphone / Location: only if features added that require them, with clear explanations.
- **Privacy messaging**:
  - Onboarding must clearly explain: "By default your data is stored *only on your device* and encrypted. iCloud backup is optional and encrypted."

## Secure coding & review
- Always use `try`/`catch` for encryption/decryption to avoid silent failures.
- Validate inputs on the client (e.g., limit journal max size to reasonable bytes).
- Avoid logging plaintext to console. Use `Logger.log` and guard with `#if DEBUG`.

## Testing & verification
- Unit tests:
  - Test `EncryptionService.encryptString` and `decryptToString` for multiple sizes.
  - Test decryption on random data to confirm failures are handled.
  - Test `JournalEntryEntity` round-trip save/decrypt.
- Pen-testing:
  - Before launch, run a small threat model review and a third-party security audit if possible.
- CI:
  - Do not commit real keys or secrets. Add test-only keys to the CI secret store when necessary.

## Incident response
- Provide a security contact (security@yourdomain.com) in `SECURITY.md`.
- Commit to acknowledge reports within 48 hours and provide an estimated fix timeline.

## Notes for App Review
- Document that the app stores data on-device and that cloud backups are optional.
- If any content could be considered medical/mental health guidance, include the appropriate disclaimers and list emergency contact flows (SOS).

