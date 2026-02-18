import SwiftUI
import NukeUI

struct RecipeDetailView: View {
    @StateObject var viewModel: RecipeDetailViewModel
    @Environment(\.dismiss) private var dismiss: DismissAction
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var dataManager: DataManager
    
    init(viewModel: RecipeDetailViewModel, navigationPath: Binding<NavigationPath>) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _navigationPath = navigationPath
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    recipeImageHeader
                    
                    VStack(alignment: .leading, spacing: 16) {
                        recipeInfoSection
                        Divider()
                        ingredientsSection
                        Divider()
                        addToShoppingListButton
                        Divider()
                        preparationSection
                        Spacer(minLength: 64)
                    }
                    .padding()
                }
            }
        }
        .ignoresSafeArea(edges: .top)
        .inlineColoredNavigationBar(
            titleColor: .white,
            tintColor: .white,
            textStyle: .headline,
            weight: .bold,
            hidesOnSwipe: true,
            transparentBackground: true
        )
        .modifier(LegacyBackButtonHider())
        .task {
            await viewModel.loadData()
        }
        .onChange(of: viewModel.shouldDismiss) {
            if viewModel.shouldDismiss {
                dismiss()
            }
        }
    }
    
    // MARK: - View Components
    private var recipeImageHeader: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                LazyImage(url: viewModel.recipe.imagePublicURL()) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        ZStack {
                            Rectangle().fill(.gray.opacity(0.1))
                            ProgressView()
                        }
                    }
                }
                .transition(.opacity.animation(.default))
                .frame(width: geo.size.width, height: max(geo.size.height, geo.frame(in: .global).minY > 0 ? geo.size.height + geo.frame(in: .global).minY : geo.size.height))
                .clipped()
                .offset(y: geo.frame(in: .global).minY > 0 ? -geo.frame(in: .global).minY : 0)
                
                if #unavailable(iOS 26) {
                    Button(action: {
                        dismiss()
                    }) {
                        ZStack(alignment: .center) {
                            Circle()
                                .fill(Color.black.opacity(0.5))
                                .frame(width: 48, height: 48)
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(.leading, 16)
                    .padding(.top, 48)
                }
            }
        }
        .frame(minHeight: 300)
    }
    
    private var recipeInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Text(viewModel.recipe.name)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.TextPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if viewModel.isOwnedByCurrentUser {
                    Button(action: {
                        navigationPath.append(AppNavigation.recipeEdit(viewModel.recipe))
                    }) {
                        Image("pencil.icon")
                            .resizable()
                            .foregroundStyle(.TextSecondary)
                            .frame(width: 24, height: 24)
                    }
                } else if viewModel.isAuthenticated {
                    Button(action: {
                        viewModel.showRatingSheet = true
                    }) {
                        Image(viewModel.userCurrentRating != nil ? "star.fill.icon" : "star.icon")
                            .resizable()
                            .foregroundStyle(viewModel.userCurrentRating != nil ? Color.AppPrimary : Color.TextSecondary)
                            .frame(width: 24, height: 24)
                    }
                    .contextMenu {
                        if viewModel.userCurrentRating != nil {
                            Button(role: .destructive) {
                                Task { await viewModel.removeRating() }
                            } label: {
                                Label("Puanı Kaldır", systemImage: "trash")
                            }
                        }
                    }
                }
                
                if viewModel.isAuthenticated {
                    Button(action: {
                        Task { await viewModel.toggleFavorite() }
                    }) {
                        Image(systemName: viewModel.isFavorite ? "heart.fill" : "heart")
                            .resizable()
                            .foregroundStyle(viewModel.isFavorite ? .Danger : .TextSecondary)
                            .frame(width: 24, height: 24)
                    }
                }
            }
            
            Text(viewModel.recipe.description)
                .font(.subheadline)
                .foregroundStyle(.TextPrimary)
            
            if let author = viewModel.recipe.user {
                HStack(spacing: 8) {
                    if let url = author.avatarPublicURL() {
                        LazyImage(url: url) { state in
                            if let image = state.image {
                                image
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                Color.gray.opacity(0.2)
                            }
                        }
                        .frame(width: 24, height: 24)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.SurfaceBorder, lineWidth: 0.5))
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundStyle(Color.TextSecondary.opacity(0.8))
                    }
                    Text(author.fullName ?? author.username ?? "İsimsiz")
                        .font(.subheadline)
                }
                .foregroundStyle(.TextSecondary)
                .padding(.top, 4)
                .padding(.bottom, 8)
            }
            
            HStack {
                RecipeInfoBadge(icon: "alarm.icon", text: "\(viewModel.recipe.cookingTime) dk", color: .TextPrimary)
                RecipeInfoBadge(icon: "people.icon", text: "\(viewModel.recipe.servings) porsiyon", color: .TextPrimary)
                RecipeInfoBadge(
                    icon: "heart.fill.icon",
                    text: "\(viewModel.recipe.favoritedCount)",
                    color: .Danger
                )
                if let rating = viewModel.recipe.rating, let ratingCount = viewModel.recipe.ratingCount {
                    RecipeInfoBadge(icon: "star.fill.icon", text: String(format: "%.1f", rating) + " (\(ratingCount))", color: .AppPrimary)
                } else {
                    let ratingCount = viewModel.recipe.ratingCount ?? 0
                    RecipeInfoBadge(icon: "star.icon", text: "0 (\(ratingCount))", color: .TextSecondary)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.recipe.categories) { recipeCategory in
                        Text(recipeCategory.category.name)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.AppPrimary.opacity(0.2))
                            .foregroundStyle(Color.AppPrimary)
                            .cornerRadius(8)
                    }
                }
            }
        }
    }
    
    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Malzemeler")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.TextPrimary)
            
            ForEach(viewModel.recipe.ingredients) { recipeIngredient in
                HStack {
                    Image("circle.fill.icon")
                        .resizable()
                        .foregroundStyle(Color.AppPrimary)
                        .frame(width: 12, height: 12)
                    
                    Text("\(recipeIngredient.formattedAmount) \(recipeIngredient.unit) \(recipeIngredient.name)")
                                .foregroundStyle(.TextPrimary)
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.toggleIngredientSelection(recipeIngredient)
                    }) {
                        Image(viewModel.isIngredientSelected(recipeIngredient) ? "checkbox.check.icon" : "checkbox.unchecked.icon")
                            .resizable()
                            .foregroundStyle(viewModel.isIngredientSelected(recipeIngredient) ? .Success : .TextSecondary)
                            .frame(width: 18, height: 18)
                    }
                }
                .padding(.vertical, 4)
            }
            
            Button(action: {
                viewModel.toggleAllIngredients()
            }) {
                Text(viewModel.areAllIngredientsSelected ? "Tüm Seçimleri Kaldır" : "Tümünü Seç")
                    .font(.subheadline)
                    .fontWeight(.heavy)
                    .foregroundStyle(Color.AppPrimary.opacity(0.8))
            }
            .padding(.top, 8)
        }
    }
    
    private var preparationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hazırlanışı")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.TextPrimary)
            
            ForEach(Array(viewModel.recipe.steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top) {
                    Text("\(index + 1).")
                        .font(.headline)
                        .foregroundStyle(.TextSecondary)
                    
                    Text(step)
                        .foregroundStyle(.TextPrimary)
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    private var addToShoppingListButton: some View {
        Button(action: {
            viewModel.addSelectedIngredientsToShoppingList()
        }) {
            VStack {
                HStack(spacing: 8) {
                    Image("cart.icon")
                        .resizable()
                        .frame(width: 18, height: 18)
                        .foregroundStyle(.white)
                    
                    Text("Seçili Malzemeleri Alışveriş Listesine Ekle")
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.AppPrimary)
            .foregroundStyle(.white)
            .cornerRadius(8)
        }
        .disabled(viewModel.selectedIngredients.isEmpty)
        .opacity(viewModel.selectedIngredients.isEmpty ? 0.6 : 1)
        .sheet(isPresented: $viewModel.showListSelector) {
            let selectedIngredients = viewModel.recipe.ingredients.filter { recipeIngredient in
                return viewModel.selectedIngredients.contains(recipeIngredient.id)
            }
            
            ListSelectorView(
                onListSelected: { selectedList in
                    await viewModel.add(ingredients: selectedIngredients, to: selectedList)
                    viewModel.showListSelector = false
                }, onCreateNewList: {
                    viewModel.showListSelector = false
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        viewModel.prepareAndShowListCreator()
                    }
                }, onCancel: {
                    viewModel.showListSelector = false
                }
            )
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $viewModel.shoppingListViewModel.isShowingEditSheet) {
            ListEditView(
                viewModel: viewModel.shoppingListViewModel,
                onSave: {
                    Task {
                        await viewModel.shoppingListViewModel.saveList(dataManager: dataManager)
                        
                        viewModel.statusMessage = "Yeni liste oluşturuldu ve malzemeler eklendi!"
                    }
                },
                onCancel: {
                    viewModel.shoppingListViewModel.isShowingEditSheet = false
                }
            )
        }
        .overlay(alignment: .bottom) {
            if let message = viewModel.statusMessage {
                HStack(spacing: 12) {
                    Text(message)
                        .foregroundColor(.white)
                    if viewModel.canUndoRatingChange {
                        Button("Geri Al") {
                            Task { await viewModel.undoRatingChange() }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.1))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(.black.opacity(0.8))
                .cornerRadius(12)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            viewModel.statusMessage = nil
                            viewModel.canUndoRatingChange = false
                        }
                    }
                }
            }
        }
        .animation(.spring(), value: viewModel.statusMessage)
        .sheet(isPresented: $viewModel.showRatingSheet) {
            RatingView(
                currentRating: $viewModel.userCurrentRating,
                onSave: { newRating in
                    Task {
                        await viewModel.submitRating(newRating)
                    }
                },
                onClear: {
                    Task {
                        await viewModel.removeRating()
                    }
                }
            )
            .presentationDetents([.height(200)])
        }
    }
}

private struct LegacyBackButtonHider: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
        } else {
            content.navigationBarBackButtonHidden()
        }
    }
}

#Preview() {
    NavigationStack {
        let viewModel = RecipeDetailViewModel(
            recipe: Recipe.allMocks.first!,
        )
        
        RecipeDetailView(viewModel: viewModel, navigationPath: .constant(NavigationPath()))
    }
}

