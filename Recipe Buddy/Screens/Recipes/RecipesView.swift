import SwiftUI
import UIKit

struct RecipesView: View {
    @StateObject var viewModel: RecipesViewModel
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        GeometryReader { geometry in
            let contentWidth = min(geometry.size.width, 430)

            ZStack {
                Color.Background.ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView(showsIndicators: false) {
                        SearchBarView(searchText: $viewModel.searchText)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)

                        if dataManager.isLoading && dataManager.ownedRecipes.isEmpty {
                            ProgressView().padding(.top, 50)
                        } else {
                            let searchResults = viewModel.searchResults(from: dataManager)
                            if !viewModel.searchText.isEmpty {
                                searchResultsContent(for: searchResults)
                            } else {
                                mainContent
                            }
                        }
                    }
                    .frame(width: contentWidth)
                    .frame(maxWidth: .infinity)
                }

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            navigationPath.append(AppNavigation.recipeCreate)
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.AppPrimary)
                                    .frame(width: 56, height: 56)
                                    .shadow(color: .black.opacity(0.4), radius: 8, y: 4)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )

                                Image("plus.icon")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                    .foregroundStyle(Color.white)
                            }
                        }
                        .accessibilityLabel("Tarif Oluştur")
                        .padding(.trailing, 16)
                        .padding(.bottom, 16)
                    }
                }
                .frame(width: contentWidth)
                .frame(maxWidth: .infinity)
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .onAppear {
            Task {
                if dataManager.ownedRecipes.isEmpty && dataManager.favoritedRecipes.isEmpty {
                    await dataManager.loadInitialUserData()
                }
            }
        }
        // Navigation title and appearance with helper modifier
        .navigationTitle("Tariflerim")
        .inlineColoredNavigationBar(titleColor: .AppPrimary, textStyle: .headline, weight: .bold, hidesOnSwipe: true, transparentBackground: true)
    }
    
    // MARK: - Supporting Views
    
    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 30) {
            if dataManager.favoritedRecipes.isEmpty && dataManager.ownedRecipes.isEmpty {
                emptyStateView
            } else {
                favoritesSectionLink
                
                if !dataManager.ownedRecipes.isEmpty {
                    myRecipesGrid
                }
            }
            Spacer(minLength: 128)
        }
    }
    
    /// Search results content
    private func searchResultsContent(for results: [Recipe]) -> some View {
        LazyVStack {
            if results.isEmpty {
                Text("Arama sonucu bulunamadı.")
                    .foregroundStyle(.secondary)
                    .padding(.top, 50)
            } else {
                ForEach(results) { recipe in
                    Button(action: { navigationPath.append(AppNavigation.recipeDetail(recipe)) }) {
                        VStack(spacing: 0) {
                            SearchResultRow(recipe: recipe)
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                            Divider().padding(.leading)
                        }
                    }
                }
            }
        }
    }
    
    private var myRecipesGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Oluşturduğum Tarifler")
                .font(.title3).bold()
                .padding(.horizontal)
                .foregroundStyle(.AppPrimary)
            
            GeometryReader { geometry in
                let cardWidth = max(132, (geometry.size.width - 48) / 2)

                LazyVGrid(
                    columns: [
                        GridItem(.fixed(cardWidth), spacing: 16),
                        GridItem(.fixed(cardWidth), spacing: 16)
                    ],
                    spacing: 16
                ) {
                    ForEach(dataManager.ownedRecipes) { recipe in
                        Button(action: { navigationPath.append(AppNavigation.recipeDetail(recipe))}) {
                            ExploreRecipeCard(recipe: recipe, cardWidth: cardWidth, showAuthor: false)
                        }
                        .onAppear {
                            if recipe.id == dataManager.ownedRecipes.last?.id {
                                Task {
                                    await dataManager.fetchMoreOwnedRecipes()
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: ownedRecipesGridHeight)
        }
    }

    private var ownedRecipesGridHeight: CGFloat {
        let rows = max(1, Int(ceil(Double(dataManager.ownedRecipes.count) / 2.0)))
        return CGFloat(rows) * 236 + CGFloat(max(0, rows - 1)) * 16
    }
    
    private var favoritesSectionLink: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Favori Tariflerim")
                .font(.title3).bold()
                .padding(.horizontal)
                .foregroundStyle(.AppPrimary)
            
            if dataManager.favoritedRecipes.isEmpty {
                // if list is empty, show the empty state message
                VStack(alignment: .leading, spacing: 4) {
                    Text("Henüz favori tarifiniz yok.")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.TextPrimary)
                    Text("Tariflerin yanındaki ❤️ simgesine tıklayarak favorilerinizi burada görebilirsiniz.")
                        .font(.caption)
                        .foregroundStyle(.TextSecondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.thinMaterial.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.SurfaceBorder , lineWidth: 1))
                .padding(.horizontal)
                
            } else {
                // if list is not empty, show the button to navigate
                Button(action: {
                    navigationPath.append(AppNavigation.favoriteRecipes)
                }) {
                    HStack {
                        Text("Tümünü Gör")
                            .fontWeight(.semibold)
                            .foregroundStyle(.TextPrimary)
                        Spacer()
                        Text("\(dataManager.favoritedRecipes.count) tarif")
                            .foregroundStyle(.TextSecondary)
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.TextSecondary)
                    }
                    .padding()
                    .background(.thinMaterial.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(.TextSecondary.opacity(0.5) , lineWidth: 1))
                    .padding(.horizontal)
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bookmark.slash")
                .font(.system(size: 50))
                .foregroundColor(.TextSecondary)
            
            Text("Henüz Tarifiniz Yok")
                .font(.headline)
                .foregroundColor(.TextPrimary)
            
            Text("Yeni bir tarif oluşturun veya Ana sayfadan beğendiklerinizi favorilerinize ekleyin.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(32)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 50)
    }
}

//#Preview {
//    RecipesView(viewModel: RecipesViewModel(), navigationPath: .constant(NavigationPath()))
//        .environmentObject(DataManager())
//}

#Preview {
    // with mock data
    let dataManager = DataManager()
    dataManager.ownedRecipes = Recipe.allMocks.shuffled()
    
    return NavigationStack {
        RecipesView(viewModel: RecipesViewModel(), navigationPath: .constant(NavigationPath()))
            .environmentObject(dataManager)
    }
}
