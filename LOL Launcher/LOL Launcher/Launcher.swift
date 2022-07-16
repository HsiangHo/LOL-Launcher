import Cocoa

struct LOLLauncher {
    enum Locale: String {
        case ja = "ja_JP"
        case ko = "ko_KR"
        case zh_hans = "zh_CN"
        case zh_hant = "zh_TW"
        case es = "es_ES"
        case es_419 = "es_MX"
        case en = "en_US"
        case fr = "fr_FR"
        case de = "de_DE"
        case it = "it_IT"
        case pl = "pl_PL"
        case ro = "ro_RO"
        case el = "el_GR"
        case pt = "pt_BR"
        case hu = "hu_HU"
        case ru = "ru_RU"
        case tr = "tr_TR"
        
        var localized: String {
            var rslt = "English"
            switch self {
            case .ja:
                rslt = "日本語"
                break
            case .ko:
                rslt = "한국어"
                break
            case .zh_hans:
                rslt = "简体中文"
                break
            case .zh_hant:
                rslt = "繁體中文"
                break
            case .es:
                rslt = "Español"
                break
            case .es_419:
                rslt = "Español(México)"
                break
            case .en:
                rslt = "English"
                break
            case .fr:
                rslt = "Français"
                break
            case .de:
                rslt = "Deutsch"
                break
            case .it:
                rslt = "Italiano"
                break
            case .pl:
                rslt = "Poski"
                break
            case .ro:
                rslt = "Română"
                break
            case .el:
                rslt = "Ελληνικά"
                break
            case .pt:
                rslt = "Português"
                break
            case .hu:
                rslt = "Magyar"
                break
            case .ru:
                rslt = "Pу́сский язы́к"
                break
            case .tr:
                rslt = "Türkçe"
                break
            }
            return rslt
        }
    }
    
    static var allLanguages: [LOLLauncher.Locale] = [.ja, .ko, .zh_hans, .zh_hant, .es, .es_419, .en, .fr, .de, .it, .pl, .ro, .el, .pt, .hu, .ru, .tr]
    
    static func launch(_ language: LOLLauncher.Locale = .en) {
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.riotgames.leagueoflegends") {
//            let args = ["--args", "--locale=\(language.rawValue)"]
//            _ = try? NSWorkspace.shared.launchApplication(at: appURL, options: .default, configuration: [NSWorkspace.LaunchConfigurationKey.arguments: args])
            
            let cmd = "open \(appURL.path.replacingOccurrences(of: " ", with: "\\ ")) --args --locale=\(language.rawValue) &"
            TaskHandler.createTask(command: "/bin/sh", arguments: ["-c", cmd]) { _, _ in
            }
        }
    }
}
