import AppKit
import ShanNianCore
import SwiftUI

/// 主界面：选择 Markdown 文档、输入闪念、按回车保存。
struct ContentView: View {
    @StateObject private var settings = AppSettings()
    @StateObject private var location = LocationService()
    @State private var thought = ""
    @State private var statusText = "写下一条闪念，然后按回车"
    @State private var statusIsError = false
    @FocusState private var inputIsFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("闪念")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    Text(documentDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Button(settings.documentURL == nil ? "选择文档" : "更换文档") {
                    chooseExistingDocument()
                }
                if settings.documentURL == nil {
                    Button("新建文档") {
                        createDocument()
                    }
                }
            }

            // 仍然是按回车保存，但长文字会自动换行，并最多增高到八行。
            TextField("此刻想到了什么？", text: $thought, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: 20))
                .lineLimit(1...6)
                .padding(14)
                .background(.background.opacity(0.75), in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(.quaternary, lineWidth: 1))
                .focused($inputIsFocused)
                .onSubmit(saveThought)

            HStack(spacing: 7) {
                Image(systemName: statusIsError ? "exclamationmark.circle.fill" : "location.fill")
                Text(statusText)
                Spacer()
                Text(location.placeName)
            }
            .font(.callout)
            .foregroundStyle(statusIsError ? Color.red : Color.secondary)
        }
        .padding(28)
        .background(
            LinearGradient(
                colors: [Color(nsColor: .windowBackgroundColor), Color.accentColor.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .onAppear {
            location.begin()
            focusInputAfterWindowIsReady()
            if settings.documentURL == nil {
                statusText = "请先选择已有文档，或新建一个文档"
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            // 每次重新打开或切回软件，都可以直接继续输入。
            focusInputAfterWindowIsReady()
        }
    }

    private var documentDescription: String {
        settings.documentURL?.path ?? "尚未设置保存位置"
    }

    private func saveThought() {
        let cleanText = thought.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanText.isEmpty else { return }
        guard let url = settings.documentURL else {
            statusIsError = true
            statusText = "请先选择或新建 Markdown 文档"
            return
        }

        do {
            try EntryWriter.append(text: cleanText, location: location.placeName, to: url)
            thought = ""
            statusIsError = false
            statusText = "已保存 · \(Date().formatted(date: .omitted, time: .shortened))"
        } catch {
            statusIsError = true
            statusText = "保存失败：\(error.localizedDescription)"
        }
    }

    private func chooseExistingDocument() {
        let panel = NSOpenPanel()
        panel.title = "选择闪念 Markdown 文档"
        panel.allowedContentTypes = [.init(filenameExtension: "md")!]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url {
            settings.remember(document: url)
            statusIsError = false
            statusText = "文档已选好，可以开始记录"
            focusInputAfterWindowIsReady()
        }
    }

    private func createDocument() {
        let panel = NSSavePanel()
        panel.title = "新建闪念 Markdown 文档"
        panel.nameFieldStringValue = "我的闪念.md"
        // Markdown 本质上是普通文本。使用系统文本类型，可避免某些 Mac
        // 没有登记 Markdown 类型时，“保存”按钮无法点击。
        panel.allowedContentTypes = [.plainText]
        panel.isExtensionHidden = false
        panel.canCreateDirectories = true
        if panel.runModal() == .OK, let url = panel.url {
            do {
                try Data(EntryWriter.documentHeader.utf8).write(to: url)
                settings.remember(document: url)
                statusIsError = false
                statusText = "新文档已建好，可以开始记录"
                focusInputAfterWindowIsReady()
            } catch {
                statusIsError = true
                statusText = "新建失败：\(error.localizedDescription)"
            }
        }
    }

    /// 窗口真正成为活动窗口后，再把键盘输入交给文本框。
    /// 如果立即设置，macOS 仍在创建窗口，会把这次焦点请求忽略掉。
    private func focusInputAfterWindowIsReady() {
        inputIsFocused = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            inputIsFocused = true
        }
    }
}
