<div align="center">
  
# 📋 ClipB
**The Smartest Native Clipboard Manager for macOS**

ClipB remembers everything you copy so you don't have to. It automatically organizes your text, images, and links, allowing you to instantly find and paste them anywhere using lightning-fast global shortcuts and a beautiful macOS-native interface.

</div>

---

## 📦 Easy Install (Recommended)
The easiest way to install ClipB is to download the pre-packaged application:
1. Go to the [Releases page](https://github.com/Ram-Dev-tech/ClipB/tree/main/Clip_B/dist) on GitHub.
3. Download the latest `ClipB.dmg` file.
4. Double-click the `.dmg` file to open it.
5. Drag the **ClipB** app icon into your Applications folder!
---


## 🚀 Quick Start (Terminal Download)

Want to try ClipB right now? Just open your **Terminal** app and run these three commands to download and launch the app immediately:

```bash
# 1. Download the app from GitHub
git clone https://github.com/Ram-Dev-tech/ClipB.git

# 2. Go into the folder
cd ClipB

# 3. Build and launch the app!
swift build && .build/arm64-apple-macosx/debug/ClipB
```

*(Note: If you don't have Xcode Command Line Tools installed, your Mac will prompt you to install them first.)*

---
<img width="1512" height="908" alt="image" src="https://github.com/user-attachments/assets/add479e6-dc52-40a4-9d2f-f6bcf1ccb396" />


**ShortCut** to Open -->> `⌘ + ⇧ + Space`

<img width="2204" height="1502" alt="image" src="https://github.com/user-attachments/assets/739d7a31-a0fd-4add-a76b-78f56c784886" />



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
