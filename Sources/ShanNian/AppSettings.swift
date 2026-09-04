import Foundation

/// 记住用户选过的 Markdown 文档，下次打开软件时无需重复选择。
@MainActor
final class AppSettings: ObservableObject {
    @Published private(set) var documentURL: URL?
    private let pathKey = "markdownDocumentPath"

    init() {
        if let savedPath = UserDefaults.standard.string(forKey: pathKey) {
            documentURL = URL(fileURLWithPath: savedPath)
        }
    }

    func remember(document url: URL) {
        documentURL = url
        UserDefaults.standard.set(url.path, forKey: pathKey)
    }
}
