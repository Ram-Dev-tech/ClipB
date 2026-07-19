<div align="center">
  
# 📋 ClipB
**The Smartest Native Clipboard Manager for macOS**

ClipB remembers everything you copy so you don't have to. It automatically organizes your text, images, and links, allowing you to instantly find and paste them anywhere using lightning-fast global shortcuts and a beautiful macOS-native interface.

</div>

---

## 🚀 Quick Start (Terminal Download)

Want to try ClipB right now? Just open your **Terminal** app and run these three commands to download and launch the app immediately:

```bash
# 1. Download the app from GitHub
git clone https://github.com/your-username/ClipB.git

# 2. Go into the folder
cd ClipB

# 3. Build and launch the app!
swift build && .build/arm64-apple-macosx/debug/ClipB
```

*(Note: If you don't have Xcode Command Line Tools installed, your Mac will prompt you to install them first.)*

---

## ✨ Features You'll Love

* **Never Lose a Copy:** Automatically saves your history (text, images, links, colors, and files).
* **Quick Access Overlay:** Press `⌘ + ⇧ + V` to instantly summon a Spotlight-like floating window to search and paste your history anywhere.
* **Auto-Select & Paste:** Hover your mouse over items to instantly select them. Hit `Enter` to auto-paste!
* **Smart Organization:** Automatically sorts your clips into Images, Links, Text, and Code.
* **Pin & Favorite:** Keep your most important snippets permanently pinned to the top.

---

## 🔒 Privacy First (100% Offline)

Your privacy is our absolute priority. **ClipB runs entirely offline directly on your Mac.** Your clipboard history, images, and personal data are stored locally in a secure database on your hard drive and will **never** be sent to any external servers or leave your device. 

*(ClipB also automatically ignores password managers to keep your sensitive data safe).*

---

## ⌨️ Global Shortcuts

ClipB stays hidden in the background until you need it. You can customize all of these in the app's Settings!

| Shortcut | What it does |
| :--- | :--- |
| `⌘ + ⇧ + V` | **Open Quick Access Overlay** (Search & Paste) |
| `⌘ + ⌥ + V` | **Quick Paste Latest** (Paste your most recent clip) |
| `Up/Down Arrows` | **Navigate** through your clipboard history |
| `Enter` | **Paste** the selected item instantly |

---

## 🛠 For Developers

Want to build a proper `.app` bundle you can put in your Applications folder? We've included a script for you:

```bash
# Make the build script executable
chmod +x Scripts/build.sh

# Run the builder
./Scripts/build.sh

# The app will open automatically! Drag build/ClipB.app to your Applications folder.
```

**Tech Stack:** Built with Swift 6, SwiftUI, GRDB (SQLite), and AppKit. Requires macOS Sonoma 14.0+.

---
*Copyright © 2026 ClipB Team. All rights reserved.*
