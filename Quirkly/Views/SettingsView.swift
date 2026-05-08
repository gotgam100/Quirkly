//
//  SettingsView.swift
//  Quirkly
//
//  설정 화면 — 언어, 테마, 알림, 통계, 동기화
//

import SwiftUI
import SwiftData
import MessageUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) private var settings

    @State private var showResetAlert = false
    @State private var reminderTime: Date = Date()
    @State private var showMailComposer = false
    @State private var mailResult: Result<MFMailComposeResult, Error>?
    @State private var showCoffeeAlert = false
    @State private var versionTapCount: Int = 0
    @State private var showSecretUnlockAlert = false
    @State private var showICloudRestartAlert = false
    @State private var pendingICloudValue = false
    @State private var secretTermsTapped = false
    @State private var showWhatsNewSecret = false
    
    private var isKorean: Bool { settings.language.resolvedIsKorean }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.quirklyBgLight.ignoresSafeArea()
                
                List {
                    // 일반
                    languageSection

                    // 데이터
                    syncSection

                    // 알림
                    notificationSection

                    // 함께하기
                    ideaSection

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
            .task {}
            .sheet(isPresented: $showWhatsNewSecret) {
                WhatsNewView(isKorean: isKorean) {
                    showWhatsNewSecret = false
                }
                .presentationDetents([.large])
                .interactiveDismissDisabled(true)
            }
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
            .alert(
                isKorean ? "감사합니다" : "Thank You",
                isPresented: $showCoffeeAlert
            ) {
                Button(isKorean ? "확인" : "OK", role: .cancel) {}
            } message: {
                Text(isKorean ? "마음만 받을께요. 즐거운 하루 되세요!😉" : "I appreciate your support! Thank you!")
            }
            .alert(
                pendingICloudValue
                    ? (isKorean ? "☁️ iCloud 동기화 켜기" : "☁️ Enable iCloud Sync")
                    : (isKorean ? "☁️ iCloud 동기화 끄기" : "☁️ Disable iCloud Sync"),
                isPresented: $showICloudRestartAlert
            ) {
                Button(isKorean ? "적용 (앱 재시작)" : "Apply (Restart)", role: .destructive) {
                    ICloudSyncService.prepareMigration(modelContext: modelContext,
                                                       enableICloud: pendingICloudValue)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { exit(0) }
                }
                Button(isKorean ? "취소" : "Cancel", role: .cancel) {}
            } message: {
                Text(pendingICloudValue
                     ? (isKorean
                        ? "기존 기록을 iCloud에 동기화합니다.\n앱이 재시작되며 기록은 자동으로 이전됩니다."
                        : "Your records will be synced to iCloud.\nThe app will restart and records will be migrated.")
                     : (isKorean
                        ? "iCloud 동기화를 끕니다.\n앱이 재시작되며 기록은 기기에 로컬 저장됩니다."
                        : "iCloud sync will be turned off.\nThe app will restart and records will be stored locally."))
            }
            .alert(
                isKorean ? "🎲 다시 뽑기가 활성화되었어요!" : "🎲 Ready to pick again!",
                isPresented: $showSecretUnlockAlert
            ) {
                Button(isKorean ? "확인" : "OK", role: .cancel) {
                    resetTodayTask()
                }
            } message: {
                Text(isKorean ? "오늘의 엉뚱한 일을 다시 뽑을 수 있습니다." : "You can now pick a new quirky task for today.")
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

            Text(isKorean ? "위젯을 이용해보세요." : "Try using the widget!")
                .font(.caption)
                .foregroundStyle(Color.quirklyTextDark.opacity(0.6))
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

            // 앱스토어 별점 남기기
            Button {
                if let url = URL(string: "https://apps.apple.com/us/app/quirkly-%EC%97%89%EB%9A%B1%ED%95%9C-%ED%95%98%EB%A3%A8-%EB%A7%8C%EB%93%A4%EA%B8%B0/id6762527265") {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack {
                    Text(isKorean ? "⭐ 앱스토어 별점 남기기" : "⭐ Rate on App Store")
                        .foregroundStyle(Color.quirklyTextDark)
                    Spacer()
                    Image(systemName: "star.fill")
                        .foregroundStyle(Color.quirklyTextDark)
                }
            }

            // 개발자에게 커피 쏘기 (인앱 구매)
            Button {
                if versionTapCount >= 5 && secretTermsTapped {
                    // 업데이트 안내문 비밀 코드
                    showWhatsNewSecret = true
                    versionTapCount = 0
                    secretTermsTapped = false
                } else if versionTapCount >= 5 {
                    // 다시 뽑기 비밀 코드
                    showSecretUnlockAlert = true
                    versionTapCount = 0
                } else {
                    Task { await purchaseCoffee() }
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
        showCoffeeAlert = true
    }

    // MARK: - iCloud 동기화

    private var syncSection: some View {
        Section {
            // iCloud 토글
            HStack {
                Text(isKorean ? "☁️ iCloud 동기화" : "☁️ iCloud Sync")
                    .foregroundStyle(Color.quirklyTextDark)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { settings.iCloudSyncEnabled },
                    set: { newValue in
                        pendingICloudValue = newValue
                        showICloudRestartAlert = true
                    }
                ))
                .tint(.quirklyBlue)
                .labelsHidden()
            }

            Text(isKorean
                 ? "활성화하면 기기 변경·재설치 후에도 기록이 iCloud에 안전하게 보관됩니다."
                 : "When enabled, your records are securely stored in iCloud and survive reinstalls or device changes.")
                .font(.caption)
                .foregroundStyle(Color.quirklyTextDark.opacity(0.6))

            // 기록 초기화
            Button(role: .destructive) {
                showResetAlert = true
            } label: {
                HStack {
                    Text(isKorean ? "🗑 기록 초기화" : "🗑 Reset All Records")
                        .foregroundStyle(.red)
                    Spacer()
                }
            }
        } header: {
            Text(isKorean ? "데이터" : "Data")
        }
        .listRowBackground(Color.quirkySurface.opacity(0.5))
    }
    
    // MARK: - 앱 정보

    private var aboutSection: some View {
        Section {
            Button {
                versionTapCount += 1
            } label: {
                HStack {
                    Text(isKorean ? "ℹ️ 앱 버전" : "ℹ️ App Version")
                        .foregroundStyle(Color.quirklyTextDark)
                    Spacer()
                    Text("1.1.0")
                        .foregroundStyle(Color.quirklyTextDark.opacity(0.5))
                }
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
                if versionTapCount >= 5 {
                    secretTermsTapped = true
                } else {
                    if let url = URL(string: "https://gotgam100.github.io/Quirkly/terms.html") {
                        UIApplication.shared.open(url)
                    }
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
                if let url = URL(string: "https://gotgam100.github.io/Quirkly/privacy.html") {
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
                if let url = URL(string: "https://gotgam100.github.io/Quirkly/licenses.html") {
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

    private func resetTodayTask() {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        let descriptor = FetchDescriptor<QuirkyRecord>(
            predicate: #Predicate { record in
                record.date >= today && record.date < tomorrow
            }
        )

        if let records = try? modelContext.fetch(descriptor) {
            for record in records {
                modelContext.delete(record)
            }
        }

        try? modelContext.save()

        settings.currentTaskId = 0
        settings.currentTaskDate = nil
        settings.isTaskDecided = false
        WidgetDataService.updateWidgetData(task: nil, isCompleted: false, language: settings.language.rawValue)
    }

    private func resetAllRecords() {
        try? modelContext.delete(model: QuirkyRecord.self)
        try? modelContext.save()
    }
    
}

#Preview {
    do {
        let container = try ModelContainer(for: QuirkyTask.self, QuirkyRecord.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        return SettingsView()
            .environment(AppSettings())
            .modelContainer(container)
    } catch {
        return Text("Preview error")
    }
}
