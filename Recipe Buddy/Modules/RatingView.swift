import SwiftUI

struct RatingView: View {
    @Binding var currentRating: Int?
    let onSave: (Int) -> Void
    let onClear: (() -> Void)?
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedRating: Int = 0

    var body: some View {
        VStack(spacing: 20) {
            Text("Tarife Puan Ver").font(.title2).bold()
            
            HStack(spacing: 16) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= selectedRating ? "star.fill" : "star")
                        .font(.largeTitle)
                        .foregroundColor(.yellow)
                        .onTapGesture {
                            selectedRating = star
                        }
                }
            }
            
            HStack(spacing: 12) {
                if let onClear {
                    Button("Puanı Kaldır") {
                        onClear()
                        dismiss()
                    }
                    .padding()
                    .background(Color.red.opacity(0.15))
                    .foregroundColor(.red)
                    .cornerRadius(12)
                }
                
                Button("Puanı Kaydet") {
                    onSave(selectedRating)
                    dismiss()
                }
                .padding()
                .background(.AppPrimary)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(selectedRating == 0)
            }
        }
        .onAppear {
            selectedRating = currentRating ?? 0
        }
    }
}
