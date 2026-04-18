//
//  SettingsView.swift
//  Quirkly
//
//  설정 화면 — 언어, 테마, 알림, 통계, 동기화
//

import SwiftUI
import SwiftData
import MessageUI
import StoreKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) private var settings
    @Environment(TaskRepository.self) private var repository

    @Query private var allRecords: [QuirkyRecord]
    
    @State private var showResetAlert = false
    @State private var showSyncSuccess = false
    @State private var streak = 0
    @State private var reminderTime: Date = Date()
    @State private var showMailComposer = false
    @State private var mailResult: Result<MFMailComposeResult, Error>?
    @Environment(\.requestReview) var requestReview
    
    private var isKorean: Bool { settings.language.resolvedIsKorean }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.quirklyBgLight.ignoresSafeArea()
                
                List {
                    // 일반
                    languageSection

                    // 알림
                    notificationSection

                    // 나의 기록
                    statsSection

                    // 기록 초기화
                    dangerSection

                    // 함께하기
                    ideaSection

                    // 데이터 연동
                    syncSection

                    // 앱 정보
                    aboutSection

                    // 이용약관 및 정책
                    policySection
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
        .listRowBackground(Color.quirkySurface.opacity(0.5))
    }
    
    // MARK: - 알림
    
    private var notificationSection: some View {
        Section {
            @Bindable var s = settings
            Toggle(isKorean ? "🔔 매일 알림" : "🔔 Daily Reminder", isOn: $s.notificationEnabled)
                .tint(.quirklyGreen)
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
        .listRowBackground(Color.quirkySurface.opacity(0.5))
    }

    // MARK: - 함께하기 (아이디어, 응원, 커피)

    private var ideaSection: some View {
        Section {
            // 아이디어 등록
            if MailView.canSendMail {
                Button {
                    showMailComposer = true
                } label: {
                    HStack {
                        Text(isKorean ? "💡 엉뚱한 아이디어 등록" : "💡 Submit Quirky Idea")
                            .foregroundStyle(Color.quirklyTextDark)
                        Spacer()
                        Image(systemName: "envelope")
                            .foregroundStyle(Color.quirklyTextDark)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $showMailComposer) {
                    MailView(
                        isPresented: $showMailComposer,
                        result: $mailResult,
                        subject: isKorean ? "엉뚱한 일 아이디어" : "Quirky Task Idea",
                        body: isKorean ? "안녕하세요!\n\n이것이 제 엉뚱한 아이디어입니다:\n\n" : "Hi!\n\nHere's my quirky idea:\n\n"
                    )
                }
            } else {
                HStack {
                    Text(isKorean ? "💡 엉뚱한 아이디어 등록" : "💡 Submit Quirky Idea")
                        .foregroundStyle(Color.quirklyTextDark)
                    Spacer()
                    Image(systemName: "envelope")
                        .foregroundStyle(Color.quirklyTextDark)
                }
            }

            Text(isKorean ? "새로운 엉뚱한 일을 생각하셨다면 개발자에게 메일로 보내주세요. 좋은 아이디어는 앱에 추가될 수 있습니다!" : "If you have a great quirky idea, send it to us! Your ideas might be featured in the app!")
                .font(.caption)
                .foregroundStyle(Color.quirklyTextDark.opacity(0.6))

            // 개발자 응원하기
            Button {
                if let url = URL(string: "https://apps.apple.com/app/quirkly/id6740123456") {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack {
                    Text(isKorean ? "⭐ 개발자 응원하기" : "⭐ Rate on App Store")
                        .foregroundStyle(Color.quirklyTextDark)
                    Spacer()
                    Image(systemName: "star.fill")
                        .foregroundStyle(Color.quirklyTextDark)
                }
            }

            // 개발자에게 커피 쏘기 (인앱 구매)
            Button {
                Task {
                    await purchaseCoffee()
                }
            } label: {
                HStack {
                    Text(isKorean ? "☕ 개발자에게 커피 쏘기" : "☕ Buy Dev a Coffee")
                        .foregroundStyle(Color.quirklyTextDark)
                    Spacer()
                    Image(systemName: "creditcard.fill")
                        .foregroundStyle(Color.quirklyTextDark)
                }
            }

        } header: {
            Text(isKorean ? "함께하기" : "Contribute")
        }
        .listRowBackground(Color.quirkySurface.opacity(0.5))
    }

    private func purchaseCoffee() async {
        print("인앱 구매 시작 - 커피")
        // StoreKit2를 사용한 인앱 구매 로직
        // 실제 구현 시 Apple에 Product ID를 등록해야 함
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
                    Text(isKorean ? "📡 엉뚱한 일 새로고침" : "📡 Refresh Quirky Tasks")
                        .foregroundStyle(Color.quirklyTextDark)
                    Spacer()
                    if repository.isLoading {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(Color.quirklyTextDark)
                    }
                }
            }
            if let error = repository.lastError {
                Text("⚠️ \(error)")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            if showSyncSuccess {
                Text(isKorean ? "✅ \(repository.taskCount)개 미션 로드 완료!" : "✅ \(repository.taskCount) missions loaded!")
                    .font(.caption)
                    .foregroundStyle(Color.quirklyGreen)
            }

            if let lastSync = settings.lastSyncDate {
                HStack {
                    Text(isKorean ? "마지막 새로고침 (미션)" : "Last Tasks Refresh")
                        .font(.caption)
                        .foregroundStyle(Color.quirklyTextDark.opacity(0.5))
                    Spacer()
                    Text(lastSync, style: .time)
                        .font(.caption)
                        .foregroundStyle(Color.quirklyTextDark.opacity(0.5))
                }
            }

            @Bindable var s = settings
            Toggle(isOn: $s.iCloudSyncEnabled) {
                Text(isKorean ? "☁️ 내 정보 iCloud 동기화" : "☁️ iCloud Sync My Info")
                    .foregroundStyle(Color.quirklyTextDark)
            }
            .tint(.quirklyBlue)
            .disabled(repository.isLoading)
        } header: {
            Text(isKorean ? "데이터 연동" : "Data & Sync")
        }
        .listRowBackground(Color.quirkySurface.opacity(0.5))
    }
    
    // MARK: - 통계
    
    private var statsSection: some View {
        Section {
            HStack {
                Text(isKorean ? "📊 총 완료한 미션" : "📊 Total Completed")
                Spacer()
                Text("\(allRecords.filter { $0.status == .completed }.count)")
                    .font(.system(.body, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.quirklyGreen)
            }
            HStack {
                Text(isKorean ? "🔥 최장 연속" : "🔥 Current Streak")
                Spacer()
                Text(isKorean ? "\(streak)일" : "\(streak) days")
                    .font(.system(.body, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.quirklyRed)
            }

        } header: {
            Text(isKorean ? "나의 기록" : "My Stats")
        }
        .listRowBackground(Color.quirkySurface.opacity(0.5))
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
        .listRowBackground(Color.quirkySurface.opacity(0.5))
    }
    
    // MARK: - 앱 정보

    private var aboutSection: some View {
        Section {
            HStack {
                Text(isKorean ? "ℹ️ 앱 버전" : "ℹ️ App Version")
                Spacer()
                Text("1.0.0")
                    .foregroundStyle(Color.quirklyTextDark.opacity(0.5))
            }
            HStack {
                Text(isKorean ? "🎲 앱 이름" : "🎲 App Name")
                Spacer()
                Text("Quirkly")
                    .foregroundStyle(Color.quirklyTextDark.opacity(0.5))
            }
        } header: {
            Text(isKorean ? "앱 정보" : "About")
        }
        .listRowBackground(Color.quirkySurface.opacity(0.5))
    }

    // MARK: - 이용약관 및 정책

    private var policySection: some View {
        Section {
            // 이용약관
            Button {
                if let url = URL(string: "https://sites.google.com/view/quirkly-terms") {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack {
                    Text(isKorean ? "📋 이용약관" : "📋 Terms of Service")
                        .foregroundStyle(Color.quirklyTextDark)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Color.quirklyTextDark.opacity(0.3))
                }
            }

            // 개인정보 처리방침
            Button {
                if let url = URL(string: "https://sites.google.com/view/quirkly-privacy") {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack {
                    Text(isKorean ? "🔒 개인정보 처리방침" : "🔒 Privacy Policy")
                        .foregroundStyle(Color.quirklyTextDark)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Color.quirklyTextDark.opacity(0.3))
                }
            }

            // 오픈소스 라이선스
            Button {
                if let url = URL(string: "https://sites.google.com/view/quirkly-licenses") {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack {
                    Text(isKorean ? "📜 오픈소스 라이선스" : "📜 Open Source Licenses")
                        .foregroundStyle(Color.quirklyTextDark)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Color.quirklyTextDark.opacity(0.3))
                }
            }
        } header: {
            Text(isKorean ? "이용약관 및 정책" : "Terms & Policies")
        }
        .listRowBackground(Color.quirkySurface.opacity(0.5))
    }
    
    // MARK: - Actions
    
    private func resetAllRecords() {
        try? modelContext.delete(model: QuirkyRecord.self)
        try? modelContext.save()
        updateStreak()
    }
    
    private func updateStreak() {
        streak = repository.currentStreak(modelContext: modelContext)
    }
}

#Preview {
    do {
        let container = try ModelContainer(for: QuirkyTask.self, QuirkyRecord.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        return SettingsView()
            .environment(AppSettings())
            .environment(TaskRepository())
            .modelContainer(container)
    } catch {
        return Text("Preview error")
    }
}
