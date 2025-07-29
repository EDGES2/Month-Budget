// Month Budget/Extensions/UUID+Helpers.swift
import Foundation
import CryptoKit

extension UUID {
    static func uuidFromString(_ string: String) -> UUID {
        let data = Data(string.utf8)
        let hash = Insecure.MD5.hash(data: data)
        var uuidBytes = Array(hash)
        
        uuidBytes[6] = (uuidBytes[6] & 0x0F) | 0x30
        uuidBytes[8] = (uuidBytes[8] & 0x3F) | 0x80
        
        return uuidBytes.withUnsafeBytes { pointer in
            let bytes = pointer.bindMemory(to: uuid_t.self)
            return UUID(uuid: bytes.baseAddress!.pointee)
        }
    }
}

extension Transaction {
    var wrappedId: UUID { id ?? UUID() }
    var validCategory: String { category ?? "Інше" }
}
