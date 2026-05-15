import Foundation
import Supabase
import UIKit

@MainActor
class RecipeService {
    static let shared = RecipeService()
    
    // MARK: - Fetch Operations
    
    /// Fetches all available categories.
    func fetchAllCategories() async throws -> [Category] {
        return try await supabase.from("categories").select().order("name").execute().value
    }
    
    /// Fetches all available ingredients.
    func fetchAllIngredients() async throws -> [Ingredient] {
        return try await supabase.from("ingredients").select().order("name").execute().value
    }
    
    /// fetches newest public recipes with pagination
    func fetchNewestRecipes(page: Int, limit: Int) async throws -> [Recipe] {
        let from = page * limit
        let to = from + limit - 1
        
        let recipes: [Recipe] = try await supabase.from("recipes")
            .select(Recipe.selectQuery)
            .eq("is_public", value: true)
            .order("created_at", ascending: false, nullsFirst: false)
            .range(from: from, to: to)
            .execute()
            .value
        
        return recipes
    }
    
    /// Fetches all sections for the home page (featured, newest, etc.).
    func fetchHomeSections() async throws -> [RecipeSection] {
        enum SectionResult {
            case featured(RecipeSection)
            case standard(RecipeSection)
        }
        
        // Use a TaskGroup for robust concurrent fetching
        return try await withThrowingTaskGroup(of: SectionResult.self) { group -> [RecipeSection] in
            // Task for "Featured"
            group.addTask {
                let section = try await self.fetchSection(title: "Öne Çıkanlar", ordering: "rating", style: .featured)
                return .featured(section)
            }
            
            // Task for "Discover"
            group.addTask {
                let recipes = try await self.fetchNewestRecipes(page: 0, limit: 10)
                let shuffledRecipes = recipes.shuffled()
                let section = RecipeSection(title: "Keşfet", recipes: shuffledRecipes, style: .standard)
                return .standard(section)
            }

            var featuredSection: RecipeSection?
            var standardSection: RecipeSection?

            // Collect results as they complete
            for try await result in group {
                switch result {
                case .featured(let section):
                    if !section.recipes.isEmpty { featuredSection = section }
                case .standard(let section):
                    if !section.recipes.isEmpty { standardSection = section }
                }
            }

            // Build the final array in the correct order
            var finalSections: [RecipeSection] = []
            if let featured = featuredSection {
                finalSections.append(featured)
            }
            if let standard = standardSection {
                finalSections.append(standard)
            }
            
            return finalSections
        }
    }
    
    func fetchPublicRecipes(userId: UUID, limit: Int = 20) async throws -> [Recipe] {
        try await supabase.from("recipes")
            .select(Recipe.selectQuery)
            .eq("user_id", value: userId)
            .eq("is_public", value: true)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    /// Fetches recipes created by the current user.
    func fetchOwnedRecipes(page: Int, limit: Int) async throws -> [Recipe] {
        guard let userId = try? await supabase.auth.session.user.id else { return [] }
        
        let from = page * limit
        let to = from + limit - 1
        
        return try await supabase.from("recipes")
            .select(Recipe.selectQuery)
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .range(from: from, to: to)
            .execute()
            .value
    }
    
    func fetchOwnedRecipesCount() async throws -> Int {
        guard let userId = try? await supabase.auth.session.user.id else { return 0 }
        let response = try await supabase.from("recipes")
            .select(count: .exact)
            .eq("user_id", value: userId)
            .execute()
        return response.count ?? 0
    }
    
    /// Fetches recipes favorited by the current user.
    func fetchFavoriteRecipes() async throws -> [Recipe] {
        struct FavoritedRecipeResult: Decodable { let recipe: Recipe }
        guard let userId = try? await supabase.auth.session.user.id else { return [] }
        
        let response: [FavoritedRecipeResult] = try await supabase.from("favorite_recipes")
            .select("recipe:recipes(\(Recipe.selectQuery))")
            .eq("user_id", value: userId)
            .execute()
            .value
        return response.map { $0.recipe }
    }
    
    func fetchTotalFavoritesReceivedCount() async throws -> Int {
        let count: Int = try await supabase
            .rpc("get_total_favorites_for_owned_recipes")
            .execute()
            .value
        
        return count
    }
    
    /// Fetches the current user's rating for a specific recipe
    func fetchUserRating(for recipeId: UUID) async throws -> Int? {
        guard let userId = try? await supabase.auth.session.user.id else { return nil }
        
        struct RatingResult: Decodable {
            let rating: Int
        }
        
        do {
            let result: RatingResult = try await supabase.from("recipe_ratings")
                .select("rating")
                .eq("user_id", value: userId)
                .eq("recipe_id", value: recipeId)
                .single()
                .execute()
                .value
            return result.rating
        } catch {
            return nil
        }
    }
    
    /// Deletes the current user's rating for a specific recipe
    func deleteUserRating(for recipeId: UUID) async throws {
        guard let userId = try? await supabase.auth.session.user.id else {
            throw URLError(.userAuthenticationRequired)
        }
        
        try await supabase.from("recipe_ratings")
            .delete()
            .eq("user_id", value: userId)
            .eq("recipe_id", value: recipeId)
            .execute()
    }
    
    // MARK: - Checks and Toggle
    
    /// Checks if a recipe is favorited by the current user
    func checkIfFavorite(recipeId: UUID) async throws -> Bool {
        guard let userId = try? await supabase.auth.session.user.id else { return false }
        
        let response = try await supabase.from("favorite_recipes")
            .select(count: .exact)
            .eq("user_id", value: userId)
            .eq("recipe_id", value: recipeId)
            .execute()
            
        return response.count ?? 0 > 0
    }
    
    /// Toggles the favorite status for a recipe
    func toggleFavorite(recipeId: UUID) async throws -> Bool {
        let newStatus: Bool = try await supabase
            .rpc("toggle_favorite", params: ["recipe_id_to_toggle": recipeId])
            .execute()
            .value
        return newStatus
    }
    
    
    // MARK: - Recipe Creation & Update & Deletion
        
        /// Saves a new recipe with all its components.
        func createRecipe(viewModel: RecipeCreateViewModel) async throws -> Recipe {
            guard let userId = try? await supabase.auth.session.user.id,
                  let imageData = viewModel.selectedImageData else {
                throw URLError(.userAuthenticationRequired)
            }
            
            if let uiImage = UIImage(data: imageData) {
                let decision = await NSFWModerationService.shared.check(image: uiImage)
                if case .rejected = decision {
                    throw NSError(domain: "Moderation", code: 403, userInfo: [NSLocalizedDescriptionKey: "Uygunsuz içerik tespit edildi (NSFW)."])
                }
            }
            
            // 1. Upload Image
            let imagePath = try await ImageUploaderService.shared.uploadRecipeImage(imageData: imageData)
            
            // 2. Insert Base Recipe
            let stepTexts = viewModel.steps.map { $0.text }
            let recipeInsert = NewRecipe(
                name: viewModel.name, description: viewModel.description,
                cookingTime: viewModel.cookingTime, servings: viewModel.servings,
                steps: stepTexts, imageName: imagePath, userId: userId, isPublic: viewModel.isPublic
            )
            let savedRecipeInfo: RecipeID = try await supabase.from("recipes")
                .insert(recipeInsert).select("id").single().execute().value
            let newRecipeId = savedRecipeInfo.id
            
            // 3. Link Ingredients
            let ingredientLinks = viewModel.recipeIngredients.map { ingInput in
                NewRecipeIngredient(
                    recipeId: newRecipeId,
                    name: ingInput.ingredient.name,
                    ingredientId: viewModel.allAvailableIngredients.contains(where: { $0.id == ingInput.ingredient.id }) ? ingInput.ingredient.id : nil,
                    amount: Double(ingInput.amount.replacingOccurrences(of: ",", with: ".")) ?? 0.0,
                    unit: ingInput.unit
                )
            }
            if !ingredientLinks.isEmpty {
                try await supabase.from("recipe_ingredients").insert(ingredientLinks).execute()
            }
            
            // 4. Link Categories
            let recipeCategoryLinks = viewModel.selectedCategories.map {
                NewRecipeCategory(recipeId: newRecipeId, categoryId: $0.id)
            }
            if !recipeCategoryLinks.isEmpty {
                try await supabase.from("recipe_categories").insert(recipeCategoryLinks).execute()
            }
            
            let newRecipe: Recipe = try await supabase.from("recipes")
                .select(Recipe.selectQuery)
                .eq("id", value: newRecipeId)
                .single()
                .execute()
                .value
            
            print("✅ Recipe created successfully \(newRecipeId)")
            return newRecipe
        }
    
    func updateRecipe(_ recipeId: UUID, viewModel: RecipeCreateViewModel) async throws -> Recipe {
        guard let userId = try? await supabase.auth.session.user.id else {
            throw URLError(.userAuthenticationRequired)
        }
        
        // update image if changed
        var imagePath = viewModel.recipeToEdit?.imageName ?? ""
        if let newImageData = viewModel.selectedImageData {
            var shouldUploadNewImage = true

            if let existingImageURL = viewModel.recipeToEdit?.imagePublicURL(),
               let originalImageData = try? await URLSession.shared.data(from: existingImageURL).0 {
                shouldUploadNewImage = newImageData != originalImageData
            }

            if shouldUploadNewImage {
                if let uiImage = UIImage(data: newImageData) {
                    let decision = await NSFWModerationService.shared.check(image: uiImage)
                    if case .rejected = decision {
                        throw NSError(domain: "Moderation", code: 403, userInfo: [NSLocalizedDescriptionKey: "Uygunsuz içerik tespit edildi (NSFW). Skor: "])
                    }
                }

                // delete old image from s3 storage
                if !imagePath.isEmpty {
                    try await ImageUploaderService.shared.deleteImage(for: imagePath)
                }

                // upload new image
                imagePath = try await ImageUploaderService.shared.uploadRecipeImage(imageData: newImageData)
            }
        }
        
        // update other recipe details
        let stepTexts = viewModel.steps.map { $0.text }
        let recipeUpdate = NewRecipe(
            name: viewModel.name, description: viewModel.description,
            cookingTime: viewModel.cookingTime, servings: viewModel.servings,
            steps: stepTexts, imageName: imagePath, userId: userId, isPublic: viewModel.isPublic
        )
        
        try await supabase.from("recipes")
            .update(recipeUpdate)
            .eq("id", value: recipeId)
            .execute()
        
        // update ingredients but first delete all
        try await supabase.from("recipe_ingredients")
            .delete()
            .eq("recipe_id", value: recipeId)
            .execute()
            
        // add new ingredients
        let ingredientLinks = viewModel.recipeIngredients.map { ingInput in
            NewRecipeIngredient(
                recipeId: recipeId,
                name: ingInput.ingredient.name,
                ingredientId: viewModel.allAvailableIngredients.contains(where: { $0.id == ingInput.ingredient.id }) ? ingInput.ingredient.id : nil,
                amount: Double(ingInput.amount.replacingOccurrences(of: ",", with: ".")) ?? 0.0,
                unit: ingInput.unit
            )
        }
        if !ingredientLinks.isEmpty {
            try await supabase.from("recipe_ingredients").insert(ingredientLinks).execute()
        }

        // update categories but first delete all
        try await supabase.from("recipe_categories")
            .delete()
            .eq("recipe_id", value: recipeId)
            .execute()
        
        // add new categories
        let recipeCategoryLinks = viewModel.selectedCategories.map {
            NewRecipeCategory(recipeId: recipeId, categoryId: $0.id)
        }
        
        if !recipeCategoryLinks.isEmpty {
            try await supabase.from("recipe_categories").insert(recipeCategoryLinks).execute()
        }
        
        let updatedRecipe: Recipe = try await supabase.from("recipes")
            .select(Recipe.selectQuery)
            .eq("id", value: recipeId)
            .single()
            .execute()
            .value
        
        print("✅ Recipe updated successfully \(recipeId)")
        return updatedRecipe
    }
    
    func deleteRecipe(recipeId: UUID, imageName: String) async throws {
        if !imageName.isEmpty {
            try await ImageUploaderService.shared.deleteImage(for: imageName)
        }
        
        try await supabase.from("recipes")
            .delete()
            .eq("id", value: recipeId)
            .execute()
        
        print("✅ Recipe deleted successfully \(recipeId)")
    }
        
    // MARK: - Helper for Sections
    private func fetchSection(title: String, ordering: String, style: SectionStyle) async throws -> RecipeSection {
        let recipes: [Recipe] = try await supabase.from("recipes")
            .select(Recipe.selectQuery)
            .eq("is_public", value: true)
            .order(ordering, ascending: false, nullsFirst: false)
            .limit(10)
            .execute()
            .value
        
        return RecipeSection(title: title, recipes: recipes, style: style)
    }
}

