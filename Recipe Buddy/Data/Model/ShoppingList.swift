import Foundation

struct ShoppingList: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let userId: UUID
    let itemCount: Int
    let checkedItemCount: Int
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case userId = "user_id"
        case itemCount = "item_count"
        case checkedItemCount = "checked_item_count"
        case createdAt = "created_at"
    }
    
    var formattedDate: String {
        guard let createdAt = createdAt else { return "Tarih bilinmiyor" }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.unitsStyle = .full
        
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
}

struct ShoppingListItem: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    var amount: Double
    let unit: String
    var isChecked: Bool
    let ingredientId: UUID?
    
    var formattedAmount: String {
        if amount.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", amount)
        } else {
            return String(format: "%.1f", amount)
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, amount, unit
        case isChecked = "is_checked"
        case ingredientId = "ingredient_id"
    }
}

struct ShoppingListItemInsert: Encodable {
    let listId: UUID
    let name: String
    let amount: Double
    let unit: String
    let ingredientId: UUID?
    
    init(from recipeIngredient: RecipeIngredientJoin, listId: UUID) {
        self.listId = listId
        self.ingredientId = recipeIngredient.ingredientId
        self.amount = recipeIngredient.amount
        self.unit = recipeIngredient.unit
        self.name = recipeIngredient.name
    }
    
    init(listId: UUID, name: String, amount: Double, unit: String, ingredientId: UUID?) {
        self.listId = listId
        self.name = name
        self.amount = amount
        self.unit = unit
        self.ingredientId = ingredientId
    }
    
    enum CodingKeys: String, CodingKey {
        case name, amount, unit
        case listId = "list_id"
        case ingredientId = "ingredient_id"
    }
}

struct EditableShoppingItem: Identifiable, Hashable {
    let id: UUID
    var name: String
    var amount: String
    var unit: String
    let originalIngredientId: UUID?
}
