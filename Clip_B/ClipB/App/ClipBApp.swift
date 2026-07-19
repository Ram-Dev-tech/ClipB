import SwiftUI
import KeyboardShortcuts

// MARK: - App Entry Point

@main
struct ClipBApp: App {
    @StateObject private var appState: AppState
    @StateObject private var clipboardViewModel: ClipboardViewModel
    @StateObject private var collectionsViewModel: CollectionsViewModel
    @StateObject private var settingsViewModel: SettingsViewModel
    @StateObject private var statisticsViewModel: StatisticsViewModel

    @Environment(\.openWindow) private var openWindow

    init() {
        // Initialize database on launch
        do {
            try DatabaseManager.shared.initialize()
        } catch {
            fatalError("[ClipB] Failed to initialize database: \(error)")
        }

        // Initialize view models AFTER database is ready
        _appState = StateObject(wrappedValue: AppState())
        _clipboardViewModel = StateObject(wrappedValue: ClipboardViewModel())
        _collectionsViewModel = StateObject(wrappedValue: CollectionsViewModel())
        _settingsViewModel = StateObject(wrappedValue: SettingsViewModel())
        _statisticsViewModel = StateObject(wrappedValue: StatisticsViewModel())

        // Register global keyboard shortcuts
        ShortcutManager.registerDefaults()
        
        // Setup Quick Access Window
        DispatchQueue.main.async {
            QuickAccessWindowController.shared.setup(with: QuickAccessView())
        }
    }

    var body: some Scene {
        // MARK: Menu Bar
        MenuBarExtra {
            MenuBarView()
                .environmentObject(appState)
                .environmentObject(clipboardViewModel)
                .onAppear {
                    clipboardViewModel.startMonitoring()
                }
                .onReceive(NotificationCenter.default.publisher(for: .clipBToggleQuickAccess)) { _ in
                    QuickAccessWindowController.shared.toggle()
                }
        } label: {
            Label("ClipB", systemImage: "clipboard.fill")
        }
        .menuBarExtraStyle(.window)

        // MARK: Main Dashboard Window
        Window("ClipB", id: "main") {
            MainContentView()
                .environmentObject(appState)
                .environmentObject(clipboardViewModel)
                .environmentObject(collectionsViewModel)
                .environmentObject(settingsViewModel)
                .environmentObject(statisticsViewModel)
                .frame(minWidth: 900, minHeight: 600)
                .onAppear {
                    clipboardViewModel.startMonitoring()
                }
                // Listen for shortcut notifications to navigate
                .onReceive(NotificationCenter.default.publisher(for: .clipBToggleMainWindow)) { _ in
                    appState.openMainWindow()
                    openWindow(id: "main")
                }
                .onReceive(NotificationCenter.default.publisher(for: .clipBActivateSearch)) { _ in
                    appState.openMainWindow()
                    openWindow(id: "main")
                    appState.activateSearch()
                }
                .onReceive(NotificationCenter.default.publisher(for: .clipBOpenSettings)) { _ in
                    appState.openMainWindow()
                    openWindow(id: "main")
                    appState.selectedSidebarItem = .settings
                }
                .onReceive(NotificationCenter.default.publisher(for: .clipBOpenAI)) { _ in
                    appState.openMainWindow()
                    openWindow(id: "main")
                    appState.selectedSidebarItem = .ai
                }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .defaultSize(width: 1100, height: 750)

        // MARK: Settings
        Settings {
            SettingsView()
                .environmentObject(settingsViewModel)
                .environmentObject(appState)
        }
    }
}
