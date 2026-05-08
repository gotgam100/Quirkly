//
//  ICloudSyncService.swift
//  Quirkly
//
//  iCloud 동기화 전환 시 기존 기록 마이그레이션 처리
//

import Foundation
import SwiftData

struct ICloudSyncService {

    // MARK: - UserDefaults Keys

    static let migrationPendingKey = "quirkly_cloud_migration_pending"
    static let migrationDataKey    = "quirkly_cloud_migration_data"
    static let iCloudEnabledKey    = "quirkly_icloud_sync"

    // MARK: - 전환 준비 (설정에서 토글 시 호출)

    /// 현재 기록을 UserDefaults에 백업하고 재시작 후 새 스토어에 이전할 준비를 합니다.
    @MainActor
    static func prepareMigration(modelContext: ModelContext, enableICloud: Bool) {
        // 1. 전체 기록 JSON 인코딩 → UserDefaults 임시 저장
        let records = (try? modelContext.fetch(FetchDescriptor<QuirkyRecord>())) ?? []
        let dtos: [[String: Any]] = records.map { r in
            [
                "taskId":      r.taskId,
                "taskTitleKo": r.taskTitleKo,
                "taskTitleEn": r.taskTitleEn,
                "taskEmoji":   r.taskEmoji,
                "status":      r.statusRaw,
                "date":        r.date.timeIntervalSince1970,
                "category":    r.taskCategoryRaw
            ]
        }

        if let data = try? JSONSerialization.data(withJSONObject: dtos) {
            UserDefaults.standard.set(data, forKey: migrationDataKey)
        }

        // 2. 재시작 후 마이그레이션 플래그 + iCloud 설정 저장
        UserDefaults.standard.set(true, forKey: migrationPendingKey)
        UserDefaults.standard.set(enableICloud, forKey: iCloudEnabledKey)
    }

    // MARK: - 마이그레이션 실행 (앱 재시작 후 새 스토어에 호출)

    /// 대기 중인 마이그레이션 데이터를 새 ModelContainer에 삽입합니다.
    @MainActor
    static func performPendingMigration(container: ModelContainer) {
        guard UserDefaults.standard.bool(forKey: migrationPendingKey) else { return }

        defer {
            UserDefaults.standard.removeObject(forKey: migrationPendingKey)
            UserDefaults.standard.removeObject(forKey: migrationDataKey)
        }

        guard let data  = UserDefaults.standard.data(forKey: migrationDataKey),
              let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return }

        let context = container.mainContext

        // 기존 기록 키 집합 (중복 삽입 방지)
        let existing     = (try? context.fetch(FetchDescriptor<QuirkyRecord>())) ?? []
        let existingKeys = Set(existing.map { "\($0.taskId)_\(Int($0.date.timeIntervalSince1970))" })

        var inserted = 0
        for dto in array {
            guard let taskId      = dto["taskId"]      as? Int,
                  let titleKo     = dto["taskTitleKo"]  as? String,
                  let titleEn     = dto["taskTitleEn"]  as? String,
                  let emoji       = dto["taskEmoji"]    as? String,
                  let statusStr   = dto["status"]       as? String,
                  let dateInterval = dto["date"]        as? TimeInterval,
                  let categoryStr = dto["category"]     as? String else { continue }

            let key = "\(taskId)_\(Int(dateInterval))"
            guard !existingKeys.contains(key) else { continue }

            let record = QuirkyRecord(
                taskId: taskId,
                taskTitleKo: titleKo,
                taskTitleEn: titleEn,
                taskEmoji: emoji,
                statusRaw: statusStr,
                date: Date(timeIntervalSince1970: dateInterval),
                taskCategoryRaw: categoryStr
            )
            context.insert(record)
            inserted += 1
        }

        if inserted > 0 { try? context.save() }
    }
}
