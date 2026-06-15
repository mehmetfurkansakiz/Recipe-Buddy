import SwiftUI
import NukeUI

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        GeometryReader { geometry in
            let contentWidth = min(geometry.size.width, 430)

            ZStack {
                Color.Background.ignoresSafeArea()
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        let usernameToShow = dataManager.currentUser?.fullName ?? dataManager.currentUser?.username ?? "Misafir"
                        HeaderView(searchText: $viewModel.searchText, username: usernameToShow)
                            .padding(.horizontal)

                        if viewModel.searchText.isEmpty {
                            CategoryScrollView(
                                categories: dataManager.availableCategories,
                                selectedCategory: $viewModel.selectedCategory
                            )
                        }

                        if dataManager.isLoading && dataManager.homeSections.isEmpty {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.top, 50)
                        } else {
                            if !viewModel.searchText.isEmpty {
                                SearchResultsView(
                                    recipes: viewModel.searchResults,
                                    users: viewModel.userSearchResults,
                                    navigationPath: $navigationPath
                                )
                            } else if viewModel.selectedCategory != nil {
                                CategoryResultsView(
                                    recipes: viewModel.categoryFilteredRecipes,
                                    isLoading: viewModel.isFetchingCategoryRecipes,
                                    navigationPath: $navigationPath
                                )
                            } else {
                                mainContent
                            }
                        }
                    }
                    .frame(width: contentWidth, alignment: .leading)
                    .frame(maxWidth: .infinity)
                }
                .refreshable {
                    await dataManager.refreshAllData()
                }
            }
        }
        .onAppear {
            Task {
                await NotificationPermissionManager.shared.requestSystemPromptOnceIfNeeded()
            }

            // Cleanup legacy trigger flags from previous flow.
            UserDefaults.standard.removeObject(forKey: "consent_prompt_after_signup")
            UserDefaults.standard.removeObject(forKey: "consent_prompt_after_login")

            TelemetryManager.configureFromConsent()

            Task {
                await ConsentManager.shared.syncMarketingPreferenceWithNotifications()
                await NotificationPermissionManager.shared.requestIfEligible()
            }
        }
    }
    
    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            if let featuredSection = dataManager.homeSections.first(where: { $0.style == .featured }) {
                RecipeCarouselSection(
                    title: featuredSection.title,
                    recipes: featuredSection.recipes,
                    style: featuredSection.style,
                    navigationPath: $navigationPath
                )
            }
            
            if let discoverSection = dataManager.homeSections.first(where: { $0.style == .standard }) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(discoverSection.title)
                        .font(.title3).bold()
                        .padding(.horizontal)
                        .foregroundStyle(.AppPrimary)
                        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                    
                    GeometryReader { geometry in
                        let cardWidth = max(132, (geometry.size.width - 48) / 2)

                        LazyVGrid(
                            columns: [
                                GridItem(.fixed(cardWidth), spacing: 16),
                                GridItem(.fixed(cardWidth), spacing: 16)
                            ],
                            spacing: 16
                        ) {
                            ForEach(discoverSection.recipes) { recipe in
                                Button(action: {
                                    navigationPath.append(AppNavigation.recipeDetail(recipe)) }) {
                                        ExploreRecipeCard(recipe: recipe, cardWidth: cardWidth)
                                    }
                                    .onAppear {
                                        if recipe.id == discoverSection.recipes.last?.id {
                                            Task {
                                                await dataManager.fetchMoreNewestRecipes()
                                            }
                                        }
                                    }
                                }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: gridHeight(itemCount: discoverSection.recipes.count, cardWidth: nil))
                }
            }
            Spacer(minLength: 128)
        }
    }

    private func gridHeight(itemCount: Int, cardWidth: CGFloat?) -> CGFloat {
        let rows = max(1, Int(ceil(Double(itemCount) / 2.0)))
        let estimatedCardHeight = (cardWidth ?? 196) + 72
        return CGFloat(rows) * estimatedCardHeight + CGFloat(max(0, rows - 1)) * 16
    }
}


// MARK: - Helper Views

struct HeaderView: View {
    @Binding var searchText: String
    let username: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Merhaba \(username) 👋")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.AppPrimary)
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text("Ne pişirmek istersin?")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.TextPrimary)
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            
            SearchBarView(searchText: $searchText)
        }
    }
}

struct SearchResultsView: View {
    let recipes: [Recipe]
    let users: [User]
    @Binding var navigationPath: NavigationPath

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !users.isEmpty {
                Text("Profiller")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.top, 4)

                ForEach(users) { user in
                    Button(action: { navigationPath.append(AppNavigation.userProfile(user)) }) {
                        UserSearchResultRow(user: user)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                    Divider().padding(.horizontal)
                }
            }

            if !recipes.isEmpty {
                Text("Tarifler")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.top, users.isEmpty ? 4 : 12)

                ForEach(recipes) { recipe in
                    Button(action: { navigationPath.append(AppNavigation.recipeDetail(recipe)) }) {
                        SearchResultRow(recipe: recipe)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                    Divider().padding(.horizontal)
                }
            }

            if users.isEmpty && recipes.isEmpty {
                Text("Arama sonucu bulunamadı.")
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.top, 24)
            }
        }
    }
}

struct CategoryResultsView: View {
    let recipes: [Recipe]
    let isLoading: Bool
    @Binding var navigationPath: NavigationPath

    var body: some View {
        Group {
            if isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                        .controlSize(.regular)
                    Text("Tarifler yükleniyor...")
                        .font(.footnote)
                        .foregroundStyle(.TextSecondary)
                }
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity, minHeight: 220)
            } else if recipes.isEmpty {
                Text("Bu kategoride tarif bulunamadı.")
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, minHeight: 220, alignment: .top)
            } else {
                GeometryReader { geometry in
                    let cardWidth = max(132, (geometry.size.width - 48) / 2)

                    LazyVGrid(
                        columns: [
                            GridItem(.fixed(cardWidth), spacing: 16),
                            GridItem(.fixed(cardWidth), spacing: 16)
                        ],
                        spacing: 16
                    ) {
                        ForEach(recipes) { recipe in
                            Button(action: { navigationPath.append(AppNavigation.recipeDetail(recipe)) }) {
                                ExploreRecipeCard(recipe: recipe, cardWidth: cardWidth)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: categoryGridHeight(itemCount: recipes.count))
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func categoryGridHeight(itemCount: Int) -> CGFloat {
        let rows = max(1, Int(ceil(Double(itemCount) / 2.0)))
        return CGFloat(rows) * 268 + CGFloat(max(0, rows - 1)) * 16
    }
}

struct UserSearchResultRow: View {
    let user: User

    var body: some View {
        HStack(spacing: 12) {
            LazyImage(url: user.avatarPublicURL()) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.TextSecondary.opacity(0.5))
                }
            }
            .frame(width: 44, height: 44)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.SurfaceBorder, lineWidth: 0.5))

            VStack(alignment: .leading, spacing: 2) {
                Text(user.fullName ?? user.username ?? "İsimsiz")
                    .font(.headline)
                    .foregroundStyle(.TextPrimary)

                if let username = user.username, !username.isEmpty {
                    Text("@\(username)")
                        .font(.caption)
                        .foregroundStyle(.TextSecondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct SearchResultRow: View {
    let recipe: Recipe
    
    var body: some View {
        HStack {
            LazyImage(url: recipe.imagePublicURL()) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .scaledToFill()
                } else {
                    Color.Surface
                }
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading) {
                Text(recipe.name)
                    .font(.headline)
                    .foregroundStyle(.TextPrimary)
                                     
                Text("\(recipe.user?.fullName ?? "")")
                    .font(.caption)
                    .foregroundStyle(.TextPrimary)
            }
            Spacer()
        }
    }
}

struct RecipeCarouselSection: View {
    let title: String
    let recipes: [Recipe]
    let style: SectionStyle
    @Binding var navigationPath: NavigationPath
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3).bold()
                .padding(.horizontal)
                .foregroundStyle(.AppPrimary)
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
            
            GeometryReader { geometry in
                let cardWidthMultiplier: CGFloat = (style == .featured) ? 0.68 : 0.42
                let cardWidth = min(300, max(150, geometry.size.width * cardWidthMultiplier))

                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        ForEach(recipes) { recipe in
                            Button(action: { navigationPath.append(AppNavigation.recipeDetail(recipe)) }) {
                                ExploreRecipeCard(recipe: recipe, cardWidth: cardWidth)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .frame(height: style == .featured ? 360 : 240)
        }
    }
}

#Preview {
    HomeView(viewModel: HomeViewModel(), navigationPath: .constant(NavigationPath()))
        .environmentObject(DataManager())
}
