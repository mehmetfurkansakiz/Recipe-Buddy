import SwiftUI

struct FavoriteRecipesView: View {
    @EnvironmentObject var dataManager: DataManager
    @Binding var navigationPath: NavigationPath
    
    var body: some View {
        ZStack {
            Color.Background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                LazyVStack {
                    if dataManager.favoritedRecipes.isEmpty {
                        Text("Henüz favori tarifi eklemediniz.")
                            .foregroundStyle(.secondary)
                            .padding(.top, 50)
                    } else {
                        ForEach(dataManager.favoritedRecipes) { recipe in
                            Button(action: {
                                navigationPath.append(AppNavigation.recipeDetail(recipe))
                            }) {
                                SearchResultRow(recipe: recipe)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal)
                            Divider().padding(.leading)
                        }
                    }
                }
            }
        }
        .navigationTitle("Favori Tariflerim")
        .inlineColoredNavigationBar(titleColor: .AppPrimary, textStyle: .headline, weight: .bold, hidesOnSwipe: true, transparentBackground: true)
    }
}
