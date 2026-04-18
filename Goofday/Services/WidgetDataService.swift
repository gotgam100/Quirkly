//
//  WidgetDataService.swift
//  Goofday
//
//  앱과 위젯 간 데이터 공유 서비스
//

import Foundation
import WidgetKit

struct WidgetData: Codable {
    let taskTitle: String
    let emoji: String
    let category: String
    let isCompleted: Bool
}

struct WidgetDataService {
    // TODO: 실제 App Group ID로 교체 필요 (예: group.com.yourname.goofday)
    // 현재는 일반 UserDefaults를 사용하지만, 위젯 연동 시에는 App Group이 필수입니다.
    private static let suiteName = "group.baekmac.goofday"
    private static let defaults = UserDefaults(suiteName: suiteName) ?? .standard
    private static let key = "goofday_widget_data"
    
    static func updateWidgetData(task: GoofyTask?, isCompleted: Bool) {
        if let task = task {
            let data = WidgetData(
                taskTitle: task.titleKo,
                emoji: task.emoji,
                category: task.category.rawValue,
                isCompleted: isCompleted
            )
            if let encoded = try? JSONEncoder().encode(data) {
                defaults.set(encoded, forKey: key)
            }
        } else {
            defaults.removeObject(forKey: key)
        }
        
        // 위젯 강제 업데이트
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    static func getWidgetData() -> WidgetData? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(WidgetData.self, from: data)
    }
}
