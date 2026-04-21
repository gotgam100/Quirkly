//
//  WidgetDataService.swift
//  Quirkly
//
//  앱과 위젯 간 데이터 공유 서비스
//

import Foundation
import WidgetKit

struct WidgetData: Codable {
    let taskTitle: String
    let taskTitleEn: String
    let emoji: String
    let category: String
    let isCompleted: Bool
}

struct WidgetDataService {
    private static let suiteName = "group.baekmac.quirkly"
    private static let defaults = UserDefaults(suiteName: suiteName) ?? .standard
    private static let key = "quirkly_widget_data"
    private static let languageKey = "quirkly_language"

    static func updateWidgetData(task: QuirkyTask?, isCompleted: Bool, language: String = "korean") {
        if let task = task {
            let data = WidgetData(
                taskTitle: task.titleKo,
                taskTitleEn: task.titleEn,
                emoji: task.emoji,
                category: task.categoryRaw,
                isCompleted: isCompleted
            )
            if let encoded = try? JSONEncoder().encode(data) {
                defaults.set(encoded, forKey: key)
            }
        } else {
            defaults.removeObject(forKey: key)
        }
        defaults.set(language, forKey: languageKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func getWidgetData() -> WidgetData? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(WidgetData.self, from: data)
    }
}
