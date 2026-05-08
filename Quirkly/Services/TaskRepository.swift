//
//  TaskRepository.swift
//  Quirkly
//
//  SwiftData 태스크 Repository
//

import Foundation
import SwiftData

@Observable
final class TaskRepository {

    // MARK: - 번들 기본 데이터 로드 (첫 실행)
    
    @MainActor
    func loadBundledTasks(modelContext: ModelContext) {
        // 이미 데이터가 있으면 스킵
        let descriptor = FetchDescriptor<QuirkyTask>()
        if let count = try? modelContext.fetchCount(descriptor), count > 0 {
            return
        }

        var dtos: [QuirkyTaskDTO] = []

        // 1. 먼저 번들 CSV에서 로드 시도
        if let csvUrl = Bundle.main.url(forResource: "tasks", withExtension: "csv"),
           let csvData = try? Data(contentsOf: csvUrl) {
            dtos = CSVParser.parse(csvData)
            print("TaskRepository: CSV 데이터 로드 완료 (\(dtos.count)개)")
        }

        // 2. CSV가 없거나 파싱 실패 시 JSON에서 로드
        if dtos.isEmpty,
           let jsonUrl = Bundle.main.url(forResource: "default_tasks", withExtension: "json"),
           let jsonData = try? Data(contentsOf: jsonUrl),
           let jsonDtos = try? JSONDecoder().decode([QuirkyTaskDTO].self, from: jsonData) {
            dtos = jsonDtos
            print("TaskRepository: JSON 데이터 로드 완료 (\(dtos.count)개)")
        }

        guard !dtos.isEmpty else {
            print("TaskRepository: 번들 기본 데이터 로드 실패")
            return
        }

        // 기존 taskId 목록 조회 (CloudKit 중복 방지)
        let existing = (try? modelContext.fetch(FetchDescriptor<QuirkyTask>())) ?? []
        let existingIds = Set(existing.map { $0.taskId })

        var inserted = 0
        for dto in dtos {
            guard !existingIds.contains(dto.id) else { continue }
            modelContext.insert(dto.toModel())
            inserted += 1
        }

        if inserted > 0 { try? modelContext.save() }
    }
    
    // MARK: - 랜덤 태스크 선택
    
    func randomTask(modelContext: ModelContext, excluding taskId: Int? = nil) -> QuirkyTask? {
        var descriptor = FetchDescriptor<QuirkyTask>()
        descriptor.fetchLimit = 500
        
        guard let tasks = try? modelContext.fetch(descriptor), !tasks.isEmpty else {
            return nil
        }
        
        let recordDescriptor = FetchDescriptor<QuirkyRecord>()
        let pastRecords = (try? modelContext.fetch(recordDescriptor)) ?? []
        let pickedTaskIds = Set(pastRecords.map { $0.taskId })
        
        // 과거 뽑혔던 taskId들을 모두 제외
        var candidates = tasks.filter { !pickedTaskIds.contains($0.taskId) }
        
        if let excluded = taskId {
            candidates = candidates.filter { $0.taskId != excluded }
        }
        
        // 만약 모든 태스크를 이미 사용했다면, 앱이 터지지 않게 전체 태스크에서 랜덤 반환
        if candidates.isEmpty { 
            candidates = tasks 
        }
        
        return candidates.randomElement() ?? tasks.randomElement()
    }
    
    // MARK: - 오늘의 통계
    
    func todayStats(modelContext: ModelContext) -> (completed: Int, passed: Int) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = #Predicate<QuirkyRecord> {
            $0.date >= startOfDay && $0.date < endOfDay
        }
        
        var descriptor = FetchDescriptor<QuirkyRecord>(predicate: predicate)
        descriptor.fetchLimit = 100
        
        guard let records = try? modelContext.fetch(descriptor) else {
            return (0, 0)
        }
        
        let completed = records.filter { $0.statusRaw == RecordStatus.completed.rawValue }.count
        let passed = records.filter { $0.statusRaw == RecordStatus.passed.rawValue }.count
        
        return (completed, passed)
    }
    
    // MARK: - Streak 계산
    
    func currentStreak(modelContext: ModelContext) -> Int {
        let descriptor = FetchDescriptor<QuirkyRecord>(
            predicate: #Predicate { $0.statusRaw == "completed" },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        guard let records = try? modelContext.fetch(descriptor), !records.isEmpty else {
            return 0
        }
        
        let calendar = Calendar.current
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        // 오늘 완료한 기록이 있으면 오늘부터, 없으면 어제부터
        let todayRecords = records.filter { calendar.isDate($0.date, inSameDayAs: Date()) }
        if todayRecords.isEmpty {
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
        }
        
        for _ in 0..<365 {
            let dayRecords = records.filter { calendar.isDate($0.date, inSameDayAs: currentDate) }
            if dayRecords.isEmpty {
                break
            }
            streak += 1
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
        }
        
        return streak
    }
}
