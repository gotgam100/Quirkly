//
//  GoofyTask.swift
//  Goofday
//
//  엉뚱한 일 항목 모델
//

import Foundation
import SwiftData

// MARK: - 카테고리

enum TaskCategory: String, Codable, CaseIterable, Identifiable {
    case observation = "observation"
    case speech = "speech"
    case food = "food"
    case movement = "movement"
    case creative = "creative"
    case solo = "solo"
    case social = "social"
    
    var id: String { rawValue }
    
    var displayNameKo: String {
        switch self {
        case .observation: return "관찰"
        case .speech: return "말하기"
        case .food: return "음식"
        case .movement: return "움직임"
        case .creative: return "창의"
        case .solo: return "혼자"
        case .social: return "사회적"
        }
    }
    
    var displayNameEn: String {
        switch self {
        case .observation: return "Observation"
        case .speech: return "Speech"
        case .food: return "Food"
        case .movement: return "Movement"
        case .creative: return "Creative"
        case .solo: return "Solo"
        case .social: return "Social"
        }
    }
    
    var emoji: String {
        switch self {
        case .observation: return "👀"
        case .speech: return "🗣"
        case .food: return "🍽"
        case .movement: return "🚶"
        case .creative: return "🎭"
        case .solo: return "🧘"
        case .social: return "👥"
        }
    }
}

// MARK: - 난이도

enum TaskDifficulty: String, Codable, CaseIterable {
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"
    
    var displayNameKo: String {
        switch self {
        case .easy: return "쉬움"
        case .medium: return "보통"
        case .hard: return "어려움"
        }
    }
    
    var displayNameEn: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        }
    }
}

// MARK: - GoofyTask 모델

@Model
final class GoofyTask {
    @Attribute(.unique) var taskId: Int
    var emoji: String
    var titleKo: String
    var titleEn: String
    var categoryRaw: String
    var difficultyRaw: String
    
    var category: TaskCategory {
        get { TaskCategory(rawValue: categoryRaw) ?? .solo }
        set { categoryRaw = newValue.rawValue }
    }
    
    var difficulty: TaskDifficulty {
        get { TaskDifficulty(rawValue: difficultyRaw) ?? .easy }
        set { difficultyRaw = newValue.rawValue }
    }
    
    /// 현재 언어에 맞는 제목 반환
    func title(for language: AppLanguage) -> String {
        switch language {
        case .korean: return titleKo
        case .english: return titleEn
        }
    }
    
    init(taskId: Int, emoji: String, titleKo: String, titleEn: String, category: TaskCategory, difficulty: TaskDifficulty) {
        self.taskId = taskId
        self.emoji = emoji
        self.titleKo = titleKo
        self.titleEn = titleEn
        self.categoryRaw = category.rawValue
        self.difficultyRaw = difficulty.rawValue
    }
}

// MARK: - CSV 파싱용 구조체

struct GoofyTaskDTO: Codable {
    let id: Int
    let emoji: String
    let titleKo: String
    let titleEn: String
    let category: String
    let difficulty: String
    
    func toModel() -> GoofyTask {
        GoofyTask(
            taskId: id,
            emoji: emoji,
            titleKo: titleKo,
            titleEn: titleEn,
            category: TaskCategory(rawValue: category) ?? .solo,
            difficulty: TaskDifficulty(rawValue: difficulty) ?? .easy
        )
    }
}
