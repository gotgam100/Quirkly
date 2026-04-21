//
//  AppSettings.swift
//  Quirkly
//
//  앱 설정 모델
//

import Foundation
import WidgetKit

// MARK: - 언어 설정

enum AppLanguage: String, Codable, CaseIterable, Identifiable {
    case korean = "korean"
    case english = "english"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .korean: return "한국어"
        case .english: return "English"
        }
    }

    var resolvedIsKorean: Bool {
        switch self {
        case .korean: return true
        case .english: return false
        }
    }
}

// MARK: - 테마 설정

enum AppTheme: String, Codable, CaseIterable, Identifiable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var id: String { rawValue }
    
    var displayNameKo: String {
        switch self {
        case .system: return "시스템"
        case .light: return "라이트"
        case .dark: return "다크"
        }
    }
    
    var displayNameEn: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

// MARK: - AppSettings

@Observable
final class AppSettings {

    private let defaults = UserDefaults.standard
    
    // MARK: - Keys
    private enum Keys {
        static let language = "quirkly_language"
        static let theme = "quirkly_theme"
        static let notificationEnabled = "quirkly_notification_enabled"
        static let notificationHour = "quirkly_notification_hour"
        static let notificationMinute = "quirkly_notification_minute"
        static let totalCompleted = "quirkly_total_completed"
        static let longestStreak = "quirkly_longest_streak"
        static let lastSyncDate = "quirkly_last_sync_date"
        static let iCloudSyncEnabled = "quirkly_icloud_sync"
        static let currentTaskId = "quirkly_current_task_id"
        static let currentTaskDate = "quirkly_current_task_date"
        static let isTaskDecided = "quirkly_is_task_decided"
    }
    
    // MARK: - Properties
    
    var language: AppLanguage {
        didSet {
            defaults.set(language.rawValue, forKey: Keys.language)
            UserDefaults(suiteName: "group.baekmac.quirkly")?.set(language.rawValue, forKey: Keys.language)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    var theme: AppTheme {
        didSet { defaults.set(theme.rawValue, forKey: Keys.theme) }
    }

    var notificationEnabled: Bool {
        didSet { defaults.set(notificationEnabled, forKey: Keys.notificationEnabled) }
    }

    var notificationHour: Int {
        didSet { defaults.set(notificationHour, forKey: Keys.notificationHour) }
    }

    var notificationMinute: Int {
        didSet { defaults.set(notificationMinute, forKey: Keys.notificationMinute) }
    }

    var lastSyncDate: Date? {
        didSet { defaults.set(lastSyncDate, forKey: Keys.lastSyncDate) }
    }

    var iCloudSyncEnabled: Bool {
        didSet { defaults.set(iCloudSyncEnabled, forKey: Keys.iCloudSyncEnabled) }
    }

    var currentTaskId: Int {
        didSet { defaults.set(currentTaskId, forKey: Keys.currentTaskId) }
    }

    var currentTaskDate: Date? {
        didSet { defaults.set(currentTaskDate, forKey: Keys.currentTaskDate) }
    }

    var isTaskDecided: Bool {
        didSet { defaults.set(isTaskDecided, forKey: Keys.isTaskDecided) }
    }

    // MARK: - Init

    init() {
        self.language = AppLanguage(rawValue: defaults.string(forKey: Keys.language) ?? "") ?? .korean
        self.theme = .light
        self.notificationEnabled = defaults.bool(forKey: Keys.notificationEnabled)
        self.notificationHour = defaults.object(forKey: Keys.notificationHour) == nil ? 8 : defaults.integer(forKey: Keys.notificationHour)
        self.notificationMinute = defaults.object(forKey: Keys.notificationMinute) == nil ? 0 : defaults.integer(forKey: Keys.notificationMinute)
        self.lastSyncDate = defaults.object(forKey: Keys.lastSyncDate) as? Date
        self.iCloudSyncEnabled = defaults.object(forKey: Keys.iCloudSyncEnabled) == nil ? false : defaults.bool(forKey: Keys.iCloudSyncEnabled)
        self.currentTaskId = defaults.object(forKey: Keys.currentTaskId) == nil ? 0 : defaults.integer(forKey: Keys.currentTaskId)
        self.currentTaskDate = defaults.object(forKey: Keys.currentTaskDate) as? Date
        self.isTaskDecided = defaults.object(forKey: Keys.isTaskDecided) == nil ? false : defaults.bool(forKey: Keys.isTaskDecided)

        // Init Notification Delegate automatically
        _ = NotificationManager.shared
    }
}

// MARK: - 알림 관리자 (Notification Manager)

import UserNotifications

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted.")
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
    
    func scheduleDailyReminder(hour: Int, minute: Int, isKorean: Bool) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        
        let content = UNMutableNotificationContent()
        content.title = isKorean ? "🎲 오늘의 엉뚱한 일을 뽑아볼까요?" : "🎲 Time for your Quirky task!"
        content.body = isKorean ? "일상을 깨울 작은 엉뚱함을 하나 실천해 보세요!" : "Pick a quirky task to spice up your day!"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "quirkly.daily.reminder", content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error.localizedDescription)")
            } else {
                print("Daily reminder scheduled at \(hour):\(String(format: "%02d", minute))")
            }
        }
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
