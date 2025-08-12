
import Foundation
import CryptoKit

final class EncryptionService {
    static let shared = EncryptionService()
    private let keyTag = "com.anchor.symmetrickey.v1"

    private init() {
        if KeychainHelper.shared.getKeyData(tag: keyTag) == nil {
            _ = generateAndStoreKey()
        }
    }

    private func generateAndStoreKey() -> SymmetricKey? {
        let key = SymmetricKey(size: .bits256)
        let data = key.withUnsafeBytes { Data(Array($0)) }
        KeychainHelper.shared.saveKeyData(data, tag: keyTag)
        return key
    }

    private func getKey() -> SymmetricKey? {
        guard let data = KeychainHelper.shared.getKeyData(tag: keyTag) else { return nil }
        return SymmetricKey(data: data)
    }

    func encryptString(_ text: String) throws -> Data {
        guard let key = getKey() else { throw NSError(domain: "EncryptionService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Key missing"]) }
        let plain = Data(text.utf8)
        let sealed = try AES.GCM.seal(plain, using: key)
        guard let combined = sealed.combined else {
            throw NSError(domain: "EncryptionService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Seal failed"])
        }
        return combined
    }

    func decryptToString(_ cipher: Data) throws -> String {
        guard let key = getKey() else { throw NSError(domain: "EncryptionService", code: -1, userInfo: nil) }
        let sealed = try AES.GCM.SealedBox(combined: cipher)
        let plain = try AES.GCM.open(sealed, using: key)
        return String(decoding: plain, as: UTF8.self)
    }
}
