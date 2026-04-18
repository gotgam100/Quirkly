//
//  SettingsView.swift
//  Goofday
//
//  설정 화면 — 언어, 테마, 알림, 통계, 동기화
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) private var settings
    @Environment(TaskRepository.self) private var repository

    @Query private var allRecords: [GoofyRecord]
    
    @State private var showResetAlert = false
    @State private var showSyncSuccess = false
    @State private var streak = 0
    @State private var reminderTime: Date = Date()
    
    private var isKorean: Bool { settings.language.resolvedIsKorean }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.goofBgLight.ignoresSafeArea()
                
                List {
                    // 언어
                    languageSection

                    // 알림
                    notificationSection

                    // 콘텐츠 동기화
                    syncSection

                    // 나의 기록
                    statsSection

                    // 위험 영역
                    dangerSection

                    // 앱 정보
                    aboutSection
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .padding(.top, -8)
            }
            .navigationTitle(isKorean ? "설정" : "Settings")
            .navigationBarTitleDisplayMode(.large)
            .task { updateStreak() }
            .alert(
                isKorean ? "기록 초기화" : "Reset Records",
                isPresented: $showResetAlert
            ) {
                Button(isKorean ? "취소" : "Cancel", role: .cancel) {}
                Button(isKorean ? "초기화" : "Reset", role: .destructive) {
                    resetAllRecords()
                }
            } message: {
                Text(isKorean ? "모든 기록이 삭제됩니다. 이 작업은 되돌릴 수 없습니다." : "All records will be deleted. This cannot be undone.")
            }
        }
    }
    
    // MARK: - 언어
    
    private var languageSection: some View {
        Section {
            @Bindable var s = settings
            Picker(isKorean ? "🌐 언어" : "🌐 Language", selection: $s.language) {
                ForEach(AppLanguage.allCases) { lang in
                    Text(lang.displayName).tag(lang)
                }
            }
        } header: {
            Text(isKorean ? "일반" : "General")
        }
        .listRowBackground(Color.goofSurface.opacity(0.5))
    }
    
    // MARK: - 알림
    
    private var notificationSection: some View {
        Section {
            @Bindable var s = settings
            Toggle(isKorean ? "🔔 매일 알림" : "🔔 Daily Reminder", isOn: $s.notificationEnabled)
                .tint(.goofGreen)
                .onChange(of: settings.notificationEnabled) { oldValue, newValue in
                    if newValue {
                        NotificationManager.shared.requestPermission()
                        NotificationManager.shared.scheduleDailyReminder(hour: settings.notificationHour, minute: settings.notificationMinute, isKorean: isKorean)
                    } else {
                        NotificationManager.shared.cancelAllNotifications()
                    }
                }
            
            if settings.notificationEnabled {
                DatePicker(isKorean ? "⏰ 알림 시간" : "⏰ Reminder Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    .onChange(of: reminderTime) { oldValue, newValue in
                        let calendar = Calendar.current
                        settings.notificationHour = calendar.component(.hour, from: newValue)
                        settings.notificationMinute = calendar.component(.minute, from: newValue)
                        
                        NotificationManager.shared.scheduleDailyReminder(hour: settings.notificationHour, minute: settings.notificationMinute, isKorean: isKorean)
                    }
                    .onAppear {
                        var components = DateComponents()
                        components.hour = settings.notificationHour
                        components.minute = settings.notificationMinute
                        if let date = Calendar.current.date(from: components) {
                            reminderTime = date
                        }
                    }
            }
        } header: {
            Text(isKorean ? "알림" : "Notifications")
        }
        .listRowBackground(Color.goofSurface.opacity(0.5))
    }
    
    // MARK: - 동기화
    
    private var syncSection: some View {
        Section {
            Button {
                Task {
                    await repository.syncFromGoogleSheets(modelContext: modelContext)
                    if repository.lastError == nil {
                        settings.lastSyncDate = Date()
                        showSyncSuccess = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showSyncSuccess = false
                        }
                    }
                }
            } label: {
                HStack {
                    Text(isKorean ? "📡 엉뚱한 일 새로고침" : "📡 Refresh Goofy Tasks")
                        .foregroundStyle(Color.goofBlue)
                    Spacer()
                    if repository.isLoading {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(Color.goofBlue)
                    }
                }
            }
            @Bindable var s = settings
            Toggle(isOn: $s.iCloudSyncEnabled) {
                Text(isKorean ? "☁️ 내 정보 iCloud 동기화" : "☁️ iCloud Sync My Info")
                    .foregroundStyle(Color.goofTextDark)
            }
            .tint(.goofBlue)
            .disabled(repository.isLoading)
            
            if let error = repository.lastError {
                Text("⚠️ \(error)")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            
            if showSyncSuccess {
                Text(isKorean ? "✅ \(repository.taskCount)개 미션 로드 완료!" : "✅ \(repository.taskCount) missions loaded!")
                    .font(.caption)
                    .foregroundStyle(Color.goofGreen)
            }
            
            if let lastSync = settings.lastSyncDate {
                HStack {
                    Text(isKorean ? "마지막 새로고침 (미션)" : "Last Tasks Refresh")
                        .font(.caption)
                        .foregroundStyle(Color.goofTextDark.opacity(0.5))
                    Spacer()
                    Text(lastSync, style: .time)
                        .font(.caption)
                        .foregroundStyle(Color.goofTextDark.opacity(0.5))
                }
            }
        } header: {
            Text(isKorean ? "데이터 연동" : "Data & Sync")
        }
        .listRowBackground(Color.goofSurface.opacity(0.5))
    }
    
    // MARK: - 통계
    
    private var statsSection: some View {
        Section {
            HStack {
                Text(isKorean ? "📊 총 완료한 미션" : "📊 Total Completed")
                Spacer()
                Text("\(allRecords.filter { $0.status == .completed }.count)")
                    .font(.system(.body, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.goofGreen)
            }
            HStack {
                Text(isKorean ? "🔥 최장 연속" : "🔥 Current Streak")
                Spacer()
                Text(isKorean ? "\(streak)일" : "\(streak) days")
                    .font(.system(.body, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.goofRed)
            }

        } header: {
            Text(isKorean ? "나의 기록" : "My Stats")
        }
        .listRowBackground(Color.goofSurface.opacity(0.5))
    }
    
    // MARK: - 위험 영역
    
    private var dangerSection: some View {
        Section {
            Button(role: .destructive) {
                showResetAlert = true
            } label: {
                HStack {
                    Text(isKorean ? "🗑 기록 초기화" : "🗑 Reset All Records")
                        .foregroundStyle(.red)
                    Spacer()
                }
            }
        }
        .listRowBackground(Color.goofSurface.opacity(0.5))
    }
    
    // MARK: - 앱 정보
    
    private var aboutSection: some View {
        Section {
            HStack {
                Text(isKorean ? "ℹ️ 앱 버전" : "ℹ️ App Version")
                Spacer()
                Text("1.0.0")
                    .foregroundStyle(Color.goofTextDark.opacity(0.5))
            }
            HStack {
                Text(isKorean ? "🎲 앱 이름" : "🎲 App Name")
                Spacer()
                Text("Goofday")
                    .foregroundStyle(Color.goofTextDark.opacity(0.5))
            }
        } header: {
            Text(isKorean ? "앱 정보" : "About")
        }
        .listRowBackground(Color.goofSurface.opacity(0.5))
    }
    
    // MARK: - Actions
    
    private func resetAllRecords() {
        try? modelContext.delete(model: GoofyRecord.self)
        try? modelContext.save()
        updateStreak()
    }
    
    private func updateStreak() {
        streak = repository.currentStreak(modelContext: modelContext)
    }
}
