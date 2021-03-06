import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet var window: NSWindow!
    @IBOutlet var btnLanguages: NSPopUpButton!
    @IBOutlet var btnLaunch: NSButton!
    @IBOutlet var lbLaunching: NSTextField!
    @IBOutlet var piLaunching: NSProgressIndicator!
    
    private var selectedItem: LOLLauncher.Locale = LOLLauncher.Locale(rawValue: (UserDefaults.standard.string(forKey: "user-selected") ?? "")) ?? .en {
        didSet {
            UserDefaults.standard.set(selectedItem.rawValue, forKey: "user-selected")
        }
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        let languageMenu = generateLocaleMenu()
        btnLanguages.menu = languageMenu
        btnLanguages.selectItem(withTag: selectedItem.hashValue)
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.isMovableByWindowBackground = true
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    func generateLocaleMenu() -> NSMenu {
        let menu = NSMenu(title: "languages")
        
        LOLLauncher.allLanguages.forEach {
            let item = menu.addItem(withTitle: $0.localized, action: #selector(localeItem_click(_:)), keyEquivalent: "")
            item.target = self
            item.tag = $0.hashValue
            item.representedObject = $0
        }
        return menu
    }
}

extension AppDelegate {
    @IBAction func localeItem_click(_ sender: Any?) {
        if let item = sender as? NSMenuItem, let locale = item.representedObject as? LOLLauncher.Locale {
            selectedItem = locale
        }
    }
    
    @IBAction func launch_click(_ sender: Any?) {
        btnLaunch.isHidden = true
        lbLaunching.isHidden = false
        piLaunching.isHidden = false
        piLaunching.startAnimation(nil)
        LOLLauncher.launch(selectedItem)
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            self.window.orderOut(nil)
        }
    }
}
