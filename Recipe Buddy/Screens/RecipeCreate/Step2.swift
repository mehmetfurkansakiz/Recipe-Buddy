import SwiftUI

struct Step2_Ingredients: View {
    @ObservedObject var viewModel: RecipeCreateViewModel
    
    var body: some View {
        VStack {
            // Use a ScrollView instead of a List for custom styling
            ScrollView {
                VStack(spacing: 12) {
                    ForEach($viewModel.recipeIngredients) { $item in
                        // If this is the item to edit, show the special row
                        if viewModel.ingredientToEditDetails?.id == item.id {
                            EditableRecipeIngredientRow(item: $item, onDone: {
                                viewModel.addOrUpdateIngredient(item)
                                viewModel.ingredientToEditDetails = nil
                            })
                        } else {
                            // show the standard display row that is tappable
                            DisplayRecipeIngredientRow(item: item, onEdit: {
                                viewModel.ingredientToEditDetails = item // Enter edit mode
                            }, onDelete: {
                                viewModel.removeIngredient(with: item.id)
                            })
                        }
                    }
                }
                .padding()
            }
            
            Button("Malzeme Ekle") {
                viewModel.showingIngredientSelector = true
            }
            .buttonStyle(CustomPickerStyle())
            .padding()
        }
        .sheet(isPresented: $viewModel.showingIngredientSelector) {
            IngredientSelectorView(viewModel: viewModel)
        }
        .animation(.default, value: viewModel.ingredientToEditDetails)
        .alert("Malzeme Zaten Mevcut", isPresented: .constant(viewModel.ingredientAlertMessage != nil), actions: {
            Button("Tamam") {
                viewModel.ingredientAlertMessage = nil
            }
        }, message: {
            Text(viewModel.ingredientAlertMessage ?? "")
        })
    }
}

// view for the animated editing row
struct EditableRecipeIngredientRow: View {
    @Binding var item: RecipeIngredientInput
    var onDone: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(item.ingredient.name)
                .font(.headline)
                .padding(.bottom, 4)
            
            HStack {
                TextField("Miktar", text: $item.amount)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(CustomTextFieldStyle())
                
                TextField("Birim", text: $item.unit)
                    .textFieldStyle(CustomTextFieldStyle())

                Spacer()
                
                Button(action: onDone) {
                    Text("Bitti")
                        .frame(maxHeight: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.AppPrimary)
            }
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.SurfaceBorder, lineWidth: 1))
    }
}

// Helper view for displaying an already-added ingredient
struct DisplayRecipeIngredientRow: View {
    let item: RecipeIngredientInput
    var onEdit: () -> Void
    var onDelete: () -> Void
    
    var body: some View {
        HStack {
            Image("pencil.icon")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text(item.ingredient.name)
                .font(.headline)
            
            Spacer()
            
            Text("\(item.amount) \(item.unit)")
                .foregroundStyle(.secondary)
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.systemGray4), lineWidth: 1))
        .onTapGesture(perform: onEdit)
    }
}

#Preview {
    Step2_Ingredients(viewModel: RecipeCreateViewModel())
}
