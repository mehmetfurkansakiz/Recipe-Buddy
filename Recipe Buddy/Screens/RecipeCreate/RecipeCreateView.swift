import SwiftUI

struct RecipeCreateView: View {
    @ObservedObject var viewModel: RecipeCreateViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.Background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Custom progress indicator for steps
                ProgressHeader(selection: viewModel.selection)
                
                // Page view for each step
                TabView(selection: $viewModel.selection) {
                    Step1_BasicInfo(viewModel: viewModel).tag(0)
                    Step2_Ingredients(viewModel: viewModel).tag(1)
                    Step3_Preparation(viewModel: viewModel).tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never)) // Hides the default dots
                
                // Navigation buttons
                StepNavigation(viewModel: viewModel)
            }
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("İptal")
                            .foregroundStyle(.AppPrimary)
                            .disabled(viewModel.isSaving)
                            .opacity(viewModel.isSaving ? 0.4 : 1.0)
                    }
                }
                if viewModel.recipeToEdit != nil {
                    ToolbarItem(placement: .destructiveAction) {
                        Button(role: .destructive) {
                            viewModel.showDeleteConfirmAlert = true
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(Color.red)
                                .opacity(viewModel.isSaving ? 0.4 : 1.0)
                                .disabled(viewModel.isSaving)
                                .font(.callout)
                            
                        }
                    }
                }
            }
            .toolbarBackground(viewModel.isSaving ? .hidden : .visible, for: .navigationBar)
            
            if viewModel.isSaving {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()

                // ProgressView
                ProgressView(viewModel.recipeToEdit != nil ? "Güncelleniyor..." : "Kaydediliyor...")
                    .padding()
                    .background(.thinMaterial)
                    .colorScheme(.dark)
                    .cornerRadius(10)
                    .transition(.opacity)
            }
        }
        .tint(.AppPrimary)
        .animation(.easeInOut(duration: 0.25), value: viewModel.isSaving)
        .animation(.default, value: viewModel.selection)
        // Sheets
        .sheet(isPresented: $viewModel.showingCategorySelector) {
            CategorySelectorView(availableCategories: viewModel.availableCategories, selectedCategories: $viewModel.selectedCategories)
        }
        .alert("Hata", isPresented: .constant(viewModel.errorMessage != nil), actions: {
            Button("Tamam") { viewModel.errorMessage = nil }
        }, message: { Text(viewModel.errorMessage ?? "") })
        .alert("Tarifi Sil", isPresented: $viewModel.showDeleteConfirmAlert) {
            Button("Sil", role: .destructive) {
                Task { await viewModel.deleteRecipe() }
            }
            Button("İptal", role: .cancel) { }
        } message: {
            Text("Bu tarif kalıcı olarak silinecektir. Emin misiniz?")
        }
        .onChange(of: viewModel.showSuccess) {
            if viewModel.showSuccess { dismiss() }
        }
    }
}

struct ProgressHeader: View {
    let selection: Int
    let steps = ["Temel Bilgiler", "Malzemeler", "Hazırlanışı"]
    
    var body: some View {
        HStack {
            ForEach(steps.indices, id: \.self) { index in
                VStack(spacing: 8) {
                    Text(steps[index])
                        .font(.caption)
                        .foregroundStyle(selection >= index ? .AppPrimary : .secondary)
                    
                    Capsule()
                        .fill(selection >= index ? Color.AppPrimary : Color.SurfaceBorder)
                        .frame(height: 4)
                }
            }
        }
        .padding()
    }
}

struct StepNavigation: View {
    @ObservedObject var viewModel: RecipeCreateViewModel
    
    var body: some View {
        HStack {
            if viewModel.selection == 0 {
                Toggle("Herkesle Paylaş", isOn: $viewModel.isPublic)
                    .tint(.AppPrimary)
                    .toggleStyle(SwitchToggleStyle(tint: .AppPrimary))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(.thinMaterial)
                    .clipShape(Capsule())
            }
            
            if viewModel.selection > 0 {
                Button { viewModel.selection -= 1 } label: {
                    Label("Geri", systemImage: "chevron.left")
                        .padding().frame(maxWidth: .infinity)
                }
                .background(.gray.opacity(0.2))
                .foregroundStyle(.TextPrimary)
                .clipShape(Capsule())
                .contentShape(Rectangle())
            }
            
            if viewModel.selection < 2 {
                Button { viewModel.selection += 1 } label: {
                    HStack(spacing: 4) {
                        Text("İleri")
                        Image(systemName: "chevron.right")
                    }
                    .padding().frame(maxWidth: .infinity)
                }
                .background(Color.AppPrimary)
                .foregroundStyle(.white)
                .clipShape(Capsule())
                .contentShape(Rectangle())
            }
            
            if viewModel.selection == 2 {
                Button {
                    Task { await viewModel.saveRecipe() }
                } label: {
                    Text(viewModel.recipeToEdit != nil ? "Güncelle" : "Kaydet")
                        .padding().frame(maxWidth: .infinity)
                }
                .background(Color.AppPrimary)
                .foregroundStyle(.white)
                .clipShape(Capsule())
                .contentShape(Rectangle())
                .opacity((!viewModel.isValid || viewModel.isSaving) ? 0.4 : 1.0)
                .disabled(!viewModel.isValid || viewModel.isSaving)
            }
        }
        .padding([.horizontal, .bottom])
        .padding(.top, 8)
        .background(.thinMaterial)
    }
}

#Preview {
    RecipeCreateView(viewModel: RecipeCreateViewModel())
}
