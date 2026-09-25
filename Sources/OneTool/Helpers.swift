import Foundation

/// Stand-in for the helper registry (converter/registry.py) until the backend is
/// wired: the same helpers, found by looking for their binaries on this Mac.
struct Helper: Identifiable {
    let name: String, bins: [String], cmd: String, unlocks: [String]
    var id: String { name }
    var found: Bool { bins.contains(where: Helpers.which) }
}

enum Helpers {
    static let all: [Helper] = [
        .init(name: "7-Zip", bins: ["7zz", "7z", "7za"], cmd: "brew install sevenzip", unlocks: ["cbr → epub", "cbr → cbz", "rar → zip", "7z → zip", "items → 7z"]),
        .init(name: "Poppler", bins: ["pdftoppm", "pdftotext"], cmd: "brew install poppler", unlocks: ["pdf → cbz", "pdf → jpg", "pdf → png", "pdf → txt"]),
        .init(name: "ffmpeg", bins: ["ffmpeg"], cmd: "brew install ffmpeg", unlocks: ["mov → mp4", "heic → jpg", "webp → png"]),
        .init(name: "ImageMagick", bins: ["magick", "convert"], cmd: "brew install imagemagick", unlocks: ["svg → png", "svg → pdf", "items → tiff", "cbr → pdf"]),
        .init(name: "LibreOffice", bins: ["soffice", "/Applications/LibreOffice.app/Contents/MacOS/soffice"], cmd: "brew install --cask libreoffice", unlocks: ["docx → pdf", "docx → epub", "docx → txt"]),
        .init(name: "Calibre", bins: ["ebook-convert", "/Applications/calibre.app/Contents/MacOS/ebook-convert"], cmd: "brew install --cask calibre", unlocks: ["pdf → epub", "epub → mobi", "mobi → epub", "azw3 → epub"]),
    ]
    nonisolated(unsafe) private static var cache: [String: Bool] = [:]
    static var missing: Int { all.filter { !$0.found }.count }
    static func rescan() { cache = [:] }

    static func which(_ bin: String) -> Bool {
        if let hit = cache[bin] { return hit }
        let dirs = ["/opt/homebrew/bin", "/usr/local/bin", "/opt/local/bin", "/usr/bin"]
        let hit = bin.hasPrefix("/") ? FileManager.default.isExecutableFile(atPath: bin)
            : dirs.contains { FileManager.default.isExecutableFile(atPath: "\($0)/\(bin)") }
        cache[bin] = hit
        return hit
    }
}
