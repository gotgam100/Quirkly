//
//  HistoryView.swift
//  Goofday
//
//  엉뚱한 일 수행 기록 화면
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) private var settings
    @Environment(TaskRepository.self) private var repository
    
    @Query(sort: \GoofyRecord.date, order: .reverse)
    private var allRecords: [GoofyRecord]
    
    @State private var filter: RecordFilter = .all
    @State private var streak = 0
    
    private var isKorean: Bool { settings.language.resolvedIsKorean }
    
    enum RecordFilter: CaseIterable {
        case all, completed, passed
        
        func titleKo() -> String {
            switch self {
            case .all: return "전체"
            case .completed: return "완료"
            case .passed: return "패스"
            }
        }
        
        func titleEn() -> String {
            switch self {
            case .all: return "All"
            case .completed: return "Done"
            case .passed: return "Passed"
            }
        }
    }
    
    private var filteredRecords: [GoofyRecord] {
        switch filter {
        case .all: return allRecords
        case .completed: return allRecords.filter { $0.status == .completed }
        case .passed: return allRecords.filter { $0.status == .passed }
        }
    }
    
    private var groupedRecords: [(String, [GoofyRecord])] {
        let formatter = DateFormatter()
        formatter.locale = isKorean ? Locale(identifier: "ko_KR") : Locale(identifier: "en_US")
        formatter.dateStyle = .long
        
        let grouped = Dictionary(grouping: filteredRecords) { record in
            formatter.string(from: record.date)
        }
        
        return grouped.sorted { lhs, rhs in
            guard let lDate = lhs.value.first?.date,
                  let rDate = rhs.value.first?.date else { return false }
            return lDate > rDate
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.goofBgLight.ignoresSafeArea()
                
                if allRecords.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 0) {
                        statsHeader
                            .padding(.bottom, 8)
                        
                        filterPicker
                            .padding(.bottom, 4)
                        
                        List {
                            ForEach(groupedRecords, id: \.0) { dateString, records in
                                Section {
                                    ForEach(records) { record in
                                        RecordRow(record: record, isKorean: isKorean)
                                    }
                                    .onDelete { offsets in
                                        deleteRecords(from: records, at: offsets)
                                    }
                                } header: {
                                    Text("📅 \(dateString)")
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundStyle(Color.goofTextDark.opacity(0.6))
                                }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle(isKorean ? "나의 엉뚱한 기록" : "My Goofy History")
            .navigationBarTitleDisplayMode(.large)
            .task { updateStreak() }
        }
    }
    
    // MARK: - 빈 상태
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("🎲")
                .font(.system(size: 60))
            Text(isKorean ? "아직 기록이 없어요" : "No records yet")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Color.goofTextDark)
            Text(isKorean ? "오늘의 엉뚱한 일을 먼저 뽑아보세요!" : "Pick your first goofy task!")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Color.goofTextDark.opacity(0.5))
        }
    }
    
    // MARK: - 통계 헤더

    private var statsHeader: some View {
        VStack(spacing: 12) {
            // 칭호 배지
            HStack {
                Spacer()
                Text(getTitleForStreak(streak))
                    .font(.custom("PyeongChangPeace-Bold", size: 16))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(colors: [Color.goofBlue, Color.goofPink], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .clipShape(Capsule())
                    .shadow(color: Color.goofPink.opacity(0.4), radius: 5, x: 0, y: 3)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            // 통계 카드
            HStack(spacing: 16) {
                StatCard(
                    emoji: "✅",
                    value: "\(allRecords.filter { $0.status == .completed }.count)",
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
        .padding(.vertical, 6)
    }

    private func getTitleForStreak(_ days: Int) -> String {
        switch days {
        case 1...6:
            return isKorean ? "제법 엉뚱한 친구" : "Quite Goofy Friend"
        case 7...29:
            return isKorean ? "괴짜" : "Weirdo"
        case 30...99:
            return isKorean ? "엉뚱한 철인" : "Goofy Ironman"
        default:
            return isKorean ? "엉뚱함의 전설" : "Legend of Goofiness"
        }
    }
    
    // MARK: - 필터
    
    private var filterPicker: some View {
        HStack(spacing: 8) {
            ForEach(RecordFilter.allCases, id: \.self) { filterOption in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        filter = filterOption
                    }
                } label: {
                    Text(isKorean ? filterOption.titleKo() : filterOption.titleEn())
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(filter == filterOption ? Color.goofTextLight : Color.goofTextDark)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(filter == filterOption ? Color.goofBlue : Color.goofSurface)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color.goofTextDark.opacity(0.15), lineWidth: 1)
                        )
                }
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
        .padding(.top, 16)
    }
    
    // MARK: - 기록 리스트
    

    
    // MARK: - 삭제
    
    private func deleteRecords(from records: [GoofyRecord], at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(records[index])
        }
        try? modelContext.save()
        updateStreak()
    }
    
    private func updateStreak() {
        streak = repository.currentStreak(modelContext: modelContext)
    }
}

// MARK: - 기록 행

struct RecordRow: View {
    let record: GoofyRecord
    let isKorean: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Text(record.status.emoji)
                .font(.title3)
            
            Text(record.taskEmoji)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(record.taskTitle(for: isKorean ? .korean : .english))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.goofTextDark)
                    .lineLimit(2)
                
                Text(record.date, style: .time)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.goofTextDark.opacity(0.4))
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
        .listRowBackground(Color.goofBgLight)
    }
}

// MARK: - 통계 카드

struct StatCard: View {
    let emoji: String
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 12) {
            Text(emoji)
                .font(.system(size: 22))
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(Color.goofTextDark)
                Text(label)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.goofTextDark.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 12)
        .background(Color.goofSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.goofTextDark.opacity(0.15), lineWidth: 1.5)
        )
    }
}
