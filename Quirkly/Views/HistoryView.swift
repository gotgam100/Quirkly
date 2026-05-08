//
//  HistoryView.swift
//  Quirkly
//
//  엉뚱한 일 수행 기록 화면 — 달력 형식
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) private var settings
    @Environment(TaskRepository.self) private var repository

    @Query(sort: \QuirkyRecord.date, order: .reverse)
    private var allRecords: [QuirkyRecord]

    @State private var selectedMonth: Date = Date()
    @State private var selectedDateItem: IdentifiableDate? = nil
    @State private var streak = 0
    @State private var showCollection = false

    private var isKorean: Bool { settings.language.resolvedIsKorean }

    private var completedRecords: [QuirkyRecord] {
        allRecords.filter { $0.status == .completed }
    }

    private var completedDayKeys: Set<String> {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return Set(completedRecords.map { formatter.string(from: $0.date) })
    }

    private func recordsForDate(_ date: Date) -> [QuirkyRecord] {
        let calendar = Calendar.current
        return completedRecords.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }

    struct IdentifiableDate: Identifiable {
        let id = UUID()
        let date: Date
    }

    private func dayKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    // 현재 월의 날짜 배열 (nil = 빈 칸)
    private var daysInMonth: [Date?] {
        let calendar = Calendar.current
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth)),
              let range = calendar.range(of: .day, in: .month, for: startOfMonth) else { return [] }

        // 월요일 시작 기준 offset (1=일, 2=월 ... 7=토)
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let offset = firstWeekday - 1 // 일요일 시작 기준

        var days: [Date?] = Array(repeating: nil, count: offset)
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }
        return days
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = isKorean ? Locale(identifier: "ko_KR") : Locale(identifier: "en_US")
        formatter.dateFormat = isKorean ? "yyyy년 M월" : "MMMM yyyy"
        return formatter.string(from: selectedMonth)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.quirklyBgLight.ignoresSafeArea()

                if allRecords.filter({ $0.status == .completed }).isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            titleHeader
                            statsHeader.padding(.vertical, 8)
                            calendarSection
                                .padding(.horizontal, 16)
                                .padding(.top, 16)
                            collectionButton
                                .padding(.horizontal, 16)
                                .padding(.top, 12)
                            Spacer(minLength: 40)
                        }
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .task { updateStreak() }
            .sheet(isPresented: $showCollection) {
                CollectionSheet(records: completedRecords, isKorean: isKorean)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(item: $selectedDateItem) { item in
                DayDetailSheet(
                    date: item.date,
                    records: recordsForDate(item.date),
                    isKorean: isKorean
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - 커스텀 타이틀 헤더
    private var titleHeader: some View {
        HStack {
            Text(isKorean ? "나의 엉뚱한 기록" : "My Quirky History")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
        .padding(.bottom, 8)
        .background(Color.quirklyBgLight)
    }

    // MARK: - 빈 상태
    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("🎲")
                .font(.system(size: 60))
            Text(isKorean ? "아직 기록이 없어요" : "No records yet")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Color.quirklyTextDark)
            Text(isKorean ? "오늘의 엉뚱한 일을 먼저 뽑아보세요!" : "Pick your first quirky task!")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Color.quirklyTextDark.opacity(0.5))
        }
    }

    // MARK: - 통계 헤더
    private var statsHeader: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                StatCard(
                    emoji: "✅",
                    value: "\(completedRecords.count)",
                    label: isKorean ? "총 완료" : "Total Done"
                )
                StatCard(
                    emoji: "🔥",
                    value: "\(streak)",
                    label: isKorean ? "연속 일수" : "Streak"
                )
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - 달력 섹션
    private var calendarSection: some View {
        VStack(spacing: 12) {
            // 월 이동 헤더
            HStack {
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.quirklyBlue)
                        .padding(8)
                }

                Spacer()

                Text(monthTitle)
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(Color.quirklyTextDark)

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.quirklyBlue)
                        .padding(8)
                }
            }
            .padding(.horizontal, 4)

            // 요일 헤더 (일요일 시작)
            let weekdays = isKorean
                ? ["일", "월", "화", "수", "목", "금", "토"]
                : ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

            HStack(spacing: 0) {
                ForEach(Array(weekdays.enumerated()), id: \.offset) { index, day in
                    Text(day)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(index == 0 ? Color.red.opacity(0.7) : Color.quirklyTextDark.opacity(0.4))
                        .frame(maxWidth: .infinity)
                }
            }

            // 날짜 그리드
            let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, date in
                    if let date = date {
                        let hasRecord = completedDayKeys.contains(dayKey(date))
                        let isToday = Calendar.current.isDateInToday(date)
                        let isSunday = Calendar.current.component(.weekday, from: date) == 1

                        Button {
                            if hasRecord {
                                selectedDateItem = IdentifiableDate(date: date)
                            }
                        } label: {
                            ZStack {
                                if hasRecord {
                                    Circle()
                                        .fill(Color.quirklyBlue)
                                } else if isToday {
                                    Circle()
                                        .stroke(Color.quirklyBlue.opacity(0.4), lineWidth: 1.5)
                                }

                                VStack(spacing: 1) {
                                    Text("\(Calendar.current.component(.day, from: date))")
                                        .font(.system(size: 14, weight: hasRecord || isToday ? .black : .regular, design: .rounded))
                                        .foregroundStyle(hasRecord ? .white : (isToday ? Color.quirklyBlue : (isSunday ? Color.red.opacity(0.7) : Color.quirklyTextDark)))

                                    if hasRecord {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 7, weight: .black))
                                            .foregroundStyle(.white)
                                    }
                                }
                            }
                            .frame(height: 44)
                        }
                        .disabled(!hasRecord)
                    } else {
                        Color.clear.frame(height: 44)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.quirkySurface.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.quirklyTextDark.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - 수집 버튼
    private var collectionButton: some View {
        Button {
            showCollection = true
        } label: {
            HStack(spacing: 8) {
                Text("🗂️")
                    .font(.system(size: 16))
                Text(isKorean ? "수집한 엉뚱카드" : "Quirky Card Collection")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [Color.quirklyBlue, Color.quirklyPink],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: Color.quirklyBlue.opacity(0.35), radius: 6, x: 0, y: 3)
        }
    }


    private func updateStreak() {
        streak = repository.currentStreak(modelContext: modelContext)
    }
}

// MARK: - 날짜 상세 시트

struct DayDetailSheet: View {
    let date: Date
    let records: [QuirkyRecord]
    let isKorean: Bool

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = isKorean ? Locale(identifier: "ko_KR") : Locale(identifier: "en_US")
        formatter.dateFormat = isKorean ? "yyyy년 M월 d일 (E)" : "MMMM d, yyyy (E)"
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(spacing: 0) {
            // 날짜 헤더
            Text("✅ \(formattedDate)")
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundStyle(Color.quirklyTextDark)
                .padding(.top, 28)
                .padding(.bottom, 24)

            // 카드 목록
            ScrollView {
                VStack(spacing: 24) {
                    Spacer().frame(height: 8)
                    ForEach(records) { record in
                        VStack(spacing: 16) {
                            HStack {
                                Text(record.taskCategory.emoji)
                                Text(isKorean ? record.taskCategory.displayNameKo : record.taskCategory.displayNameEn)
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                Spacer()
                                Text(record.date, style: .time)
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .opacity(0.6)
                            }
                            .foregroundStyle(record.taskCategory.cardTextColor.opacity(0.8))

                            Text(record.taskEmoji)
                                .font(.system(size: 64))

                            Text(record.taskTitle(for: isKorean ? .korean : .english))
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(record.taskCategory.cardTextColor)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 10)
                        }
                        .padding(.vertical, 32)
                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity)
                        .popArtCard(
                            color: record.taskCategory.cardColor,
                            rotation: Double.random(in: -2...2)
                        )
                        .padding(.horizontal, 24)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .background(Color.quirklyBgLight)
    }
}

// MARK: - 통계 카드

struct StatCard: View {
    let emoji: String
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 8) {
            Text(emoji)
                .font(.system(size: 26))
            Text(label)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.quirklyTextDark.opacity(0.5))
            Text(value)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(Color.quirklyTextDark)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 14)
        .background(Color.quirkySurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.quirklyTextDark.opacity(0.15), lineWidth: 1.5)
        )
    }
}

// MARK: - 수집 필터

enum CollectionFilter: Equatable {
    case all, collected, undiscovered
    case category(TaskCategory)

    func displayName(isKorean: Bool) -> String {
        switch self {
        case .all:             return isKorean ? "전체" : "All"
        case .collected:       return isKorean ? "수집됨" : "Collected"
        case .undiscovered:    return isKorean ? "미발견" : "Missing"
        case .category(let c): return isKorean ? c.displayNameKo : c.displayNameEn
        }
    }
}

// MARK: - 수집 시트

struct CollectionSheet: View {
    let records: [QuirkyRecord]
    let isKorean: Bool

    @Query(sort: \QuirkyTask.taskId) private var allTasks: [QuirkyTask]
    @State private var filter: CollectionFilter = .all

    private func levelTitle(_ count: Int) -> String {
        let level: String
        switch count {
        case 1...6:   level = isKorean ? "제법 엉뚱한 친구" : "Quite a Quirky Friend"
        case 7...29:  level = isKorean ? "괴짜" : "Weirdo"
        case 30...99: level = isKorean ? "엉뚱함의 왕" : "King of Quirky"
        default:      level = isKorean ? "엉뚱함의 전설" : "Legend of Quirkiness"
        }
        return isKorean ? "당신의 레벨 : \(level)" : "Your Level : \(level)"
    }

    private var collectedIds: Set<Int> { Set(records.map { $0.taskId }) }

    /// taskId 기준 중복 제거 (CloudKit 동기화로 인한 중복 방지)
    private var uniqueTasks: [QuirkyTask] {
        var seen = Set<Int>()
        return allTasks.filter { seen.insert($0.taskId).inserted }
    }

    private var filteredTasks: [QuirkyTask] {
        switch filter {
        case .all:             return uniqueTasks
        case .collected:       return uniqueTasks.filter { collectedIds.contains($0.taskId) }
        case .undiscovered:    return uniqueTasks.filter { !collectedIds.contains($0.taskId) }
        case .category(let c): return uniqueTasks.filter { $0.category == c }
        }
    }

    private var progress: Double {
        guard !uniqueTasks.isEmpty else { return 0 }
        return Double(collectedIds.count) / Double(uniqueTasks.count)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // ── 레벨 + 진행도 ──
                VStack(alignment: .leading, spacing: 10) {
                    Text(levelTitle(records.count))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 9)
                        .background(
                            LinearGradient(colors: [Color.quirklyBlue, Color.quirklyPink],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .clipShape(Capsule())
                        .shadow(color: Color.quirklyPink.opacity(0.35), radius: 5, x: 0, y: 3)
                        .frame(maxWidth: .infinity, alignment: .trailing)

                    HStack {
                        Text("\(collectedIds.count) / \(uniqueTasks.count) \(isKorean ? "수집 완료" : "collected")")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.quirklyTextDark)
                        Spacer()
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.quirklyTextDark.opacity(0.5))
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.quirklyTextDark.opacity(0.1))
                            Capsule()
                                .fill(LinearGradient(
                                    colors: [Color.quirklyYellow, Color.quirklyOrange],
                                    startPoint: .leading, endPoint: .trailing))
                                .frame(width: max(0, geo.size.width * progress))
                        }
                        .frame(height: 8)
                    }
                    .frame(height: 8)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 14)

                // ── 필터 탭 ──
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        filterChip(.all)
                        filterChip(.collected)
                        filterChip(.undiscovered)
                        ForEach(TaskCategory.allCases) { cat in
                            filterChip(.category(cat))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                }

                Divider().opacity(0.2)

                // ── 카드 그리드 ──
                ScrollView {
                    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(filteredTasks) { task in
                            if collectedIds.contains(task.taskId) {
                                CollectedCard(task: task, isKorean: isKorean)
                            } else {
                                UndiscoveredCard(task: task, isKorean: isKorean)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .padding(.bottom, 24)
                }
            }
            .background(Color.quirklyBgLight)
            .navigationTitle(isKorean ? "수집한 엉뚱카드" : "Quirky Card Collection")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder
    private func filterChip(_ f: CollectionFilter) -> some View {
        let selected = filter == f
        Button { withAnimation(.spring(response: 0.25)) { filter = f } } label: {
            Text(f.displayName(isKorean: isKorean))
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(selected ? .white : Color.quirklyTextDark.opacity(0.55))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(selected ? Color.quirklyBlue : Color.quirklyTextDark.opacity(0.07))
                .clipShape(Capsule())
        }
    }
}

// MARK: - 수집된 카드

struct CollectedCard: View {
    let task: QuirkyTask
    let isKorean: Bool

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            Text(task.emoji)
                .font(.system(size: 34))
            Spacer()
            Text(isKorean ? task.titleKo : task.titleEn)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(task.category.cardTextColor)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 6)
                .padding(.bottom, 10)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .background(task.category.cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12)
            .stroke(Color.quirklyTextDark.opacity(0.12), lineWidth: 1.5))
        .shadow(color: .black.opacity(0.10), radius: 5, x: 2, y: 3)
    }
}

// MARK: - 미발견 카드

struct UndiscoveredCard: View {
    let task: QuirkyTask
    let isKorean: Bool

    var body: some View {
        VStack(spacing: 4) {
            Spacer()
            Text("#\(String(format: "%02d", task.taskId))")
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundStyle(Color.quirklyTextDark.opacity(0.22))
            Text(isKorean ? "미발견" : "???")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(Color.quirklyTextDark.opacity(0.18))
            Spacer()
            Text(isKorean ? task.category.displayNameKo : task.category.displayNameEn)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(task.category.cardColor.opacity(0.75))
                .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .background(Color(hex: "EDE8DE"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
                .foregroundStyle(Color.quirklyTextDark.opacity(0.2))
        )
    }
}

#Preview {
    do {
        let container = try ModelContainer(for: QuirkyTask.self, QuirkyRecord.self,
                                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        return HistoryView()
            .environment(AppSettings())
            .environment(TaskRepository())
            .modelContainer(container)
    } catch {
        return Text("Preview error")
    }
}
