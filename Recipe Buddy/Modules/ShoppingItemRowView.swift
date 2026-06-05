import SwiftUI

struct ShoppingItemRowView: View {
    let item: ShoppingListItem
    let index: Int
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 15) {
            Circle()
                .frame(width: 8, height: 8)
                .foregroundStyle(item.isChecked ? Color.gray : Color.orange)
                .opacity(0.8)
            
            Text(item.name)
                .font(.subheadline.weight(.semibold))
                .strikethrough(item.isChecked, color: .secondary)
            
            Spacer()
            
            Text("\(item.formattedAmount) \(item.unit)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .strikethrough(item.isChecked, color: .secondary)
            
            Button(action: onToggle) {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(item.isChecked ? .green : .secondary)
            }
            .buttonStyle(.plain)
            
        }
        .padding(.vertical, 12)
        .padding(.horizontal)
        .background(index % 2 == 0 ? Color(.systemGray6) : Color.clear)
        .cornerRadius(8)
        .opacity(item.isChecked ? 0.6 : 1.0)
    }
}
