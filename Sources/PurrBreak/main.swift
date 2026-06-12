import AppKit
import AVFoundation
import SwiftUI

private enum DefaultsKey {
    static let watchLimitMinutes = "watchLimitMinutes"
    static let shortsLimitMinutes = "shortsLimitMinutes"
    static let breakMinutes = "breakMinutes"
    static let soundEnabled = "soundEnabled"
    static let purrVolume = "purrVolume"
    static let screensaverThemeID = "screensaverThemeID"
    static let didShowBrowserSetup = "didShowBrowserSetup"
    static let languageCode = "languageCode"
    static let statsDate = "statsDate"
    static let dailyYouTubeSeconds = "dailyYouTubeSeconds"
    static let dailyBreakCount = "dailyBreakCount"
    static let dailySavedSeconds = "dailySavedSeconds"
}

private enum AppLanguage: String, CaseIterable, Identifiable, Equatable {
    case ru
    case en

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ru:
            return "Русский"
        case .en:
            return "English"
        }
    }

    var locale: Locale {
        switch self {
        case .ru:
            return Locale(identifier: "ru_RU")
        case .en:
            return Locale(identifier: "en_US")
        }
    }

    static var systemDefault: AppLanguage {
        let preferred = Locale.preferredLanguages.first?.lowercased() ?? ""
        return preferred.hasPrefix("ru") ? .ru : .en
    }

    static func matching(_ code: String?) -> AppLanguage {
        guard let code else {
            return systemDefault
        }

        guard let language = AppLanguage(rawValue: code) else {
            return systemDefault
        }

        return language
    }
}

private enum L10n {
    private static let ru: [String: String] = [
        "app.subtitle": "Мягкий тайм-аут для YouTube",
        "language": "Язык",
        "theme.sleep": "Рыжий сон",
        "theme.moon": "Лунная дрема",
        "theme.rain": "Дождливое окно",
        "theme.space": "Космический сон",
        "status.breakRemaining": "До конца паузы",
        "status.previewRemaining": "До конца теста",
        "status.untilBreak": "До заставки",
        "monitor.ready": "Готов следить за YouTube",
        "monitor.noBrowser": "Браузер не найден",
        "monitor.breakInProgress": "Идет пауза",
        "monitor.accessNeeded": "Нужен доступ Automation: %@",
        "monitor.unsupported": "%@ пока не поддерживается",
        "monitor.browserNotFront": "Браузер не на переднем плане",
        "monitor.waitingYouTube": "Жду активный YouTube",
        "monitor.youtubeActive": "YouTube активен",
        "monitor.shortsActive": "YouTube Shorts активны",
        "monitor.emptyTab": "Вкладка без адреса",
        "monitor.notYouTube": "Сейчас не YouTube",
        "browser.state.notInstalled": "Не найден",
        "browser.state.waiting": "Ожидает проверки",
        "browser.state.connected": "Подключен",
        "browser.state.needsPermission": "Нужен доступ",
        "browser.state.unsupported": "Пока не поддерживается",
        "browser.detail.notInstalled": "Приложение не найдено на этом Mac.",
        "browser.detail.waiting": "Открой YouTube в этом браузере, чтобы macOS запросила доступ.",
        "browser.detail.connected": "URL активной вкладки читается.",
        "browser.detail.unsupported": "Нужен отдельный способ отслеживания, например расширение.",
        "browser.detail.unsupportedSpecific": "%@ пока лучше подключать через расширение или отдельный fallback.",
        "browser.error.unsupported": "%@: пока не умею читать URL активной вкладки",
        "browser.error.noAccess": "%@: macOS пока не дала доступ к активной вкладке",
        "settings.youtubeActive": "YouTube идет",
        "settings.youtubeInactive": "YouTube не активен",
        "settings.watched": "Просмотрено",
        "settings.screensaver": "Заставка",
        "settings.limit": "Лимит YouTube",
        "settings.shortsLimit": "Лимит Shorts",
        "settings.breakLength": "Длина паузы",
        "settings.purrSound": "Мурчание во время паузы",
        "settings.purrVolume": "Громкость мурчания",
        "settings.minutes": "%d мин",
        "settings.testStop": "Остановить тест",
        "settings.test": "Тест заставки",
        "settings.startBreak": "Блокировка сейчас",
        "settings.resetCounter": "Сбросить счетчик",
        "settings.browserCheck": "Проверка браузеров",
        "settings.help": "Справка",
        "settings.quit": "Выйти",
        "stats.today": "Сегодня YouTube: %@ • Паузы: %d • Спасено: %@",
        "duration.hoursMinutes": "%dч %02dм",
        "duration.minutes": "%dм",
        "browserCheck.firstTitle": "Доступ к браузеру",
        "browserCheck.title": "Проверка браузеров",
        "browserCheck.subtitle": "Галочка появляется сама, когда PurrBreak успешно читает активную вкладку",
        "browserCheck.firstRun": "Первый запуск",
        "browserCheck.firstRunText": "Ничего заранее подключать не нужно. Открой YouTube в Chrome, Safari или Yandex Browser. Когда macOS спросит Automation, разреши доступ. Если запроса нет или ты случайно отказал, открой системные разрешения кнопкой ниже.",
        "browserCheck.openPermissions": "Открыть разрешения macOS",
        "browserCheck.openMainSettings": "Перейти к настройкам",
        "browserCheck.done": "Готово",
        "browserCheck.access": "Доступ к браузерам",
        "browserCheck.explainer": "Это не ручная настройка. Статус просто показывает, получилось ли у PurrBreak прочитать активную вкладку. Если галочка уже есть, делать ничего не нужно.",
        "browserCheck.hidden": "Неустановленные браузеры скрыты: %d.",
        "help.title": "Как работает PurrBreak",
        "help.subtitle": "Коротко о счетчике, паузах и разрешениях",
        "help.whatCounts.title": "Что считает приложение",
        "help.whatCounts.text": "PurrBreak каждую секунду смотрит, какой браузер сейчас активен, и читает URL активной вкладки. Счетчик идет только если активная вкладка открыта на youtube.com или youtu.be.",
        "help.whenBreak.title": "Когда появляется заставка",
        "help.whenBreak.text": "Когда накоплен лимит просмотра, приложение показывает полноэкранную паузу с выбранной заставкой. По умолчанию обычный YouTube ограничен 20 минутами, Shorts - 5 минутами, пауза длится 5 минут. После завершения паузы счетчик сбрасывается.",
        "help.automation.title": "Зачем нужен Automation",
        "help.automation.text": "macOS требует разрешение Automation, чтобы приложение могло спросить браузер об адресе активной вкладки. PurrBreak не читает историю, пароли, содержимое страниц или личные данные.",
        "help.browserStatus.title": "Статусы браузеров",
        "help.browserStatus.text": "Отдельное окно Проверка браузеров показывает, получилось ли прочитать активную вкладку. Если галочка уже есть, делать ничего не нужно; системные настройки нужны только при отказе или ошибке доступа.",
        "help.supported.title": "Какие браузеры поддерживаются",
        "help.supported.text": "Safari, Chrome, Yandex Browser, Brave, Edge, Arc, Chromium, Vivaldi и Opera. Firefox виден в списке, но текущий AppleScript-способ не умеет надежно читать его активную вкладку; для него лучше подойдет отдельное расширение.",
        "help.test.title": "Тест заставки",
        "help.test.text": "Тест показывает оверлей примерно на 20 секунд, но клики проходят сквозь него. Закрыть тест можно кнопкой Остановить тест, из меню-бара или клавишей Esc, если macOS передала ее приложению.",
        "help.afterBreak.title": "После паузы",
        "help.afterBreak.text": "Когда пауза закончилась, PurrBreak показывает маленькую развилку: вернуться к YouTube, взять еще 2 минуты тишины или закрыть окно и вернуться к делам. Приложение не закрывает вкладки насильно.",
        "help.notDoing.title": "Что приложение не делает",
        "help.notDoing.text": "PurrBreak не блокирует сайты на уровне сети, не следит за всеми приложениями и не отправляет данные наружу. Это мягкий локальный таймер для YouTube-пауз.",
        "help.backgroundMusic.title": "YouTube-музыка фоном",
        "help.backgroundMusic.text": "Если ты привык держать YouTube как фоновый музыкальный плеер во время работы, PurrBreak будет считать это просмотром YouTube. Текущая версия не умеет надежно отличать музыку от залипания; лучше заранее скачать плейлист или использовать отдельное музыкальное приложение.",
        "postBreak.title": "Пауза закончилась",
        "postBreak.subtitle": "Кот сделал свою часть. Что выбираем дальше?",
        "postBreak.stats": "Сегодня уже спасено: %@",
        "postBreak.work": "Вернуться к делам",
        "postBreak.more": "Еще 2 минуты",
        "postBreak.youtube": "Вернуться к YouTube",
        "overlay.breakTitle": "Пять минут перезагрузки",
        "overlay.previewTitle": "Тест заставки",
        "overlay.breakMessage": "Кот занял экран. YouTube подождет.",
        "overlay.previewMessage": "Это предпросмотр: клики проходят сквозь оверлей. Esc закрывает.",
        "menu.openSettings": "Открыть настройки",
        "menu.screensaver": "Заставка",
        "menu.tooltip": "PurrBreak: %@ %@. Просмотрено %@ / %@",
        "window.help": "Справка PurrBreak",
        "window.postBreak": "Пауза закончилась"
    ]

    private static let en: [String: String] = [
        "app.subtitle": "A gentle YouTube timeout",
        "language": "Language",
        "theme.sleep": "Orange Nap",
        "theme.moon": "Moonlit Doze",
        "theme.rain": "Rainy Window",
        "theme.space": "Cosmic Sleep",
        "status.breakRemaining": "Break ends in",
        "status.previewRemaining": "Preview ends in",
        "status.untilBreak": "Until break",
        "monitor.ready": "Ready to watch YouTube",
        "monitor.noBrowser": "Browser not found",
        "monitor.breakInProgress": "Break in progress",
        "monitor.accessNeeded": "Automation access needed: %@",
        "monitor.unsupported": "%@ is not supported yet",
        "monitor.browserNotFront": "No supported browser in front",
        "monitor.waitingYouTube": "Waiting for active YouTube",
        "monitor.youtubeActive": "YouTube is active",
        "monitor.shortsActive": "YouTube Shorts are active",
        "monitor.emptyTab": "Active tab has no address",
        "monitor.notYouTube": "Not YouTube right now",
        "browser.state.notInstalled": "Not found",
        "browser.state.waiting": "Waiting to check",
        "browser.state.connected": "Connected",
        "browser.state.needsPermission": "Needs access",
        "browser.state.unsupported": "Not supported yet",
        "browser.detail.notInstalled": "This app was not found on this Mac.",
        "browser.detail.waiting": "Open YouTube in this browser so macOS can ask for access.",
        "browser.detail.connected": "PurrBreak can read the active tab URL.",
        "browser.detail.unsupported": "Needs a separate tracking method, such as a browser extension.",
        "browser.detail.unsupportedSpecific": "%@ will work best through an extension or another fallback.",
        "browser.error.unsupported": "%@: cannot read the active tab URL yet",
        "browser.error.noAccess": "%@: macOS has not allowed access to the active tab yet",
        "settings.youtubeActive": "YouTube is active",
        "settings.youtubeInactive": "YouTube is not active",
        "settings.watched": "Watched",
        "settings.screensaver": "Screensaver",
        "settings.limit": "YouTube limit",
        "settings.shortsLimit": "Shorts limit",
        "settings.breakLength": "Break length",
        "settings.purrSound": "Purring during breaks",
        "settings.purrVolume": "Purr volume",
        "settings.minutes": "%d min",
        "settings.testStop": "Stop preview",
        "settings.test": "Preview break",
        "settings.startBreak": "Break now",
        "settings.resetCounter": "Reset counter",
        "settings.browserCheck": "Check browsers",
        "settings.help": "Help",
        "settings.quit": "Quit",
        "stats.today": "Today YouTube: %@ • Breaks: %d • Saved: %@",
        "duration.hoursMinutes": "%dh %02dm",
        "duration.minutes": "%dm",
        "browserCheck.firstTitle": "Browser Access",
        "browserCheck.title": "Check Browsers",
        "browserCheck.subtitle": "The checkmark appears automatically when PurrBreak can read the active tab",
        "browserCheck.firstRun": "First launch",
        "browserCheck.firstRunText": "There is nothing to connect manually. Open YouTube in Chrome, Safari, or Yandex Browser. When macOS asks for Automation access, allow it. If the prompt does not appear or you denied it by accident, open macOS permissions below.",
        "browserCheck.openPermissions": "Open macOS Permissions",
        "browserCheck.openMainSettings": "Open Settings",
        "browserCheck.done": "Done",
        "browserCheck.access": "Browser access",
        "browserCheck.explainer": "This is not a manual setup screen. It only shows whether PurrBreak could read the active tab. If you already see a checkmark, you are done.",
        "browserCheck.hidden": "Hidden browsers not installed: %d.",
        "help.title": "How PurrBreak Works",
        "help.subtitle": "A quick guide to timers, breaks, and permissions",
        "help.whatCounts.title": "What gets counted",
        "help.whatCounts.text": "Every second, PurrBreak checks which browser is active and reads the active tab URL. The timer only runs when the active tab is on youtube.com or youtu.be.",
        "help.whenBreak.title": "When the break appears",
        "help.whenBreak.text": "When your watch limit is reached, the app shows a full-screen pause with the selected cat animation. By default, regular YouTube is limited to 20 minutes, Shorts to 5 minutes, followed by a 5-minute break. After the break ends, the counter resets.",
        "help.automation.title": "Why Automation is needed",
        "help.automation.text": "macOS requires Automation permission so the app can ask the browser for the active tab address. PurrBreak does not read history, passwords, page contents, or personal data.",
        "help.browserStatus.title": "Browser status",
        "help.browserStatus.text": "The Check Browsers window shows whether PurrBreak can read the active tab. If you already see a checkmark, you are done; macOS settings are only needed after a denied or failed permission check.",
        "help.supported.title": "Supported browsers",
        "help.supported.text": "Safari, Chrome, Yandex Browser, Brave, Edge, Arc, Chromium, Vivaldi, and Opera are supported. Firefox appears in the list, but the current AppleScript method cannot reliably read its active tab; an extension would be a better fit.",
        "help.test.title": "Break preview",
        "help.test.text": "The preview shows the overlay for about 20 seconds without intercepting clicks. You can close it with Stop Preview, from the menu bar, or with Esc if macOS passes the key to the app.",
        "help.afterBreak.title": "After the break",
        "help.afterBreak.text": "When the break ends, PurrBreak shows a small choice: return to YouTube, take two more quiet minutes, or close the window and go back to work. The app does not force-close tabs.",
        "help.notDoing.title": "What the app does not do",
        "help.notDoing.text": "PurrBreak does not block websites at the network level, monitor all apps, or send data anywhere. It is a gentle local timer for YouTube breaks.",
        "help.backgroundMusic.title": "YouTube music in the background",
        "help.backgroundMusic.text": "If you use YouTube as a background music player while working, PurrBreak will count that as YouTube time. The current version cannot reliably distinguish music from watching; it is better to download a playlist in advance or use a dedicated music app.",
        "postBreak.title": "Break complete",
        "postBreak.subtitle": "The cat did its part. What happens next?",
        "postBreak.stats": "Saved today: %@",
        "postBreak.work": "Back to work",
        "postBreak.more": "2 more minutes",
        "postBreak.youtube": "Return to YouTube",
        "overlay.breakTitle": "Five-Minute Reset",
        "overlay.previewTitle": "Break Preview",
        "overlay.breakMessage": "The cat has taken the screen. YouTube can wait.",
        "overlay.previewMessage": "This is a preview: clicks pass through the overlay. Esc closes it.",
        "menu.openSettings": "Open Settings",
        "menu.screensaver": "Screensaver",
        "menu.tooltip": "PurrBreak: %@ %@. Watched %@ / %@",
        "window.help": "PurrBreak Help",
        "window.postBreak": "Break Complete"
    ]

    static func text(_ key: String, language: AppLanguage) -> String {
        let table = language == .ru ? ru : en
        return table[key] ?? ru[key] ?? key
    }

    static func text(_ key: String, language: AppLanguage, _ args: CVarArg...) -> String {
        text(key, language: language, arguments: args)
    }

    static func text(_ key: String, language: AppLanguage, arguments: [CVarArg]) -> String {
        String(format: text(key, language: language), locale: language.locale, arguments: arguments)
    }
}

private struct BreakTheme: Identifiable, Equatable {
    let id: String
    let displayName: String
    let resourceName: String

    static let all: [BreakTheme] = [
        BreakTheme(id: "sleep", displayName: "Рыжий сон", resourceName: "cat-sleep-spritesheet"),
        BreakTheme(id: "moon", displayName: "Лунная дрема", resourceName: "cat-moon-spritesheet"),
        BreakTheme(id: "rain", displayName: "Дождливое окно", resourceName: "cat-rain-spritesheet"),
        BreakTheme(id: "space", displayName: "Космический сон", resourceName: "cat-space-spritesheet")
    ]

    static var fallback: BreakTheme {
        all[0]
    }

    static func matching(_ id: String) -> BreakTheme {
        all.first { $0.id == id } ?? fallback
    }

    func displayName(language: AppLanguage) -> String {
        L10n.text("theme.\(id)", language: language)
    }
}

private struct PurrSettings: Equatable {
    var watchLimitMinutes: Int
    var shortsLimitMinutes: Int
    var breakMinutes: Int
    var soundEnabled: Bool
    var purrVolume: Double
    var screensaverThemeID: String
    var language: AppLanguage

    static func load() -> PurrSettings {
        let defaults = UserDefaults.standard

        let watchLimit = defaults.object(forKey: DefaultsKey.watchLimitMinutes) as? Int ?? 20
        let shortsLimit = defaults.object(forKey: DefaultsKey.shortsLimitMinutes) as? Int ?? 5
        let breakLength = defaults.object(forKey: DefaultsKey.breakMinutes) as? Int ?? 5
        let sound = defaults.object(forKey: DefaultsKey.soundEnabled) as? Bool ?? true
        let volume = defaults.object(forKey: DefaultsKey.purrVolume) as? Double ?? 0.65
        let themeID = defaults.string(forKey: DefaultsKey.screensaverThemeID) ?? BreakTheme.fallback.id
        let language = AppLanguage.matching(defaults.string(forKey: DefaultsKey.languageCode))

        return PurrSettings(
            watchLimitMinutes: max(1, min(watchLimit, 240)),
            shortsLimitMinutes: max(1, min(shortsLimit, 120)),
            breakMinutes: max(1, min(breakLength, 60)),
            soundEnabled: sound,
            purrVolume: max(0.0, min(volume, 1.0)),
            screensaverThemeID: BreakTheme.matching(themeID).id,
            language: language
        )
    }

    func save() {
        let defaults = UserDefaults.standard
        defaults.set(watchLimitMinutes, forKey: DefaultsKey.watchLimitMinutes)
        defaults.set(shortsLimitMinutes, forKey: DefaultsKey.shortsLimitMinutes)
        defaults.set(breakMinutes, forKey: DefaultsKey.breakMinutes)
        defaults.set(soundEnabled, forKey: DefaultsKey.soundEnabled)
        defaults.set(purrVolume, forKey: DefaultsKey.purrVolume)
        defaults.set(screensaverThemeID, forKey: DefaultsKey.screensaverThemeID)
        defaults.set(language.rawValue, forKey: DefaultsKey.languageCode)
    }
}

private final class PurrModel: ObservableObject {
    @Published var settings: PurrSettings {
        didSet {
            settings.save()
            onSettingsChanged?(settings)
        }
    }

    @Published var watchedSeconds: Int = 0
    @Published var watchedShortsSeconds: Int = 0
    @Published var isWatchingYouTube = false
    @Published var isWatchingShorts = false
    @Published var activeBrowserName: String
    @Published var currentURL = ""
    @Published var lastYouTubeBundleID: String?
    @Published var monitorMessage: String
    @Published var isOnBreak = false
    @Published var isPreviewingBreak = false
    @Published var breakRemainingSeconds = 0
    @Published var browserStatuses: [BrowserStatus]
    @Published var dailyYouTubeSeconds: Int
    @Published var dailyBreakCount: Int
    @Published var dailySavedSeconds: Int

    var onSettingsChanged: ((PurrSettings) -> Void)?
    private var dailyStatsDate: String

    init(settings: PurrSettings) {
        self.settings = settings
        self.activeBrowserName = L10n.text("monitor.noBrowser", language: settings.language)
        self.monitorMessage = L10n.text("monitor.ready", language: settings.language)
        self.browserStatuses = BrowserStatus.initialStatuses()
        let stats = Self.loadDailyStats()
        self.dailyStatsDate = stats.date
        self.dailyYouTubeSeconds = stats.youtubeSeconds
        self.dailyBreakCount = stats.breakCount
        self.dailySavedSeconds = stats.savedSeconds
    }

    var watchLimitSeconds: Int {
        settings.watchLimitMinutes * 60
    }

    var shortsLimitSeconds: Int {
        settings.shortsLimitMinutes * 60
    }

    var activeWatchedSeconds: Int {
        isWatchingShorts ? watchedShortsSeconds : watchedSeconds
    }

    var activeLimitSeconds: Int {
        isWatchingShorts ? shortsLimitSeconds : watchLimitSeconds
    }

    var progress: Double {
        guard activeLimitSeconds > 0 else { return 0 }
        return min(1.0, Double(activeWatchedSeconds) / Double(activeLimitSeconds))
    }

    var watchedTimeText: String {
        Self.clockText(seconds: activeWatchedSeconds)
    }

    var limitText: String {
        Self.clockText(seconds: activeLimitSeconds)
    }

    var remainingUntilBreakSeconds: Int {
        max(0, activeLimitSeconds - activeWatchedSeconds)
    }

    var remainingUntilBreakText: String {
        Self.clockText(seconds: remainingUntilBreakSeconds)
    }

    var statusCountdownText: String {
        if isOnBreak || isPreviewingBreak {
            return Self.clockText(seconds: breakRemainingSeconds)
        }

        return remainingUntilBreakText
    }

    var statusCountdownLabel: String {
        if isOnBreak {
            return tr("status.breakRemaining")
        }

        if isPreviewingBreak {
            return tr("status.previewRemaining")
        }

        return tr("status.untilBreak")
    }

    var selectedTheme: BreakTheme {
        BreakTheme.matching(settings.screensaverThemeID)
    }

    var dailyStatsText: String {
        tr(
            "stats.today",
            Self.durationText(seconds: dailyYouTubeSeconds, language: language),
            dailyBreakCount,
            Self.durationText(seconds: dailySavedSeconds, language: language)
        )
    }

    static func clockText(seconds: Int) -> String {
        let clamped = max(0, seconds)
        return String(format: "%02d:%02d", clamped / 60, clamped % 60)
    }

    static func durationText(seconds: Int, language: AppLanguage) -> String {
        let minutes = max(0, Int((Double(seconds) / 60.0).rounded()))
        if minutes >= 60 {
            return L10n.text("duration.hoursMinutes", language: language, minutes / 60, minutes % 60)
        }

        return L10n.text("duration.minutes", language: language, minutes)
    }

    var language: AppLanguage {
        settings.language
    }

    func tr(_ key: String) -> String {
        L10n.text(key, language: language)
    }

    func tr(_ key: String, _ args: CVarArg...) -> String {
        L10n.text(key, language: language, arguments: args)
    }

    func markBrowserConnected(bundleID: String, displayName: String) {
        updateBrowserStatus(bundleID: bundleID) { status in
            status.state = .connected
            status.detail = .connected
        }
    }

    func markBrowserNeedsPermission(bundleID: String, displayName: String, message: String) {
        updateBrowserStatus(bundleID: bundleID) { status in
            status.state = .needsPermission
            status.detail = .needsPermission(message)
        }
    }

    func markBrowserUnsupported(bundleID: String, displayName: String) {
        updateBrowserStatus(bundleID: bundleID) { status in
            status.state = .unsupported
            status.detail = .unsupportedSpecific(displayName)
        }
    }

    private func updateBrowserStatus(bundleID: String, mutate: (inout BrowserStatus) -> Void) {
        guard let index = browserStatuses.firstIndex(where: { $0.bundleID == bundleID }) else {
            return
        }

        var status = browserStatuses[index]
        mutate(&status)
        browserStatuses[index] = status
    }

    func recordYouTubeWatch(kind: YouTubeKind, elapsed: Int) {
        resetDailyStatsIfNeeded()
        dailyYouTubeSeconds += elapsed

        switch kind {
        case .regular:
            watchedSeconds += elapsed
        case .shorts:
            watchedShortsSeconds += elapsed
        }

        saveDailyStats()
    }

    func resetCounters() {
        watchedSeconds = 0
        watchedShortsSeconds = 0
        isWatchingShorts = false
    }

    func recordBreakStarted(seconds: Int) {
        resetDailyStatsIfNeeded()
        dailyBreakCount += 1
        dailySavedSeconds += seconds
        saveDailyStats()
    }

    private static func currentStatsDateString() -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private static func loadDailyStats() -> (date: String, youtubeSeconds: Int, breakCount: Int, savedSeconds: Int) {
        let defaults = UserDefaults.standard
        let today = currentStatsDateString()
        guard defaults.string(forKey: DefaultsKey.statsDate) == today else {
            defaults.set(today, forKey: DefaultsKey.statsDate)
            defaults.set(0, forKey: DefaultsKey.dailyYouTubeSeconds)
            defaults.set(0, forKey: DefaultsKey.dailyBreakCount)
            defaults.set(0, forKey: DefaultsKey.dailySavedSeconds)
            return (today, 0, 0, 0)
        }

        return (
            today,
            defaults.object(forKey: DefaultsKey.dailyYouTubeSeconds) as? Int ?? 0,
            defaults.object(forKey: DefaultsKey.dailyBreakCount) as? Int ?? 0,
            defaults.object(forKey: DefaultsKey.dailySavedSeconds) as? Int ?? 0
        )
    }

    private func resetDailyStatsIfNeeded() {
        let today = Self.currentStatsDateString()
        guard dailyStatsDate != today else { return }

        dailyStatsDate = today
        dailyYouTubeSeconds = 0
        dailyBreakCount = 0
        dailySavedSeconds = 0
        saveDailyStats()
    }

    private func saveDailyStats() {
        let defaults = UserDefaults.standard
        defaults.set(Self.currentStatsDateString(), forKey: DefaultsKey.statsDate)
        defaults.set(dailyYouTubeSeconds, forKey: DefaultsKey.dailyYouTubeSeconds)
        defaults.set(dailyBreakCount, forKey: DefaultsKey.dailyBreakCount)
        defaults.set(dailySavedSeconds, forKey: DefaultsKey.dailySavedSeconds)
    }
}

private struct BrowserDescriptor {
    let bundleID: String
    let displayName: String
    let scriptKind: ScriptKind

    enum ScriptKind {
        case safari
        case chromium
        case unsupported
    }

    var canReadURL: Bool {
        scriptKind != .unsupported
    }

    static let all: [BrowserDescriptor] = [
        BrowserDescriptor(bundleID: "com.apple.Safari", displayName: "Safari", scriptKind: .safari),
        BrowserDescriptor(bundleID: "com.apple.SafariTechnologyPreview", displayName: "Safari Technology Preview", scriptKind: .safari),
        BrowserDescriptor(bundleID: "com.google.Chrome", displayName: "Google Chrome", scriptKind: .chromium),
        BrowserDescriptor(bundleID: "com.google.Chrome.canary", displayName: "Chrome Canary", scriptKind: .chromium),
        BrowserDescriptor(bundleID: "ru.yandex.desktop.yandex-browser", displayName: "Yandex Browser", scriptKind: .chromium),
        BrowserDescriptor(bundleID: "com.brave.Browser", displayName: "Brave", scriptKind: .chromium),
        BrowserDescriptor(bundleID: "com.microsoft.edgemac", displayName: "Microsoft Edge", scriptKind: .chromium),
        BrowserDescriptor(bundleID: "company.thebrowser.Browser", displayName: "Arc", scriptKind: .chromium),
        BrowserDescriptor(bundleID: "org.chromium.Chromium", displayName: "Chromium", scriptKind: .chromium),
        BrowserDescriptor(bundleID: "com.vivaldi.Vivaldi", displayName: "Vivaldi", scriptKind: .chromium),
        BrowserDescriptor(bundleID: "com.operasoftware.Opera", displayName: "Opera", scriptKind: .chromium),
        BrowserDescriptor(bundleID: "org.mozilla.firefox", displayName: "Firefox", scriptKind: .unsupported)
    ]

    static var byBundleID: [String: BrowserDescriptor] {
        Dictionary(uniqueKeysWithValues: all.map { ($0.bundleID, $0) })
    }
}

private enum BrowserConnectionState: Equatable {
    case notInstalled
    case waiting
    case connected
    case needsPermission
    case unsupported
}

private enum BrowserStatusDetail: Equatable {
    case notInstalled
    case waiting
    case connected
    case unsupported
    case unsupportedSpecific(String)
    case needsPermission(String)

    func text(language: AppLanguage) -> String {
        switch self {
        case .notInstalled:
            return L10n.text("browser.detail.notInstalled", language: language)
        case .waiting:
            return L10n.text("browser.detail.waiting", language: language)
        case .connected:
            return L10n.text("browser.detail.connected", language: language)
        case .unsupported:
            return L10n.text("browser.detail.unsupported", language: language)
        case .unsupportedSpecific(let browserName):
            return L10n.text("browser.detail.unsupportedSpecific", language: language, browserName)
        case .needsPermission(let message):
            return message
        }
    }
}

private struct BrowserStatus: Identifiable, Equatable {
    let id: String
    let displayName: String
    let bundleID: String
    let isInstalled: Bool
    let canReadURL: Bool
    var state: BrowserConnectionState
    var detail: BrowserStatusDetail

    func stateText(language: AppLanguage) -> String {
        switch state {
        case .notInstalled:
            return L10n.text("browser.state.notInstalled", language: language)
        case .waiting:
            return L10n.text("browser.state.waiting", language: language)
        case .connected:
            return L10n.text("browser.state.connected", language: language)
        case .needsPermission:
            return L10n.text("browser.state.needsPermission", language: language)
        case .unsupported:
            return L10n.text("browser.state.unsupported", language: language)
        }
    }

    var symbolName: String {
        switch state {
        case .notInstalled:
            return "minus.circle"
        case .waiting:
            return "clock"
        case .connected:
            return "checkmark.circle.fill"
        case .needsPermission:
            return "exclamationmark.triangle.fill"
        case .unsupported:
            return "hammer.circle"
        }
    }

    var symbolColor: Color {
        switch state {
        case .notInstalled:
            return .secondary
        case .waiting:
            return .orange
        case .connected:
            return .green
        case .needsPermission:
            return .red
        case .unsupported:
            return .secondary
        }
    }

    static func initialStatuses() -> [BrowserStatus] {
        BrowserDescriptor.all.map { descriptor in
            let isInstalled = NSWorkspace.shared.urlForApplication(withBundleIdentifier: descriptor.bundleID) != nil
            let state: BrowserConnectionState
            let detail: BrowserStatusDetail

            if !isInstalled {
                state = .notInstalled
                detail = .notInstalled
            } else if !descriptor.canReadURL {
                state = .unsupported
                detail = .unsupported
            } else {
                state = .waiting
                detail = .waiting
            }

            return BrowserStatus(
                id: descriptor.bundleID,
                displayName: descriptor.displayName,
                bundleID: descriptor.bundleID,
                isInstalled: isInstalled,
                canReadURL: descriptor.canReadURL,
                state: state,
                detail: detail
            )
        }
    }
}

private struct BrowserSnapshot {
    let browserName: String
    let bundleID: String
    let url: String
}

private enum YouTubeKind {
    case regular
    case shorts
}

private enum BrowserReadError: Error, CustomStringConvertible {
    case browserError(bundleID: String, browserName: String, message: String)
    case unsupported(bundleID: String, browserName: String)

    var bundleID: String {
        switch self {
        case .browserError(let bundleID, _, _), .unsupported(let bundleID, _):
            return bundleID
        }
    }

    var browserName: String {
        switch self {
        case .browserError(_, let browserName, _), .unsupported(_, let browserName):
            return browserName
        }
    }

    var description: String {
        switch self {
        case .browserError(_, _, let message):
            return message
        case .unsupported(_, let browserName):
            return L10n.text("browser.error.unsupported", language: .ru, browserName)
        }
    }
}

private final class BrowserURLReader {
    func frontmostSnapshot(language: AppLanguage) -> Result<BrowserSnapshot?, BrowserReadError> {
        guard let app = NSWorkspace.shared.frontmostApplication,
              let bundleID = app.bundleIdentifier else {
            return .success(nil)
        }

        guard let browser = BrowserDescriptor.byBundleID[bundleID] else {
            return .success(nil)
        }

        guard browser.canReadURL else {
            return .failure(.unsupported(bundleID: browser.bundleID, browserName: browser.displayName))
        }

        let script = appleScript(for: browser)
        var error: NSDictionary?
        guard let descriptor = NSAppleScript(source: script)?.executeAndReturnError(&error) else {
            return .failure(.browserError(
                bundleID: browser.bundleID,
                browserName: browser.displayName,
                message: errorMessage(from: error, browserName: browser.displayName, language: language)
            ))
        }

        let url = descriptor.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return .success(BrowserSnapshot(browserName: browser.displayName, bundleID: bundleID, url: url))
    }

    private func appleScript(for browser: BrowserDescriptor) -> String {
        switch browser.scriptKind {
        case .safari:
            return """
            tell application id "\(browser.bundleID)"
                if (count of documents) is 0 then return ""
                return URL of front document
            end tell
            """
        case .chromium:
            return """
            tell application id "\(browser.bundleID)"
                if (count of windows) is 0 then return ""
                return URL of active tab of front window
            end tell
            """
        case .unsupported:
            return ""
        }
    }

    private func errorMessage(from error: NSDictionary?, browserName: String, language: AppLanguage) -> String {
        if let message = error?[NSAppleScript.errorMessage] as? String, !message.isEmpty {
            return "\(browserName): \(message)"
        }

        return L10n.text("browser.error.noAccess", language: language, browserName)
    }
}

private final class YouTubeMonitor {
    private let model: PurrModel
    private let reader = BrowserURLReader()
    private var timer: Timer?
    private var lastTickDate = Date()
    private var onLimitReached: (() -> Void)?
    private var onStatusChanged: (() -> Void)?

    init(model: PurrModel, onLimitReached: @escaping () -> Void, onStatusChanged: @escaping () -> Void) {
        self.model = model
        self.onLimitReached = onLimitReached
        self.onStatusChanged = onStatusChanged
    }

    func start() {
        lastTickDate = Date()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func resetCounter() {
        model.resetCounters()
    }

    private func tick() {
        let now = Date()
        let elapsed = max(1, Int(now.timeIntervalSince(lastTickDate).rounded()))
        lastTickDate = now

        guard !model.isOnBreak else {
            model.isWatchingYouTube = false
            model.isWatchingShorts = false
            model.monitorMessage = model.tr("monitor.breakInProgress")
            return
        }

        switch reader.frontmostSnapshot(language: model.language) {
        case .success(let snapshot):
            update(with: snapshot, elapsed: elapsed)
        case .failure(let error):
            model.isWatchingYouTube = false
            model.isWatchingShorts = false
            model.currentURL = ""

            switch error {
            case .browserError(let bundleID, let browserName, let message):
                model.activeBrowserName = browserName
                model.markBrowserNeedsPermission(bundleID: bundleID, displayName: browserName, message: message)
                model.monitorMessage = model.tr("monitor.accessNeeded", message)
            case .unsupported(let bundleID, let browserName):
                model.activeBrowserName = browserName
                model.markBrowserUnsupported(bundleID: bundleID, displayName: browserName)
                model.monitorMessage = model.tr("monitor.unsupported", browserName)
            }
        }

        onStatusChanged?()
    }

    private func update(with snapshot: BrowserSnapshot?, elapsed: Int) {
        guard let snapshot else {
            model.isWatchingYouTube = false
            model.isWatchingShorts = false
            model.currentURL = ""
            model.activeBrowserName = model.tr("monitor.browserNotFront")
            model.monitorMessage = model.tr("monitor.waitingYouTube")
            return
        }

        model.activeBrowserName = snapshot.browserName
        model.currentURL = snapshot.url
        model.markBrowserConnected(bundleID: snapshot.bundleID, displayName: snapshot.browserName)

        if let kind = Self.youtubeKind(for: snapshot.url) {
            model.isWatchingYouTube = true
            model.isWatchingShorts = kind == .shorts
            model.lastYouTubeBundleID = snapshot.bundleID
            model.recordYouTubeWatch(kind: kind, elapsed: elapsed)
            model.monitorMessage = kind == .shorts ? model.tr("monitor.shortsActive") : model.tr("monitor.youtubeActive")

            let reachedLimit = kind == .shorts
                ? model.watchedShortsSeconds >= model.shortsLimitSeconds
                : model.watchedSeconds >= model.watchLimitSeconds

            if reachedLimit {
                onLimitReached?()
            }
        } else {
            model.isWatchingYouTube = false
            model.isWatchingShorts = false
            model.monitorMessage = snapshot.url.isEmpty ? model.tr("monitor.emptyTab") : model.tr("monitor.notYouTube")
        }
    }

    private static func youtubeKind(for rawURL: String) -> YouTubeKind? {
        guard let components = URLComponents(string: rawURL.lowercased()),
              let host = components.host else {
            return nil
        }

        let normalizedHost = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
        let isYouTube = normalizedHost == "youtube.com"
            || normalizedHost.hasSuffix(".youtube.com")
            || normalizedHost == "youtu.be"

        guard isYouTube else { return nil }

        if normalizedHost != "youtu.be", components.path.lowercased().hasPrefix("/shorts") {
            return .shorts
        }

        return .regular
    }
}

private final class BreakManager {
    private let model: PurrModel
    private let audio = PurrAudioPlayer()
    private var windows: [NSWindow] = []
    private var previewWindows: [NSWindow] = []
    private var timer: Timer?
    private var previewTimer: Timer?
    private var breakEndDate: Date?
    private var previewEndDate: Date?
    private var previewLocalKeyMonitor: Any?
    private var previewGlobalKeyMonitor: Any?
    private var isClosingPreview = false
    private var onFinished: (() -> Void)?
    private var onStatusChanged: (() -> Void)?

    init(model: PurrModel, onFinished: @escaping () -> Void, onStatusChanged: @escaping () -> Void) {
        self.model = model
        self.onFinished = onFinished
        self.onStatusChanged = onStatusChanged
    }

    func beginBreak(seconds overrideSeconds: Int? = nil) {
        guard !model.isOnBreak else { return }

        closePreview()

        let seconds = max(60, overrideSeconds ?? model.settings.breakMinutes * 60)
        model.isOnBreak = true
        model.breakRemainingSeconds = seconds
        model.recordBreakStarted(seconds: seconds)
        onStatusChanged?()
        breakEndDate = Date().addingTimeInterval(TimeInterval(seconds))

        windows = createWindows(mode: .break, ignoresMouseEvents: false, level: .screenSaver)

        if model.settings.soundEnabled {
            audio.play(volume: Float(model.settings.purrVolume))
        }

        NSApp.activate(ignoringOtherApps: true)

        timer?.invalidate()
        let breakTimer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.updateBreak()
        }
        timer = breakTimer
        RunLoop.main.add(breakTimer, forMode: .common)
    }

    func previewBreak(seconds: Int = 20) {
        guard !model.isOnBreak else { return }

        closePreview()

        let seconds = max(5, seconds)
        model.isPreviewingBreak = true
        model.breakRemainingSeconds = seconds
        onStatusChanged?()
        previewEndDate = Date().addingTimeInterval(TimeInterval(seconds))
        previewWindows = createWindows(mode: .preview, ignoresMouseEvents: true, level: .screenSaver)
        startPreviewKeyMonitors()

        previewTimer?.invalidate()
        let timer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.updatePreview()
        }
        previewTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    func stopPreview() {
        closePreview()
    }

    func updateAudioSettings(_ settings: PurrSettings) {
        audio.volume = Float(settings.purrVolume)
        if model.isOnBreak {
            if settings.soundEnabled {
                audio.play(volume: Float(settings.purrVolume))
            } else {
                audio.stop()
            }
        }
    }

    private func updatePreview() {
        guard let previewEndDate else { return }

        let remaining = Int(ceil(previewEndDate.timeIntervalSinceNow))
        model.breakRemainingSeconds = max(0, remaining)
        onStatusChanged?()

        if remaining <= 0 {
            closePreview()
        }
    }

    private func updateBreak() {
        guard let breakEndDate else { return }

        let remaining = Int(ceil(breakEndDate.timeIntervalSinceNow))
        model.breakRemainingSeconds = max(0, remaining)
        onStatusChanged?()

        if remaining <= 0 {
            finishBreak()
        }
    }

    private func finishBreak() {
        timer?.invalidate()
        timer = nil
        breakEndDate = nil
        model.isOnBreak = false
        model.breakRemainingSeconds = 0
        onStatusChanged?()
        audio.stop()

        dismissOverlayWindows(windows)
        windows.removeAll()

        onFinished?()
    }

    private func requestClosePreview() {
        guard model.isPreviewingBreak || !previewWindows.isEmpty else { return }
        guard !isClosingPreview else { return }

        isClosingPreview = true
        DispatchQueue.main.async { [weak self] in
            self?.closePreview()
        }
    }

    private func closePreview() {
        guard model.isPreviewingBreak || !previewWindows.isEmpty || previewTimer != nil else {
            isClosingPreview = false
            return
        }

        previewTimer?.invalidate()
        previewTimer = nil
        previewEndDate = nil
        model.isPreviewingBreak = false
        stopPreviewKeyMonitors()
        dismissOverlayWindows(previewWindows)
        previewWindows.removeAll()
        isClosingPreview = false

        if !model.isOnBreak {
            model.breakRemainingSeconds = 0
        }

        onStatusChanged?()
    }

    private func createWindows(mode: OverlayMode, ignoresMouseEvents: Bool, level: NSWindow.Level) -> [NSWindow] {
        var createdWindows: [NSWindow] = []
        for screen in NSScreen.screens {
            let window = NSWindow(
                contentRect: screen.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false,
                screen: screen
            )
            window.contentView = NSHostingView(rootView: CatBreakOverlay(model: model, mode: mode))
            window.level = level
            window.isOpaque = false
            window.backgroundColor = .clear
            window.ignoresMouseEvents = ignoresMouseEvents
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
            window.animationBehavior = .none
            window.hidesOnDeactivate = false
            window.canHide = false
            window.orderFrontRegardless()
            createdWindows.append(window)
        }

        return createdWindows
    }

    private func dismissOverlayWindows(_ windows: [NSWindow]) {
        for window in windows {
            window.animations = [:]
            window.orderOut(nil)
            window.contentView = nil
        }
    }

    private func startPreviewKeyMonitors() {
        stopPreviewKeyMonitors()

        previewLocalKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 {
                self?.requestClosePreview()
                return nil
            }

            return event
        }

        previewGlobalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 {
                self?.requestClosePreview()
            }
        }
    }

    private func stopPreviewKeyMonitors() {
        if let previewLocalKeyMonitor {
            NSEvent.removeMonitor(previewLocalKeyMonitor)
            self.previewLocalKeyMonitor = nil
        }

        if let previewGlobalKeyMonitor {
            NSEvent.removeMonitor(previewGlobalKeyMonitor)
            self.previewGlobalKeyMonitor = nil
        }
    }
}

private final class PurrAudioPlayer: NSObject {
    private var player: AVAudioPlayer?
    private var cachedURL: URL?

    var volume: Float {
        get { player?.volume ?? 0.65 }
        set { player?.volume = newValue }
    }

    func play(volume: Float) {
        do {
            let url = try soundURL()
            if player == nil {
                player = try AVAudioPlayer(contentsOf: url)
                player?.numberOfLoops = -1
                player?.prepareToPlay()
            }

            player?.volume = volume
            player?.play()
        } catch {
            NSLog("PurrBreak sound error: \(error.localizedDescription)")
        }
    }

    func stop() {
        player?.stop()
        player?.currentTime = 0
    }

    private func soundURL() throws -> URL {
        if let cachedURL, FileManager.default.fileExists(atPath: cachedURL.path) {
            return cachedURL
        }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("PurrBreak-purr.wav")
        try Self.writePurrWav(to: url, seconds: 8.0)
        cachedURL = url
        return url
    }

    private static func writePurrWav(to url: URL, seconds: Double) throws {
        let sampleRate = 44_100
        let channels = 2
        let bitsPerSample = 16
        let frameCount = Int(Double(sampleRate) * seconds)
        let byteRate = sampleRate * channels * bitsPerSample / 8
        let blockAlign = channels * bitsPerSample / 8
        let dataByteCount = frameCount * blockAlign

        var data = Data()
        data.appendASCII("RIFF")
        data.appendUInt32LE(UInt32(36 + dataByteCount))
        data.appendASCII("WAVE")
        data.appendASCII("fmt ")
        data.appendUInt32LE(16)
        data.appendUInt16LE(1)
        data.appendUInt16LE(UInt16(channels))
        data.appendUInt32LE(UInt32(sampleRate))
        data.appendUInt32LE(UInt32(byteRate))
        data.appendUInt16LE(UInt16(blockAlign))
        data.appendUInt16LE(UInt16(bitsPerSample))
        data.appendASCII("data")
        data.appendUInt32LE(UInt32(dataByteCount))

        var noiseSeed: UInt64 = 0xBADC0FFEE

        for frame in 0..<frameCount {
            let t = Double(frame) / Double(sampleRate)
            let breath = 0.58 + 0.42 * sin(2.0 * .pi * 0.72 * t)
            let base = sin(2.0 * .pi * 64.0 * t) * 0.34
            let throat = sin(2.0 * .pi * 96.0 * t + sin(2.0 * .pi * 0.35 * t)) * 0.18
            let sub = sin(2.0 * .pi * 36.0 * t) * 0.10
            noiseSeed = noiseSeed &* 6364136223846793005 &+ 1
            let noiseUnit = Double((noiseSeed >> 33) & 0xFFFF) / Double(UInt16.max)
            let noise = (noiseUnit - 0.5) * 0.10
            let sample = max(-1.0, min(1.0, (base + throat + sub + noise) * breath * 0.55))
            let pcm = Int16(sample * Double(Int16.max))

            data.appendInt16LE(pcm)
            data.appendInt16LE(pcm)
        }

        try data.write(to: url, options: .atomic)
    }
}

private extension Data {
    mutating func appendASCII(_ string: String) {
        append(contentsOf: string.utf8)
    }

    mutating func appendUInt16LE(_ value: UInt16) {
        append(UInt8(value & 0x00FF))
        append(UInt8((value & 0xFF00) >> 8))
    }

    mutating func appendInt16LE(_ value: Int16) {
        appendUInt16LE(UInt16(bitPattern: value).littleEndian)
    }

    mutating func appendUInt32LE(_ value: UInt32) {
        append(UInt8(value & 0x000000FF))
        append(UInt8((value & 0x0000FF00) >> 8))
        append(UInt8((value & 0x00FF0000) >> 16))
        append(UInt8((value & 0xFF000000) >> 24))
    }
}

private enum AppIconStore {
    static func image() -> NSImage? {
        if let url = Bundle.main.url(forResource: "app-icon-mark", withExtension: "png") {
            return NSImage(contentsOf: url)
        }

        #if SWIFT_PACKAGE
        if let url = Bundle.module.url(forResource: "app-icon-mark", withExtension: "png") {
            return NSImage(contentsOf: url)
        }
        #endif

        return nil
    }

    static func resizedImage(size: NSSize) -> NSImage? {
        guard let source = image() else { return nil }

        let image = NSImage(size: size)
        image.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        source.draw(
            in: NSRect(origin: .zero, size: size),
            from: NSRect(origin: .zero, size: source.size),
            operation: .sourceOver,
            fraction: 1.0
        )
        image.unlockFocus()
        return image
    }
}

private struct AppIconMark: View {
    let size: CGFloat

    var body: some View {
        Group {
            if let image = AppIconStore.image() {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
            } else {
                Image(systemName: "pawprint.fill")
                    .resizable()
                    .scaledToFit()
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.accentColor)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

private struct SettingsView: View {
    @ObservedObject var model: PurrModel
    let startBreak: () -> Void
    let previewBreak: () -> Void
    let stopPreview: () -> Void
    let resetCounter: () -> Void
    let showHelp: () -> Void
    let showBrowserSettings: () -> Void
    let quit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center, spacing: 14) {
                AppIconMark(size: 58)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("PurrBreak")
                            .font(.system(size: 28, weight: .bold))
                        Text(model.tr("app.subtitle"))
                            .foregroundStyle(.secondary)
                    }
                }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(model.isWatchingYouTube ? model.tr("settings.youtubeActive") : model.tr("settings.youtubeInactive"))
                        .font(.headline)
                    Spacer()
                    Text("\(model.statusCountdownLabel): \(model.statusCountdownText)")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                ProgressView(value: model.progress)
                    .progressViewStyle(.linear)

                HStack {
                    Text(model.tr("settings.watched"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(model.watchedTimeText) / \(model.limitText)")
                        .font(.system(.footnote, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                Text(model.dailyStatsText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text(model.monitorMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Divider()

            VStack(alignment: .leading, spacing: 14) {
                Picker(model.tr("settings.screensaver"), selection: binding(\.screensaverThemeID)) {
                    ForEach(BreakTheme.all) { theme in
                        Text(theme.displayName(language: model.language)).tag(theme.id)
                    }
                }
                .pickerStyle(.menu)

                Picker(model.tr("language"), selection: binding(\.language)) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                .pickerStyle(.segmented)

                Stepper(value: binding(\.watchLimitMinutes), in: 1...240) {
                    settingRow(title: model.tr("settings.limit"), value: model.tr("settings.minutes", model.settings.watchLimitMinutes))
                }

                Stepper(value: binding(\.shortsLimitMinutes), in: 1...120) {
                    settingRow(title: model.tr("settings.shortsLimit"), value: model.tr("settings.minutes", model.settings.shortsLimitMinutes))
                }

                Stepper(value: binding(\.breakMinutes), in: 1...60) {
                    settingRow(title: model.tr("settings.breakLength"), value: model.tr("settings.minutes", model.settings.breakMinutes))
                }

                Toggle(model.tr("settings.purrSound"), isOn: binding(\.soundEnabled))

                VStack(alignment: .leading, spacing: 6) {
                    settingRow(title: model.tr("settings.purrVolume"), value: "\(Int(model.settings.purrVolume * 100))%")
                    Slider(value: binding(\.purrVolume), in: 0...1)
                        .disabled(!model.settings.soundEnabled)
                }
            }

            Divider()

            HStack(spacing: 10) {
                Button {
                    if model.isPreviewingBreak {
                        stopPreview()
                    } else {
                        previewBreak()
                    }
                } label: {
                    Label(
                        model.isPreviewingBreak ? model.tr("settings.testStop") : model.tr("settings.test"),
                        systemImage: model.isPreviewingBreak ? "stop.circle.fill" : "play.display"
                    )
                }
                .buttonStyle(.borderedProminent)

                Button {
                    startBreak()
                } label: {
                    Label(model.tr("settings.startBreak"), systemImage: "moon.zzz.fill")
                }

                Button {
                    resetCounter()
                } label: {
                    Label(model.tr("settings.resetCounter"), systemImage: "arrow.counterclockwise")
                }
            }

            HStack(spacing: 10) {
                Button {
                    showBrowserSettings()
                } label: {
                    Label(model.tr("settings.browserCheck"), systemImage: "globe")
                }

                Spacer()

                Button {
                    showHelp()
                } label: {
                    Label(model.tr("settings.help"), systemImage: "questionmark.circle")
                }

                Button {
                    quit()
                } label: {
                    Label(model.tr("settings.quit"), systemImage: "xmark.circle")
                }
            }
        }
        .padding(24)
        .frame(width: 560)
    }

    private func settingRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }

    private func binding<Value>(_ keyPath: WritableKeyPath<PurrSettings, Value>) -> Binding<Value> {
        Binding(
            get: { model.settings[keyPath: keyPath] },
            set: { newValue in
                var settings = model.settings
                settings[keyPath: keyPath] = newValue
                model.settings = settings
            }
        )
    }
}

private struct BrowserSettingsView: View {
    @ObservedObject var model: PurrModel
    let isFirstRun: Bool
    let openAutomationSettings: () -> Void
    let openMainSettings: () -> Void
    let close: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .center, spacing: 14) {
                    AppIconMark(size: 48)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(isFirstRun ? model.tr("browserCheck.firstTitle") : model.tr("browserCheck.title"))
                            .font(.system(size: 26, weight: .bold))
                        Text(model.tr("browserCheck.subtitle"))
                            .foregroundStyle(.secondary)
                    }
                }

                if isFirstRun {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(model.tr("browserCheck.firstRun"))
                            .font(.headline)
                        Text(model.tr("browserCheck.firstRunText"))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.accentColor.opacity(0.08))
                    )
                }

                BrowserStatusPanel(
                    statuses: model.browserStatuses,
                    language: model.language
                )

                Divider()

                HStack(spacing: 10) {
                    Button {
                        openAutomationSettings()
                    } label: {
                        Label(model.tr("browserCheck.openPermissions"), systemImage: "gearshape")
                    }

                    Spacer()

                    if isFirstRun {
                        Button {
                            close()
                            openMainSettings()
                        } label: {
                            Label(model.tr("browserCheck.openMainSettings"), systemImage: "arrow.right.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        Button {
                            close()
                        } label: {
                            Label(model.tr("browserCheck.done"), systemImage: "checkmark.circle")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .padding(24)
            .frame(width: 620)
        }
        .frame(width: 620, height: 560)
    }
}

private struct BrowserStatusPanel: View {
    let statuses: [BrowserStatus]
    let language: AppLanguage

    private var visibleStatuses: [BrowserStatus] {
        let visible = statuses.filter { status in
            status.isInstalled || status.state == .connected || status.state == .needsPermission || status.state == .unsupported
        }

        return visible.isEmpty ? statuses : visible
    }

    private var hiddenCount: Int {
        max(0, statuses.count - visibleStatuses.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(L10n.text("browserCheck.access", language: language), systemImage: "globe")
                .font(.headline)

            Text(L10n.text("browserCheck.explainer", language: language))
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 8) {
                ForEach(visibleStatuses) { status in
                    BrowserStatusRow(status: status, language: language)
                }
            }

            if hiddenCount > 0 {
                Text(L10n.text("browserCheck.hidden", language: language, hiddenCount))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct BrowserStatusRow: View {
    let status: BrowserStatus
    let language: AppLanguage

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: status.symbolName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(status.symbolColor)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(status.displayName)
                        .font(.system(.subheadline, weight: .semibold))

                    Spacer()

                    Text(status.stateText(language: language))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Text(status.detail.text(language: language))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.primary.opacity(0.045))
        )
    }
}

private struct HelpView: View {
    @ObservedObject var model: PurrModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 12) {
                    AppIconMark(size: 44)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(model.tr("help.title"))
                            .font(.system(size: 26, weight: .bold))
                        Text(model.tr("help.subtitle"))
                            .foregroundStyle(.secondary)
                    }
                }

                helpSection(
                    title: model.tr("help.whatCounts.title"),
                    icon: "timer",
                    text: model.tr("help.whatCounts.text")
                )

                helpSection(
                    title: model.tr("help.whenBreak.title"),
                    icon: "moon.zzz.fill",
                    text: model.tr("help.whenBreak.text")
                )

                helpSection(
                    title: model.tr("help.automation.title"),
                    icon: "lock.shield",
                    text: model.tr("help.automation.text")
                )

                helpSection(
                    title: model.tr("help.browserStatus.title"),
                    icon: "checklist",
                    text: model.tr("help.browserStatus.text")
                )

                helpSection(
                    title: model.tr("help.supported.title"),
                    icon: "globe",
                    text: model.tr("help.supported.text")
                )

                helpSection(
                    title: model.tr("help.test.title"),
                    icon: "play.display",
                    text: model.tr("help.test.text")
                )

                helpSection(
                    title: model.tr("help.afterBreak.title"),
                    icon: "arrow.right.circle",
                    text: model.tr("help.afterBreak.text")
                )

                helpSection(
                    title: model.tr("help.backgroundMusic.title"),
                    icon: "music.note",
                    text: model.tr("help.backgroundMusic.text")
                )

                helpSection(
                    title: model.tr("help.notDoing.title"),
                    icon: "hand.raised",
                    text: model.tr("help.notDoing.text")
                )
            }
            .padding(24)
        }
        .frame(width: 620, height: 620)
    }

    private func helpSection(title: String, icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                Text(text)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct PostBreakView: View {
    @ObservedObject var model: PurrModel
    let returnToYouTube: () -> Void
    let takeMoreBreak: () -> Void
    let backToWork: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(spacing: 14) {
                AppIconMark(size: 54)

                VStack(alignment: .leading, spacing: 4) {
                    Text(model.tr("postBreak.title"))
                        .font(.system(size: 28, weight: .bold))
                    Text(model.tr("postBreak.subtitle"))
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 10) {
                Label(model.tr("postBreak.stats", PurrModel.durationText(seconds: model.dailySavedSeconds, language: model.language)), systemImage: "sparkles")
                    .font(.system(.callout, weight: .medium))
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.primary.opacity(0.045))
            )

            VStack(spacing: 10) {
                Button {
                    backToWork()
                } label: {
                    Label(model.tr("postBreak.work"), systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                HStack(spacing: 10) {
                    Button {
                        takeMoreBreak()
                    } label: {
                        Label(model.tr("postBreak.more"), systemImage: "timer")
                            .frame(maxWidth: .infinity)
                    }

                    Button {
                        returnToYouTube()
                    } label: {
                        Label(model.tr("postBreak.youtube"), systemImage: "play.circle")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .controlSize(.large)
        }
        .padding(24)
        .frame(width: 520)
    }
}

private enum OverlayMode {
    case `break`
    case preview

    func title(language: AppLanguage) -> String {
        switch self {
        case .break:
            return L10n.text("overlay.breakTitle", language: language)
        case .preview:
            return L10n.text("overlay.previewTitle", language: language)
        }
    }

    func message(language: AppLanguage) -> String {
        switch self {
        case .break:
            return L10n.text("overlay.breakMessage", language: language)
        case .preview:
            return L10n.text("overlay.previewMessage", language: language)
        }
    }
}

private struct CatBreakOverlay: View {
    @ObservedObject var model: PurrModel
    let mode: OverlayMode

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.07, blue: 0.10).opacity(0.94),
                    Color(red: 0.12, green: 0.10, blue: 0.13).opacity(0.96),
                    Color(red: 0.04, green: 0.08, blue: 0.09).opacity(0.94)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer(minLength: 24)

                SpriteCatView(theme: model.selectedTheme)
                    .frame(maxWidth: 820, maxHeight: 440)
                    .padding(.horizontal, 34)

                VStack(spacing: 10) {
                    Text(mode.title(language: model.language))
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white)
                        .multilineTextAlignment(.center)

                    Text(PurrModel.clockText(seconds: model.breakRemainingSeconds))
                        .font(.system(size: 72, weight: .heavy, design: .monospaced))
                        .foregroundStyle(Color(red: 1.0, green: 0.82, blue: 0.55))
                        .monospacedDigit()

                    Text(mode.message(language: model.language))
                        .font(.system(size: 24, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.78))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 24)
            }
        }
    }
}

private struct SpriteCatView: View {
    let theme: BreakTheme

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let breath = CGFloat(sin(time * 2.0 * .pi / 4.6))
            let drift = CGFloat(sin(time * 2.0 * .pi / 8.0))

            ZStack {
                Group {
                    if let image = CatSpriteStore.shared.image(for: theme, frameIndex: 0) {
                        Image(nsImage: image)
                            .resizable()
                            .interpolation(.high)
                            .scaledToFit()
                    } else {
                        AnimatedCatView()
                    }
                }
                .scaleEffect(x: 1.0 + breath * 0.006, y: 1.0 + breath * 0.018, anchor: .bottom)
                .rotationEffect(.degrees(Double(drift) * 0.28), anchor: .bottom)
                .offset(y: -breath * 4.0)
                .shadow(color: Color.black.opacity(0.34), radius: 24, x: 0, y: 22)

                MotionParticlesView(theme: theme, time: time)
            }
        }
        .accessibilityHidden(true)
    }
}

private struct MotionParticlesView: View {
    let theme: BreakTheme
    let time: TimeInterval

    var body: some View {
        GeometryReader { proxy in
            ForEach(0..<7, id: \.self) { index in
                particle(index: index, size: proxy.size)
            }
        }
        .allowsHitTesting(false)
    }

    private func particle(index: Int, size: CGSize) -> some View {
        let phase = progress(index: index)
        let opacity = max(0.0, sin(phase * .pi))
        let baseX = [0.28, 0.38, 0.48, 0.58, 0.68, 0.42, 0.62][index]
        let wave = sin(time * 0.85 + Double(index) * 1.7) * 0.035
        let x = size.width * CGFloat(baseX + wave)
        let y = size.height * CGFloat(0.33 - phase * 0.22 + Double(index % 3) * 0.018)
        let fontSize = CGFloat(18 + (index % 3) * 6)
        let rotation = Double(sin(time + Double(index))) * 8.0

        return particleSymbol(index: index)
            .font(.system(size: fontSize, weight: .bold, design: .rounded))
            .foregroundStyle(particleColor.opacity(opacity * 0.82))
            .shadow(color: particleColor.opacity(opacity * 0.42), radius: 8, x: 0, y: 0)
            .rotationEffect(.degrees(rotation))
            .scaleEffect(0.92 + opacity * 0.18)
            .position(x: x, y: y)
    }

    @ViewBuilder
    private func particleSymbol(index: Int) -> some View {
        switch theme.id {
        case "rain":
            Image(systemName: index.isMultiple(of: 2) ? "drop.fill" : "zzz")
        case "moon":
            Image(systemName: index.isMultiple(of: 2) ? "sparkle" : "moon.fill")
        case "space":
            Image(systemName: index.isMultiple(of: 2) ? "sparkle" : "circle.fill")
        default:
            Text("Z")
        }
    }

    private var particleColor: Color {
        switch theme.id {
        case "rain":
            return Color(red: 0.55, green: 0.82, blue: 1.0)
        case "moon":
            return Color(red: 1.0, green: 0.88, blue: 0.55)
        case "space":
            return Color(red: 1.0, green: 0.86, blue: 0.46)
        default:
            return Color(red: 1.0, green: 0.92, blue: 0.52)
        }
    }

    private func progress(index: Int) -> Double {
        let speed = theme.id == "rain" ? 0.18 : 0.12
        let raw = time * speed + Double(index) * 0.17
        return raw - floor(raw)
    }
}

@MainActor
private final class CatSpriteStore {
    static let frameCount = 6
    static let shared = CatSpriteStore()

    private var cache: [String: [NSImage]] = [:]

    private init() {}

    func image(for theme: BreakTheme, frameIndex: Int) -> NSImage? {
        let frames = frames(for: theme)
        guard !frames.isEmpty else { return nil }
        return frames[frameIndex % frames.count]
    }

    private func frames(for theme: BreakTheme) -> [NSImage] {
        if let frames = cache[theme.id] {
            return frames
        }

        let frames = Self.loadFrames(theme: theme)
        cache[theme.id] = frames
        return frames
    }

    private static func loadFrames(theme: BreakTheme) -> [NSImage] {
        guard let image = loadSpritesheet(theme: theme),
              let sheet = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return []
        }

        let sheetWidth = sheet.width
        let sheetHeight = sheet.height
        let frameWidth = sheetWidth / frameCount
        guard frameWidth > 0 else { return [] }

        let bytesPerPixel = 4
        let bytesPerRow = sheetWidth * bytesPerPixel
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        var pixels = [UInt8](repeating: 0, count: sheetHeight * bytesPerRow)

        guard let context = CGContext(
            data: &pixels,
            width: sheetWidth,
            height: sheetHeight,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: bitmapInfo
        ) else {
            return splitFrames(from: sheet, frameWidth: frameWidth, crop: CGRect(x: 0, y: 0, width: frameWidth, height: sheetHeight))
        }

        context.draw(sheet, in: CGRect(x: 0, y: 0, width: sheetWidth, height: sheetHeight))

        var minX = frameWidth
        var maxX = 0
        var minY = sheetHeight
        var maxY = 0

        for frame in 0..<frameCount {
            let frameStartX = frame * frameWidth

            for y in 0..<sheetHeight {
                for x in 0..<frameWidth {
                    let alphaOffset = y * bytesPerRow + (frameStartX + x) * bytesPerPixel + 3
                    if pixels[alphaOffset] > 16 {
                        minX = min(minX, x)
                        maxX = max(maxX, x)
                        minY = min(minY, y)
                        maxY = max(maxY, y)
                    }
                }
            }
        }

        guard minX <= maxX, minY <= maxY else {
            return splitFrames(from: sheet, frameWidth: frameWidth, crop: CGRect(x: 0, y: 0, width: frameWidth, height: sheetHeight))
        }

        let padX = max(28, Int(Double(frameWidth) * 0.10))
        let padY = max(32, Int(Double(sheetHeight) * 0.12))
        let cropX = max(0, minX - padX)
        let cropY = max(0, minY - padY)
        let cropMaxX = min(frameWidth - 1, maxX + padX)
        let cropMaxY = min(sheetHeight - 1, maxY + padY)
        let crop = CGRect(
            x: cropX,
            y: cropY,
            width: cropMaxX - cropX + 1,
            height: cropMaxY - cropY + 1
        )

        return splitFrames(from: sheet, frameWidth: frameWidth, crop: crop)
    }

    private static func splitFrames(from sheet: CGImage, frameWidth: Int, crop: CGRect) -> [NSImage] {
        (0..<frameCount).compactMap { frame in
            let rect = CGRect(
                x: CGFloat(frame * frameWidth) + crop.origin.x,
                y: crop.origin.y,
                width: crop.width,
                height: crop.height
            )

            guard let cropped = sheet.cropping(to: rect) else { return nil }
            return NSImage(
                cgImage: cropped,
                size: NSSize(width: rect.width, height: rect.height)
            )
        }
    }

    private static func loadSpritesheet(theme: BreakTheme) -> NSImage? {
        if let url = Bundle.main.url(forResource: theme.resourceName, withExtension: "png") {
            return NSImage(contentsOf: url)
        }

        #if SWIFT_PACKAGE
        if let url = Bundle.module.url(forResource: theme.resourceName, withExtension: "png") {
            return NSImage(contentsOf: url)
        }
        #endif

        return nil
    }
}

private struct AnimatedCatView: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let breathing = 1.0 + 0.025 * sin(t * 2.4)
            let headLift = CGFloat(sin(t * 1.3) * 4.0)
            let tailLift = CGFloat(sin(t * 2.2) * 18.0)
            let ringOpacity = 0.18 + 0.12 * sin(t * 1.8)

            GeometryReader { proxy in
                let width = proxy.size.width
                let height = proxy.size.height
                let scale = min(width / 920, height / 520)
                let centerX = width / 2
                let centerY = height / 2 + 32 * scale
                let bodyWidth = 560 * scale
                let bodyHeight = 220 * scale
                let headSize = 190 * scale
                let catColor = Color(red: 0.97, green: 0.69, blue: 0.40)
                let catShadow = Color(red: 0.66, green: 0.34, blue: 0.18)

                ZStack {
                    ForEach(0..<4, id: \.self) { index in
                        Ellipse()
                            .stroke(Color(red: 1.0, green: 0.86, blue: 0.58).opacity(ringOpacity / Double(index + 1)), lineWidth: max(1, 3 * scale))
                            .frame(width: (380 + CGFloat(index) * 72) * scale, height: (110 + CGFloat(index) * 26) * scale)
                            .offset(x: 24 * scale, y: (-18 + CGFloat(index) * -12) * scale)
                            .scaleEffect(1.0 + 0.04 * sin(t * 1.2 + Double(index)))
                    }

                    Path { path in
                        path.move(to: CGPoint(x: centerX + bodyWidth * 0.36, y: centerY - bodyHeight * 0.10))
                        path.addCurve(
                            to: CGPoint(x: centerX + bodyWidth * 0.62, y: centerY - bodyHeight * 0.54 + tailLift),
                            control1: CGPoint(x: centerX + bodyWidth * 0.55, y: centerY - bodyHeight * 0.16),
                            control2: CGPoint(x: centerX + bodyWidth * 0.66, y: centerY - bodyHeight * 0.25 + tailLift)
                        )
                        path.addCurve(
                            to: CGPoint(x: centerX + bodyWidth * 0.72, y: centerY - bodyHeight * 0.10 + tailLift * 0.2),
                            control1: CGPoint(x: centerX + bodyWidth * 0.72, y: centerY - bodyHeight * 0.68 + tailLift),
                            control2: CGPoint(x: centerX + bodyWidth * 0.82, y: centerY - bodyHeight * 0.36 + tailLift)
                        )
                    }
                    .stroke(catColor, style: StrokeStyle(lineWidth: 34 * scale, lineCap: .round, lineJoin: .round))
                    .shadow(color: catShadow.opacity(0.28), radius: 16 * scale, x: 0, y: 10 * scale)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [catColor, Color(red: 0.91, green: 0.51, blue: 0.26)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: bodyWidth, height: bodyHeight)
                        .scaleEffect(x: 1.0, y: breathing)
                        .position(x: centerX, y: centerY)
                        .shadow(color: Color.black.opacity(0.35), radius: 26 * scale, x: 0, y: 24 * scale)

                    Capsule()
                        .fill(Color(red: 0.99, green: 0.78, blue: 0.50).opacity(0.85))
                        .frame(width: bodyWidth * 0.62, height: bodyHeight * 0.62)
                        .position(x: centerX - bodyWidth * 0.04, y: centerY + bodyHeight * 0.10)
                        .scaleEffect(x: 1.0, y: breathing)

                    paw(x: centerX - bodyWidth * 0.24, y: centerY + bodyHeight * 0.38, scale: scale, color: catShadow.opacity(0.82))
                    paw(x: centerX + bodyWidth * 0.18, y: centerY + bodyHeight * 0.40, scale: scale, color: catShadow.opacity(0.82))

                    ZStack {
                        Triangle()
                            .fill(catColor)
                            .frame(width: 68 * scale, height: 82 * scale)
                            .rotationEffect(.degrees(-20))
                            .offset(x: -58 * scale, y: -82 * scale)

                        Triangle()
                            .fill(catColor)
                            .frame(width: 68 * scale, height: 82 * scale)
                            .rotationEffect(.degrees(20))
                            .offset(x: 58 * scale, y: -82 * scale)

                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 1.0, green: 0.73, blue: 0.43), Color(red: 0.88, green: 0.44, blue: 0.23)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: headSize, height: headSize)

                        Circle()
                            .fill(Color(red: 1.0, green: 0.82, blue: 0.62))
                            .frame(width: 94 * scale, height: 72 * scale)
                            .offset(y: 32 * scale)

                        closedEye()
                            .stroke(Color(red: 0.24, green: 0.12, blue: 0.09), lineWidth: max(2, 5 * scale))
                            .frame(width: 48 * scale, height: 26 * scale)
                            .offset(x: -38 * scale, y: -8 * scale)

                        closedEye()
                            .stroke(Color(red: 0.24, green: 0.12, blue: 0.09), lineWidth: max(2, 5 * scale))
                            .frame(width: 48 * scale, height: 26 * scale)
                            .offset(x: 38 * scale, y: -8 * scale)

                        Circle()
                            .fill(Color(red: 0.25, green: 0.11, blue: 0.10))
                            .frame(width: 12 * scale, height: 10 * scale)
                            .offset(y: 24 * scale)

                        Whiskers()
                            .stroke(Color(red: 0.24, green: 0.12, blue: 0.09).opacity(0.7), lineWidth: max(1, 3 * scale))
                            .frame(width: 174 * scale, height: 70 * scale)
                            .offset(y: 36 * scale)
                    }
                    .frame(width: headSize, height: headSize)
                    .position(x: centerX - bodyWidth * 0.40, y: centerY - bodyHeight * 0.32 + headLift)
                    .rotationEffect(.degrees(-3 + sin(t * 1.1) * 1.4))
                    .shadow(color: Color.black.opacity(0.28), radius: 14 * scale, x: 0, y: 12 * scale)
                }
            }
        }
        .accessibilityHidden(true)
    }

    private func paw(x: CGFloat, y: CGFloat, scale: CGFloat, color: Color) -> some View {
        Capsule()
            .fill(color)
            .frame(width: 130 * scale, height: 54 * scale)
            .rotationEffect(.degrees(-3))
            .position(x: x, y: y)
    }

    private func closedEye() -> Path {
        Path { path in
            path.move(to: CGPoint(x: 4, y: 4))
            path.addQuadCurve(to: CGPoint(x: 44, y: 4), control: CGPoint(x: 22, y: 24))
        }
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct Whiskers: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midY = rect.midY
        let left = rect.minX
        let right = rect.maxX
        let midX = rect.midX

        path.move(to: CGPoint(x: midX - 14, y: midY - 8))
        path.addLine(to: CGPoint(x: left, y: midY - 24))
        path.move(to: CGPoint(x: midX - 12, y: midY + 2))
        path.addLine(to: CGPoint(x: left + 2, y: midY + 2))
        path.move(to: CGPoint(x: midX - 14, y: midY + 12))
        path.addLine(to: CGPoint(x: left + 6, y: midY + 24))

        path.move(to: CGPoint(x: midX + 14, y: midY - 8))
        path.addLine(to: CGPoint(x: right, y: midY - 24))
        path.move(to: CGPoint(x: midX + 12, y: midY + 2))
        path.addLine(to: CGPoint(x: right - 2, y: midY + 2))
        path.move(to: CGPoint(x: midX + 14, y: midY + 12))
        path.addLine(to: CGPoint(x: right - 6, y: midY + 24))

        return path
    }
}

private final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private let model = PurrModel(settings: PurrSettings.load())
    private var monitor: YouTubeMonitor?
    private var breakManager: BreakManager?
    private var statusItem: NSStatusItem?
    private var settingsWindow: NSWindow?
    private var browserSettingsWindow: NSWindow?
    private var helpWindow: NSWindow?
    private var postBreakWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        breakManager = BreakManager(
            model: model,
            onFinished: { [weak self] in
                self?.monitor?.resetCounter()
                self?.updateStatusItem()
                self?.showPostBreakChoice()
            },
            onStatusChanged: { [weak self] in
                self?.updateStatusItem()
            }
        )

        monitor = YouTubeMonitor(
            model: model,
            onLimitReached: { [weak self] in
                self?.breakManager?.beginBreak()
            },
            onStatusChanged: { [weak self] in
                self?.updateStatusItem()
            }
        )

        model.onSettingsChanged = { [weak self] settings in
            self?.breakManager?.updateAudioSettings(settings)
            self?.updateStatusItem()
            self?.updateWindowTitles()
        }

        configureStatusItem()
        monitor?.start()

        if UserDefaults.standard.bool(forKey: DefaultsKey.didShowBrowserSetup) {
            showSettings()
        } else {
            showBrowserSettings(isFirstRun: true)
            UserDefaults.standard.set(true, forKey: DefaultsKey.didShowBrowserSetup)
        }
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let image = AppIconStore.resizedImage(size: NSSize(width: 18, height: 18))
            ?? NSImage(systemSymbolName: "pawprint.fill", accessibilityDescription: "PurrBreak")
        image?.isTemplate = false
        item.button?.image = image
        item.button?.title = " Purr"
        item.button?.imagePosition = .imageLeft
        item.button?.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        item.button?.target = self
        item.button?.action = #selector(statusItemClicked)
        statusItem = item
        updateStatusItem()
    }

    private func updateStatusItem() {
        statusItem?.button?.title = " Purr \(model.statusCountdownText)"
        statusItem?.button?.toolTip = model.tr(
            "menu.tooltip",
            model.statusCountdownLabel.lowercased(),
            model.statusCountdownText,
            model.watchedTimeText,
            model.limitText
        )
    }

    @objc private func statusItemClicked() {
        let menu = NSMenu()
        let countdownItem = NSMenuItem(title: "\(model.statusCountdownLabel): \(model.statusCountdownText)", action: nil, keyEquivalent: "")
        countdownItem.isEnabled = false
        menu.addItem(countdownItem)
        menu.addItem(.separator())
        menu.addItem(menuItem(title: model.tr("menu.openSettings"), action: #selector(openSettingsFromMenu)))
        menu.addItem(menuItem(title: model.tr("settings.browserCheck"), action: #selector(openBrowserSettingsFromMenu)))
        menu.addItem(menuItem(title: model.tr("settings.help"), action: #selector(openHelpFromMenu)))
        if model.isPreviewingBreak {
            menu.addItem(menuItem(title: model.tr("settings.testStop"), action: #selector(stopPreviewFromMenu)))
        } else {
            menu.addItem(menuItem(title: model.tr("settings.test"), action: #selector(previewBreakFromMenu)))
        }
        menu.addItem(menuItem(title: model.tr("settings.startBreak"), action: #selector(startBreakFromMenu)))
        menu.addItem(menuItem(title: model.tr("settings.resetCounter"), action: #selector(resetCounterFromMenu)))
        menu.addItem(themeMenuItem())
        menu.addItem(.separator())
        menu.addItem(menuItem(title: model.tr("settings.quit"), action: #selector(quitFromMenu), keyEquivalent: "q"))
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }

    private func menuItem(title: String, action: Selector, keyEquivalent: String = "") -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.target = self
        return item
    }

    private func themeMenuItem() -> NSMenuItem {
        let item = NSMenuItem(title: model.tr("menu.screensaver"), action: nil, keyEquivalent: "")
        let submenu = NSMenu()

        for theme in BreakTheme.all {
            let themeItem = NSMenuItem(title: theme.displayName(language: model.language), action: #selector(selectThemeFromMenu(_:)), keyEquivalent: "")
            themeItem.target = self
            themeItem.representedObject = theme.id
            themeItem.state = model.settings.screensaverThemeID == theme.id ? .on : .off
            submenu.addItem(themeItem)
        }

        item.submenu = submenu
        return item
    }

    @objc private func openSettingsFromMenu() {
        showSettings()
    }

    @objc private func openBrowserSettingsFromMenu() {
        showBrowserSettings()
    }

    @objc private func openHelpFromMenu() {
        showHelp()
    }

    @objc private func previewBreakFromMenu() {
        breakManager?.previewBreak()
    }

    @objc private func stopPreviewFromMenu() {
        breakManager?.stopPreview()
    }

    @objc private func startBreakFromMenu() {
        breakManager?.beginBreak()
    }

    @objc private func resetCounterFromMenu() {
        monitor?.resetCounter()
        updateStatusItem()
    }

    @objc private func selectThemeFromMenu(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String else { return }
        var settings = model.settings
        settings.screensaverThemeID = BreakTheme.matching(id).id
        model.settings = settings
    }

    @objc private func quitFromMenu() {
        NSApp.terminate(nil)
    }

    func windowWillClose(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            self?.updateActivationPolicyForOpenWindows()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag, let window = managedWindows.first(where: { $0.isMiniaturized }) {
            window.deminiaturize(nil)
            presentAppWindow(window)
            return true
        }

        if !flag {
            showSettings()
            return true
        }

        return true
    }

    private var managedWindows: [NSWindow] {
        [settingsWindow, browserSettingsWindow, helpWindow, postBreakWindow].compactMap { $0 }
    }

    private func updateWindowTitles() {
        settingsWindow?.title = "PurrBreak"
        browserSettingsWindow?.title = model.tr("browserCheck.title")
        helpWindow?.title = model.tr("window.help")
        postBreakWindow?.title = model.tr("window.postBreak")
    }

    private func presentAppWindow(_ window: NSWindow) {
        NSApp.setActivationPolicy(.regular)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func updateActivationPolicyForOpenWindows() {
        let hasOpenWindow = managedWindows.contains { window in
            window.isVisible || window.isMiniaturized
        }

        NSApp.setActivationPolicy(hasOpenWindow ? .regular : .accessory)
    }

    private func showSettings() {
        if settingsWindow == nil {
            let view = SettingsView(
                model: model,
                startBreak: { [weak self] in self?.breakManager?.beginBreak() },
                previewBreak: { [weak self] in self?.breakManager?.previewBreak() },
                stopPreview: { [weak self] in self?.breakManager?.stopPreview() },
                resetCounter: { [weak self] in
                    self?.monitor?.resetCounter()
                    self?.updateStatusItem()
                },
                showHelp: { [weak self] in self?.showHelp() },
                showBrowserSettings: { [weak self] in self?.showBrowserSettings() },
                quit: { NSApp.terminate(nil) }
            )

            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 560, height: 590),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.title = "PurrBreak"
            window.contentView = NSHostingView(rootView: view)
            window.delegate = self
            window.center()
            window.isReleasedWhenClosed = false
            settingsWindow = window
        }

        if let settingsWindow {
            presentAppWindow(settingsWindow)
        }
    }

    private func showBrowserSettings(isFirstRun: Bool = false) {
        let view = BrowserSettingsView(
            model: model,
            isFirstRun: isFirstRun,
            openAutomationSettings: { [weak self] in self?.openAutomationSettings() },
            openMainSettings: { [weak self] in self?.showSettings() },
            close: { [weak self] in self?.browserSettingsWindow?.close() }
        )

        if browserSettingsWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 620, height: 560),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.center()
            window.delegate = self
            window.isReleasedWhenClosed = false
            browserSettingsWindow = window
        }

        browserSettingsWindow?.title = isFirstRun ? model.tr("browserCheck.firstTitle") : model.tr("browserCheck.title")
        browserSettingsWindow?.contentView = NSHostingView(rootView: view)
        if let browserSettingsWindow {
            presentAppWindow(browserSettingsWindow)
        }
    }

    private func showHelp() {
        if helpWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 620, height: 620),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.title = model.tr("window.help")
            window.contentView = NSHostingView(rootView: HelpView(model: model))
            window.delegate = self
            window.center()
            window.isReleasedWhenClosed = false
            helpWindow = window
        }

        if let helpWindow {
            presentAppWindow(helpWindow)
        }
    }

    private func showPostBreakChoice() {
        let view = PostBreakView(
            model: model,
            returnToYouTube: { [weak self] in
                self?.closePostBreakWindow()
                self?.activateLastYouTubeBrowser()
            },
            takeMoreBreak: { [weak self] in
                self?.closePostBreakWindow()
                self?.breakManager?.beginBreak(seconds: 120)
            },
            backToWork: { [weak self] in
                self?.closePostBreakWindow()
            }
        )

        if postBreakWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 520, height: 320),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.title = model.tr("window.postBreak")
            window.delegate = self
            window.center()
            window.isReleasedWhenClosed = false
            postBreakWindow = window
        }

        postBreakWindow?.title = model.tr("window.postBreak")
        postBreakWindow?.contentView = NSHostingView(rootView: view)
        postBreakWindow?.center()
        if let postBreakWindow {
            presentAppWindow(postBreakWindow)
        }
    }

    private func closePostBreakWindow() {
        postBreakWindow?.close()
    }

    private func activateLastYouTubeBrowser() {
        guard let bundleID = model.lastYouTubeBundleID,
              let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first else {
            return
        }

        app.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
    }

    private func openAutomationSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") {
            NSWorkspace.shared.open(url)
        } else {
            NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/System Settings.app"))
        }
    }
}

let app = NSApplication.shared
private let delegate = AppDelegate()
app.delegate = delegate
app.run()
