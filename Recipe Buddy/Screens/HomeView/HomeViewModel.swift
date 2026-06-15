import Foundation
import Combine
import Supabase

enum SectionStyle {
    case featured
    case standard
}

struct RecipeSection: Identifiable {
    let id = UUID()
    let title: String
    var recipes: [Recipe]
    let style: SectionStyle
}

@MainActor
class HomeViewModel: ObservableObject {
    // Search
    @Published var searchText = ""
    @Published var searchResults: [Recipe] = []
    @Published var userSearchResults: [User] = []
    
    // Category Filtering
    @Published var selectedCategory: Category?
    @Published var categoryFilteredRecipes: [Recipe] = []
    @Published var isFetchingCategoryRecipes = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupSearchDebounce()
        setupCategoryFiltering()
    }
    
    func searchRecipes(for query: String) async {
        do {
            async let fetchedRecipesTask: [Recipe] = supabase
                .rpc("search_recipes_and_users", params: ["search_term": query])
                .select(Recipe.selectQuery)
                .execute()
                .value

            async let fetchedUsersTask: [User] = UserService.shared.searchPublicUsers(query: query)

            self.searchResults = try await fetchedRecipesTask
            self.userSearchResults = try await fetchedUsersTask
        } catch {
            self.searchResults = []
            self.userSearchResults = []
            print("❌ Error searching recipes/users: \(error)")
        }
    }
    
    func fetchRecipes(forCategory category: Category) async {
        isFetchingCategoryRecipes = true
        defer { isFetchingCategoryRecipes = false }
        
        do {
            let recipes: [Recipe] = try await supabase
                .rpc("get_recipes_by_category", params: ["cat_id": category.id])
                .select(Recipe.selectQuery)
                .execute()
                .value
            
            self.categoryFilteredRecipes = recipes
            
        } catch {
            print("❌ Kategoriye göre tarif çekilirken hata oluştu: \(category.name), Hata: \(error)")
            self.categoryFilteredRecipes = []
        }
    }
    
    private func fetchSection(title: String, ordering: String, style: SectionStyle) async throws -> RecipeSection {
        let query = supabase.from("recipes")
            .select(Recipe.selectQuery)
            .eq("is_public", value: true)
        
        let transformedQuery = query
            .order(ordering, ascending: false, nullsFirst: false)
            .limit(10)
        
        let recipes: [Recipe] = try await transformedQuery.execute().value
        
        return RecipeSection(title: title, recipes: recipes, style: style)
    }
    
    private func setupSearchDebounce() {
        $searchText
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] searchText in
                guard let self = self else { return }
                
                if searchText.isEmpty {
                    self.searchResults = []
                    self.userSearchResults = []
                } else {
                    Task {
                        await self.searchRecipes(for: searchText)
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupCategoryFiltering() {
        $selectedCategory
            .removeDuplicates()
            .sink { [weak self] category in
                guard let self = self else { return }
                
                if let selected = category {
                    Task { await self.fetchRecipes(forCategory: selected) }
                } else {
                    self.categoryFilteredRecipes = []
                }
            }
            .store(in: &cancellables)
    }
    
    enum RecipeFilter { case featured, none }
    fileprivate struct FilteredRecipeResult: Decodable {
        let recipe: Recipe
    }
}
