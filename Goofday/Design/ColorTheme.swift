//
//  ColorTheme.swift
//  Goofday
//
//  팝아트 + 리소그래프 스타일 컬러 팔레트
//

import SwiftUI

// MARK: - Goofday 컬러 팔레트

extension Color {
    // Primary
    static let goofYellow = Color(hex: "F5C800")
    static let goofBlue = Color(hex: "2B4EE8")
    
    // Accents
    static let goofRed = Color(hex: "E8304A")
    static let goofPink = Color(hex: "FF85A1")
    static let goofGreen = Color(hex: "3DBF6E")
    static let goofOrange = Color(hex: "FF8C42")
    
    // Backgrounds
    static let goofBgLight = Color(hex: "FFFEF5")
    static let goofSurface = Color(hex: "FFF0C8")
    static let goofBgDark = Color(hex: "1A1A2E")
    static let goofSurfaceDark = Color(hex: "2A2A45")
    
    // Text
    static let goofTextDark = Color(hex: "1A1A2E")
    static let goofTextLight = Color(hex: "FFFEF5")
    
    // Hex 초기화
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - 카드 배경색 (카테고리별)

extension TaskCategory {
    var cardColor: Color {
        switch self {
        case .observation: return .goofYellow
        case .speech: return .goofBlue
        case .food: return .goofRed
        case .movement: return .goofGreen
        case .creative: return .goofPink
        case .solo: return .goofOrange
        case .social: return .goofBlue.opacity(0.8)
        }
    }
    
    var cardTextColor: Color {
        switch self {
        case .observation: return .goofTextDark
        case .speech: return .goofTextLight
        case .food: return .goofTextLight
        case .movement: return .goofTextLight
        case .creative: return .goofTextDark
        case .solo: return .goofTextLight
        case .social: return .goofTextLight
        }
    }
}

// MARK: - 팝아트 카드 스타일

struct PopArtCardStyle: ViewModifier {
    var backgroundColor: Color = .goofYellow
    var rotation: Double = 0
    
    func body(content: Content) -> some View {
        content
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.goofTextDark, lineWidth: 3)
            )
            .rotationEffect(.degrees(rotation))
            .shadow(color: .black.opacity(0.15), radius: 8, x: 4, y: 4)
    }
}

extension View {
    func popArtCard(color: Color = .goofYellow, rotation: Double = 0) -> some View {
        modifier(PopArtCardStyle(backgroundColor: color, rotation: rotation))
    }
}

// MARK: - 볼드 버튼 스타일

struct GoofButtonStyle: ButtonStyle {
    var color: Color = .goofBlue
    var textColor: Color = .goofTextLight
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .bold))
            .foregroundColor(textColor)
            .padding(.horizontal, 28)
            .padding(.vertical, 14)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.goofTextDark, lineWidth: 2.5)
            )
            .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Sparkle 장식 효과

struct SparkleView: View {
    let size: CGFloat
    let color: Color
    
    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: size, weight: .bold))
            .foregroundStyle(color)
    }
}
