import SwiftUI
import NukeUI

struct RecipeCardView: View {
    let recipe: Recipe
    let width: CGFloat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            LazyImage(url: recipe.imagePublicURL()) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    ZStack {
                        Color.gray.opacity(0.1)
                        ProgressView()
                    }
                }
            }
            .frame(width: width - 16, height: width * 1)
            .clipped()
            .cornerRadius(8)
            
            Text(recipe.name)
                .font(.headline)
                .lineLimit(1)
                .foregroundStyle(.TextPrimary)
            
            HStack(spacing: 8) {
                Image("clock.icon")
                    .resizable()
                    .foregroundStyle(.TextSecondary)
                    .frame(width: 18, height: 18)
                Text(LocalizedText.minutesShort(recipe.cookingTime))
                    .font(.caption)
                    .foregroundStyle(.TextSecondary)
                
                Spacer()
                
                if let rating = recipe.rating {
                    Image("star.fill.icon")
                        .foregroundStyle(.AppPrimary)
                    Text(String(format: "%.1f", rating))
                        .font(.caption)
                        .foregroundStyle(.TextSecondary)
                } else {
                    Image("star.icon")
                        .foregroundStyle(Color("C2C2C2"))
                }
            }
        }
        .padding(8)
        .background(.Surface)
        .cornerRadius(8)
        .shadow(radius: 1)
        .padding(.vertical, 8)
    }
}
