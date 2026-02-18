import SwiftUI

struct SearchBarView: View {
    @Binding var searchText: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.TextSecondary)
            
            TextField("Tarif Ara...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 16))
                .foregroundColor(.TextPrimary)
                .tint(.AppPrimary)
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image("close.circle.icon")
                        .resizable()
                        .foregroundStyle(.TextSecondary)
                        .frame(width: 18, height: 18)
                }
            }
        }
        .frame(height: 40)
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(.Surface)
        .cornerRadius(12)
        
    }
}

#Preview {
    SearchBarView(searchText: .constant(""))
}
