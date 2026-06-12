import AppKit
import AVFoundation
import SwiftUI

private enum DefaultsKey {
    static let watchLimitMinutes = "watchLimitMinutes"
    static let breakMinutes = "breakMinutes"
    static let soundEnabled = "soundEnabled"
    static let purrVolume = "purrVolume"
    static let screensaverThemeID = "screensaverThemeID"
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
}

private struct PurrSettings: Equatable {
    var watchLimitMinutes: Int
    var breakMinutes: Int
    var soundEnabled: Bool
    var purrVolume: Double
    var screensaverThemeID: String

    static func load() -> PurrSettings {
        let defaults = UserDefaults.standard

        let watchLimit = defaults.object(forKey: DefaultsKey.watchLimitMinutes) as? Int ?? 20
        let breakLength = defaults.object(forKey: DefaultsKey.breakMinutes) as? Int ?? 5
        let sound = defaults.object(forKey: DefaultsKey.soundEnabled) as? Bool ?? true
        let volume = defaults.object(forKey: DefaultsKey.purrVolume) as? Double ?? 0.65
        let themeID = defaults.string(forKey: DefaultsKey.screensaverThemeID) ?? BreakTheme.fallback.id

        return PurrSettings(
            watchLimitMinutes: max(1, min(watchLimit, 240)),
            breakMinutes: max(1, min(breakLength, 60)),
            soundEnabled: sound,
            purrVolume: max(0.0, min(volume, 1.0)),
            screensaverThemeID: BreakTheme.matching(themeID).id
        )
    }

    func save() {
        let defaults = UserDefaults.standard
        defaults.set(watchLimitMinutes, forKey: DefaultsKey.watchLimitMinutes)
        defaults.set(breakMinutes, forKey: DefaultsKey.breakMinutes)
        defaults.set(soundEnabled, forKey: DefaultsKey.soundEnabled)
        defaults.set(purrVolume, forKey: DefaultsKey.purrVolume)
        defaults.set(screensaverThemeID, forKey: DefaultsKey.screensaverThemeID)
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
    @Published var isWatchingYouTube = false
    @Published var activeBrowserName = "Браузер не найден"
    @Published var currentURL = ""
    @Published var monitorMessage = "Готов следить за YouTube"
    @Published var isOnBreak = false
    @Published var isPreviewingBreak = false
    @Published var breakRemainingSeconds = 0
    @Published var browserStatuses: [BrowserStatus]

    var onSettingsChanged: ((PurrSettings) -> Void)?

    init(settings: PurrSettings) {
        self.settings = settings
        self.browserStatuses = BrowserStatus.initialStatuses()
    }

    var watchLimitSeconds: Int {
        settings.watchLimitMinutes * 60
    }

    var progress: Double {
        guard watchLimitSeconds > 0 else { return 0 }
        return min(1.0, Double(watchedSeconds) / Double(watchLimitSeconds))
    }

    var watchedTimeText: String {
        Self.clockText(seconds: watchedSeconds)
    }

    var limitText: String {
        Self.clockText(seconds: watchLimitSeconds)
    }

    var remainingUntilBreakSeconds: Int {
        max(0, watchLimitSeconds - watchedSeconds)
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
            return "До конца паузы"
        }

        if isPreviewingBreak {
            return "До конца теста"
        }

        return "До заставки"
    }

    var selectedTheme: BreakTheme {
        BreakTheme.matching(settings.screensaverThemeID)
    }

    static func clockText(seconds: Int) -> String {
        let clamped = max(0, seconds)
        return String(format: "%02d:%02d", clamped / 60, clamped % 60)
    }

    func markBrowserConnected(bundleID: String, displayName: String) {
        updateBrowserStatus(bundleID: bundleID) { status in
            status.state = .connected
            status.detail = "URL активной вкладки читается."
        }
    }

    func markBrowserNeedsPermission(bundleID: String, displayName: String, message: String) {
        updateBrowserStatus(bundleID: bundleID) { status in
            status.state = .needsPermission
            status.detail = message
        }
    }

    func markBrowserUnsupported(bundleID: String, displayName: String) {
        updateBrowserStatus(bundleID: bundleID) { status in
            status.state = .unsupported
            status.detail = "\(displayName) пока лучше подключать через расширение или отдельный fallback."
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

private struct BrowserStatus: Identifiable, Equatable {
    let id: String
    let displayName: String
    let bundleID: String
    let isInstalled: Bool
    let canReadURL: Bool
    var state: BrowserConnectionState
    var detail: String

    var stateText: String {
        switch state {
        case .notInstalled:
            return "Не найден"
        case .waiting:
            return "Ожидает проверки"
        case .connected:
            return "Подключен"
        case .needsPermission:
            return "Нужен доступ"
        case .unsupported:
            return "Пока не поддерживается"
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
            let detail: String

            if !isInstalled {
                state = .notInstalled
                detail = "Приложение не найдено на этом Mac."
            } else if !descriptor.canReadURL {
                state = .unsupported
                detail = "Нужен отдельный способ отслеживания, например расширение."
            } else {
                state = .waiting
                detail = "Открой YouTube в этом браузере, чтобы macOS запросила доступ."
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
            return "\(browserName): пока не умею читать URL активной вкладки"
        }
    }
}

private final class BrowserURLReader {
    func frontmostSnapshot() -> Result<BrowserSnapshot?, BrowserReadError> {
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
                message: errorMessage(from: error, browserName: browser.displayName)
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

    private func errorMessage(from error: NSDictionary?, browserName: String) -> String {
        if let message = error?[NSAppleScript.errorMessage] as? String, !message.isEmpty {
            return "\(browserName): \(message)"
        }

        return "\(browserName): macOS пока не дала доступ к активной вкладке"
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
        model.watchedSeconds = 0
    }

    private func tick() {
        let now = Date()
        let elapsed = max(1, Int(now.timeIntervalSince(lastTickDate).rounded()))
        lastTickDate = now

        guard !model.isOnBreak else {
            model.isWatchingYouTube = false
            model.monitorMessage = "Идет пауза"
            return
        }

        switch reader.frontmostSnapshot() {
        case .success(let snapshot):
            update(with: snapshot, elapsed: elapsed)
        case .failure(let error):
            model.isWatchingYouTube = false
            model.currentURL = ""

            switch error {
            case .browserError(let bundleID, let browserName, let message):
                model.activeBrowserName = browserName
                model.markBrowserNeedsPermission(bundleID: bundleID, displayName: browserName, message: message)
                model.monitorMessage = "Нужен доступ Automation: \(message)"
            case .unsupported(let bundleID, let browserName):
                model.activeBrowserName = browserName
                model.markBrowserUnsupported(bundleID: bundleID, displayName: browserName)
                model.monitorMessage = "\(browserName) пока не поддерживается"
            }
        }

        onStatusChanged?()
    }

    private func update(with snapshot: BrowserSnapshot?, elapsed: Int) {
        guard let snapshot else {
            model.isWatchingYouTube = false
            model.currentURL = ""
            model.activeBrowserName = "Браузер не на переднем плане"
            model.monitorMessage = "Жду активный YouTube"
            return
        }

        model.activeBrowserName = snapshot.browserName
        model.currentURL = snapshot.url
        model.markBrowserConnected(bundleID: snapshot.bundleID, displayName: snapshot.browserName)

        if Self.isYouTubeURL(snapshot.url) {
            model.isWatchingYouTube = true
            model.watchedSeconds += elapsed
            model.monitorMessage = "YouTube активен"

            if model.watchedSeconds >= model.watchLimitSeconds {
                onLimitReached?()
            }
        } else {
            model.isWatchingYouTube = false
            model.monitorMessage = snapshot.url.isEmpty ? "Вкладка без адреса" : "Сейчас не YouTube"
        }
    }

    private static func isYouTubeURL(_ rawURL: String) -> Bool {
        guard let components = URLComponents(string: rawURL.lowercased()),
              let host = components.host else {
            return false
        }

        let normalizedHost = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
        return normalizedHost == "youtube.com"
            || normalizedHost.hasSuffix(".youtube.com")
            || normalizedHost == "youtu.be"
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
    private var onFinished: (() -> Void)?
    private var onStatusChanged: (() -> Void)?

    init(model: PurrModel, onFinished: @escaping () -> Void, onStatusChanged: @escaping () -> Void) {
        self.model = model
        self.onFinished = onFinished
        self.onStatusChanged = onStatusChanged
    }

    func beginBreak() {
        guard !model.isOnBreak else { return }

        closePreview()

        let seconds = max(60, model.settings.breakMinutes * 60)
        model.isOnBreak = true
        model.breakRemainingSeconds = seconds
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

        windows.forEach { $0.close() }
        windows.removeAll()

        onFinished?()
    }

    private func closePreview() {
        previewTimer?.invalidate()
        previewTimer = nil
        previewEndDate = nil
        model.isPreviewingBreak = false
        stopPreviewKeyMonitors()
        previewWindows.forEach { $0.close() }
        previewWindows.removeAll()

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
            window.hidesOnDeactivate = false
            window.canHide = false
            window.orderFrontRegardless()
            createdWindows.append(window)
        }

        return createdWindows
    }

    private func startPreviewKeyMonitors() {
        stopPreviewKeyMonitors()

        previewLocalKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 {
                self?.closePreview()
                return nil
            }

            return event
        }

        previewGlobalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 {
                DispatchQueue.main.async {
                    self?.closePreview()
                }
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

private struct SettingsView: View {
    @ObservedObject var model: PurrModel
    let startBreak: () -> Void
    let previewBreak: () -> Void
    let stopPreview: () -> Void
    let resetCounter: () -> Void
    let showHelp: () -> Void
    let openAutomationSettings: () -> Void
    let quit: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .center, spacing: 14) {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 34, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(Color.accentColor)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("PurrBreak")
                            .font(.system(size: 28, weight: .bold))
                        Text("Мягкий тайм-аут для YouTube")
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(model.isWatchingYouTube ? "YouTube идет" : "YouTube не активен")
                            .font(.headline)
                        Spacer()
                        Text("\(model.statusCountdownLabel): \(model.statusCountdownText)")
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }

                    ProgressView(value: model.progress)
                        .progressViewStyle(.linear)

                    HStack {
                        Text("Просмотрено")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(model.watchedTimeText) / \(model.limitText)")
                            .font(.system(.footnote, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }

                    Text(model.monitorMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Divider()

                BrowserStatusPanel(
                    statuses: model.browserStatuses,
                    openAutomationSettings: openAutomationSettings
                )

                Divider()

                VStack(alignment: .leading, spacing: 14) {
                    Picker("Заставка", selection: binding(\.screensaverThemeID)) {
                        ForEach(BreakTheme.all) { theme in
                            Text(theme.displayName).tag(theme.id)
                        }
                    }
                    .pickerStyle(.menu)

                    Stepper(value: binding(\.watchLimitMinutes), in: 1...240) {
                        settingRow(title: "Лимит YouTube", value: "\(model.settings.watchLimitMinutes) мин")
                    }

                    Stepper(value: binding(\.breakMinutes), in: 1...60) {
                        settingRow(title: "Длина паузы", value: "\(model.settings.breakMinutes) мин")
                    }

                    Toggle("Мурчание во время паузы", isOn: binding(\.soundEnabled))

                    VStack(alignment: .leading, spacing: 6) {
                        settingRow(title: "Громкость мурчания", value: "\(Int(model.settings.purrVolume * 100))%")
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
                            model.isPreviewingBreak ? "Остановить тест" : "Тест заставки",
                            systemImage: model.isPreviewingBreak ? "stop.circle.fill" : "play.display"
                        )
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.escape, modifiers: [])

                    Button {
                        startBreak()
                    } label: {
                        Label("Блокировка сейчас", systemImage: "moon.zzz.fill")
                    }

                    Button {
                        resetCounter()
                    } label: {
                        Label("Сбросить счетчик", systemImage: "arrow.counterclockwise")
                    }

                    Spacer()

                    Button {
                        showHelp()
                    } label: {
                        Label("Справка", systemImage: "questionmark.circle")
                    }

                    Button {
                        quit()
                    } label: {
                        Label("Выйти", systemImage: "xmark.circle")
                    }
                }
            }
            .padding(24)
            .frame(width: 640)
        }
        .frame(width: 640, height: 680)
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

private struct BrowserStatusPanel: View {
    let statuses: [BrowserStatus]
    let openAutomationSettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Браузеры", systemImage: "globe")
                    .font(.headline)

                Spacer()

                Button {
                    openAutomationSettings()
                } label: {
                    Label("Automation", systemImage: "gearshape")
                }
            }

            Text("Статус обновляется после попытки прочитать активную вкладку. Открой YouTube в браузере, чтобы проверить подключение.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 8) {
                ForEach(statuses) { status in
                    BrowserStatusRow(status: status)
                }
            }
        }
    }
}

private struct BrowserStatusRow: View {
    let status: BrowserStatus

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

                    Text(status.stateText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Text(status.detail)
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
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 12) {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(Color.accentColor)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Как работает PurrBreak")
                            .font(.system(size: 26, weight: .bold))
                        Text("Коротко о счетчике, паузах и разрешениях")
                            .foregroundStyle(.secondary)
                    }
                }

                helpSection(
                    title: "Что считает приложение",
                    icon: "timer",
                    text: "PurrBreak каждую секунду смотрит, какой браузер сейчас активен, и читает URL активной вкладки. Счетчик идет только если активная вкладка открыта на youtube.com или youtu.be."
                )

                helpSection(
                    title: "Когда появляется заставка",
                    icon: "moon.zzz.fill",
                    text: "Когда накоплен лимит просмотра, приложение показывает полноэкранную паузу с выбранной заставкой. По умолчанию лимит 20 минут, пауза 5 минут. После завершения паузы счетчик сбрасывается."
                )

                helpSection(
                    title: "Зачем нужен Automation",
                    icon: "lock.shield",
                    text: "macOS требует разрешение Automation, чтобы приложение могло спросить браузер об адресе активной вкладки. PurrBreak не читает историю, пароли, содержимое страниц или личные данные."
                )

                helpSection(
                    title: "Статусы браузеров",
                    icon: "checklist",
                    text: "В настройках есть список браузеров. Он показывает, найден ли браузер на этом Mac, получилось ли прочитать активную вкладку или нужно открыть системные настройки Automation."
                )

                helpSection(
                    title: "Какие браузеры поддерживаются",
                    icon: "globe",
                    text: "Safari, Chrome, Yandex Browser, Brave, Edge, Arc, Chromium, Vivaldi и Opera. Firefox виден в списке, но текущий AppleScript-способ не умеет надежно читать его активную вкладку; для него лучше подойдет отдельное расширение."
                )

                helpSection(
                    title: "Тест заставки",
                    icon: "play.display",
                    text: "Тест показывает оверлей примерно на 20 секунд, но клики проходят сквозь него. Закрыть тест можно кнопкой Остановить тест, из меню-бара или клавишей Esc, если macOS передала ее приложению."
                )

                helpSection(
                    title: "Что приложение не делает",
                    icon: "hand.raised",
                    text: "PurrBreak не блокирует сайты на уровне сети, не следит за всеми приложениями и не отправляет данные наружу. Это мягкий локальный таймер для YouTube-пауз."
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

private enum OverlayMode {
    case `break`
    case preview

    var title: String {
        switch self {
        case .break:
            return "Пять минут перезагрузки"
        case .preview:
            return "Тест заставки"
        }
    }

    var message: String {
        switch self {
        case .break:
            return "Кот занял экран. YouTube подождет."
        case .preview:
            return "Это предпросмотр: клики проходят сквозь оверлей. Esc закрывает."
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
                    Text(mode.title)
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white)
                        .multilineTextAlignment(.center)

                    Text(PurrModel.clockText(seconds: model.breakRemainingSeconds))
                        .font(.system(size: 72, weight: .heavy, design: .monospaced))
                        .foregroundStyle(Color(red: 1.0, green: 0.82, blue: 0.55))
                        .monospacedDigit()

                    Text(mode.message)
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

private final class AppDelegate: NSObject, NSApplicationDelegate {
    private let model = PurrModel(settings: PurrSettings.load())
    private var monitor: YouTubeMonitor?
    private var breakManager: BreakManager?
    private var statusItem: NSStatusItem?
    private var settingsWindow: NSWindow?
    private var helpWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        breakManager = BreakManager(
            model: model,
            onFinished: { [weak self] in
                self?.monitor?.resetCounter()
                self?.updateStatusItem()
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
        }

        configureStatusItem()
        monitor?.start()
        showSettings()
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let image = NSImage(systemSymbolName: "pawprint.fill", accessibilityDescription: "PurrBreak")
        image?.isTemplate = true
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
        statusItem?.button?.toolTip = "PurrBreak: \(model.statusCountdownLabel.lowercased()) \(model.statusCountdownText). Просмотрено \(model.watchedTimeText) / \(model.limitText)"
    }

    @objc private func statusItemClicked() {
        let menu = NSMenu()
        let countdownItem = NSMenuItem(title: "\(model.statusCountdownLabel): \(model.statusCountdownText)", action: nil, keyEquivalent: "")
        countdownItem.isEnabled = false
        menu.addItem(countdownItem)
        menu.addItem(.separator())
        menu.addItem(menuItem(title: "Открыть настройки", action: #selector(openSettingsFromMenu)))
        menu.addItem(menuItem(title: "Справка", action: #selector(openHelpFromMenu)))
        menu.addItem(menuItem(title: "Разрешения браузеров", action: #selector(openAutomationFromMenu)))
        if model.isPreviewingBreak {
            menu.addItem(menuItem(title: "Остановить тест", action: #selector(stopPreviewFromMenu)))
        } else {
            menu.addItem(menuItem(title: "Тест заставки", action: #selector(previewBreakFromMenu)))
        }
        menu.addItem(menuItem(title: "Блокировка сейчас", action: #selector(startBreakFromMenu)))
        menu.addItem(menuItem(title: "Сбросить счетчик", action: #selector(resetCounterFromMenu)))
        menu.addItem(themeMenuItem())
        menu.addItem(.separator())
        menu.addItem(menuItem(title: "Выйти", action: #selector(quitFromMenu), keyEquivalent: "q"))
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
        let item = NSMenuItem(title: "Заставка", action: nil, keyEquivalent: "")
        let submenu = NSMenu()

        for theme in BreakTheme.all {
            let themeItem = NSMenuItem(title: theme.displayName, action: #selector(selectThemeFromMenu(_:)), keyEquivalent: "")
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

    @objc private func openHelpFromMenu() {
        showHelp()
    }

    @objc private func openAutomationFromMenu() {
        openAutomationSettings()
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
                openAutomationSettings: { [weak self] in self?.openAutomationSettings() },
                quit: { NSApp.terminate(nil) }
            )

            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 640, height: 680),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.title = "PurrBreak"
            window.contentView = NSHostingView(rootView: view)
            window.center()
            window.isReleasedWhenClosed = false
            settingsWindow = window
        }

        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func showHelp() {
        if helpWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 620, height: 620),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.title = "Справка PurrBreak"
            window.contentView = NSHostingView(rootView: HelpView())
            window.center()
            window.isReleasedWhenClosed = false
            helpWindow = window
        }

        helpWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
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
