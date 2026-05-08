//
//  QuirklyApp.swift
//  Quirkly
//
//  Created by BAEKMAC on 4/14/26.
//

import SwiftUI
import SwiftData
import CoreText

@main
struct QuirklyApp: App {

    init() {
        QuirklyApp.registerFonts()
    }

    private static func registerFonts() {
        // 번들 내 모든 .otf 폰트를 자동 등록 (subdirectory 무관)
        for ext in ["otf", "ttf"] {
            if let urls = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: nil) {
                for url in urls {
                    CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
                }
            }
            // Resources 하위 폴더도 탐색
            if let urls = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: "Resources") {
                for url in urls {
                    CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
                }
            }
        }
        applyNavigationBarAppearance()
    }

    private static func applyNavigationBarAppearance() {
        // Large title: 기본 시스템 폰트
        let largeTitleFont = UIFont.systemFont(ofSize: 34, weight: .bold)
        let inlineTitleFont = UIFont.systemFont(ofSize: 18, weight: .semibold)

        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.largeTitleTextAttributes = [.font: largeTitleFont]
        appearance.titleTextAttributes = [.font: inlineTitleFont]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([QuirkyTask.self, QuirkyRecord.self])
        let isICloudEnabled = UserDefaults.standard.bool(forKey: ICloudSyncService.iCloudEnabledKey)

        do {
            if isICloudEnabled {
                let config = ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
                return try ModelContainer(for: schema, configurations: [config])
            } else {
                let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
                return try ModelContainer(for: schema, configurations: [config])
            }
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    @State private var settings = AppSettings()
    @State private var repository = TaskRepository()
    @State private var showWhatsNew = false

    private let currentVersion = "1.1.0"
    private let lastSeenVersionKey = "quirkly_last_seen_version"

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(settings)
                .environment(repository)
                .preferredColorScheme(colorScheme)
                .onAppear {
                    // iCloud 전환 후 기록 마이그레이션
                    ICloudSyncService.performPendingMigration(container: sharedModelContainer)

                    if settings.notificationEnabled {
                        NotificationManager.shared.requestPermission()
                        NotificationManager.shared.scheduleDailyReminder(
                            hour: settings.notificationHour,
                            minute: settings.notificationMinute,
                            isKorean: settings.language.resolvedIsKorean
                        )
                    }
                    checkWhatsNew()
                }
                .sheet(isPresented: $showWhatsNew) {
                    WhatsNewView(isKorean: settings.language.resolvedIsKorean) {
                        UserDefaults.standard.set(currentVersion, forKey: lastSeenVersionKey)
                        showWhatsNew = false
                    }
                    .presentationDetents([.large])
                    .interactiveDismissDisabled(true)
                }
        }
        .modelContainer(sharedModelContainer)
    }

    private func checkWhatsNew() {
        let lastSeen = UserDefaults.standard.string(forKey: lastSeenVersionKey) ?? ""
        if lastSeen != currentVersion {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                showWhatsNew = true
            }
        }
    }
    
    private var colorScheme: ColorScheme? {
        switch settings.theme {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
