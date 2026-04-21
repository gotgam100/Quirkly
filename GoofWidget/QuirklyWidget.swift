//
//  QuirklyWidget.swift
//  QuirklyWidget
//
//  오늘의 엉뚱한 일을 홈 화면에 표시하는 위젯

import WidgetKit
import SwiftUI

// MARK: - 위젯 데이터 모델

struct WidgetTaskData: Codable {
    let taskTitle: String
    let taskTitleEn: String
    let emoji: String
    let category: String
    let isCompleted: Bool
}

// MARK: - 타임라인 엔트리

struct QuirklyEntry: TimelineEntry {
    let date: Date
    let taskData: WidgetTaskData?
    let isKorean: Bool
}

// MARK: - 데이터 프로바이더

struct QuirklyProvider: AppIntentTimelineProvider {
    private static let suiteName = "group.baekmac.quirkly"
    private static let dataKey = "quirkly_widget_data"
    private static let languageKey = "quirkly_language"

    func placeholder(in context: Context) -> QuirklyEntry {
        QuirklyEntry(
            date: Date(),
            taskData: WidgetTaskData(
                taskTitle: "오늘의 엉뚱한 일",
                taskTitleEn: "Today's Quirky Task",
                emoji: "🎲",
                category: "solo",
                isCompleted: false
            ),
            isKorean: true
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> QuirklyEntry {
        loadEntry()
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<QuirklyEntry> {
        let entry = loadEntry()
        let nextUpdate = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: Date())!)
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    private func loadEntry() -> QuirklyEntry {
        let defaults = UserDefaults(suiteName: Self.suiteName) ?? .standard
        let isKorean = (defaults.string(forKey: Self.languageKey) ?? "korean") == "korean"

        if let data = defaults.data(forKey: Self.dataKey),
           let taskData = try? JSONDecoder().decode(WidgetTaskData.self, from: data) {
            return QuirklyEntry(date: Date(), taskData: taskData, isKorean: isKorean)
        }
        return QuirklyEntry(date: Date(), taskData: nil, isKorean: isKorean)
    }
}

// MARK: - 위젯 뷰

struct QuirklyWidgetEntryView: View {
    var entry: QuirklyProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        if let taskData = entry.taskData {
            if taskData.isCompleted {
                // 완료 상태
                VStack(spacing: 12) {
                    Text("🌈")
                        .font(.system(size: family == .systemSmall ? 44 : 56))
                    Text(entry.isKorean ? "내일도 엉뚱하게" : "Stay quirky tomorrow!")
                        .font(.system(size: family == .systemSmall ? 13 : 16, weight: .black, design: .rounded))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .widgetURL(URL(string: "quirkly://open"))
            } else {
                // 결정한 상태
                VStack(spacing: 8) {
                    Spacer()

                    Text(taskData.emoji)
                        .font(.system(size: family == .systemSmall ? 44 : 56))

                    Text(entry.isKorean ? taskData.taskTitle : taskData.taskTitleEn)
                        .font(.system(size: family == .systemSmall ? 11 : 14, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .lineLimit(3)

                    Spacer()
                }
                .padding(12)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .widgetURL(URL(string: "quirkly://open"))
            }
        } else {
            // 뽑기 전 상태
            VStack(spacing: 8) {
                Text("🎲")
                    .font(.system(size: 44))
                Text("Quirkly")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(Color(red: 0.17, green: 0.31, blue: 0.91))
                Text(entry.isKorean ? "오늘의 엉뚱함을\n뽑아보세요!" : "Pick today's\nquirky task!")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .widgetURL(URL(string: "quirkly://open"))
        }
    }

    private func categoryColor(_ category: String) -> Color {
        switch category {
        case "solo":    return Color(red: 0.53, green: 0.81, blue: 0.98)
        case "social":  return Color(red: 1.0, green: 0.75, blue: 0.60)
        case "creative": return Color(red: 0.80, green: 0.70, blue: 0.98)
        case "active":  return Color(red: 0.60, green: 0.90, blue: 0.75)
        case "mindful": return Color(red: 1.0, green: 0.88, blue: 0.55)
        default:        return Color(red: 0.90, green: 0.90, blue: 0.90)
        }
    }
}

// MARK: - 위젯 정의

struct QuirklyWidget: Widget {
    let kind: String = "QuirklyWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: QuirklyProvider()) { entry in
            QuirklyWidgetEntryView(entry: entry)
                .containerBackground(.fill.secondary, for: .widget)
        }
        .configurationDisplayName("Quirkly")
        .description("오늘의 엉뚱한 일을 홈 화면에서 확인하세요.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - 미리보기

#Preview(as: .systemSmall) {
    QuirklyWidget()
} timeline: {
    QuirklyEntry(
        date: .now,
        taskData: WidgetTaskData(
            taskTitle: "모르는 사람에게 인사하기",
            taskTitleEn: "Say hi to a stranger",
            emoji: "👋",
            category: "social",
            isCompleted: false
        ),
        isKorean: true
    )
    QuirklyEntry(
        date: .now,
        taskData: WidgetTaskData(
            taskTitle: "눈 감고 밥 먹기",
            taskTitleEn: "Eat with your eyes closed",
            emoji: "🙈",
            category: "solo",
            isCompleted: true
        ),
        isKorean: true
    )
}
