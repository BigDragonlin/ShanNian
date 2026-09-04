import Foundation

/// 把一条闪念整理成 Markdown，并安全地追加到指定文档末尾。
public enum EntryWriter {
    /// 新文档统一使用的标题和说明。
    public static let documentHeader = "# 闪念记录\n\n> 随手记录当下的想法。每条记录包含时间、地点和正文。\n\n"

    public static func formattedEntry(
        text: String,
        date: Date,
        location: String,
        timeZone: TimeZone = .current
    ) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy年M月d日 HH:mm"

        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanLocation = location.trimmingCharacters(in: .whitespacesAndNewlines)
        let shownLocation = cleanLocation.isEmpty ? "地点获取中" : cleanLocation
        return "## \(formatter.string(from: date))\n\n📍 **地点：** \(shownLocation)\n\n\(cleanText)\n\n---\n\n"
    }

    public static func append(
        text: String,
        date: Date = Date(),
        location: String,
        timeZone: TimeZone = .current,
        to fileURL: URL
    ) throws {
        let entry = formattedEntry(text: text, date: date, location: location, timeZone: timeZone)
        let fileManager = FileManager.default

        // 新建的空文档可以直接写入；已有文档则从末尾继续追加。
        if !fileManager.fileExists(atPath: fileURL.path) {
            try Data().write(to: fileURL)
        }

        let handle = try FileHandle(forWritingTo: fileURL)
        defer { try? handle.close() }

        let oldData = try Data(contentsOf: fileURL)
        try handle.seekToEnd()

        // 空文档先写入统一标题；已有内容则从下一行开始追加。
        if oldData.isEmpty {
            try handle.write(contentsOf: Data(documentHeader.utf8))
        } else if let lastByte = oldData.last, lastByte != 10 {
            try handle.write(contentsOf: Data("\n".utf8))
        }
        try handle.write(contentsOf: Data(entry.utf8))
    }
}
