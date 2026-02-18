import SwiftUI

struct RecipeInfoBadge: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(icon)
                .resizable()
                .foregroundStyle(color)
                .frame(width: 18, height: 18)
            Text(text)
                .font(.caption)
                .fontWeight(.heavy)
                .foregroundStyle(.TextSecondary)
        }
        .lineLimit(1)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.Surface)
        .cornerRadius(8)
    }
}
