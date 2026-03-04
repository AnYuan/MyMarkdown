//
//  ImageAttachmentBuilder.swift
//  MarkdownKit
//

import Foundation

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// A dedicated builder for converting `ImageNode` entities into fully scaled
/// and measured `NSTextAttachment` strings for layout inline embedding.
struct ImageAttachmentBuilder {
    
    // An NSCache instance for thread-safe cross-layout image reuse
    nonisolated(unsafe) private static let cache = NSCache<NSString, NativeImage>()

    static func build(
        from imageNode: ImageNode,
        constrainedToWidth maxWidth: CGFloat
    ) async -> NSAttributedString? {
        guard let source = imageNode.source?.trimmingCharacters(in: .whitespacesAndNewlines),
              !source.isEmpty else {
            return nil
        }
        
        // Fast path: cached image
        let cacheKey = NSString(string: source)
        let nativeImage: NativeImage
        
        if let cached = cache.object(forKey: cacheKey) {
            nativeImage = cached
        } else {
            // Respect cooperative cancellation during slow downloads
            try? Task.checkCancellation()
            
            guard let downloaded = await loadImage(from: source) else { return nil }
            nativeImage = downloaded
            cache.setObject(downloaded, forKey: cacheKey)
        }

        let imageSize = nativeImage.size
        guard imageSize.width > 0, imageSize.height > 0 else { return nil }

        let maxAttachmentWidth = max(80, maxWidth - 24)
        let scale = min(1.0, maxAttachmentWidth / imageSize.width)
        let targetSize = CGSize(
            width: max(1, imageSize.width * scale),
            height: max(1, imageSize.height * scale)
        )

        let attachment = NSTextAttachment()
        #if canImport(UIKit)
        attachment.image = nativeImage
        #elseif canImport(AppKit)
        attachment.image = nativeImage
        #endif
        attachment.bounds = CGRect(origin: .zero, size: targetSize)
        return NSAttributedString(attachment: attachment)
    }

    private static func loadImage(from source: String) async -> NativeImage? {
        guard let url = resolvedImageURL(from: source) else { return nil }

        do {
            let data: Data
            if url.isFileURL {
                data = try Data(contentsOf: url)
            } else {
                let request = URLRequest(
                    url: url,
                    cachePolicy: .returnCacheDataElseLoad,
                    timeoutInterval: 12.0
                )
                let (networkData, response) = try await URLSession.shared.data(for: request)
                if let http = response as? HTTPURLResponse,
                   !(200...299).contains(http.statusCode) {
                    return nil
                }
                if let mimeType = response.mimeType?.lowercased(),
                   !mimeType.hasPrefix("image/") {
                    return nil
                }
                data = networkData
            }

            guard !data.isEmpty else { return nil }
            return NativeImage(data: data)
        } catch {
            return nil
        }
    }

    private static func resolvedImageURL(from source: String) -> URL? {
        let trimmed = source.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let url = URL(string: trimmed), let scheme = url.scheme, !scheme.isEmpty {
            return url
        }

        // If it looks like a URL but failed parsing, do not reinterpret it as a local file path.
        if trimmed.contains("://") {
            return nil
        }

        if trimmed.hasPrefix("~/") {
            let expandedPath = (trimmed as NSString).expandingTildeInPath
            return URL(fileURLWithPath: expandedPath)
        }

        if trimmed.hasPrefix("/") {
            return URL(fileURLWithPath: trimmed)
        }

        let cwd = FileManager.default.currentDirectoryPath
        return URL(fileURLWithPath: cwd).appendingPathComponent(trimmed)
    }
}
