import Foundation

/// One row of the unified list (convertRows() in convert-selectors.js): queued work
/// and written output share a table, and the state is a column.
struct ConvertRow: Identifiable, Hashable {
    enum Kind { case queue, history }
    enum State: String { case idle, queued, running, done, stopped, missing, blocked, error }
    enum Thumb { case doc, image, comic }

    let id: String
    var kind: Kind
    var name: String
    var from: String
    var to: String
    var state: State
    var cat: String           // comics / images / documents / video
    var thumb: Thumb = .doc
    var progress: Double = 0  // 0…1
    var units = 0, doneUnits = 0
    var helper: String? = nil // for blocked rows
    var size = ""
    var when = ""

    /// thumbKind(): the label printed in the tile's pill.
    var tileLabel: String {
        switch thumb {
        case .image: "IMG"
        case .comic: "CBZ"
        case .doc: kind == .history ? "FILE" : String(from.uppercased().prefix(4))
        }
    }
}

enum Tone { case plain, quiet, run, ok, warn, bad }

extension ConvertRow {
    /// U_STATE in convert-selectors.js.
    var status: (label: String, tone: Tone, bar: Bool, shimmer: Bool) {
        switch state {
        case .idle: ("ready", .plain, false, false)
        case .queued: ("waiting", .quiet, true, false)
        case .running: (units > 0 ? "page \(max(1, doneUnits)) of \(units)" : "working…", .run, true, units == 0)
        case .done: ("on disk", .ok, false, false)
        case .stopped: ("stopped", .warn, true, false)
        case .missing: ("missing", .quiet, false, false)
        case .blocked: (helper.map { "needs \($0)" } ?? "needs a helper", .warn, false, false)
        case .error: ("could not convert", .bad, false, false)
        }
    }
}

enum Filter: String, CaseIterable, Identifiable {
    case all, active, completed, stopped, missing, comics, images, documents, video
    var id: String { rawValue }
    var name: String { rawValue.prefix(1).uppercased() + rawValue.dropFirst() }

    static let activeStates: [ConvertRow.State] = [.running, .queued, .blocked, .idle, .stopped]
    func matches(_ r: ConvertRow) -> Bool {
        switch self {
        case .all: true
        case .active: Self.activeStates.contains(r.state)
        case .completed: r.state == .done
        case .stopped: r.state == .stopped || r.state == .error
        case .missing: r.state == .missing
        default: r.cat == rawValue
        }
    }
}

enum Sort: String, CaseIterable { case newest = "Newest", oldest = "Oldest", name = "Name", largest = "Largest" }

enum SampleData {
    static let rows: [ConvertRow] = [
        .init(id: "q1", kind: .queue, name: "Saga Vol. 1.cbz", from: "CBZ", to: "EPUB", state: .running, cat: "comics", thumb: .comic, progress: 0.42, units: 160, doneUnits: 67),
        .init(id: "q2", kind: .queue, name: "Quarterly report final.docx", from: "DOCX", to: "PDF", state: .running, cat: "documents"),
        .init(id: "q3", kind: .queue, name: "IMG_4021.heic", from: "HEIC", to: "JPG", state: .queued, cat: "images", thumb: .image),
        .init(id: "q4", kind: .queue, name: "Holiday clip.mov", from: "MOV", to: "MP4", state: .blocked, cat: "video", helper: "ffmpeg"),
        .init(id: "q5", kind: .queue, name: "Lecture notes.pdf", from: "PDF", to: "EPUB", state: .idle, cat: "documents"),
        .init(id: "q6", kind: .queue, name: "Invoice 0231.pdf", from: "PDF", to: "TXT", state: .done, cat: "documents", size: "12 KB", when: "07:51 PM"),
        .init(id: "h1", kind: .history, name: "Bundle.zip", from: "Items", to: "ZIP", state: .done, cat: "documents", size: "183 B", when: "07:43 PM"),
        .init(id: "h2", kind: .history, name: "Moon Knight 01.epub", from: "CBR", to: "EPUB", state: .done, cat: "comics", size: "48.2 MB", when: "Yesterday"),
        .init(id: "h3", kind: .history, name: "Scan 2026-09-01.pdf", from: "JPG", to: "PDF", state: .stopped, cat: "images"),
        .init(id: "h4", kind: .history, name: "Old draft.txt", from: "EPUB", to: "TXT", state: .missing, cat: "documents", size: "4 KB", when: "Sep 12"),
    ]
}
