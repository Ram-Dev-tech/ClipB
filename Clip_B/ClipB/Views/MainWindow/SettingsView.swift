//
//  SettingsView.swift
//  ClipB
//
//  Created by ClipB Team on 2026-07-17.
//  Copyright © 2026 ClipB. All rights reserved.
//

import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
    @EnvironmentObject var viewModel: SettingsViewModel
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        TabView(selection: $viewModel.selectedSettingsTab) {
            generalTab()
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
                .tag(SettingsViewModel.SettingsTab.general)
            
            appearanceTab()
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush")
                }
                .tag(SettingsViewModel.SettingsTab.appearance)
            
            aiTab()
                .tabItem {
                    Label("AI Support", systemImage: "brain")
                }
                .tag(SettingsViewModel.SettingsTab.ai)
            
            clipboardTab()
                .tabItem {
                    Label("Clipboard", systemImage: "clipboard")
                }
                .tag(SettingsViewModel.SettingsTab.clipboard)
            
            shortcutsTab()
                .tabItem {
                    Label("Shortcuts", systemImage: "keyboard")
                }
                .tag(SettingsViewModel.SettingsTab.shortcuts)
            
            privacyTab()
                .tabItem {
                    Label("Privacy", systemImage: "hand.raised")
                }
                .tag(SettingsViewModel.SettingsTab.privacy)
            
            databaseTab()
                .tabItem {
                    Label("Database", systemImage: "externaldrive")
                }
                .tag(SettingsViewModel.SettingsTab.database)
            
            aboutTab()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
                .tag(SettingsViewModel.SettingsTab.about)
        }
        .padding(DesignTokens.spacingXL)
        .frame(width: 620, height: 520)
    }
    
    // MARK: - Tab Panes
    
    @ViewBuilder
    private func generalTab() -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacingL) {
            Text("General Preferences")
                .font(.title2)
                .fontWeight(.bold)
            
            Form {
                Toggle("Launch ClipB at login", isOn: $viewModel.launchAtStartup)
                Toggle("Automatically check for updates", isOn: $viewModel.autoUpdateEnabled)
                Toggle("Show system notifications on copy", isOn: $viewModel.showNotifications)
            }
            Spacer()
        }
    }
    
    @ViewBuilder
    private func appearanceTab() -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacingL) {
            Text("Appearance Settings")
                .font(.title2)
                .fontWeight(.bold)
            
            Form {
                Picker("Theme Mode", selection: $viewModel.selectedTheme) {
                    Text("System Default").tag("system")
                    Text("Force Light").tag("light")
                    Text("Force Dark").tag("dark")
                }
                .pickerStyle(.radioGroup)
                .onChange(of: viewModel.selectedTheme) { _, newValue in
                    if newValue == "dark" {
                        appState.isDarkMode = true
                    } else if newValue == "light" {
                        appState.isDarkMode = false
                    } else {
                        appState.isDarkMode = NSApp?.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                    }
                }
            }
            Spacer()
        }
    }
    
    @ViewBuilder
    private func aiTab() -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.spacingL) {
                // Header
                HStack(spacing: DesignTokens.spacingM) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 28))
                        .foregroundStyle(
                            .linearGradient(
                                colors: [Color.clipBGradientStart, Color.clipBGradientEnd],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    VStack(alignment: .leading, spacing: 2) {
                        Text("AI Configuration")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("AI is optional. ClipB works fully offline with smart local categorization.")
                            .font(.caption)
                            .foregroundColor(.clipBTextSecondary)
                    }
                }
                
                Divider()
                
                // Offline capabilities (always visible)
                GroupBox {
                    VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
                        Label("Built-in Offline Features (always active, no AI needed)", systemImage: "checkmark.seal.fill")
                            .font(.headline)
                            .foregroundColor(.green)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            offlineFeatureRow(icon: "envelope.fill", label: "Email detection", color: .blue)
                            offlineFeatureRow(icon: "phone.fill", label: "Phone number detection", color: .green)
                            offlineFeatureRow(icon: "link", label: "URL & website link detection", color: .orange)
                            offlineFeatureRow(icon: "chevron.left.forwardslash.chevron.right", label: "Code snippet detection (20+ languages)", color: .purple)
                            offlineFeatureRow(icon: "paintpalette.fill", label: "Color value detection (Hex, RGB, HSL)", color: .pink)
                            offlineFeatureRow(icon: "doc.richtext", label: "Markdown & rich text detection", color: .teal)
                            offlineFeatureRow(icon: "tag.fill", label: "Auto-tagging & smart categorization", color: .indigo)
                            offlineFeatureRow(icon: "photo.fill", label: "Image & screenshot capture", color: .cyan)
                            offlineFeatureRow(icon: "magnifyingglass", label: "Full-text search (FTS5)", color: .yellow)
                        }
                        .padding(.leading, 4)
                    }
                    .padding(.vertical, DesignTokens.spacingS)
                }
                
                Divider()
                
                // AI master toggle
                GroupBox {
                    VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                        Toggle(isOn: $viewModel.aiEnabled) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Enable AI Features")
                                    .font(.body)
                                    .fontWeight(.semibold)
                                Text("Connect to an AI provider for advanced features like summarization, translation, grammar correction, and smart explanations.")
                                    .font(.caption)
                                    .foregroundColor(.clipBTextSecondary)
                            }
                        }
                        .toggleStyle(.switch)
                        
                        if !viewModel.aiEnabled {
                            Label("AI is disabled. ClipB runs completely offline using local detection only.", systemImage: "wifi.slash")
                                .font(.caption)
                                .foregroundColor(.clipBTextSecondary)
                        }
                    }
                    .padding(.vertical, DesignTokens.spacingS)
                }
                
                // AI configuration (only shown when enabled)
                if viewModel.aiEnabled {
                    // Provider Selection
                    GroupBox("Provider") {
                        VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                            Picker("AI Provider", selection: $viewModel.aiProvider) {
                                Text("OpenRouter").tag("openrouter")
                                Text("OpenAI").tag("openai")
                                Text("Anthropic").tag("anthropic")
                                Text("Google Gemini").tag("gemini")
                                Text("Ollama (Local)").tag("ollama")
                            }
                            .pickerStyle(.radioGroup)
                            
                            if viewModel.aiProvider == "ollama" {
                                Label("Ollama runs entirely on your Mac — no API key required.", systemImage: "checkmark.shield.fill")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                        .padding(.vertical, DesignTokens.spacingS)
                    }
                    
                    // Credentials
                    if viewModel.aiProvider != "ollama" {
                        GroupBox("Credentials") {
                            VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                                HStack {
                                    Text("API Key")
                                        .frame(width: 80, alignment: .trailing)
                                    SecureField("sk-... or your provider key", text: $viewModel.aiApiKey)
                                        .textFieldStyle(.roundedBorder)
                                }
                                
                                HStack {
                                    Text("Endpoint")
                                        .frame(width: 80, alignment: .trailing)
                                    TextField("Custom endpoint URL (optional)", text: $viewModel.aiEndpoint)
                                        .textFieldStyle(.roundedBorder)
                                }
                                
                                Text("Leave endpoint empty to use the provider's default URL.")
                                    .font(.caption)
                                    .foregroundColor(.clipBTextSecondary)
                            }
                            .padding(.vertical, DesignTokens.spacingS)
                        }
                    }
                    
                    // Model & Parameters
                    GroupBox("Model") {
                        VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                            HStack {
                                Text("Model ID")
                                    .frame(width: 80, alignment: .trailing)
                                TextField(modelPlaceholder, text: $viewModel.aiModelName)
                                    .textFieldStyle(.roundedBorder)
                            }
                            
                            VStack(alignment: .leading) {
                                Text("Temperature: \(String(format: "%.2f", viewModel.aiTemperature))")
                                Slider(value: $viewModel.aiTemperature, in: 0.0...2.0, step: 0.05)
                                Text("Lower = deterministic. Higher = creative.")
                                    .font(.caption)
                                    .foregroundColor(.clipBTextSecondary)
                            }
                        }
                        .padding(.vertical, DesignTokens.spacingS)
                    }
                    
                    // Auto AI features
                    GroupBox("Automatic AI Features") {
                        VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
                            Toggle("AI-powered summarization for long entries", isOn: $viewModel.aiAutoSummarize)
                            Toggle("AI-powered smart tagging (on top of local detection)", isOn: $viewModel.aiAutoTag)
                            Toggle("AI-generated titles for code snippets", isOn: $viewModel.aiAutoTitle)
                            Toggle("AI-powered OCR text extraction for images", isOn: $viewModel.aiAutoOCR)
                        }
                        .padding(.vertical, DesignTokens.spacingS)
                    }
                }
            }
            .padding(.bottom, DesignTokens.spacingM)
        }
    }
    
    /// A row showing one offline capability.
    @ViewBuilder
    private func offlineFeatureRow(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(color)
                .frame(width: 16, alignment: .center)
            Text(label)
                .font(.callout)
        }
    }
    
    /// Provider-specific placeholder for the model text field.
    private var modelPlaceholder: String {
        switch viewModel.aiProvider {
        case "openai":     return "gpt-4o"
        case "anthropic":  return "claude-sonnet-4-20250514"
        case "gemini":     return "gemini-2.5-flash"
        case "ollama":     return "llama3"
        default:           return "openrouter/auto"
        }
    }
    
    @ViewBuilder
    private func clipboardTab() -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacingL) {
            Text("Clipboard Settings")
                .font(.title2)
                .fontWeight(.bold)
            
            Form {
                VStack(alignment: .leading) {
                    Text("Clipboard history limit: \(viewModel.historyLimit) items")
                    Slider(value: Binding(
                        get: { Double(viewModel.historyLimit) },
                        set: { viewModel.historyLimit = Int($0) }
                    ), in: 100...50000, step: 100)
                }
                
                VStack(alignment: .leading) {
                    Text("Polling interval: \(String(format: "%.1f", viewModel.pollingInterval))s")
                    Slider(value: $viewModel.pollingInterval, in: 0.1...2.0, step: 0.1)
                }
                
                VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
                    Text("Quick Access 'Recent' filters by:")
                    Picker("", selection: $viewModel.quickAccessRecentPeriod) {
                        Text("Today").tag("today")
                        Text("Last 7 Days").tag("week")
                        Text("All Time").tag("all")
                    }
                    .pickerStyle(.segmented)
                }
            }
            Spacer()
        }
    }
    
    @ViewBuilder
    private func shortcutsTab() -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacingL) {
            // Header
            HStack(spacing: DesignTokens.spacingM) {
                Image(systemName: "keyboard")
                    .font(.system(size: 28))
                    .foregroundColor(.clipBPrimary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Keyboard Shortcuts")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Customize global hotkeys to control ClipB from anywhere on your Mac.")
                        .font(.caption)
                        .foregroundColor(.clipBTextSecondary)
                }
            }
            
            Divider()
            
            // Shortcut Recorders
            VStack(spacing: 0) {
                shortcutRow(
                    icon: "macwindow",
                    label: "Open ClipB Window",
                    description: "Bring the main ClipB dashboard to the front.",
                    name: .togglePanel
                )
                Divider().padding(.leading, 40)
                shortcutRow(
                    icon: "magnifyingglass",
                    label: "Quick Search",
                    description: "Instantly open the search bar.",
                    name: .quickSearch
                )
                Divider().padding(.leading, 40)
                shortcutRow(
                    icon: "bolt.fill",
                    label: "Quick Access Overlay",
                    description: "Open the floating quick access overlay from anywhere.",
                    name: .toggleQuickAccess
                )
                Divider().padding(.leading, 40)
                shortcutRow(
                    icon: "doc.on.clipboard",
                    label: "Quick Paste",
                    description: "Paste the most recently copied item.",
                    name: .quickPaste
                )
                Divider().padding(.leading, 40)
                shortcutRow(
                    icon: "gearshape",
                    label: "Open Settings",
                    description: "Jump directly to the Settings view.",
                    name: .openSettings
                )
                Divider().padding(.leading, 40)
                shortcutRow(
                    icon: "brain",
                    label: "Open AI Assistant",
                    description: "Jump directly to the AI Assistant view.",
                    name: .openAI
                )
            }
            .background(Color.clipBSurfaceElevated.opacity(0.5))
            .cornerRadius(DesignTokens.cornerRadiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusMedium)
                    .stroke(Color.clipBBorder, lineWidth: 1)
            )
            
            Spacer()
            
            // Reset button
            HStack {
                Spacer()
                Button("Reset All Shortcuts to Defaults") {
                    KeyboardShortcuts.reset(.togglePanel, .quickSearch, .toggleQuickAccess, .quickPaste, .openSettings, .openAI)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }
    
    /// A styled row for a single keyboard shortcut recorder.
    @ViewBuilder
    private func shortcutRow(icon: String, label: String, description: String, name: KeyboardShortcuts.Name) -> some View {
        HStack(spacing: DesignTokens.spacingM) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.clipBPrimary)
                .frame(width: 24, alignment: .center)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.body)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.clipBTextSecondary)
            }
            
            Spacer()
            
            KeyboardShortcuts.Recorder(for: name)
                .fixedSize()
        }
        .padding(.horizontal, DesignTokens.spacingM)
        .padding(.vertical, 10)
    }
    
    @ViewBuilder
    private func privacyTab() -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacingL) {
            Text("Privacy Settings")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("ClipB is designed to be completely offline by default. Your data is processed locally on your device and will never be sent to any external server without your explicit permission, ensuring maximum privacy and security.")
                .font(.body)
                .foregroundColor(.clipBTextSecondary)
                .padding(.bottom, DesignTokens.spacingM)
            
            Form {
                Toggle("Ignore sensitive types from password managers", isOn: $viewModel.excludePasswordManagers)
            }
            
            Spacer()
            
            Button("Clear All Clipboard History", role: .destructive) {
                // Confirm clear
                let alert = NSAlert()
                alert.messageText = "Clear Clipboard History?"
                alert.informativeText = "This action is permanent and cannot be undone. All entries will be deleted."
                alert.addButton(withTitle: "Clear")
                alert.addButton(withTitle: "Cancel")
                alert.alertStyle = .critical
                
                if alert.runModal() == .alertFirstButtonReturn {
                    NotificationCenter.default.post(name: .clipBClearAllHistory, object: nil)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
    }
    
    @ViewBuilder
    private func databaseTab() -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacingL) {
            Text("Database & Maintenance")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
                Text("Storage Size: \(viewModel.getDatabaseSize())")
                    .fontWeight(.medium)
                
                HStack(spacing: DesignTokens.spacingM) {
                    Button("Export Database...") {
                        viewModel.exportDatabase()
                    }
                    
                    Button("Import Backup...") {
                        viewModel.importDatabase()
                    }
                }
            }
            Spacer()
        }
    }
    
    @ViewBuilder
    private func aboutTab() -> some View {
        VStack(spacing: DesignTokens.spacingM) {
            Spacer()
            
            Image(systemName: "clipboard.fill")
                .font(.system(size: 64))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.clipBGradientStart, Color.clipBGradientEnd],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("ClipB")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Version 1.0.0 (Build 1)")
                .font(.system(size: 11))
                .foregroundColor(.clipBTextSecondary)
            
            Text("The smartest clipboard you'll ever use.")
                .font(.subheadline)
                .foregroundColor(.clipBTextSecondary)
            
            Text("Copyright © 2026 ClipB Team. All rights reserved.")
                .font(.system(size: 9))
                .foregroundColor(.clipBTextSecondary)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let clipBClearAllHistory = Notification.Name("clipBClearAllHistory")
}
