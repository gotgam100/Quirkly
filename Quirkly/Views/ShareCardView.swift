//
//  ShareCardView.swift
//  Quirkly
//

import SwiftUI

struct ShareCardView: View {
    let task: QuirkyTask
    let isKorean: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("🎲 Quirkly")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                Spacer()
                Text(Date(), style: .date)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
            }
            .foregroundStyle(task.category.cardTextColor)
            
            Spacer()
            
            VStack(spacing: 16) {
                Text(task.emoji)
                    .font(.system(size: 80))
                
                Text(task.title(for: isKorean ? .korean : .english))
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(task.category.cardTextColor)
                    .padding(.horizontal, 20)
            }
            
            Spacer()
            
            Text(isKorean ? "엉뚱한 일 하나, 오늘도 엉뚱한 하루!" : "One quirky thing, one quirky day!")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Color.white.opacity(0.3))
                .clipShape(Capsule())
                .foregroundStyle(task.category.cardTextColor)
        }
        .padding(30)
        .frame(width: 400, height: 400)
        .background(task.category.cardColor)
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(Color.black.opacity(0.8), lineWidth: 4)
        )
    }
}
