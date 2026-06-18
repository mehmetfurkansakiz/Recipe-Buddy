import SwiftUI

struct ListSelectorView: View {
    var onListSelected: (ShoppingList) async -> Void
    var onCreateNewList: () -> Void
    var onCancel: () -> Void
    
    @State private var lists: [ShoppingList] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.Background.ignoresSafeArea()
                
                Group {
                    if isLoading {
                        ProgressView()
                    } else {
                        // Listeyi veya boş görünümü göstermek için ScrollView kullan
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                if lists.isEmpty {
                                    emptyList
                                } else {
                                    listBody
                                }
                            }
                            .padding(.top) // Listenin üstüne biraz boşluk ekle
                        }
                    }
                }
                .navigationTitle("Listeye Ekle")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("İptal", action: onCancel)
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button("Yeni Liste", systemImage: "plus", action: onCreateNewList)
                    }
                }
                .tint(.AppPrimary)
                .task {
                    await fetchLists()
                }
            }
        }
    }
    
    private var emptyList: some View {
        VStack(spacing: 12) {
            Image(systemName: "list.bullet.clipboard")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("Hiç Alışveriş Listeniz Yok")
                .font(.headline)
            Text("Yukarıdaki \"Yeni Liste\" butonuna basarak seçili malzemelerle yeni bir liste oluşturabilirsiniz.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .center)
        .listRowBackground(Color.clear)
    }
    
    private var listBody: some View {
        ForEach(lists) { list in
            Button(action: {
                Task {
                    await onListSelected(list)
                }
            }) {
                HStack {
                    Text(list.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.TextPrimary)
                    
                    Circle()
                        .frame(width: 4, height: 4)
                        .foregroundStyle(.TextSecondary.opacity(0.5))
                    
                    Text(LocalizedText.listItems(list.itemCount))
                        .font(.callout)
                        .foregroundStyle(.TextSecondary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.TextSecondary.opacity(0.5))
                }
                .padding()
                .background(.thinMaterial.opacity(0.3)) // Arka plan
                .clipShape(RoundedRectangle(cornerRadius: 12)) // Köşeleri yuvarla
                .overlay(RoundedRectangle(cornerRadius: 12) // Kenarlık ekle
                    .stroke(Color.SurfaceBorder, lineWidth: 1))
                .padding(.horizontal)
            }
            .buttonStyle(.plain)
        }
    }
    
    private func fetchLists() async {
        isLoading = true
        defer { isLoading = false }
        do {
            self.lists = try await ShoppingListService.shared.fetchListsWithCounts()
        } catch {
            print("❌ Error fetching lists for selector: \(error.localizedDescription)")
            self.lists = []
        }
    }
}


#Preview {
    ListSelectorView(onListSelected: {_ in }, onCreateNewList: {}, onCancel: {})
}
