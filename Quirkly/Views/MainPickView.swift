//
//  MainPickView.swift
//  Quirkly
//
//  메인 뽑기 화면 — 모든 제한 로직 및 공유 기능 포함
//

import SwiftUI
import SwiftData

struct MainPickView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) private var settings
    @Environment(TaskRepository.self) private var repository
    
    @State private var currentTask: QuirkyTask?
    @State private var isSpinning = false
    @State private var showConfetti = false
    @State private var cardRotation: Double = -2
    @State private var cardScale: CGFloat = 1.0
    @State private var isDecided = false
    
    // 오늘 통계 저장용
    @State private var todayCompleted = 0
    @State private var todayPassed = 0
    @State private var hasLoadedInitial = false
    
    @State private var confettiParticles: [ConfettiParticle] = []
    
    private var isKorean: Bool { settings.language.resolvedIsKorean }
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundView
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        // 설명글
                        subtitleSection

                        // 메인 카드
                        missionCard
                            .padding(.horizontal, 24)

                        // 오늘 날짜 (테스트용 리셋 버튼)
                        dateDisplaySection

                        // 버튼 섹션
                        actionButtons

                        Spacer(minLength: 40)
                    }
                    .padding(.top, 0)
                }

                if showConfetti {
                    ConfettiOverlay(particles: confettiParticles)
                        .allowsHitTesting(false)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Quirkly : 나의 엉뚱일지")
                        .font(.system(size: 17, weight: .heavy))
                }
            }
            .task {
                if !hasLoadedInitial {
                    repository.loadBundledTasks(modelContext: modelContext)
                    updateStats()
                    hasLoadedInitial = true
                }
            }
        }
    }
    
    // MARK: - 배경
    private var backgroundView: some View {
        ZStack {
            Color.quirklyBgLight.ignoresSafeArea()
            GeometryReader { geo in
                SparkleView(size: 20, color: .quirklyYellow).position(x: 40, y: 80)
                SparkleView(size: 14, color: .quirklyPink).position(x: geo.size.width - 50, y: 120)
                SparkleView(size: 16, color: .quirklyGreen).position(x: 60, y: geo.size.height - 80)
                SparkleView(size: 10, color: .quirklyBlue).position(x: geo.size.width - 30, y: geo.size.height - 100)
            }
        }
    }
    
    // MARK: - 서브 타이틀 (설명글)
    private var subtitleSection: some View {
        HStack {
            Text(isKorean ? "오늘은 어떤 엉뚱한 일을 해볼까?" : "What quirky thing will you do today?")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.quirklyBlue)
            Spacer()
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - 미션 카드 (상태별 메시지)
    private var missionCard: some View {
        VStack(spacing: 16) {
            if todayCompleted >= 1 {
                // 하루 1개 제한 메시지
                VStack(spacing: 12) {
                    Text("🌟")
                        .font(.system(size: 60))
                    Text(isKorean ? "오늘의 엉뚱한 일 완료!" : "Today's Quirky Done!")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                    Text(isKorean ? "내일 새로운 엉뚱함으로 만나요!" : "See you tomorrow with new quirkiness!")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 20)
                .foregroundStyle(Color.quirklyTextDark)
            } else if let task = currentTask {
                // 현재 미션 카드
                VStack(spacing: 16) {
                    HStack {
                        Text(task.category.emoji)
                        Text(isKorean ? task.category.displayNameKo : task.category.displayNameEn)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                        Spacer()
                        // 소셜 공유 버튼
                        shareActionMenu(task: task)
                    }
                    .foregroundStyle(task.category.cardTextColor.opacity(0.8))
                    
                    Text(task.emoji)
                        .font(.system(size: 64))
                        .scaleEffect(cardScale)

                    Text(task.title(for: settings.language))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(task.category.cardTextColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 10)
                }
            } else {
                // 최초 뽑기 이전 화면
                VStack(spacing: 20) {
                    Text("🎲")
                        .font(.system(size: 64))
                    Text(isKorean ? "오늘의 엉뚱한 일을\n뽑아보세요!" : "Pick today's\nquirky mission!")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.quirklyTextDark.opacity(0.7))
                        .multilineTextAlignment(.center)
                    
                    Text(isKorean ? "하루에 하나만 뽑을 수 있어요. 단, 패스 3번 가능." : "You can pick only one per day. Up to 3 passes allowed.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.quirklyTextDark.opacity(0.5))
                }
                .padding(.vertical, 20)
            }
        }
        .padding(.vertical, 32)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 280)
        .popArtCard(
            color: todayCompleted >= 1 ? Color.quirklyPink.opacity(0.4) : (currentTask?.category.cardColor ?? Color.quirkySurface),
            rotation: isSpinning ? 0 : cardRotation
        )
        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: isSpinning)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentTask?.taskId)
    }

    // MARK: - 공유 메뉴
    @MainActor
    private func shareActionMenu(task: QuirkyTask) -> some View {
        let renderer = ImageRenderer(content: ShareCardView(task: task, isKorean: isKorean))
        renderer.scale = UIScreen.main.scale
        
        return Group {
            if let image = renderer.uiImage {
                ShareLink(item: Image(uiImage: image), preview: SharePreview("Quirkly", image: Image(uiImage: image))) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18, weight: .bold))
                }
            }
        }
    }
    
    // MARK: - 오늘 날짜 섹션 (테스트용: 클릭으로 제한 리셋)
    private var dateDisplaySection: some View {
        Button(action: resetDailyLimit) {
            HStack {
                Image(systemName: "calendar")
                Text(formattedDate)
            }
            .font(.system(size: 15, weight: .black, design: .rounded))
            .foregroundStyle(Color.quirklyTextDark.opacity(0.6))
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(Color.quirklyBlue.opacity(0.1))
            .clipShape(Capsule())
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = isKorean ? Locale(identifier: "ko_KR") : Locale(identifier: "en_US")
        formatter.dateFormat = isKorean ? "yyyy. MM. dd. (E)" : "MMM dd, yyyy (E)"
        return formatter.string(from: Date())
    }
    
    // MARK: - 버튼 섹션 로직
    private var actionButtons: some View {
        VStack(spacing: 12) {
            if todayCompleted < 1 {
                if currentTask == nil {
                    // 최초 뽑기 버튼
                    Button(action: spinAndPick) {
                        HStack(spacing: 8) {
                            Image(systemName: "dice.fill")
                            Text(isKorean ? "뽑기!" : "Pick!")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(QuirklyButtonStyle(color: .quirklyBlue))
                    .disabled(isSpinning)
                } else {
                    if !isDecided {
                        // 미션 뽑힌 후: 패스(위) + 결정(아래) 세로 배열
                        Button(action: passMission) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.uturn.forward")
                                Text(isKorean ? "패스 (\(3 - todayPassed)/3)" : "Pass (\(3 - todayPassed)/3)")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(QuirklyButtonStyle(color: .quirklyRed))
                        .disabled(todayPassed >= 3 || isSpinning)

                        Button(action: {
                            withAnimation(.spring()) { isDecided = true }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle")
                                Text(isKorean ? "결정했어!" : "Decided!")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(QuirklyButtonStyle(color: .quirklyBlue))
                        .disabled(isSpinning)
                    } else {
                        // 결정 후 '완료' 버튼 노출
                        Button(action: completeMission) {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                Text(isKorean ? "완료!" : "Done!")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(QuirklyButtonStyle(color: .quirklyGreen))
                        .disabled(isSpinning)
                    }
                }
            } else {
                Text(isKorean ? "내일 또 만나요! 🌈" : "See you tomorrow! 🌈")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(Color.quirklyBlue)
                    .padding(.top, 10)
            }
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - 오늘 통계 뷰
    private var todayStatsView: some View {
        HStack(spacing: 20) {
            StatBadge(emoji: "✅", count: todayCompleted, label: isKorean ? "완료" : "Done")
            StatBadge(emoji: "🔁", count: todayPassed, label: isKorean ? "패스" : "Pass")
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - 로직 함수들
    
    private func pickNewTask() {
        currentTask = repository.randomTask(modelContext: modelContext, excluding: currentTask?.taskId)
        cardRotation = Double.random(in: -3...3)
    }
    
    private func spinAndPick() {
        isSpinning = true
        isDecided = false
        withAnimation(.easeInOut(duration: 0.3)) { cardScale = 0.8 }
        
        var spinCount = 0
        let totalSpins = 8
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            spinCount += 1
            pickNewTask()
            if spinCount >= totalSpins {
                timer.invalidate()
                withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) {
                    cardScale = 1.0
                    isSpinning = false
                    
                    // 위젯 업데이트
                    WidgetDataService.updateWidgetData(task: currentTask, isCompleted: false)
                }
            }
        }
    }
    
    private func completeMission() {
        guard let task = currentTask else { return }
        let record = QuirkyRecord(task: task, status: .completed)
        modelContext.insert(record)
        try? modelContext.save()
        
        triggerConfetti()
        updateStats()
        
        // 위젯 업데이트 (완료 상태)
        WidgetDataService.updateWidgetData(task: task, isCompleted: true)
        
        // 완료 후 최초 상태로 리셋
        contextClearWithDelay()
    }
    
    private func contextClearWithDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.spring()) {
                currentTask = nil
                isDecided = false
            }
        }
    }
    
    private func passMission() {
        guard let task = currentTask else { return }
        let record = QuirkyRecord(task: task, status: .passed)
        modelContext.insert(record)
        try? modelContext.save()
        
        updateStats()
        spinAndPick()
    }
    
    private func updateStats() {
        let stats = repository.todayStats(modelContext: modelContext)
        todayCompleted = stats.completed
        todayPassed = stats.passed
    }
    
    private func triggerConfetti() {
        confettiParticles = (0..<50).map { _ in
            ConfettiParticle(color: [.quirklyYellow, .quirklyBlue, .quirklyRed, .quirklyPink, .quirklyGreen].randomElement()!, x: CGFloat.random(in: 0...400), delay: Double.random(in: 0...0.5))
        }
        showConfetti = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            showConfetti = false
            confettiParticles = []
        }
    }

    // 테스트용: 날짜 버튼 클릭으로 일일 제한 리셋 (DB 포함)
    private func resetDailyLimit() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        let predicate = #Predicate<QuirkyRecord> {
            $0.date >= startOfDay && $0.date < endOfDay
        }
        if let records = try? modelContext.fetch(FetchDescriptor<QuirkyRecord>(predicate: predicate)) {
            records.forEach { modelContext.delete($0) }
            try? modelContext.save()
        }
        withAnimation {
            currentTask = nil
            todayCompleted = 0
            todayPassed = 0
            isDecided = false
        }
    }
}

// MARK: - 하단 필수 컴포넌트들 (에러 방지용 재정의)

struct StatBadge: View {
    let emoji: String
    let count: Int
    let label: String
    
    var body: some View {
        HStack(spacing: 8) {
            Text(emoji).font(.title3)
            VStack(alignment: .leading, spacing: 1) {
                Text("\(count)").font(.system(size: 18, weight: .black, design: .rounded))
                Text(label).font(.system(size: 11, weight: .bold, design: .rounded)).opacity(0.6)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.quirkySurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.1), lineWidth: 1))
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    let color: Color
    let x: CGFloat
    let delay: Double
}

struct ConfettiOverlay: View {
    let particles: [ConfettiParticle]
    var body: some View {
        ZStack { ForEach(particles) { particle in ConfettiPiece(particle: particle) } }.ignoresSafeArea()
    }
}

struct ConfettiPiece: View {
    let particle: ConfettiParticle
    @State private var yPosition: CGFloat = -20
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(particle.color)
            .frame(width: CGFloat.random(in: 6...10), height: CGFloat.random(in: 8...12))
            .rotationEffect(.degrees(rotation))
            .position(x: particle.x, y: yPosition)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeIn(duration: Double.random(in: 1.5...2.5)).delay(particle.delay)) {
                    yPosition = 1000
                    rotation = Double.random(in: 360...720)
                    opacity = 0
                }
            }
    }
}

#Preview {
    do {
        let container = try ModelContainer(for: QuirkyTask.self, QuirkyRecord.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        return MainPickView()
            .environment(AppSettings())
            .environment(TaskRepository())
            .modelContainer(container)
    } catch {
        return Text("Preview error")
    }
}
