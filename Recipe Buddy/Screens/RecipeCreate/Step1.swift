import SwiftUI
import PhotosUI

struct Step1_BasicInfo: View {
    @ObservedObject var viewModel: RecipeCreateViewModel
    
    @State private var activePicker: ActivePicker?

    enum ActivePicker: Identifiable {
        case servings
        case time
        var id: String {
            switch self {
            case .servings: return "servings"
            case .time: return "time"
            }
        }
    }
    
    var body: some View {
        let imageData = viewModel.selectedImageData
        
        ScrollView {
            VStack(spacing: 16) {
                // Image Picker
                PhotosPicker(selection: $viewModel.selectedPhotoItem, matching: .images) {
                    ZStack {
                        if let data = imageData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable().aspectRatio(contentMode: .fill)
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.thinMaterial)
                                    .frame(height: 240)
                                
                                VStack {
                                    Image(systemName: "photo.on.rectangle.angled")
                                        .font(.largeTitle)
                                    Text("Tarif Resmi Seç")
                                }
                                .foregroundColor(.TextSecondary)
                            }
                        }
                    }
                    
                    .frame(height: 240).cornerRadius(12)
                }
                .tint(.AppPrimary)
                .task(id: viewModel.selectedPhotoItem) {
                    await viewModel.loadImage(from: viewModel.selectedPhotoItem)
                }
                
                // Text Fields
                VStack(spacing: 16) {
                    // Name
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Tarif Adı", text: $viewModel.name)
                            .textInputAutocapitalization(.words)
                            .disableAutocorrection(true)
                            .onChange(of: viewModel.name) { oldValue, newValue in
                                let clamped = viewModel.clamp(newValue, to: viewModel.nameMaxLength)
                                if clamped != newValue { viewModel.name = clamped }
                            }
                    }

                    // Description
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Açıklama (Örn: Annemin meşhur tarifi...)", text: $viewModel.description, axis: .vertical)
                            .textInputAutocapitalization(.sentences)
                            .disableAutocorrection(false)
                            .onChange(of: viewModel.description) { oldValue, newValue in
                                let clamped = viewModel.clamp(newValue, to: viewModel.descriptionMaxLength)
                                if clamped != newValue { viewModel.description = clamped }
                            }
                            .lineLimit(3, reservesSpace: true)
                            .frame(minHeight: 60)
                    }
                }
                .textFieldStyle(CustomTextFieldStyle())
                
                // Category Selector
                Button(action: { viewModel.showingCategorySelector = true }) {
                    HStack {
                        if viewModel.selectedCategories.isEmpty {
                            Text("Kategori Seç")
                                .foregroundStyle(.TextSecondary)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(Array(viewModel.selectedCategories)) { category in
                                        Text(category.name)
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(.AppPrimary.opacity(0.2))
                                            .foregroundStyle(.AppPrimary)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(CustomPickerStyle())
                
                // Porsiyon ve Süre: adaptive grid ile iki sütun, dar alanda alta geçer
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 160), spacing: 12)
                ], spacing: 12) {
                    // Servings selector button
                    Button(action: { activePicker = .servings }) {
                        HStack(spacing: 8) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Porsiyon")
                                    .foregroundStyle(.TextSecondary)
                                Text(LocalizedText.servings(viewModel.servings))
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.TextPrimary)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer(minLength: 8)
                            Image(systemName: "chevron.down")
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                    }
                    .buttonStyle(CustomPickerStyle())

                    // Cooking time selector button
                    Button(action: { activePicker = .time }) {
                        HStack(spacing: 8) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Süre")
                                    .foregroundStyle(.TextSecondary)
                                Text(LocalizedText.minutesShort(viewModel.cookingTime))
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.TextPrimary)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer(minLength: 8)
                            Image(systemName: "chevron.down")
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                    }
                    .buttonStyle(CustomPickerStyle())
                }
            }
            .padding()
            .sheet(item: $activePicker) { picker in
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        Button("Bitti") { activePicker = nil }
                            .tint(.AppPrimary)
                    }
                    .padding()

                    switch picker {
                    case .servings:
                        Picker("Porsiyon", selection: $viewModel.servings) {
                            ForEach(viewModel.servingsOptions, id: \.self) { value in
                                Text(LocalizedText.servings(value)).tag(value)
                            }
                        }
                        .pickerStyle(.wheel)
                        .labelsHidden()
                        .tint(.AppPrimary)

                    case .time:
                        Picker("Süre", selection: $viewModel.cookingTime) {
                            ForEach(viewModel.timeOptions, id: \.self) { value in
                                Text(viewModel.formattedDuration(minutes: value)).tag(value)
                            }
                        }
                        .pickerStyle(.wheel)
                        .labelsHidden()
                        .tint(.AppPrimary)
                    }
                }
                .presentationDetents([.height(300)])
                .presentationDragIndicator(.visible)
            }
        }
    }
}

// Custom styles to match your design
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.SurfaceBorder, lineWidth: 1))
    }
}

struct CustomPickerStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.SurfaceBorder, lineWidth: 1))
    }
}

#Preview {
    Step1_BasicInfo(viewModel: RecipeCreateViewModel())
}
