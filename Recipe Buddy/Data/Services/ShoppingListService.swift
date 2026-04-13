import Foundation
import Supabase

@MainActor
class ShoppingListService {
    static let shared = ShoppingListService()

    private struct MergeShoppingListIngredientsParams: Encodable {
        let listId: UUID
        let ingredients: [MergeIngredientPayload]

        enum CodingKeys: String, CodingKey {
            case listId = "p_list_id"
            case ingredients = "p_ingredients"
        }
    }

    private struct MergeIngredientPayload: Encodable {
        let name: String
        let amount: Double
        let unit: String
        let ingredientId: UUID?

        init(from ingredient: RecipeIngredientJoin) {
            self.name = ingredient.name
            self.amount = ingredient.amount
            self.unit = ingredient.unit
            self.ingredientId = ingredient.ingredientId
        }

        enum CodingKeys: String, CodingKey {
            case name, amount, unit
            case ingredientId = "ingredient_id"
        }
    }

    private struct IngredientMergeKey: Hashable {
        let normalizedName: String
        let unit: String
        let ingredientId: UUID?

        init(name: String, unit: String, ingredientId: UUID?) {
            self.normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            self.unit = unit
            self.ingredientId = ingredientId
        }
    }
    
    /// Fetches all of the current user's lists along with their item counts via an RPC.
    func fetchListsWithCounts() async throws -> [ShoppingList] {
        let lists: [ShoppingList] = try await supabase
            .rpc("get_shopping_lists_with_counts")
            .execute()
            .value
        return lists
    }
    
    /// Fetches all items for a specific shopping list.
    func fetchItems(for listId: UUID) async throws -> [ShoppingListItem] {
        let response: [ShoppingListItem] = try await supabase.from("shopping_list_items")
            .select("*")
            .eq("list_id", value: listId)
            .order("is_checked", ascending: true)
            .order("created_at", ascending: true)
            .execute()
            .value
        return response
    }
    
    /// Creates a new shopping list and returns the created list's UUID.
    func createList(withName name: String) async throws -> UUID {
        guard let userId = try? await supabase.auth.session.user.id else {
            throw URLError(.userAuthenticationRequired)
        }
        
        struct NewListID: Codable {
            let id: UUID
        }
        
        let result: NewListID = try await supabase
            .from("shopping_lists")
            .insert(["name": name, "user_id": userId.uuidString])
            .select("id")
            .single()
            .execute()
            .value
            
        return result.id
    }
    
    /// Updates the name of a specified shopping list.
    func updateList(_ list: ShoppingList, newName: String) async throws {
        try await supabase.from("shopping_lists")
            .update(["name": newName])
            .eq("id", value: list.id)
            .execute()
    }
    
    /// Updates the 'is_checked' status of a single shopping list item.
    func updateItemCheck(id: UUID, isChecked: Bool) async throws {
        try await supabase.from("shopping_list_items")
            .update(["is_checked": isChecked])
            .eq("id", value: id)
            .execute()
    }
    
    /// Updates the 'is_checked' status for all items in a given list.
    func updateCheckStatusForAllItems(listId: UUID, isChecked: Bool) async throws {
        try await supabase.from("shopping_list_items")
            .update(["is_checked": isChecked])
            .eq("list_id", value: listId)
            .execute()
    }
    
    /// Deletes a list and all of its associated items from the database.
    func deleteList(_ list: ShoppingList) async throws {
        
        // 1. Delete all items associated with the list.
        try await supabase.from("shopping_list_items")
            .delete()
            .eq("list_id", value: list.id)
            .execute()
            
        // 2. Delete the list itself.
        try await supabase.from("shopping_lists")
            .delete()
            .eq("id", value: list.id)
            .execute()
    }
    
    /// Deletes all checked items in a given list.
    func clearCheckedItems(in list: ShoppingList, itemIds: [UUID]) async throws {
        try await supabase.from("shopping_list_items")
            .delete()
            .in("id", values: itemIds)
            .execute()
    }
    
    /// Adds an array of recipe ingredients to a shopping list.
    func addRecipeIngredients(_ ingredients: [RecipeIngredientJoin], to list: ShoppingList) async throws {
        let itemsToInsert = ingredients.map {
            ShoppingListItemInsert(
                listId: list.id,
                name: $0.name,
                amount: $0.amount,
                unit: $0.unit,
                ingredientId: $0.ingredientId
            )
        }
        
        if !itemsToInsert.isEmpty {
            try await supabase.from("shopping_list_items").insert(itemsToInsert).execute()
        }
    }
    
    /// add ingredients to a shopping list
    func addIngredients(_ ingredients: [RecipeIngredientJoin], to list: ShoppingList) async throws {
        guard !ingredients.isEmpty else { return }

        let payload = ingredients.map { MergeIngredientPayload(from: $0) }

        do {
            try await supabase
                .rpc(
                    "merge_shopping_list_ingredients",
                    params: MergeShoppingListIngredientsParams(
                        listId: list.id,
                        ingredients: payload
                    )
                )
                .execute()
            return
        } catch {
            // Fallback for environments where RPC is not deployed yet.
            try await mergeIngredientsFallback(ingredients, to: list)
        }
    }

    private func mergeIngredientsFallback(_ ingredients: [RecipeIngredientJoin], to list: ShoppingList) async throws {
        let existingItems: [ShoppingListItem] = try await supabase
            .from("shopping_list_items")
            .select("*")
            .eq("list_id", value: list.id)
            .execute()
            .value

        var existingByKey: [IngredientMergeKey: ShoppingListItem] = [:]
        for item in existingItems {
            let key = IngredientMergeKey(name: item.name, unit: item.unit, ingredientId: item.ingredientId)
            existingByKey[key] = item
        }

        var updatesById: [UUID: Double] = [:]
        var inserts: [ShoppingListItemInsert] = []

        for ingredient in ingredients {
            let key = IngredientMergeKey(
                name: ingredient.name,
                unit: ingredient.unit,
                ingredientId: ingredient.ingredientId
            )

            if let existing = existingByKey[key] {
                updatesById[existing.id, default: existing.amount] += ingredient.amount
            } else {
                inserts.append(ShoppingListItemInsert(from: ingredient, listId: list.id))
            }
        }

        if !updatesById.isEmpty {
            try await withThrowingTaskGroup(of: Void.self) { group in
                for (id, amount) in updatesById {
                    group.addTask {
                        try await supabase
                            .from("shopping_list_items")
                            .update(["amount": amount])
                            .eq("id", value: id)
                            .execute()
                    }
                }

                try await group.waitForAll()
            }
        }

        if !inserts.isEmpty {
            try await supabase
                .from("shopping_list_items")
                .insert(inserts)
                .execute()
        }
    }
    
    /// Deletes all items for a given list ID and inserts a new set of items.
    func replaceItems(for listId: UUID, with items: [ShoppingListItemInsert]) async throws {
        // 1. Delete all existing items for this list.
        try await supabase.from("shopping_list_items")
            .delete()
            .eq("list_id", value: listId)
            .execute()
            
        // 2. Insert the new list of items, if any.
        if !items.isEmpty {
            try await supabase.from("shopping_list_items").insert(items).execute()
        }
    }

}
