//
//  GoofyRecord.swift
//  Goofday
//
//  엉뚱한 일 수행 기록 모델
//

import Foundation
import SwiftData

// MARK: - 기록 상태

enum RecordStatus: String, Codable {
    case completed = "completed"
    case passed = "passed"
    
    var emoji: String {
        switch self {
        case .completed: return "✅"
        case .passed: return "🔁"
        }
    }
    
    var displayNameKo: String {
        switch self {
        case .completed: return "완료"
        case .passed: return "패스"
        }
    }
    
    var displayNameEn: String {
        switch self {
        case .completed: return "Completed"
        case .passed: return "Passed"
        }
    }
}

// MARK: - GoofyRecord 모델

@Model
final class GoofyRecord {
    var taskId: Int
    var taskEmoji: String
    var taskTitleKo: String
    var taskTitleEn: String
    var taskCategoryRaw: String
    var date: Date
    var statusRaw: String
    
    var status: RecordStatus {
        get { RecordStatus(rawValue: statusRaw) ?? .completed }
        set { statusRaw = newValue.rawValue }
    }
    
    var taskCategory: TaskCategory {
        get { TaskCategory(rawValue: taskCategoryRaw) ?? .solo }
        set { taskCategoryRaw = newValue.rawValue }
    }
    
    func taskTitle(for language: AppLanguage) -> String {
        switch language {
        case .korean: return taskTitleKo
        case .english: return taskTitleEn
        }
    }
    
    init(task: GoofyTask, status: RecordStatus) {
        self.taskId = task.taskId
        self.taskEmoji = task.emoji
        self.taskTitleKo = task.titleKo
        self.taskTitleEn = task.titleEn
        self.taskCategoryRaw = task.categoryRaw
        self.date = Date()
        self.statusRaw = status.rawValue
    }
}
