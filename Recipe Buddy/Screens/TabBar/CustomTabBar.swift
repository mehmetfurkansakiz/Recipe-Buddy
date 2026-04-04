import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    let tabs: [TabItem]
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    withAnimation {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(tabs[index].icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(selectedTab == index ? Color.AppPrimary : Color.TextSecondary)
                            .frame(width: 24, height: 24)
                    }
                    // Her bir butona eşit alan vererek yayılmalarını sağla
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
            }
        }
        // Arka plan ve köşe yuvarlatma işlemleri burada kalmalı
        .background(.regularMaterial)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
    }
}

struct CustomTabBarExample: View {
    @State private var selectedTab = 0
    private let tabs = [
        TabItem(icon: "home.icon"),
        TabItem(icon: "cupcake.icon"),
        TabItem(icon: "cupcake.icon"),
        TabItem(icon: "user.icon")
    ]
    
    var body: some View {
        VStack {
            Spacer()
            CustomTabBar(selectedTab: $selectedTab, tabs: tabs)
        }
    }
}

#Preview {
    CustomTabBarExample()
}
