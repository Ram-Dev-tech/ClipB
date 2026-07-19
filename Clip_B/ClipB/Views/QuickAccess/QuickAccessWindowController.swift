import Cocoa
import SwiftUI

/// A custom NSPanel that can become key even when borderless and non-activating.
class QuickAccessPanel: NSPanel {
    override var canBecomeKey: Bool {
        return true
    }
    override var canBecomeMain: Bool {
        return true
    }
}

class QuickAccessWindowController: NSWindowController, NSWindowDelegate {
    
    static let shared = QuickAccessWindowController()
    
    private var isAnimating = false
    
    private init() {
        let panel = QuickAccessPanel(
            contentRect: NSRect(x: 0, y: 0, width: 750, height: 450),
            styleMask: [.borderless, .nonactivatingPanel, .resizable],
            backing: .buffered,
            defer: false
        )
        
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.center()
        panel.isMovableByWindowBackground = true
        panel.acceptsMouseMovedEvents = true
        panel.setFrameAutosaveName("QuickAccessPanel")
        
        super.init(window: panel)
        
        panel.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Sets the SwiftUI view to be hosted inside the panel.
    func setup<Content: View>(with rootView: Content) {
        guard let panel = self.window as? QuickAccessPanel else { return }
        
        let hostingView = NSHostingView(rootView: rootView)
        // Ensure the hosting view allows the background to be transparent
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        
        panel.contentView = hostingView
    }
    
    func toggle() {
        if window?.isVisible == true {
            hide()
        } else {
            show()
        }
    }
    
    func show() {
        guard let panel = self.window as? QuickAccessPanel, !isAnimating else { return }
        
        panel.alphaValue = 0.0
        panel.makeKeyAndOrderFront(nil)
        panel.center() // Ensure it's centered each time it appears
        
        NSApp.activate(ignoringOtherApps: true)
        
        isAnimating = true
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1.0
        }, completionHandler: {
            self.isAnimating = false
        })
    }
    
    func hide() {
        guard let panel = self.window as? QuickAccessPanel, !isAnimating, panel.isVisible else { return }
        
        isAnimating = true
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().alphaValue = 0.0
        }, completionHandler: {
            panel.orderOut(nil)
            self.isAnimating = false
        })
    }
    
    // MARK: - NSWindowDelegate
    
    func windowDidResignKey(_ notification: Notification) {
        // Auto-hide when focus is lost
        hide()
    }
}
