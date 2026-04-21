//
//  AppIntent.swift
//  QuirklyWidget
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Quirkly 위젯" }
    static var description: IntentDescription { "오늘의 엉뚱한 일을 홈 화면에서 확인하세요." }
}
