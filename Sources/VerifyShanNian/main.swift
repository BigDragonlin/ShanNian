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
require(formatted == "- 2026年9月4日 15:20｜上海市 徐汇区｜想到一个新点子\n", "记录格式不正确")

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
    require(result == "旧内容\n- 2026年9月4日 15:20｜上海市 徐汇区｜新闪念\n", "追加内容或换行不正确")
    print("全部检查通过：时间、地点、文字和追加写入均正确。")
} catch {
    FileHandle.standardError.write(Data("检查失败：\(error.localizedDescription)\n".utf8))
    exit(1)
}
