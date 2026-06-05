import Foundation
import Supabase
import Combine

@MainActor
class ShoppingListViewModel: ObservableObject {
    @Published var shoppingLists: [ShoppingList] = []
    @Published var itemsByListID: [UUID: [ShoppingListItem]] = [:]
    @Published var isLoading = false
    @Published var expandedListID: UUID?
    @Published var showingClearAlertForList: ShoppingList?
    @Published var isShowingEditSheet = false
    @Published var listToEdit: ShoppingList?
    @Published var listNameForSheet = ""
    @Published var itemsForEditingList: [EditableShoppingItem] = []
    @Published var newItemName = ""
    @Published var allAvailableIngredients: [Ingredient] = []
    @Published var ingredientSearchText = ""
    @Published var showingIngredientSelector = false
    @Published var ingredientInlineStatus: String?
    
    /// A reference to the data service layer.
    private let service = ShoppingListService.shared
    private let recipeService = RecipeService.shared
    
    func hasCheckedItems(in listId: UUID) -> Bool {
        itemsByListID[listId]?.contains { $0.isChecked } ?? false
    }
    
    // MARK: - Initialization
    
    init() {
        Task {
            await fetchAvailableIngredientsIfNeeded()
        }
    }
    
    // init for preview
    init(forPreview: Bool) {
        if forPreview {
            self.shoppingLists = ShoppingList.mockLists
            self.allAvailableIngredients = Ingredient.mockData
            for list in self.shoppingLists {
                self.itemsByListID[list.id] = ShoppingListItem.mocks(for: list)
            }
            self.expandedListID = self.shoppingLists.first?.id
            self.isLoading = false
        }
    }

    var filteredIngredients: [Ingredient] {
        let trimmedSearch = ingredientSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSearch.isEmpty else { return allAvailableIngredients }

        return allAvailableIngredients.filter {
            $0.name.localizedCaseInsensitiveContains(trimmedSearch)
        }
    }

    var isCustomAddButtonShown: Bool {
        let trimmedSearch = ingredientSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSearch.isEmpty else { return false }

        return !allAvailableIngredients.contains {
            $0.name.caseInsensitiveCompare(trimmedSearch) == .orderedSame
        }
    }
    
    /// Fetches all shopping lists by calling the service layer.
    func fetchAllLists(dataManager: DataManager) async {
        if !dataManager.cachedShoppingLists.isEmpty {
            self.shoppingLists = dataManager.cachedShoppingLists
            self.itemsByListID = dataManager.cachedShoppingListItems
            
            if dataManager.isShoppingListLoaded {
                isLoading = false
            }
        } else {
            isLoading = true
        }
        
        defer { isLoading = false }
        
        do {
            let fetchedLists = try await service.fetchListsWithCounts()
            
            self.shoppingLists = fetchedLists
            dataManager.cachedShoppingLists = fetchedLists
            
            if let firstList = fetchedLists.first {
                self.expandedListID = firstList.id
                await fetchItems(for: firstList.id, dataManager: dataManager)
            }
            
            dataManager.isShoppingListLoaded = true
            
        } catch {
            print("❌ Error fetching lists: \(error.localizedDescription)")
        }
    }
    
    /// Fetches the items for a specific list by calling the service.
    private func fetchItems(for listId: UUID, dataManager: DataManager? = nil) async {
        if let cachedItems = dataManager?.cachedShoppingListItems[listId], !cachedItems.isEmpty {
            self.itemsByListID[listId] = cachedItems
        }
        
        do {
            let items = try await service.fetchItems(for: listId)
            self.itemsByListID[listId] = items
            dataManager?.cachedShoppingListItems[listId] = items
        } catch {
            print("❌ Error fetching items for list \(listId): \(error.localizedDescription)")
            // On failure, set an empty array to prevent repeated failed attempts.
            self.itemsByListID[listId] = []
        }
    }
    
    // MARK: - List & Item Management
    
    /// get items to show or hide the list
    func toggleListExpansion(listId: UUID) async {
        let newExpandedID = (expandedListID == listId) ? nil : listId

        self.expandedListID = newExpandedID
        
        if let idToFetch = newExpandedID {
            await fetchItems(for: idToFetch)
        }
    }
    
    /// Toggles the 'checked' state of an item and calls the service to persist the change.
    func toggleItemCheck(_ item: ShoppingListItem) async {
        guard let listId = findListID(for: item) else { return }
        
        // 1. Optimistically update the UI
        guard let itemIndex = itemsByListID[listId]?.firstIndex(where: { $0.id == item.id }) else { return }
        itemsByListID[listId]?[itemIndex].isChecked.toggle()
        
        // 2. Get the new state to send to the service
        let newCheckedState = itemsByListID[listId]?[itemIndex].isChecked ?? false
        
        // 3. Call the service to update the database
        do {
            try await service.updateItemCheck(id: item.id, isChecked: newCheckedState)
        } catch {
            print("❌ Error toggling item: \(error.localizedDescription)")
            // On failure, revert the UI change
            itemsByListID[listId]?[itemIndex].isChecked.toggle()
        }
    }
    
    /// Toggles the checked state of all items in a list.
    /// If some are unchecked, it checks all. If all are checked, it unchecks all.
    func toggleCheckAllItems(in list: ShoppingList, dataManager: DataManager) async {
        if itemsByListID[list.id] == nil {
                await fetchItems(for: list.id)
            }
            
            let areAllChecked = itemsByListID[list.id]?.allSatisfy { $0.isChecked } ?? false
            let newCheckedState = !areAllChecked
            
            do {
                try await service.updateCheckStatusForAllItems(listId: list.id, isChecked: newCheckedState)
                
                if itemsByListID[list.id] != nil {
                    for i in itemsByListID[list.id]!.indices {
                        itemsByListID[list.id]?[i].isChecked = newCheckedState
                    }
                }
                
                if let index = shoppingLists.firstIndex(where: { $0.id == list.id }) {
                    let newCheckedCount = newCheckedState ? shoppingLists[index].itemCount : 0
                    
                    let updatedList = ShoppingList(
                        id: shoppingLists[index].id,
                        name: shoppingLists[index].name,
                        userId: shoppingLists[index].userId,
                        itemCount: shoppingLists[index].itemCount,
                        checkedItemCount: newCheckedCount,
                        createdAt: .now
                    )
                    
                    shoppingLists[index] = updatedList
                }
                
            } catch {
                    print("❌ Error toggling all items: \(error.localizedDescription)")
                    // On error, a full refresh is a good idea to re-sync with the database.
                    await fetchAllLists(dataManager: dataManager)
            }
    }
    
    func areAllItemsChecked(for list: ShoppingList) -> Bool {
        if let items = itemsByListID[list.id] {
            guard !items.isEmpty else { return false }
            return items.allSatisfy { $0.isChecked }
        }
        
        guard list.itemCount > 0 else { return false }
        return list.itemCount == list.checkedItemCount
    }
    
    /// delete checked items from the database
    func clearCheckedItems(in list: ShoppingList, dataManager: DataManager) async {
        let checkedItemIds = (itemsByListID[list.id] ?? []).filter { $0.isChecked }.map { $0.id }
        guard !checkedItemIds.isEmpty else { return }
        
        do {
            try await service.clearCheckedItems(in: list, itemIds: checkedItemIds)
            
            itemsByListID[list.id]?.removeAll { $0.isChecked }
            
            if itemsByListID[list.id]?.isEmpty ?? false {
                await deleteList(list, dataManager: dataManager)
            }
        } catch {
            print("❌ Error clearing checked items: \(error)")
        }
    }
    
    /// delete all list items from the database
    func clearAllItems(in list: ShoppingList) {
        showingClearAlertForList = list
    }
    
    /// confirm clearing all items in the list
    func confirmClearAllItems(dataManager: DataManager) async {
        guard let listToClear = showingClearAlertForList else { return }
        defer { showingClearAlertForList = nil }
        
        await deleteList(listToClear, dataManager: dataManager)
    }
    
    /// Deletes a shopping list by calling the service layer.
    func deleteList(_ list: ShoppingList, dataManager: DataManager) async {
        isLoading = true
        do {
            try await service.deleteList(list)
            // Optimistically update the UI by removing the list locally.
            shoppingLists.removeAll { $0.id == list.id }
        } catch {
            print("❌ Error deleting list: \(error.localizedDescription)")
            // If the deletion fails, refetch from the server to ensure UI is in sync.
            await fetchAllLists(dataManager: dataManager)
        }
        isLoading = false
    }
    
    // MARK: - Sheet Presentation
    
    func presentListEditSheetForCreate() {
        listToEdit = nil
        listNameForSheet = ""
        itemsForEditingList = []
        newItemName = ""
        ingredientSearchText = ""
        ingredientInlineStatus = nil
        isShowingEditSheet = true

        Task {
            await fetchAvailableIngredientsIfNeeded()
        }
    }
    
    // This function needs to be updated
    func presentListEditSheetForUpdate(_ list: ShoppingList) async {
        listToEdit = list
        listNameForSheet = list.name
        
        if itemsByListID[list.id] == nil {
            await fetchItems(for: list.id)
        }
        
        // Convert the fetched items into our new editable format
        let editableItems = itemsByListID[list.id]?.map {
            EditableShoppingItem(
                id: $0.id,
                name: $0.name,
                amount: $0.formattedAmount,
                unit: $0.unit,
                originalIngredientId: $0.ingredientId
            )
        } ?? []
        
        self.itemsForEditingList = editableItems
        self.newItemName = ""
        self.ingredientSearchText = ""
        self.ingredientInlineStatus = nil
        self.isShowingEditSheet = true

        await fetchAvailableIngredientsIfNeeded()
    }
    
    func addItemToEditor() {
        addCustomItemToEditor(named: newItemName)
    }

    func addCustomItemToEditor(named name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        if let existingIndex = itemsForEditingList.firstIndex(where: { $0.name.caseInsensitiveCompare(trimmedName) == .orderedSame }) {
            ingredientInlineStatus = "\(itemsForEditingList[existingIndex].name) zaten listede."
            newItemName = ""
            ingredientSearchText = ""
            return
        }

        let newItem = EditableShoppingItem(
            id: UUID(),
            name: trimmedName,
            amount: "1",
            unit: "adet",
            originalIngredientId: nil
        )
        
        itemsForEditingList.append(newItem)
        newItemName = ""
        ingredientSearchText = ""
        ingredientInlineStatus = "\(trimmedName) eklendi."
    }

    func selectIngredientForEditor(_ ingredient: Ingredient) {
        if let existingIndex = itemsForEditingList.firstIndex(where: {
            if let originalIngredientId = $0.originalIngredientId {
                return originalIngredientId == ingredient.id
            }

            return $0.name.caseInsensitiveCompare(ingredient.name) == .orderedSame
        }) {
            ingredientInlineStatus = "\(itemsForEditingList[existingIndex].name) zaten listede."
            ingredientSearchText = ""
            return
        }

        let newItem = EditableShoppingItem(
            id: UUID(),
            name: ingredient.name,
            amount: "1",
            unit: "adet",
            originalIngredientId: ingredient.id
        )

        itemsForEditingList.append(newItem)
        ingredientSearchText = ""
        ingredientInlineStatus = "\(ingredient.name) eklendi."
    }
    
    func removeItemFromEditor(at offsets: IndexSet) {
        itemsForEditingList.remove(atOffsets: offsets)
    }
    
    // MARK: - Create / Update Logic
    
    /// Saves changes by calling the appropriate service method.
    func saveList(dataManager: DataManager) async {
        let name = listNameForSheet.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        
        isShowingEditSheet = false
        isLoading = true
        
        do {
            if let listToEdit {
                // --- EDIT MODE ---
                if listToEdit.name != name {
                    try await service.updateList(listToEdit, newName: name)
                }
                
                // Convert UI state to database insert model
                let newItemsToInsert = itemsForEditingList.map {
                    ShoppingListItemInsert(
                        listId: listToEdit.id,
                        name: $0.name,
                        amount: Double($0.amount) ?? 1.0,
                        unit: $0.unit,
                        ingredientId: $0.originalIngredientId  // Keep the original link, or nil if it's a custom item
                    )
                }

                try await service.replaceItems(for: listToEdit.id, with: newItemsToInsert)
                itemsByListID.removeValue(forKey: listToEdit.id)
                
            } else {
                // --- CREATE MODE ---
                let newListId = try await service.createList(withName: name)
                
                let newItemsToInsert = itemsForEditingList.map {
                    ShoppingListItemInsert (
                        listId: newListId,
                        name: $0.name,
                        amount: Double($0.amount.replacingOccurrences(of: ",", with: ".")) ?? 1.0,
                        unit: $0.unit,
                        ingredientId: $0.originalIngredientId
                    )
                }

                if !newItemsToInsert.isEmpty {
                    try await service.replaceItems(for: newListId, with: newItemsToInsert)
                }
            }
        } catch {
            print("❌ Error saving list with items: \(error.localizedDescription)")
        }
        
        // Refresh everything
        await fetchAllLists(dataManager: dataManager)
    }

    // MARK: - Helpers
    
    /// Finds which list an item belongs to locally.
    private func findListID(for item: ShoppingListItem) -> UUID? {
        return itemsByListID.first(where: { $0.value.contains(where: { $0.id == item.id }) })?.key
    }

    private func fetchAvailableIngredientsIfNeeded() async {
        guard allAvailableIngredients.isEmpty else { return }

        do {
            allAvailableIngredients = try await recipeService.fetchAllIngredients()
        } catch {
            print("❌ Error fetching ingredients for shopping list editor: \(error.localizedDescription)")
        }
    }
}

// MARK: - Mock Data for Previews
extension ShoppingListViewModel {
    
    /// An example of a filled, dummy ViewModel used for previews.
    static var mock: ShoppingListViewModel {
        let vm = ShoppingListViewModel()
        
        let mockLists = ShoppingList.mockLists
        vm.shoppingLists = mockLists
        
        for list in mockLists {
            vm.itemsByListID[list.id] = ShoppingListItem.mocks(for: list)
        }
        
        if let firstList = mockLists.first {
            vm.expandedListID = firstList.id
        }
        
        vm.isLoading = false
        
        return vm
    }
}
