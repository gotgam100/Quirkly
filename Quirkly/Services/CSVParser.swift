//
//  CSVParser.swift
//  Quirkly
//
//  Google Sheets CSV 파싱 유틸리티
//

import Foundation

struct CSVParser {
    
    /// CSV 데이터를 QuirkyTaskDTO 배열로 변환
    static func parse(_ data: Data) -> [QuirkyTaskDTO] {
        guard let csvString = String(data: data, encoding: .utf8) else { return [] }
        
        let rows = parseCSVRows(csvString)
        guard rows.count > 1 else { return [] } // 헤더 + 최소 1행 필요
        
        let header = rows[0]
        
        // 컬럼 인덱스 찾기
        guard let idIndex = header.firstIndex(of: "id"),
              let emojiIndex = header.firstIndex(of: "emoji"),
              let titleKoIndex = header.firstIndex(of: "titleKo"),
              let titleEnIndex = header.firstIndex(of: "titleEn"),
              let categoryIndex = header.firstIndex(of: "category"),
              let difficultyIndex = header.firstIndex(of: "difficulty") else {
            print("CSVParser: 필수 컬럼이 누락되었습니다.")
            return []
        }
        
        let maxIndex = [idIndex, emojiIndex, titleKoIndex, titleEnIndex, categoryIndex, difficultyIndex].max()!
        
        var tasks: [QuirkyTaskDTO] = []
        
        for i in 1..<rows.count {
            let columns = rows[i]
            guard columns.count > maxIndex else { continue }
            
            guard let id = Int(columns[idIndex].trimmingCharacters(in: .whitespaces)) else { continue }
            
            // category: "관찰 / observation" 형식에서 영문만 추출
            let rawCategory = columns[categoryIndex].trimmingCharacters(in: .whitespaces)
            let category = rawCategory.contains("/")
                ? (rawCategory.components(separatedBy: "/").last?.trimmingCharacters(in: .whitespaces) ?? rawCategory)
                : rawCategory

            let task = QuirkyTaskDTO(
                id: id,
                emoji: columns[emojiIndex].trimmingCharacters(in: .whitespaces),
                titleKo: columns[titleKoIndex].trimmingCharacters(in: .whitespaces),
                titleEn: columns[titleEnIndex].trimmingCharacters(in: .whitespaces),
                category: category,
                difficulty: columns[difficultyIndex].trimmingCharacters(in: .whitespaces)
            )
            tasks.append(task)
        }
        
        return tasks
    }
    
    /// CSV 문자열을 행/열 2차원 배열로 파싱 (따옴표 내 쉼표 처리)
    private static func parseCSVRows(_ csv: String) -> [[String]] {
        var rows: [[String]] = []
        var currentRow: [String] = []
        var currentField = ""
        var inQuotes = false
        
        let chars = Array(csv)
        var i = 0
        
        while i < chars.count {
            let char = chars[i]
            
            if inQuotes {
                if char == "\"" {
                    // 다음 문자도 따옴표면 이스케이프
                    if i + 1 < chars.count && chars[i + 1] == "\"" {
                        currentField.append("\"")
                        i += 2
                        continue
                    } else {
                        inQuotes = false
                    }
                } else {
                    currentField.append(char)
                }
            } else {
                if char == "\"" {
                    inQuotes = true
                } else if char == "," {
                    currentRow.append(currentField)
                    currentField = ""
                } else if char.isNewline {
                    currentRow.append(currentField)
                    currentField = ""
                    if !currentRow.allSatisfy({ $0.isEmpty }) {
                        rows.append(currentRow)
                    }
                    currentRow = []
                } else {
                    currentField.append(char)
                }
            }
            i += 1
        }
        
        // 마지막 행
        if !currentField.isEmpty || !currentRow.isEmpty {
            currentRow.append(currentField)
            if !currentRow.allSatisfy({ $0.isEmpty }) {
                rows.append(currentRow)
            }
        }
        
        return rows
    }
}
