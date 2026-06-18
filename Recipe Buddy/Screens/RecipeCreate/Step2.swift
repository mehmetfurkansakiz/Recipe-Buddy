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
                            EditableRecipeIngredientRow(
                                item: $item,
                                fallbackAmountOptions: viewModel.ingredientAmountOptions,
                                unitOptions: viewModel.ingredientUnitOptions,
                                groupedUnits: viewModel.groupedIngredientUnits(),
                                defaultAmountForUnit: viewModel.defaultAmount(for:),
                                sanitizeAmount: viewModel.sanitizeAmount(_:),
                                onDone: {
                                    viewModel.addOrUpdateIngredient(item)
                                    viewModel.ingredientToEditDetails = nil
                                }
                            )
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
        .overlay(alignment: .top) {
            if let status = viewModel.ingredientInlineStatus {
                Text(status)
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.thinMaterial)
                    .clipShape(Capsule())
                    .padding(.top, 8)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                            viewModel.ingredientInlineStatus = nil
                        }
                    }
            }
        }
        .alert("Malzeme Zaten Mevcut", isPresented: .constant(viewModel.ingredientAlertMessage != nil), actions: {
            Button("Tamam") {
                viewModel.ingredientAlertMessage = nil
            }
        }, message: {
            Text(LocalizedStringKey(viewModel.ingredientAlertMessage ?? ""))
        })
    }
}

// view for the animated editing row
struct EditableRecipeIngredientRow: View {
    @Binding var item: RecipeIngredientInput
    var fallbackAmountOptions: [String]
    var unitOptions: [String]
    var groupedUnits: [(String, [String])]
    var defaultAmountForUnit: (String) -> String
    var sanitizeAmount: (String) -> String
    var onDone: () -> Void

    @State private var isEditing = false

    private var quickAmountOptions: [String] {
        let normalized = item.unit.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if normalized.isEmpty {
            return fallbackAmountOptions
        }

        if normalized.contains("kaşığı") || normalized.contains("bardağı") {
            return ["0.1", "0.25", "0.33", "0.5", "0.66", "0.75", "1", "1.25", "1.5", "1.75", "2", "2.5", "3", "3.5", "4", "5", "6", "8"]
        }

        if normalized == "gram" || normalized == "ml" {
            return ["5", "10", "15", "20", "25", "30", "40", "50", "60", "75", "100", "125", "150", "175", "200", "250", "300", "400", "500", "750", "1000"]
        }

        if normalized == "kg" || normalized == "litre" {
            return ["0.1", "0.25", "0.33", "0.5", "0.66", "0.75", "1", "1.25", "1.5", "2", "2.5", "3", "4", "5"]
        }

        return ["0.5", "1", "1.5", "2", "2.5", "3", "3.5", "4", "4.5", "5", "6", "7", "8", "9", "10", "12", "15", "20"]
    }

    private var unitSections: [(String, [String])] {
        groupedUnits.map { header, units in
            (header, units.filter { unitOptions.contains($0) })
        }.filter { !$0.1.isEmpty }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(item.ingredient.name)
                .font(.headline)

            HStack(spacing: 8) {
                Menu {
                    ForEach(unitSections, id: \.0) { section in
                        Section(section.0) {
                            ForEach(section.1, id: \.self) { unit in
                                Button {
                                    item.unit = unit
                                    if !quickAmountOptions.contains(item.amount) {
                                        item.amount = defaultAmountForUnit(unit)
                                    }
                                    isEditing = true
                                } label: {
                                    Text(LocalizedStringKey("unit.\(unit)"))
                                }
                            }
                        }
                    }
                } label: {
                    pickerFieldLabel(
                        title: "Birim",
                        value: item.unit.isEmpty ? "Seç" : LocalizedText.unit(item.unit)
                    )
                }
                .buttonStyle(.plain)

                Menu {
                    ForEach(quickAmountOptions, id: \.self) { amount in
                        Button(amount) {
                            item.amount = amount
                            isEditing = true
                        }
                    }
                } label: {
                    pickerFieldLabel(
                        title: "Hızlı Miktar",
                        value: item.amount.isEmpty ? "Seç" : item.amount
                    )
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 8) {
                presetButton("Az") { setPresetAmount(multiplier: 0.5) }
                presetButton("Orta") { setPresetAmount(multiplier: 1.0) }
                presetButton("Bol") { setPresetAmount(multiplier: 1.5) }
                Spacer()
                stepButton("minus") { stepAmount(by: -1) }
                stepButton("plus") { stepAmount(by: 1) }
            }

            TextField("Özel miktar gir", text: $item.amount)
                .keyboardType(.decimalPad)
                .textFieldStyle(CustomTextFieldStyle())
                .onChange(of: item.amount) { _, newValue in
                    let sanitized = sanitizeAmount(newValue)
                    if sanitized != newValue {
                        item.amount = sanitized
                    }
                    isEditing = true
                }

            Button(action: {
                item.amount = sanitizeAmount(item.amount)
                if let number = Double(item.amount), number > 0 {
                    // keep value
                } else {
                    item.amount = defaultAmountForUnit(item.unit)
                }
                onDone()
                isEditing = false
            }) {
                Text("Bitti")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.AppPrimary)

            if isEditing {
                Text("Düzenleniyor")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.SurfaceBorder, lineWidth: 1))
    }

    private func normalizedAmountString(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", value)
        }

        var text = String(format: "%.2f", value)
        while text.contains(".") && (text.hasSuffix("0") || text.hasSuffix(".")) {
            text.removeLast()
        }
        return text
    }

    private func setPresetAmount(multiplier: Double) {
        let base = Double(defaultAmountForUnit(item.unit)) ?? 1
        let value = max(0.1, base * multiplier)
        item.amount = normalizedAmountString(value)
        isEditing = true
    }

    private func stepAmount(by direction: Int) {
        let options = quickAmountOptions
        guard !options.isEmpty else { return }

        let normalizedCurrent = normalizedAmountString(Double(item.amount.replacingOccurrences(of: ",", with: ".")) ?? 0)

        if let idx = options.firstIndex(of: normalizedCurrent) {
            let next = max(0, min(options.count - 1, idx + direction))
            item.amount = options[next]
        } else {
            let currentValue = Double(normalizedCurrent) ?? 0
            let numericOptions = options.compactMap { Double($0) }
            guard !numericOptions.isEmpty else { return }

            let closest = numericOptions.enumerated().min { lhs, rhs in
                abs(lhs.element - currentValue) < abs(rhs.element - currentValue)
            }?.offset ?? 0

            let next = max(0, min(options.count - 1, closest + direction))
            item.amount = options[next]
        }

        isEditing = true
    }

    private func stepButton(_ systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.caption.weight(.bold))
                .frame(width: 28, height: 28)
                .background(Color.Surface)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private func presetButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(LocalizedStringKey(title))
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.Surface)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func pickerFieldLabel(title: String, value: String) -> some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(title))
                    .font(.caption)
                    .foregroundStyle(.TextSecondary)
                Text(LocalizedStringKey(value))
                    .foregroundStyle(.TextPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Spacer(minLength: 4)
            Image(systemName: "chevron.down")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.SurfaceBorder, lineWidth: 1))
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
            
            Text(LocalizedText.amount(item.amount, unit: item.unit))
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
