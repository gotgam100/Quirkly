//
//  MainTabView.swift
//  Goofday
//
//  3탭 구조 메인 탭뷰
//

import SwiftUI

struct MainTabView: View {
    @Environment(AppSettings.self) private var settings
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            MainPickView()
                .tabItem {
                    Image(systemName: "dice.fill")
                    Text(settings.language.resolvedIsKorean ? "뽑기" : "Pick")
                }
                .tag(0)

            HistoryView()
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text(settings.language.resolvedIsKorean ? "기록" : "History")
                }
                .tag(1)

            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text(settings.language.resolvedIsKorean ? "설정" : "Settings")
                }
                .tag(2)
        }
        .tint(.goofBlue)
        .padding(.bottom, 8) 
    }
}
