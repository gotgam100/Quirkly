//
//  WhatsNewView.swift
//  Quirkly
//
//  업데이트 새 기능 안내 화면
//

import SwiftUI

struct WhatsNewView: View {
    let isKorean: Bool
    let onDismiss: () -> Void

    private let features: [(emoji: String, titleKo: String, titleEn: String, descKo: String, descEn: String)] = [
        (
            emoji: "☁️",
            titleKo: "iCloud 동기화",
            titleEn: "iCloud Sync",
            descKo: "설정에서 iCloud 동기화를 켜면 기기 변경·재설치 후에도 기록이 유지됩니다.",
            descEn: "Enable iCloud sync in Settings to keep your records across devices and reinstalls."
        ),
        (
            emoji: "📅",
            titleKo: "달력 기록",
            titleEn: "Calendar History",
            descKo: "완료한 날들을 달력에서 한눈에 확인하고, 날짜를 탭해 내용을 볼 수 있어요.",
            descEn: "See completed days on a calendar and tap a date to view details."
        ),
        (
            emoji: "🗂️",
            titleKo: "엉뚱 카드 수집",
            titleEn: "Quirky Card Collection",
            descKo: "완료한 엉뚱한 일들을 카드로 수집해보세요. 아직 찾지 못한 카드도 확인할 수 있어요.",
            descEn: "Collect completed quirky tasks as cards and discover ones you haven't found yet."
        ),
        (
            emoji: "🪄",
            titleKo: "홈 화면 위젯",
            titleEn: "Home Screen Widget",
            descKo: "오늘의 엉뚱한 일을 홈 화면에서 바로 확인하세요.",
            descEn: "Check today's quirky task right from your home screen."
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            VStack(spacing: 12) {
                Text("🎉")
                    .font(.system(size: 56))
                    .padding(.top, 40)

                Text(isKorean ? "새로운 기능" : "What's New")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(Color.quirklyTextDark)

                Text(isKorean ? "버전 1.1.0" : "Version 1.1.0")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.quirklyTextDark.opacity(0.4))
            }
            .padding(.bottom, 32)

            // 기능 목록
            VStack(spacing: 20) {
                ForEach(features, id: \.titleKo) { feature in
                    HStack(alignment: .top, spacing: 16) {
                        Text(feature.emoji)
                            .font(.system(size: 36))
                            .frame(width: 52, height: 52)
                            .background(Color.quirklyBlue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(isKorean ? feature.titleKo : feature.titleEn)
                                .font(.system(size: 16, weight: .black, design: .rounded))
                                .foregroundStyle(Color.quirklyTextDark)
                            Text(isKorean ? feature.descKo : feature.descEn)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.quirklyTextDark.opacity(0.55))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 28)

            Spacer()

            // 확인 버튼
            Button {
                onDismiss()
            } label: {
                Text(isKorean ? "시작하기!" : "Let's Go!")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.quirklyBlue, Color.quirklyPink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 40)
        }
        .background(Color.quirklyBgLight)
    }
}
