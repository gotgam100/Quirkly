//
//  TaskRepository.swift
//  Goofday
//
//  Google Sheets CSV 연동 + SwiftData 캐시 Repository
//

import Foundation
import SwiftData

@Observable
final class TaskRepository {
    
    // MARK: - Google Sheets 설정
    private let sheetID = "1mOJS4oV7C_blOZ8coExb7bCUhWhxFj9MhR8f4zNoNkw"
    
    private var exportURL: URL {
        URL(string: "https://docs.google.com/spreadsheets/d/\(sheetID)/export?format=csv&gid=0")!
    }
    
    // MARK: - 상태
    var isLoading = false
    var lastError: String?
    var taskCount = 0
    
    // MARK: - 원격에서 최신 태스크 가져오기 + SwiftData 저장
    
    @MainActor
    func syncFromGoogleSheets(modelContext: ModelContext) async {
        isLoading = true
        lastError = nil
        
        do {
            let (data, response) = try await URLSession.shared.data(from: exportURL)
            
            // HTTP 응답 확인
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode != 200 {
                lastError = "서버 응답 오류: \(httpResponse.statusCode)"
                isLoading = false
                return
            }
            
            let dtos = CSVParser.parse(data)
            
            guard !dtos.isEmpty else {
                lastError = "파싱된 데이터가 없습니다"
                isLoading = false
                return
            }
            
            // 기존 태스크 모두 삭제 후 새로 삽입
            try modelContext.delete(model: GoofyTask.self)
            
            for dto in dtos {
                let task = dto.toModel()
                modelContext.insert(task)
            }
            
            try modelContext.save()
            taskCount = dtos.count
            
        } catch {
            lastError = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - 번들 기본 데이터 로드 (오프라인 / 첫 실행)
    
    @MainActor
    func loadBundledTasks(modelContext: ModelContext) {
        // 이미 데이터가 있으면 스킵
        let descriptor = FetchDescriptor<GoofyTask>()
        if let count = try? modelContext.fetchCount(descriptor), count > 0 {
            taskCount = count
            return
        }
        
        // 번들 JSON에서 로드
        guard let url = Bundle.main.url(forResource: "default_tasks", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let dtos = try? JSONDecoder().decode([GoofyTaskDTO].self, from: data) else {
            print("TaskRepository: 번들 기본 데이터 로드 실패")
            return
        }
        
        for dto in dtos {
            let task = dto.toModel()
            modelContext.insert(task)
        }
        
        try? modelContext.save()
        taskCount = dtos.count
    }
    
    // MARK: - 랜덤 태스크 선택
    
    func randomTask(modelContext: ModelContext, excluding taskId: Int? = nil) -> GoofyTask? {
        var descriptor = FetchDescriptor<GoofyTask>()
        descriptor.fetchLimit = 500
        
        guard let tasks = try? modelContext.fetch(descriptor), !tasks.isEmpty else {
            return nil
        }
        
        let recordDescriptor = FetchDescriptor<GoofyRecord>()
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
        
        let predicate = #Predicate<GoofyRecord> {
            $0.date >= startOfDay && $0.date < endOfDay
        }
        
        var descriptor = FetchDescriptor<GoofyRecord>(predicate: predicate)
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
        let descriptor = FetchDescriptor<GoofyRecord>(
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
