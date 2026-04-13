import Foundation

struct CategoryDistributionItem: Identifiable, Equatable {
    let category: Category
    let count: Int

    var id: UUID { category.id }

    static func == (lhs: CategoryDistributionItem, rhs: CategoryDistributionItem) -> Bool {
        lhs.category.id == rhs.category.id && lhs.count == rhs.count
    }
}

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var totalFavoritesReceived: Int = 0
    @Published var averageRating: Double = 0.0
    @Published var isLoading = false
    @Published private(set) var categoryDistribution: [CategoryDistributionItem] = []
    
    let coordinator: AppCoordinator
    private let recipeService = RecipeService.shared
    
    init(coordinator: AppCoordinator) {
        self.coordinator = coordinator
    }

    /// Fetches all data needed for the profile screen.
    func fetchAllProfileData(dataManager: DataManager) async {
        isLoading = true
        
        defer { isLoading = false }
        
        do {
            let count = try await recipeService.fetchTotalFavoritesReceivedCount()
            self.totalFavoritesReceived = count
            
            guard let user = dataManager.currentUser else {
                self.averageRating = 0.0
                return
            }
            
            let points = user.totalRatingPoints ?? 0
            let received = user.totalRatingsReceived ?? 0
            
            if received > 0 {
                self.averageRating = Double(points) / Double(received)
            } else {
                self.averageRating = 0.0
            }
            
        } catch {
            print("❌ Error fetching profile data: \(error.localizedDescription)")
        }
    }

    func updateCategoryDistribution(from recipes: [Recipe]) {
        var counts: [Category: Int] = [:]
        for recipe in recipes {
            for category in recipe.categories.map({ $0.category }) {
                counts[category, default: 0] += 1
            }
        }

        let newDistribution = counts
            .sorted { lhs, rhs in
                if lhs.value == rhs.value {
                    return lhs.key.name.localizedCaseInsensitiveCompare(rhs.key.name) == .orderedAscending
                }
                return lhs.value > rhs.value
            }
            .map { CategoryDistributionItem(category: $0.key, count: $0.value) }

        guard newDistribution != categoryDistribution else { return }
        categoryDistribution = newDistribution
    }
}
