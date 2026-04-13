import SwiftUI

@MainActor
class DataManager: ObservableObject {
    // MARK: - Published Properties
    /// published variables to notify views about data changes
    @Published var currentUser: User?
    @Published var ownedRecipes: [Recipe] = []
    @Published var favoritedRecipes: [Recipe] = []
    @Published var ownedRecipesTotalCount: Int = 0
    @Published var totalFavoritesReceived: Int = 0
    @Published var averageRating: Double = 0.0
    @Published var areProfileStatsLoaded: Bool = false
    @Published var isProfessionEnabled: Bool = false
    @Published var professionText: String = ""
    
    /// properties for home page sections and categories
    @Published var homeSections: [RecipeSection] = []
    @Published var availableCategories: [Category] = []
    
    /// cached shopping lists and their items
    @Published var cachedShoppingLists: [ShoppingList] = []
    @Published var cachedShoppingListItems: [UUID: [ShoppingListItem]] = [:]
    var isShoppingListLoaded = false
    
    @Published var isLoading: Bool = false
    
    // properties for pagination owned recipes
    private var ownedRecipesPage = 0
    private var canLoadMoreOwnedRecipes = true
    private var isFetchingMoreOwnedRecipes = false
    
    // Pagination for home page
    private var discoverRecipesPage = 1
    private var canLoadMoreRecipes = true
    private var isFetchingMoreRecipes = false
    
    // MARK: - Services
    private let userService = UserService.shared
    private let recipeService = RecipeService.shared
    
    init() {
        addObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    /// when user logs in, fetch all necessary data
    func loadInitialUserData() async {
        guard currentUser == nil else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            async let userTask = userService.fetchCurrentUser()
            async let ownedTask = recipeService.fetchOwnedRecipes(page: 0, limit: 10)
            async let favoritesTask = recipeService.fetchFavoriteRecipes()
            async let favoritesReceivedTask = recipeService.fetchTotalFavoritesReceivedCount()
            async let ownedCountTask = recipeService.fetchOwnedRecipesCount()
            
            let user = try await userTask
            self.currentUser = user
            let loadedProfession = user?.profession ?? ""
            self.professionText = loadedProfession
            self.isProfessionEnabled = user?.showProfession ?? !loadedProfession.isEmpty
            self.ownedRecipes = try await ownedTask
            self.favoritedRecipes = try await favoritesTask
            self.ownedRecipesTotalCount = try await ownedCountTask
            
            // Profile stats
            self.totalFavoritesReceived = try await favoritesReceivedTask
            let points = user?.totalRatingPoints ?? 0
            let received = user?.totalRatingsReceived ?? 0
            self.averageRating = received > 0 ? Double(points) / Double(received) : 0.0
            self.areProfileStatsLoaded = true
            
            self.ownedRecipesPage = 1
            print("✅ DataManager: Tüm kullanıcı verileri başarıyla yüklendi.")
        } catch {
            print("❌ DataManager: Başlangıç verileri çekilirken hata oluştu: \(error)")
        }
    }
    
    /// fetches categories and home sections for the home page
    func loadHomePageData(isRefresh: Bool = false) async {
        if !isRefresh {
            isLoading = true
        }
        
        defer { isLoading = false }
        
        do {
            enum HomePageLoadResult {
                case categories([Category])
                case sections([RecipeSection])
            }

            var fetchedCategories: [Category] = []
            var fetchedSections: [RecipeSection] = []

            try await withThrowingTaskGroup(of: HomePageLoadResult.self) { group in
                group.addTask {
                    .categories(try await self.recipeService.fetchAllCategories())
                }
                group.addTask {
                    .sections(try await self.recipeService.fetchHomeSections())
                }

                for try await result in group {
                    switch result {
                    case .categories(let categories):
                        fetchedCategories = categories
                    case .sections(let sections):
                        fetchedSections = sections
                    }
                }
            }
            
            // Reset pagination state after successful loading
            self.availableCategories = fetchedCategories
            self.homeSections = fetchedSections
                    
            self.discoverRecipesPage = 1
            self.canLoadMoreRecipes = true
            
            print("✅ DataManager: Ana sayfa verileri başarıyla yüklendi.")
        } catch {
            // Let the system report the actual error, including cancellation if it happens.
            print("❌ DataManager: Ana sayfa verileri çekilirken hata: \(error)")
        }
    }
    
    /// Refreshes all data including user-specific and home page data
    func refreshAllData() async {
        await loadHomePageData(isRefresh: true)
    }

    /// Refreshes profile-related data when returning back to profile screen.
    func refreshProfileData() async {
        do {
            async let userTask = userService.fetchCurrentUser()
            async let ownedTask = recipeService.fetchOwnedRecipes(page: 0, limit: 10)
            async let favoritesTask = recipeService.fetchFavoriteRecipes()
            async let favoritesReceivedTask = recipeService.fetchTotalFavoritesReceivedCount()
            async let ownedCountTask = recipeService.fetchOwnedRecipesCount()

            let user = try await userTask
            self.currentUser = user
            let loadedProfession = user?.profession ?? ""
            self.professionText = loadedProfession
            self.isProfessionEnabled = user?.showProfession ?? !loadedProfession.isEmpty
            self.ownedRecipes = try await ownedTask
            self.favoritedRecipes = try await favoritesTask
            self.ownedRecipesTotalCount = try await ownedCountTask
            self.totalFavoritesReceived = try await favoritesReceivedTask

            let points = user?.totalRatingPoints ?? 0
            let received = user?.totalRatingsReceived ?? 0
            self.averageRating = received > 0 ? Double(points) / Double(received) : 0.0
            self.areProfileStatsLoaded = true

            self.ownedRecipesPage = 1
            self.canLoadMoreOwnedRecipes = true
        } catch {
            // Screen transitions/pull-to-refresh interruption can cancel in-flight requests.
            if let urlError = error as? URLError, urlError.code == .cancelled {
                return
            }
            if error is CancellationError {
                return
            }
            print("❌ DataManager: Profil verileri yenilenirken hata: \(error)")
        }
    }
    
    func fetchMoreNewestRecipes() async {
        guard !isFetchingMoreRecipes, canLoadMoreRecipes else { return }
        
        isFetchingMoreRecipes = true
        defer { isFetchingMoreRecipes = false }
        
        do {
            let newRecipes = try await recipeService.fetchNewestRecipes(page: discoverRecipesPage, limit: 10)
            
            if newRecipes.isEmpty {
                canLoadMoreRecipes = false
            } else {
                if let discoverSectionIndex = homeSections.firstIndex(where: { $0.style == .standard }) {
                    let shuffledNewRecipes = newRecipes.shuffled()
                    homeSections[discoverSectionIndex].recipes.append(contentsOf: shuffledNewRecipes)
                    discoverRecipesPage += 1
                }
            }
        } catch {
            print("❌ DataManager: Daha fazla 'Keşfet' tarifi çekilirken hata: \(error)")
        }
    }
    
    func fetchMoreOwnedRecipes() async {
        guard !isFetchingMoreOwnedRecipes, canLoadMoreOwnedRecipes else { return }
        
        isFetchingMoreOwnedRecipes = true
        
        do {
            let newRecipes = try await recipeService.fetchOwnedRecipes(page: ownedRecipesPage, limit: 10)
            
            if newRecipes.isEmpty {
                canLoadMoreOwnedRecipes = false
            } else {
                self.ownedRecipes.append(contentsOf: newRecipes)
                self.ownedRecipesPage += 1
            }
        } catch {
            print("❌ Daha fazla 'owned recipe' çekilirken hata: \(error)")
        }
        
        isFetchingMoreOwnedRecipes = false
    }
    
    /// when user logs out, clear all user-specific data
    func clearUserData() {
        self.currentUser = nil
        self.ownedRecipes = []
        self.favoritedRecipes = []
        self.ownedRecipesTotalCount = 0
        self.totalFavoritesReceived = 0
        self.averageRating = 0.0
        self.areProfileStatsLoaded = false
        self.isProfessionEnabled = false
        self.professionText = ""
        print("ℹ️ DataManager: Kullanıcı verileri temizlendi.")
        
        self.cachedShoppingLists = []
        self.cachedShoppingListItems = [:]
        self.isShoppingListLoaded = false
        print("ℹ️ DataManager: Alışveriş listesi verileri temizlendi.")
    }
    
    // MARK: - Profile Update
    func updateProfile(
        fullName: String?,
        city: String?,
        showCity: Bool,
        bio: String?,
        birthDate: Date?,
        showBirthDate: Bool,
        profession: String?,
        showProfession: Bool,
        avatarImageData: Data?
    ) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let updatedUser = try await userService.updateUserProfile(
                fullName: fullName,
                city: city,
                showCity: showCity,
                bio: bio,
                birthDate: birthDate,
                showBirthDate: showBirthDate,
                profession: profession,
                showProfession: showProfession,
                avatarImageData: avatarImageData
            )
            self.currentUser = updatedUser
            let loadedProfession = updatedUser.profession ?? ""
            self.professionText = loadedProfession
            self.isProfessionEnabled = updatedUser.showProfession ?? !loadedProfession.isEmpty
            print("✅ DataManager: Profil güncellendi.")
        } catch {
            print("❌ DataManager: Profil güncellenirken hata: \(error)")
        }
    }
    
    func updateProfileWithAvatarControl(
        fullName: String?,
        city: String?,
        showCity: Bool,
        bio: String?,
        birthDate: Date?,
        showBirthDate: Bool,
        profession: String?,
        showProfession: Bool,
        avatarImageData: Data?,
        removeAvatar: Bool
    ) async -> Bool {
        isLoading = true
        defer { isLoading = false }
        do {
            let updatedUser = try await userService.updateUserProfileWithAvatarControl(
                fullName: fullName,
                city: city,
                showCity: showCity,
                bio: bio,
                birthDate: birthDate,
                showBirthDate: showBirthDate,
                profession: profession,
                showProfession: showProfession,
                avatarImageData: avatarImageData,
                removeAvatar: removeAvatar
            )
            self.currentUser = updatedUser
            let loadedProfession = updatedUser.profession ?? ""
            self.professionText = loadedProfession
            self.isProfessionEnabled = updatedUser.showProfession ?? !loadedProfession.isEmpty
            print("✅ DataManager: Profil güncellendi (avatar control).")
            return true
        } catch {
            print("❌ DataManager: Profil güncellenirken hata (avatar control): \(error)")
            return false
        }
    }
    
    // MARK: - Notification Handlers
    
    private func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleRecipeDeleted), name: .recipeDeleted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleRecipeUpdated), name: .recipeUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleRecipeCreated), name: .recipeCreated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleFavoriteStatusChanged), name: .favoriteStatusChanged, object: nil)
    }
    
    @objc private func handleRecipeDeleted(notification: Notification) {
        guard let userInfo = notification.userInfo, let deletedRecipeID = userInfo["recipeID"] as? UUID else { return }
        
        ownedRecipes.removeAll { $0.id == deletedRecipeID }
        favoritedRecipes.removeAll { $0.id == deletedRecipeID }

        for i in 0..<homeSections.count {
            homeSections[i].recipes.removeAll { $0.id == deletedRecipeID }
        }
        
        if self.ownedRecipesTotalCount > 0 { self.ownedRecipesTotalCount -= 1 }
    }

    @objc private func handleRecipeUpdated(notification: Notification) {
        guard let userInfo = notification.userInfo, let updatedRecipe = userInfo["updatedRecipe"] as? Recipe else { return }
        
        if let index = ownedRecipes.firstIndex(where: { $0.id == updatedRecipe.id }) {
            ownedRecipes[index] = updatedRecipe
        }
        if let index = favoritedRecipes.firstIndex(where: { $0.id == updatedRecipe.id }) {
            favoritedRecipes[index] = updatedRecipe
        }
        
        for i in 0..<homeSections.count {
            if let index = homeSections[i].recipes.firstIndex(where: { $0.id == updatedRecipe.id }) {
                homeSections[i].recipes[index] = updatedRecipe
            }
        }
    }
    
    @objc private func handleRecipeCreated(notification: Notification) {
        guard let userInfo = notification.userInfo, let newRecipe = userInfo["newRecipe"] as? Recipe else { return }
        // add new recipe to the top of the owned recipes list
        ownedRecipes.insert(newRecipe, at: 0)
        self.ownedRecipesTotalCount += 1
    }
    
    @objc private func handleFavoriteStatusChanged(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let recipe = userInfo["recipe"] as? Recipe,
              let isFavorite = userInfo["isFavorite"] as? Bool else { return }
              
        if let index = ownedRecipes.firstIndex(where: { $0.id == recipe.id }) {
            ownedRecipes[index].favoritedCount = recipe.favoritedCount
        }
        
        if let index = favoritedRecipes.firstIndex(where: { $0.id == recipe.id }) {
            favoritedRecipes[index].favoritedCount = recipe.favoritedCount
        }
        
        if isFavorite {
            if !favoritedRecipes.contains(where: { $0.id == recipe.id }) {
                favoritedRecipes.append(recipe)
            }
        } else {
            favoritedRecipes.removeAll { $0.id == recipe.id }
        }
    }
}

