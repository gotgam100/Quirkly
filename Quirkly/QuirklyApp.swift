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
        let schema = Schema([
            QuirkyTask.self,
            QuirkyRecord.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    @State private var settings = AppSettings()
    @State private var repository = TaskRepository()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(settings)
                .environment(repository)
                .preferredColorScheme(colorScheme)
                .onAppear {
                    if settings.notificationEnabled {
                        NotificationManager.shared.requestPermission()
                        NotificationManager.shared.scheduleDailyReminder(
                            hour: settings.notificationHour,
                            minute: settings.notificationMinute,
                            isKorean: settings.language.resolvedIsKorean
                        )
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }
    
    private var colorScheme: ColorScheme? {
        switch settings.theme {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
