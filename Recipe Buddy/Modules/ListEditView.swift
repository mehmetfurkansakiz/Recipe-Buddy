import SwiftUI

struct ListEditView: View {
    @ObservedObject var viewModel: ShoppingListViewModel
    var onSave: () -> Void
    var onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    listNameSection
                    itemsSection
                }
                .padding()
            }
            
            Spacer()
            
            saveButtonView
                .padding()
        }
        .background(Color.Background.ignoresSafeArea())
        .sheet(isPresented: $viewModel.showingIngredientSelector) {
            ShoppingListIngredientSelectorView(viewModel: viewModel)
        }
        .overlay(alignment: .top) {
            if let status = viewModel.ingredientInlineStatus {
                Text(status)
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.thinMaterial)
                    .clipShape(Capsule())
                    .padding(.top, 56)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                            viewModel.ingredientInlineStatus = nil
                        }
                    }
            }
        }
    }
    
    /// The header view with title and close button.
    private var headerView: some View {
        HStack {
            Text(viewModel.listToEdit != nil ? "Listeyi Düzenle" : "Yeni Liste Oluştur")
                .font(.headline).fontWeight(.bold)
            Spacer()
            Button(action: onCancel) {
                Image("close.circle.icon")
                    .font(.title2).foregroundStyle(.AppPrimary)
            }
        }
        .padding()
        .background(.thinMaterial)
    }
    
    /// The section for entering the list name.
    private var listNameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("LİSTE ADI")
                .font(.caption).foregroundStyle(.secondary).padding(.leading, 4)
            
            TextField("Örn: Haftalık Alışveriş", text: $viewModel.listNameForSheet)
                .textFieldStyle(CustomTextFieldStyle())
        }
    }
    
    /// The section for managing ingredients.
    private var itemsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("MALZEMELER")
                .font(.caption).foregroundStyle(.secondary).padding(.leading, 4)
            
            VStack(spacing: 12) {
                if viewModel.itemsForEditingList.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "basket")
                            .font(.title2)
                            .foregroundStyle(.TextSecondary)

                        Text("Henüz malzeme eklenmedi.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                        .frame(maxWidth: .infinity, minHeight: 96)
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.SurfaceBorder, lineWidth: 1))
                } else {
                    ForEach($viewModel.itemsForEditingList) { $item in
                        EditableShoppingItemRow(item: $item) {
                            if let index = viewModel.itemsForEditingList.firstIndex(where: { $0.id == item.id }) {
                                viewModel.itemsForEditingList.remove(at: index)
                            }
                        }
                    }
                }

                Button(action: {
                    viewModel.showingIngredientSelector = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.AppPrimary)

                        Text("Malzeme Seç veya Yeni Ekle")
                            .fontWeight(.semibold)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.TextSecondary)
                    }
                }
                .buttonStyle(CustomPickerStyle())
            }
        }
    }
    
    /// The main save button.
    private var saveButtonView: some View {
        Button(action: onSave) {
            Text(viewModel.listToEdit != nil ? "Değişiklikleri Kaydet" : "Listeyi Oluştur")
                .fontWeight(.semibold).frame(maxWidth: .infinity).padding()
                .background(Color.AppPrimary).foregroundStyle(.white).cornerRadius(12)
        }
        .disabled(viewModel.listNameForSheet.trimmingCharacters(in: .whitespaces).isEmpty)
        .opacity(viewModel.listNameForSheet.trimmingCharacters(in: .whitespaces).isEmpty ? 0.6 : 1.0)
    }
}

#Preview {
    ListEditView(viewModel: ShoppingListViewModel(), onSave: {}, onCancel: {})
}
