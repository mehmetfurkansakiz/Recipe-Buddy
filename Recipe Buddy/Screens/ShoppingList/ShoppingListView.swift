import SwiftUI
import UIKit

struct ShoppingListView: View {
    @StateObject var viewModel: ShoppingListViewModel
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        GeometryReader { geometry in
            let contentWidth = min(geometry.size.width, 430)

            ZStack {
                Color.Background.ignoresSafeArea()

                Group {
                    if viewModel.isLoading {
                        ProgressView()
                    } else if viewModel.shoppingLists.isEmpty {
                        EmptyShoppingListView()
                    } else {
                        listContent
                    }
                }
                .frame(width: contentWidth)
                .frame(maxWidth: .infinity)

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            viewModel.presentListEditSheetForCreate()
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.AppPrimary)
                                    .frame(width: 52, height: 52)
                                    .shadow(color: .black.opacity(0.35), radius: 8, y: 4)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )

                                Image("plus.icon")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 22, height: 22)
                                    .foregroundStyle(Color.white)
                            }
                        }
                        .accessibilityLabel("Liste Oluştur")
                        .padding(.trailing, 16)
                        .padding(.bottom, 16)
                    }
                }
                .frame(width: contentWidth)
                .frame(maxWidth: .infinity)
                .ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
        // Navigation title and appearance with helper modifier
        .navigationTitle("Alışveriş Listelerim")
        .inlineColoredNavigationBar(titleColor: .AppPrimary, textStyle: .headline, weight: .bold, hidesOnSwipe: true, transparentBackground: true)
        .task {
            await viewModel.fetchAllLists(dataManager: dataManager)
        }
        .sheet(isPresented: $viewModel.isShowingEditSheet) {
            ListEditView(
                viewModel: viewModel,
                onSave: {
                    Task { await viewModel.saveList(dataManager: dataManager) }
                },
                onCancel: { viewModel.isShowingEditSheet = false }
            )
        }
    }
    
    private var listContent: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: []) {
                ForEach(viewModel.shoppingLists) { list in
                    ShoppingListSectionView(
                        list: list,
                        items: viewModel.itemsByListID[list.id] ?? [],
                        isExpanded: viewModel.expandedListID == list.id,
                        areAllItemsChecked: viewModel.areAllItemsChecked(for: list),
                        onHeaderTap: {
                            Task { await viewModel.toggleListExpansion(listId: list.id) }
                        },
                        onItemToggle: { item in
                            Task { await viewModel.toggleItemCheck(item) }
                        },
                        onListDelete: {
                            Task { await viewModel.deleteList(list, dataManager: dataManager) }
                        },
                        onListEdit: {
                            Task { await viewModel.presentListEditSheetForUpdate(list) }
                        },
                        onToggleCheckAll: {
                            Task { await viewModel.toggleCheckAllItems(in: list, dataManager: dataManager) }
                        },
                        onClearChecked: {
                            Task { await viewModel.clearCheckedItems(in: list, dataManager: dataManager) }
                        }
                    )
                }
            }
            .padding(.top)
        }
    }
}


// MARK: - Helper Views

/// show a list of shopping lists
struct ShoppingListSectionView: View {
    // Properties passed from the parent view
    let list: ShoppingList
    let items: [ShoppingListItem]
    let isExpanded: Bool
    let areAllItemsChecked: Bool
    
    // Closures for actions
    let onHeaderTap: () -> Void
    let onItemToggle: (ShoppingListItem) -> Void
    let onListDelete: () -> Void
    let onListEdit: () -> Void
    let onToggleCheckAll: () -> Void
    let onClearChecked: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            header
                .contextMenu {
                    Button(action: onListEdit) {
                        Label("Listeyi Düzenle", systemImage: "pencil")
                    }
                    
                    Button(action: onClearChecked) {
                        Label("İşaretlileri Temizle", systemImage: "eraser")
                    }
                    
                    Button(action: onToggleCheckAll) {
                        Label("Tümünü İşaretle/Kaldır", systemImage: "checklist")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive, action: onListDelete) {
                        Label("Listeyi Sil", systemImage: "trash")
                    }
                }
            
            if isExpanded {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    ShoppingItemRowView(item: item, index: index) {
                        onItemToggle(item)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
                .transition(.opacity
                    .combined(with: .scale(scale: 0.95, anchor: .top)))
            }
        }
        .overlay(RoundedRectangle(cornerRadius: 12)
            .stroke(Color.SurfaceBorder, lineWidth: 1))
        .padding(.horizontal)
        .padding(.vertical, 6)
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(list.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(areAllItemsChecked ? .TextSecondary : .TextPrimary)
                    .strikethrough(areAllItemsChecked, color: .TextSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Circle()
                    .frame(width: 4, height: 4)
                    .foregroundStyle(.TextSecondary)
                    .opacity(0.5)
                
                Text("\(list.itemCount) adet")
                    .font(.subheadline)
                    .foregroundStyle(.TextSecondary)
                    .lineLimit(1)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(isExpanded ? 90 : -90))
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onHeaderTap)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isExpanded)
            
            if !list.formattedDate.isEmpty {
                Text(list.formattedDate)
                    .font(.caption2)
                    .foregroundStyle(.TextSecondary)
            }
        }
        .padding()
    }
}

// MARK: - Preview

#Preview() {
    NavigationStack {
        ShoppingListView(
            viewModel: ShoppingListViewModel(forPreview: true),
            navigationPath: .constant(NavigationPath())
        )
        .environmentObject(DataManager())
    }
}
