import SwiftUI

struct OnboardingView: View {
    let onFinish: () -> Void

    @State private var pageIndex: Int = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Tarifleri Keşfet",
            subtitle: "Topluluğun tariflerini kategorilere göre bul, ilham al ve hemen pişirmeye başla.",
            backgroundAsset: "onboarding_1_bg",
            titleSize: 56,
            visualHeight: 430,
            backgroundWidthRatio: 0.88,
            bubbles: [
                BubbleSpec(
                    width: 70,
                    height: 70,
                    offsetXRatio: 0.33,
                    offsetY: -124,
                    rotation: 4,
                    iconSystemName: "star",
                    iconBackground: Color(red: 0.78, green: 0.12, blue: 0.35),
                    iconForeground: .white,
                    title: nil,
                    subtitle: nil,
                    progress: nil,
                    textRotation: 0,
                    textTopPadding: 18,
                    textLeadingPadding: 56
                ),
                BubbleSpec(
                    width: 228,
                    height: 86,
                    offsetXRatio: -0.20,
                    offsetY: 134,
                    rotation: 0,
                    iconSystemName: "fork.knife",
                    iconBackground: Color(red: 0.78, green: 0.12, blue: 0.20),
                    iconForeground: .white,
                    title: "Günün İlhamı",
                    subtitle: "Yeni tarifler seni bekliyor",
                    progress: nil,
                    textRotation: 0,
                    textTopPadding: 24,
                    textLeadingPadding: 66
                )
            ]
        ),
        OnboardingPage(
            title: "Kendi Tarifini Paylaş",
            subtitle: "Adım adım tarif oluştur, görsel ekle ve mutfağındaki favorileri herkesle paylaş.",
            backgroundAsset: "onboarding_3_bg",
            titleSize: 50,
            visualHeight: 430,
            backgroundWidthRatio: 0.89,
            bubbles: [
                BubbleSpec(
                    width: 62,
                    height: 62,
                    offsetXRatio: -0.30,
                    offsetY: -130,
                    rotation: -7,
                    iconSystemName: "fork.knife",
                    iconBackground: .white,
                    iconForeground: Color(red: 0.78, green: 0.12, blue: 0.20),
                    title: nil,
                    subtitle: nil,
                    progress: nil,
                    textRotation: 0,
                    textTopPadding: 20,
                    textLeadingPadding: 60
                ),
                BubbleSpec(
                    width: 236,
                    height: 100,
                    offsetXRatio: 0.13,
                    offsetY: 126,
                    rotation: -7,
                    iconSystemName: "camera.fill",
                    iconBackground: Color(red: 0.10, green: 0.73, blue: 0.86),
                    iconForeground: .white,
                    title: "YENİ TARİF EKLE",
                    subtitle: "Görsel yükleniyor... %75",
                    progress: .init(value: 0.75, trackTint: Color(red: 0.95, green: 0.83, blue: 0.84), fillTint: Color(red: 0.10, green: 0.73, blue: 0.86)),
                    textRotation: 0,
                    textTopPadding: 23,
                    textLeadingPadding: 76,
                    subtitleSpacing: 7
                )
            ]
        ),
        OnboardingPage(
            title: "Planla ve Yönet",
            subtitle: "Favorilere ekle, alışveriş listeni düzenle ve her hafta menünü kolayca hazırla.",
            backgroundAsset: "onboarding_2_bg",
            titleSize: 56,
            visualHeight: 430,
            backgroundWidthRatio: 0.90,
            bubbles: [
                BubbleSpec(
                    width: 188,
                    height: 82,
                    offsetXRatio: 0.28,
                    offsetY: -128,
                    rotation: -8,
                    iconSystemName: "calendar",
                    iconBackground: Color(red: 0.78, green: 0.12, blue: 0.20),
                    iconForeground: .white,
                    title: "HAFTALIK PLAN",
                    subtitle: "Pazartesi Hazır!",
                    progress: nil,
                    textRotation: 0,
                    textTopPadding: 22,
                    textLeadingPadding: 74,
                    subtitleSpacing: 6
                ),
                BubbleSpec(
                    width: 214,
                    height: 82,
                    offsetXRatio: -0.20,
                    offsetY: 134,
                    rotation: -3,
                    iconSystemName: "leaf.fill",
                    iconBackground: Color(red: 0.20, green: 0.23, blue: 0.25),
                    iconForeground: .white,
                    title: "YENİ FAVORİ",
                    subtitle: "Kinoa Salatası",
                    progress: nil,
                    textRotation: 0,
                    textTopPadding: 24,
                    textLeadingPadding: 74,
                    titleColor: Color(red: 0.03, green: 0.63, blue: 0.63)
                )
            ]
        )
    ]

    var body: some View {
        ZStack {
            Color(red: 0.98, green: 0.95, blue: 0.95)
                .ignoresSafeArea()

            TabView(selection: $pageIndex) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    OnboardingPageView(page: page)
                        .tag(index)
                        .padding(.horizontal, 8)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .safeAreaInset(edge: .bottom) {
            controls
                .padding(.top, 10)
                .padding(.bottom, 12)
                .background(Color(red: 0.98, green: 0.95, blue: 0.95).opacity(0.96))
        }
    }

    private var controls: some View {
        VStack(spacing: 14) {
            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { idx in
                    Capsule()
                        .fill(idx == pageIndex ? Color.AppPrimary : Color.AppPrimary.opacity(0.25))
                        .frame(width: idx == pageIndex ? 24 : 8, height: 8)
                }
            }

            HStack(spacing: 12) {
                if pageIndex > 0 {
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            pageIndex -= 1
                        }
                    } label: {
                        Text("Geri")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.AppPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white.opacity(0.9))
                            .clipShape(Capsule())
                    }
                }

                Button {
                    if pageIndex == pages.count - 1 {
                        onFinish()
                    } else {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            pageIndex += 1
                        }
                    }
                } label: {
                    Text(pageIndex == pages.count - 1 ? "Başla" : "İleri")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color.AppPrimary.opacity(0.95), Color.AppPrimary.opacity(0.78)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 26)
        }
    }
}

private struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        GeometryReader { geo in
            let canvas = min(geo.size.width * 0.95, 380)
            let visualHeight = min(page.visualHeight, max(280, geo.size.height * 0.48))
            let adaptiveTitleSize = min(page.titleSize - 14, geo.size.width * 0.09)
            let adaptiveSubtitleSize = min(16.0, geo.size.width * 0.043)
            let topPadding = min(22, max(10, geo.size.height * 0.025))
            let bubbleScale = min(0.88, max(0.76, geo.size.height / 900))

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    ZStack {
                        Image(page.backgroundAsset)
                            .resizable()
                            .scaledToFit()
                            .frame(width: canvas * page.backgroundWidthRatio)

                        ForEach(Array(page.bubbles.enumerated()), id: \.offset) { _, bubble in
                            BubbleCard(spec: bubble)
                                .frame(width: bubble.width, height: bubble.height)
                                .scaleEffect(bubbleScale)
                                .offset(
                                    x: canvas * bubble.offsetXRatio * bubbleScale,
                                    y: bubble.offsetY * bubbleScale
                                )
                                .rotationEffect(.degrees(bubble.rotation))
                        }
                    }
                    .frame(height: visualHeight)
                    .clipped()
                    .padding(.top, topPadding)

                    Text(LocalizedStringKey(page.title))
                        .font(.system(size: adaptiveTitleSize, weight: .heavy, design: .rounded))
                        .minimumScaleFactor(0.65)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color(red: 0.34, green: 0.14, blue: 0.16))
                        .padding(.horizontal, 18)
                        .padding(.top, 18)

                    Text(LocalizedStringKey(page.subtitle))
                        .font(.system(size: adaptiveSubtitleSize, weight: .semibold))
                        .foregroundStyle(Color(red: 0.45, green: 0.32, blue: 0.33))
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct BubbleCard: View {
    let spec: BubbleSpec

    private var isIconOnly: Bool {
        spec.title == nil && spec.subtitle == nil && spec.progress == nil
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Group {
                if isIconOnly {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.97), Color.white.opacity(0.90)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.78), lineWidth: 1))
                } else {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.94), Color.white.opacity(0.82)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Color.white.opacity(0.75), lineWidth: 1)
                        )
                }
            }
            .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 6)

            Circle()
                .fill(spec.iconBackground)
                .frame(width: isIconOnly ? 34 : 40, height: isIconOnly ? 34 : 40)
                .overlay(
                    Image(systemName: spec.iconSystemName)
                        .font(.system(size: isIconOnly ? 14 : 16, weight: .bold))
                        .foregroundStyle(spec.iconForeground)
                )
                .offset(x: isIconOnly ? (spec.width - 34) / 2 : 10, y: isIconOnly ? (spec.height - 34) / 2 : 10)

            if let title = spec.title, let subtitle = spec.subtitle {
                VStack(alignment: .leading, spacing: spec.subtitleSpacing) {
                    Text(LocalizedStringKey(title))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(spec.titleColor)
                        .lineLimit(1)

                    Text(LocalizedStringKey(subtitle))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(spec.subtitleColor)
                        .lineLimit(1)
                }
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: spec.progress == nil ? .leading : .topLeading
                )
                .padding(.top, spec.progress == nil ? 0 : spec.textTopPadding)
                .padding(.leading, spec.textLeadingPadding)
                .padding(.trailing, 12)
                .padding(.bottom, spec.progress == nil ? 0 : 26)
                .rotationEffect(.degrees(spec.textRotation))
            }

            if let progress = spec.progress {
                VStack {
                    Spacer()
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(progress.trackTint)
                            .frame(height: 6)

                        Capsule()
                            .fill(progress.fillTint)
                            .frame(width: max((spec.width - 32) * progress.value, 10), height: 6)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
            }
        }
    }
}

private struct OnboardingPage {
    let title: String
    let subtitle: String
    let backgroundAsset: String
    let titleSize: CGFloat
    let visualHeight: CGFloat
    let backgroundWidthRatio: CGFloat
    let bubbles: [BubbleSpec]
}

private struct BubbleSpec {
    let width: CGFloat
    let height: CGFloat
    let offsetXRatio: CGFloat
    let offsetY: CGFloat
    let rotation: Double
    let iconSystemName: String
    let iconBackground: Color
    let iconForeground: Color
    let title: String?
    let subtitle: String?
    let progress: ProgressSpec?
    let textRotation: Double
    let textTopPadding: CGFloat
    let textLeadingPadding: CGFloat
    var subtitleSpacing: CGFloat = 2
    var titleColor: Color = Color(red: 0.72, green: 0.12, blue: 0.20)
    var subtitleColor: Color = Color(red: 0.28, green: 0.23, blue: 0.23)
}

private struct ProgressSpec {
    let value: CGFloat
    let trackTint: Color
    let fillTint: Color
}

#Preview {
    OnboardingView(onFinish: {})
}
