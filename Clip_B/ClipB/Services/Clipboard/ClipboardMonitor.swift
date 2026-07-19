//
//  ClipboardMonitor.swift
//  ClipB
//
//  Created by ClipB on 2026-07-17.
//

import AppKit
import Combine

/// Monitors the macOS system clipboard for changes and creates
/// `ClipboardEntry` records.
///
/// The monitor polls `NSPasteboard.general.changeCount` at a fixed
/// interval (0.5 s). When a change is detected it reads the pasteboard,
/// determines the content type via `ContentDetector`, builds a
/// `ClipboardEntry`, and persists it through `DatabaseManager`.
///
/// Password-manager concealed types (`org.nspasteboard.ConcealedType`)
/// are automatically skipped to respect user privacy.
@MainActor
class ClipboardMonitor: ObservableObject {

    // MARK: - Published State

    /// The most recent entry created by the monitor.
    @Published var lastEntry: ClipboardEntry?

    /// Whether the monitor is currently polling the pasteboard.
    @Published var isMonitoring: Bool = false

    // MARK: - Private State

    /// Tracks the last-seen pasteboard change count to detect new copies.
    private var lastChangeCount: Int = 0

    /// Timer subscription driving the polling loop.
    private var timer: AnyCancellable?

    /// Pasteboard type indicating concealed (password-manager) content.
    private static let concealedType = NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType")

    // MARK: - Public API

    /// Begin polling the system pasteboard for changes.
    ///
    /// Calling this when already monitoring is a no-op.
    func startMonitoring() {
        guard !isMonitoring else { return }

        // Seed the change count so we don't re-process the current
        // pasteboard contents on launch.
        lastChangeCount = NSPasteboard.general.changeCount

        isMonitoring = true

        timer = Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkClipboard()
            }
    }

    /// Stop polling the system pasteboard.
    func stopMonitoring() {
        timer?.cancel()
        timer = nil
        isMonitoring = false
    }

    // MARK: - Private Helpers

    /// Compare the current change count to the last-seen value.
    /// If they differ, new content is available.
    private func checkClipboard() {
        let pasteboard = NSPasteboard.general
        let currentCount = pasteboard.changeCount

        guard currentCount != lastChangeCount else { return }
        lastChangeCount = currentCount

        // Skip concealed (password-manager) content.
        if let types = pasteboard.types, types.contains(Self.concealedType) {
            return
        }

        processClipboardContent()
    }

    /// Read the pasteboard, detect the content type, build an entry,
    /// and persist it.
    private func processClipboardContent() {
        let pasteboard = NSPasteboard.general
        guard let types = pasteboard.types else { return }

        let sourceApp = detectSourceApp()
        var entry: ClipboardEntry?

        // ── URL ──
        if types.contains(.URL),
           let urlString = pasteboard.string(forType: .URL) ?? pasteboard.string(forType: .string),
           URL(string: urlString) != nil
        {
            let preview = String(urlString.prefix(200))
            let tags = ContentDetector.generateBasicTags(from: urlString, type: .url)
            entry = ClipboardEntry(
                contentType: .url,
                textContent: urlString,
                preview: preview,
                tags: encodeTags(tags),
                sourceApp: sourceApp
            )
        }

        // ── Rich Text (RTF / RTFD) ──
        if entry == nil,
           types.contains(.rtf) || types.contains(.rtfd),
           let rtfData = pasteboard.data(forType: .rtf) ?? pasteboard.data(forType: .rtfd)
        {
            let attributedString = NSAttributedString(rtf: rtfData, documentAttributes: nil)
            let plainText = attributedString?.string ?? ""
            let preview = String(plainText.prefix(200))
            let detectedType: ContentType = ContentDetector.detectType(from: plainText) == .code ? .code : .richText
            let tags = ContentDetector.generateBasicTags(from: plainText, type: detectedType)
            entry = ClipboardEntry(
                contentType: detectedType,
                textContent: plainText,
                preview: preview,
                tags: encodeTags(tags),
                sourceApp: sourceApp
            )
        }

        // ── File URLs ──
        if entry == nil,
           types.contains(.fileURL),
           let urlString = pasteboard.string(forType: .fileURL),
           let fileURL = URL(string: urlString)
        {
            let fileName = fileURL.lastPathComponent
            let ext = fileURL.pathExtension.lowercased()
            let contentType: ContentType = ext == "pdf" ? .pdf : .file
            let preview = fileName
            let tags = ContentDetector.generateBasicTags(from: fileName, type: contentType)
            entry = ClipboardEntry(
                contentType: contentType,
                textContent: fileURL.absoluteString,
                preview: preview,
                tags: encodeTags(tags),
                sourceApp: sourceApp
            )
        }

        // ── Images (TIFF / PNG) ──
        if entry == nil,
           types.contains(.tiff) || types.contains(.png)
        {
            let imageData = pasteboard.data(forType: .tiff) ?? pasteboard.data(forType: .png)
            if let data = imageData {
                let isScreenshot = sourceApp?.lowercased().contains("screenshot") == true
                let contentType: ContentType = isScreenshot ? .screenshot : .image
                let tags = ContentDetector.generateBasicTags(from: "", type: contentType)
                entry = ClipboardEntry(
                    contentType: contentType,
                    imageData: data,
                    preview: contentType == .screenshot ? "Screenshot" : "Image",
                    tags: encodeTags(tags),
                    sourceApp: sourceApp
                )
            }
        }

        // ── Plain Text (fallback) ──
        if entry == nil,
           types.contains(.string),
           let text = pasteboard.string(forType: .string),
           !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
            let detectedType = ContentDetector.detectType(from: text)
            let preview = String(text.prefix(200))
            let tags = ContentDetector.generateBasicTags(from: text, type: detectedType)
            entry = ClipboardEntry(
                contentType: detectedType,
                textContent: text,
                preview: preview,
                tags: encodeTags(tags),
                sourceApp: sourceApp
            )
        }

        // ── Generate Semantic Embedding ──
        if var entryWithEmbedding = entry, let text = entryWithEmbedding.textContent {
            if let vector = SemanticSearchService.shared.generateEmbedding(for: text) {
                entryWithEmbedding.embedding = SemanticSearchService.shared.encode(vector: vector)
            }
            entry = entryWithEmbedding
        }

        // ── Persist ──
        guard let newEntry = entry else { return }

        do {
            try DatabaseManager.shared.insertEntry(newEntry)
            self.lastEntry = newEntry
            
            // ── AI Processing Background Task ──
            // If AI is enabled, spawn a background task to process the entry
            if UserDefaults.standard.bool(forKey: "aiEnabled") {
                Task.detached {
                    if let updatedEntry = await AIService.shared.process(entry: newEntry) {
                        do {
                            try await MainActor.run {
                                try DatabaseManager.shared.updateEntry(updatedEntry)
                            }
                        } catch {
                            print("[ClipboardMonitor] Failed to update AI processed entry: \(error)")
                        }
                    }
                }
            }
        } catch {
            // In production this would route to a logging subsystem.
            print("[ClipboardMonitor] Failed to save entry: \(error)")
        }
    }

    /// Detect the name of the frontmost application (the likely source
    /// of the copy operation).
    ///
    /// - Returns: The localized app name, or `nil` if unavailable.
    private func detectSourceApp() -> String? {
        NSWorkspace.shared.frontmostApplication?.localizedName
    }

    // MARK: - Utility

    /// Encode a `[String]` to a JSON string for storage in the `tags` column.
    private func encodeTags(_ tags: [String]) -> String? {
        guard !tags.isEmpty else { return nil }
        guard let data = try? JSONEncoder().encode(tags) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
