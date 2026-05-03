import SwiftUI
import NukeUI

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var dataManager: DataManager
    @State private var showConsentSheet = false
    
    var body: some View {
        ZStack {
            Color.Background.ignoresSafeArea()
            // main scrollview
            ScrollView(.vertical, showsIndicators: false) {
                // main vstack
                VStack(alignment: .leading, spacing: 16) {
                    
                    // head and searchbar
                    let usernameToShow = dataManager.currentUser?.fullName ?? dataManager.currentUser?.username ?? ""
                    HeaderView(searchText: $viewModel.searchText, username: usernameToShow)
                        .padding(.horizontal)
                    
                    // category filter buttons
                    if viewModel.searchText.isEmpty {
                        CategoryScrollView(
                            categories: dataManager.availableCategories,
                            selectedCategory: $viewModel.selectedCategory
                        )
                    }

                    // content area
                    if dataManager.isLoading && dataManager.homeSections.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.top, 50)
                    } else {
                        // search mode or category filtered mode
                        if !viewModel.searchText.isEmpty {
                            SearchResultsView(
                                recipes: viewModel.searchResults,
                                navigationPath: $navigationPath
                            )
                        } else if viewModel.selectedCategory != nil {
                            CategoryResultsView(
                                recipes: viewModel.categoryFilteredRecipes,
                                isLoading: viewModel.isFetchingCategoryRecipes,
                                navigationPath: $navigationPath
                            )
                        } else {
                            // main
                            mainContent
                        }
                    }
                }
            }
            .refreshable {
                await dataManager.refreshAllData()
            }
        }
        .onAppear {
            Task {
                await NotificationPermissionManager.shared.requestSystemPromptOnceIfNeeded()
            }

            // Cleanup legacy trigger flags from previous flow.
            UserDefaults.standard.removeObject(forKey: "consent_prompt_after_signup")
            UserDefaults.standard.removeObject(forKey: "consent_prompt_after_login")

            // Show consent prompt only once, even if user dismisses without deciding.
            if ConsentManager.shared.shouldShowConsentPromptOnce() {
                ConsentManager.shared.markConsentPromptSeen()
                showConsentSheet = true
            } else {
                Task {
                    await ConsentManager.shared.syncMarketingPreferenceWithNotifications()
                    await NotificationPermissionManager.shared.requestIfEligible()
                }
            }
        }
        .sheet(isPresented: $showConsentSheet, onDismiss: {
            // After consent completed, if personalization is allowed, consider requesting tracking authorization for ads
            if ConsentManager.shared.personalizationAllowed() {
                ConsentManager.shared.requestTrackingAuthorizationIfNeeded()
            }
            // Reconfigure telemetry according to latest consent
            TelemetryManager.configureFromConsent()

            // Sync marketing preference when consent flow finishes.
            Task {
                await ConsentManager.shared.syncMarketingPreferenceWithNotifications()
                await NotificationPermissionManager.shared.requestIfEligible()
            }
        }) {
            NavigationStack {
                DataConsentPreferencesView(viewModel: DataConsentPreferencesViewModel())
            }
            .presentationDetents([.medium, .large])
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
                        .font(.title2).bold()
                        .padding(.horizontal)
                        .foregroundStyle(.AppPrimary)
                        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                    
                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)],spacing: 16)
                    {
                        ForEach(discoverSection.recipes) { recipe in
                            Button(action: {
                                navigationPath.append(AppNavigation.recipeDetail(recipe)) }) {
                                    let cardWidth = (UIScreen.main.bounds.width / 2) - 24
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
            }
            Spacer(minLength: 128)
        }
    }
}


// MARK: - Helper Views

struct HeaderView: View {
    @Binding var searchText: String
    let username: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Merhaba \(username) 👋")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.AppPrimary)
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
            Text("Ne pişirmek istersin?")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundStyle(.TextPrimary)
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
            
            SearchBarView(searchText: $searchText)
        }
    }
}

struct SearchResultsView: View {
    let recipes: [Recipe]
    @Binding var navigationPath: NavigationPath

    var body: some View {
        VStack {
            ForEach(recipes) { recipe in
                Button(action: { navigationPath.append(AppNavigation.recipeDetail(recipe)) }) {
                    SearchResultRow(recipe: recipe)
                }
                .padding(.horizontal)
                Divider().padding(.horizontal)
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
                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)],
                    spacing: 16
                ) {
                    ForEach(recipes) { recipe in
                        Button(action: { navigationPath.append(AppNavigation.recipeDetail(recipe)) }) {
                            let cardWidth = (UIScreen.main.bounds.width / 2) - 24
                            ExploreRecipeCard(recipe: recipe, cardWidth: cardWidth)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity)
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
        let cardWidthMultiplier: CGFloat = (style == .featured) ? 0.7 : 0.40
        let cardWidth = UIScreen.main.bounds.width * cardWidthMultiplier
        
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2).bold()
                .padding(.horizontal)
                .foregroundStyle(.AppPrimary)
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
            
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
    }
}

#Preview {
    HomeView(viewModel: HomeViewModel(), navigationPath: .constant(NavigationPath()))
        .environmentObject(DataManager())
}
