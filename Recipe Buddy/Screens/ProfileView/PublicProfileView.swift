import SwiftUI

struct PublicProfileView: View {
    let user: User
    @Binding var navigationPath: NavigationPath

    @State private var loadedUser: User?
    @State private var recipes: [Recipe] = []
    @State private var isLoading = true
    @State private var categoryDistribution: [CategoryDistributionItem] = []

    private var displayUser: User { loadedUser ?? user }

    private var totalFavoritesReceived: Int {
        recipes.reduce(0) { $0 + $1.favoritedCount }
    }

    private var averageRating: Double {
        let points = displayUser.totalRatingPoints ?? 0
        let received = displayUser.totalRatingsReceived ?? 0
        return received > 0 ? Double(points) / Double(received) : 0
    }

    var body: some View {
        ZStack {
            Color.Background.ignoresSafeArea()

            if isLoading {
                ProgressView()
            } else {
                ScrollView(showsIndicators: false) {
                    ProfileContentView(
                        mode: .publicUser,
                        user: displayUser,
                        recipes: recipes,
                        totalFavoritesReceived: totalFavoritesReceived,
                        averageRating: averageRating,
                        categoryDistribution: categoryDistribution,
                        navigationPath: $navigationPath,
                        onEditProfile: nil,
                        onSeeAllRecipes: nil,
                        forceHidePersonalDetails: displayUser.isLikelyDeletedOrAnonymized
                    )
                }
            }
        }
        .navigationTitle("Profil")
        .inlineColoredNavigationBar(titleColor: .AppPrimary, tintColor: .AppPrimary, textStyle: .headline, weight: .bold, hidesOnSwipe: true, transparentBackground: true)
        .task {
            await load()
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }

        async let userTask = UserService.shared.fetchPublicUser(userId: user.id)
        async let recipesTask = RecipeService.shared.fetchPublicRecipes(userId: user.id, limit: 20)

        do {
            loadedUser = try await userTask
            recipes = try await recipesTask
            categoryDistribution = buildCategoryDistribution(from: recipes)
        } catch {
            loadedUser = user
            recipes = []
            categoryDistribution = []
            print("❌ Public profile load failed: \(error)")
        }
    }

    private func buildCategoryDistribution(from recipes: [Recipe]) -> [CategoryDistributionItem] {
        var counts: [Category: Int] = [:]
        for recipe in recipes {
            for category in recipe.categories.map({ $0.category }) {
                counts[category, default: 0] += 1
            }
        }

        return counts
            .sorted { lhs, rhs in
                if lhs.value == rhs.value {
                    return lhs.key.name.localizedCaseInsensitiveCompare(rhs.key.name) == .orderedAscending
                }
                return lhs.value > rhs.value
            }
            .map { CategoryDistributionItem(category: $0.key, count: $0.value) }
    }
}

#Preview {
    NavigationStack {
        PublicProfileView(
            user: User(
                id: UUID(),
                fullName: "Demo Kullanıcı",
                email: "demo@example.com",
                username: "demo",
                avatarUrl: nil,
                profession: "Aşçı",
                showProfession: true,
                totalRatingPoints: 21,
                totalRatingsReceived: 5,
                city: "İstanbul",
                showCity: true,
                bio: "Bu bir önizleme profilidir.",
                birthDate: nil,
                showBirthDate: false,
                emailNewsletter: nil,
                emailProductUpdates: nil,
                emailRecipeTips: nil
            ),
            navigationPath: .constant(NavigationPath())
        )
    }
}
