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
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) private var settings
    @Environment(TaskRepository.self) private var repository

    @Query private var allRecords: [QuirkyRecord]
    
    @State private var showResetAlert = false
    @State private var showSyncSuccess = false
    @State private var reminderTime: Date = Date()
    @State private var showMailComposer = false
    @State private var mailResult: Result<MFMailComposeResult, Error>?
    @State private var showFileImporter = false
    @State private var exportError: String?
    @State private var showCoffeeAlert = false
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
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [UTType.json],
                onCompletion: { result in
                    switch result {
                    case .success(let url):
                        importRecords(from: url)
                    case .failure(let error):
                        exportError = error.localizedDescription
                    }
                }
            )
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
            .alert(
                isKorean ? "감사합니다" : "Thank You",
                isPresented: $showCoffeeAlert
            ) {
                Button(isKorean ? "확인" : "OK", role: .cancel) {}
            } message: {
                Text(isKorean ? "마음만 받을께요. 즐거운 하루 되세요!😉" : "I appreciate your support! Thank you!")
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

            // 앱스토어 별점 남기기
            Button {
                if let url = URL(string: "https://apps.apple.com/app/quirkly/id6740123456") {
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
        showCoffeeAlert = true
    }

    // MARK: - 데이터 연동

    private var syncSection: some View {
        Section {
            Button {
                Task {
                    await repository.syncFromGoogleSheets(modelContext: modelContext)
                }
            } label: {
                HStack {
                    Text(isKorean ? "📡 엉뚱한 일들 새로고침" : "📡 Refresh Quirky Tasks")
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

            HStack(spacing: 12) {
                Button {
                    exportRecords()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.doc")
                        Text(isKorean ? "내보내기" : "Export")
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(Color.quirklyTextLight)
                    .padding(.vertical, 8)
                    .background(Color.quirklyBlue)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)

                Button {
                    showFileImporter = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.down.doc")
                        Text(isKorean ? "가져오기" : "Import")
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(Color.quirklyTextLight)
                    .padding(.vertical, 8)
                    .background(Color.quirklyGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))

            Text(isKorean ? "앱 재설치 혹은 기기 변경 전에 기록을 유지하세요." : "Back up your records before reinstalling or switching devices.")
                .font(.caption)
                .foregroundStyle(Color.quirklyTextDark.opacity(0.6))

            if let error = exportError {
                Text("⚠️ \(error)")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

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
            Text(isKorean ? "데이터 연동" : "Data & Sync")
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
                if let url = URL(string: "https://gotgam100.github.io/Quirkly/terms.html") {
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
    
    private func resetAllRecords() {
        try? modelContext.delete(model: QuirkyRecord.self)
        try? modelContext.save()
        updateStreak()
    }
    
    private func updateStreak() {
        streak = repository.currentStreak(modelContext: modelContext)
    }

    private func exportRecords() {
        do {
            let records = try modelContext.fetch(FetchDescriptor<QuirkyRecord>())
            let dtos = records.map { record -> [String: Any] in
                [
                    "taskId": record.taskId,
                    "taskTitleKo": record.taskTitleKo,
                    "taskTitleEn": record.taskTitleEn,
                    "taskEmoji": record.taskEmoji,
                    "status": record.statusRaw,
                    "date": record.date.timeIntervalSince1970,
                    "category": record.taskCategoryRaw
                ]
            }

            let jsonData = try JSONSerialization.data(withJSONObject: dtos, options: .prettyPrinted)
            let fileName = "quirkly_records_\(Date().timeIntervalSince1970).json"

            if let tempURL = FileManager.default.temporaryDirectory as NSURL? {
                let fileURL = tempURL.appendingPathComponent(fileName)!
                try jsonData.write(to: fileURL)

                let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first,
                   let rootVC = window.rootViewController {
                    rootVC.present(activityVC, animated: true)
                }

                exportError = nil
            }
        } catch {
            exportError = isKorean ? "내보내기 실패: \(error.localizedDescription)" : "Export failed: \(error.localizedDescription)"
        }
    }

    private func importRecords(from url: URL) {
        do {
            let accessing = url.startAccessingSecurityScopedResource()
            defer { if accessing { url.stopAccessingSecurityScopedResource() } }

            let data = try Data(contentsOf: url)
            guard let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                exportError = isKorean ? "잘못된 파일 형식입니다." : "Invalid file format"
                return
            }

            for dto in jsonArray {
                guard let taskId = dto["taskId"] as? Int,
                      let taskTitleKo = dto["taskTitleKo"] as? String,
                      let taskTitleEn = dto["taskTitleEn"] as? String,
                      let taskEmoji = dto["taskEmoji"] as? String,
                      let statusStr = dto["status"] as? String,
                      let _ = RecordStatus(rawValue: statusStr),
                      let dateInterval = dto["date"] as? TimeInterval,
                      let categoryStr = dto["category"] as? String,
                      let _ = TaskCategory(rawValue: categoryStr) else {
                    continue
                }

                let record = QuirkyRecord(
                    taskId: taskId,
                    taskTitleKo: taskTitleKo,
                    taskTitleEn: taskTitleEn,
                    taskEmoji: taskEmoji,
                    statusRaw: statusStr,
                    date: Date(timeIntervalSince1970: dateInterval),
                    taskCategoryRaw: categoryStr
                )

                modelContext.insert(record)
            }

            try modelContext.save()
            exportError = nil
            updateStreak()
        } catch {
            exportError = isKorean ? "가져오기 실패: \(error.localizedDescription)" : "Import failed: \(error.localizedDescription)"
        }
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
