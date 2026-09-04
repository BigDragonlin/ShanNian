import Foundation
import ShanNianCore

/// 轻量验证器：实际写入临时文档，再读回来检查结果。
func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        FileHandle.standardError.write(Data("检查失败：\(message)\n".utf8))
        exit(1)
    }
}

var components = DateComponents()
components.calendar = Calendar(identifier: .gregorian)
components.timeZone = TimeZone(secondsFromGMT: 8 * 3600)
components.year = 2026
components.month = 9
components.day = 4
components.hour = 15
components.minute = 20

let formatted = EntryWriter.formattedEntry(
    text: "  想到一个新点子  ",
    date: components.date!,
    location: "上海市 徐汇区",
    timeZone: components.timeZone!
)
let expectedEntry = "## 2026年9月4日 15:20\n\n📍 **地点：** 上海市 徐汇区\n\n想到一个新点子\n\n---\n\n"
require(formatted == expectedEntry, "记录格式不正确")

let fileURL = FileManager.default.temporaryDirectory
    .appendingPathComponent(UUID().uuidString)
    .appendingPathExtension("md")
defer { try? FileManager.default.removeItem(at: fileURL) }

do {
    try Data("旧内容".utf8).write(to: fileURL)
    try EntryWriter.append(
        text: "新闪念",
        date: components.date!,
        location: "上海市 徐汇区",
        timeZone: components.timeZone!,
        to: fileURL
    )
    let result = try String(contentsOf: fileURL, encoding: .utf8)
    require(result == "旧内容\n" + expectedEntry.replacingOccurrences(of: "想到一个新点子", with: "新闪念"), "追加内容或换行不正确")

    // 空白文档应自动带上统一标题，避免第一条记录没有文档说明。
    try Data().write(to: fileURL)
    try EntryWriter.append(
        text: "空文档里的第一条",
        date: components.date!,
        location: "上海市 徐汇区",
        timeZone: components.timeZone!,
        to: fileURL
    )
    let firstEntryResult = try String(contentsOf: fileURL, encoding: .utf8)
    require(firstEntryResult.hasPrefix(EntryWriter.documentHeader), "空文档没有自动写入标题")
    require(firstEntryResult.contains("正文。\n\n## 2026年"), "文档说明与第一条记录之间缺少空行")
    require(firstEntryResult.hasSuffix(expectedEntry.replacingOccurrences(of: "想到一个新点子", with: "空文档里的第一条")), "空文档第一条记录格式不正确")

    try EntryWriter.append(
        text: "第二条记录",
        date: components.date!,
        location: "上海市 徐汇区",
        timeZone: components.timeZone!,
        to: fileURL
    )
    let twoEntryResult = try String(contentsOf: fileURL, encoding: .utf8)
    require(twoEntryResult.contains("---\n\n## 2026年"), "两条记录之间缺少空行")
    print("全部检查通过：时间、地点、文字和追加写入均正确。")
} catch {
    FileHandle.standardError.write(Data("检查失败：\(error.localizedDescription)\n".utf8))
    exit(1)
}
