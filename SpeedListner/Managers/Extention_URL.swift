//
//  Extention_URL.swift
//  SpeedListner
//
//  Created by YATIN  KALRA on 25/08/25.
//

import CommonCrypto
import Foundation

extension URL {
    /// Compute MD5 hash of a file at this URL
    func md5Hash() -> String? {
        guard let stream = InputStream(url: self) else { return nil }
        stream.open()
        defer { stream.close() }

        var context = CC_MD5_CTX()
        CC_MD5_Init(&context)

        let bufferSize = 1024 * 8
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }

        while stream.hasBytesAvailable {
            let read = stream.read(buffer, maxLength: bufferSize)
            if read > 0 {
                CC_MD5_Update(&context, buffer, CC_LONG(read))
            } else {
                break
            }
        }

        var digest = Data(count: Int(CC_MD5_DIGEST_LENGTH))
        digest.withUnsafeMutableBytes { (bytes: UnsafeMutableRawBufferPointer) in
            _ = CC_MD5_Final(bytes.bindMemory(to: UInt8.self).baseAddress, &context)
        }

        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
}
