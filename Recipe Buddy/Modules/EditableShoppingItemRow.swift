import SwiftUI

struct EditableShoppingItemRow: View {
    @Binding var item: EditableShoppingItem
    var onDelete: () -> Void

    private let unitOptions = ["adet", "çay kaşığı", "tatlı kaşığı", "yemek kaşığı", "su bardağı", "çay bardağı", "gram", "kg", "ml", "litre", "demet", "dilim", "paket", "tutam"]
    private let amountOptions = ["0.25", "0.5", "1", "1.5", "2", "2.5", "3", "4", "5", "10", "25", "50", "100", "250", "500", "1000"]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                TextField("Malzeme adı", text: $item.name)
                    .font(.headline)
                    .textFieldStyle(.plain)

                Button(action: {
                    withAnimation {
                        onDelete()
                    }
                }) {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 8) {
                Menu {
                    ForEach(amountOptions, id: \.self) { amount in
                        Button(amount) {
                            item.amount = amount
                        }
                    }
                } label: {
                    editorFieldLabel(title: "Miktar", value: item.amount.isEmpty ? "Seç" : item.amount)
                }
                .buttonStyle(.plain)

                Menu {
                    ForEach(unitOptions, id: \.self) { unit in
                        Button(unit) {
                            item.unit = unit
                        }
                    }
                } label: {
                    editorFieldLabel(title: "Birim", value: item.unit.isEmpty ? "Seç" : item.unit)
                }
                .buttonStyle(.plain)
            }

            TextField("Özel miktar gir", text: $item.amount)
                .keyboardType(.decimalPad)
                .textFieldStyle(CustomTextFieldStyle())
                .onChange(of: item.amount) { _, newValue in
                    let sanitized = sanitizeAmount(newValue)
                    if sanitized != newValue {
                        item.amount = sanitized
                    }
                }
        }
        .padding(12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.SurfaceBorder, lineWidth: 1))
    }

    private func sanitizeAmount(_ raw: String) -> String {
        var value = raw.replacingOccurrences(of: ",", with: ".")
        value = value.filter { $0.isNumber || $0 == "." }

        if value.filter({ $0 == "." }).count > 1 {
            var result = ""
            var dotSeen = false

            for character in value {
                if character == "." {
                    if dotSeen { continue }
                    dotSeen = true
                }

                result.append(character)
            }

            value = result
        }

        return value
    }

    private func editorFieldLabel(title: String, value: String) -> some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.TextSecondary)

                Text(value)
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
        .background(Color.Surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.SurfaceBorder, lineWidth: 1))
    }
}
