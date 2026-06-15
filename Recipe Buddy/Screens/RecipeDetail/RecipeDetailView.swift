import SwiftUI
import NukeUI

struct RecipeDetailView: View {
    @StateObject var viewModel: RecipeDetailViewModel
    @Environment(\.dismiss) private var dismiss: DismissAction
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var dataManager: DataManager
    @State private var showAuthenticationPrompt = false
    let onAuthRequired: () -> Void
    
    init(viewModel: RecipeDetailViewModel, navigationPath: Binding<NavigationPath>, onAuthRequired: @escaping () -> Void = {}) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _navigationPath = navigationPath
        self.onAuthRequired = onAuthRequired
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.Background.ignoresSafeArea()

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
                    .frame(maxWidth: 430, alignment: .leading)
                    .frame(maxWidth: .infinity)
                }
            }
            .coordinateSpace(name: "recipeDetailScroll")
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
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if #available(iOS 26, *) {
                    EmptyView()
                } else {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(.black.opacity(0.96))
                            )
                            .overlay(
                                Circle()
                                    .stroke(.white.opacity(0.18), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .task {
            await viewModel.loadData()
        }
        .onChange(of: viewModel.shouldDismiss) {
            if viewModel.shouldDismiss {
                dismiss()
            }
        }
        .alert("Liste oluşturmak için giriş yap", isPresented: $showAuthenticationPrompt) {
            Button("İptal", role: .cancel) { }
            Button("Giriş Yap") {
                onAuthRequired()
            }
        } message: {
            Text("Malzemeleri seçip tarifi incelemeye devam edebilirsin. Seçili malzemeleri alışveriş listesine eklemek için kayıt olman veya giriş yapman gerekir.")
        }
    }
    
    // MARK: - View Components
    private var recipeImageHeader: some View {
        GeometryReader { geo in
            let minY = geo.frame(in: .named("recipeDetailScroll")).minY
            let headerHeight: CGFloat = 300
            let stretchHeight = minY > 0 ? headerHeight + minY : headerHeight

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
                .frame(width: geo.size.width, height: stretchHeight)
                .clipped()
                .offset(y: minY > 0 ? -minY : 0)
            }
        }
        .frame(minHeight: 300)
    }
    
    private var recipeInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.recipe.name)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.TextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            
            Text(viewModel.recipe.description)
                .font(.subheadline)
                .foregroundStyle(.TextPrimary)
            
            if let author = viewModel.recipe.user {
                HStack(spacing: 8) {
                    Button {
                        navigationPath.append(AppNavigation.userProfile(author))
                    } label: {
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
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)

                    if viewModel.isOwnedByCurrentUser || viewModel.isAuthenticated {
                        topActionsRow
                    }
                }
                .foregroundStyle(.TextSecondary)
                .padding(.top, 4)
                .padding(.bottom, 8)
            } else if viewModel.isOwnedByCurrentUser || viewModel.isAuthenticated {
                HStack {
                    Spacer()
                    topActionsRow
                }
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
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.TextPrimary)
            
            ForEach(viewModel.recipe.ingredients) { recipeIngredient in
                Button(action: {
                        viewModel.toggleIngredientSelection(recipeIngredient)
                    }) {
                        HStack(spacing: 10) {
                            Image("circle.fill.icon")
                                .resizable()
                                .foregroundStyle(Color.AppPrimary)
                                .frame(width: 10, height: 10)
                            
                            Text("\(recipeIngredient.formattedAmount) \(recipeIngredient.unit) \(recipeIngredient.name)")
                                .font(.subheadline)
                                .foregroundStyle(.TextPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            let isSelected = viewModel.isIngredientSelected(recipeIngredient)
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(isSelected ? Color.Success.opacity(0.16) : Color.Surface)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(isSelected ? Color.Success : Color.SurfaceBorder, lineWidth: 1.2)
                                    )
                                    .frame(width: 24, height: 24)
                                
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(isSelected ? Color.Success : Color.clear)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                .buttonStyle(.plain)
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
                .font(.title3)
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
            guard viewModel.isAuthenticated else {
                showAuthenticationPrompt = true
                return
            }
            viewModel.addSelectedIngredientsToShoppingList()
        }) {
            HStack(spacing: 8) {
                Image("cart.icon")
                    .resizable()
                    .frame(width: 16, height: 16)
                    .foregroundStyle(.AppPrimary)
                
                Text("Seçilileri Listeye Ekle")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
                
                Spacer(minLength: 8)
                
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.TextSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.Surface)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.SurfaceBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
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

    private var topActionsRow: some View {
        HStack(spacing: 10) {
            if viewModel.isOwnedByCurrentUser {
                Button(action: {
                    navigationPath.append(AppNavigation.recipeEdit(viewModel.recipe))
                }) {
                    actionLabel(
                        title: "Düzenle",
                        color: .TextSecondary
                    ) {
                        Image("pencil.icon")
                            .resizable()
                            .frame(width: 18, height: 18)
                    }
                }
            } else if viewModel.isAuthenticated {
                Button(action: {
                    viewModel.showRatingSheet = true
                }) {
                    actionLabel(
                        title: "Puanla",
                        color: viewModel.userCurrentRating != nil ? .AppPrimary : .TextSecondary
                    ) {
                        Image(viewModel.userCurrentRating != nil ? "star.fill.icon" : "star.icon")
                            .resizable()
                            .frame(width: 18, height: 18)
                    }
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
                    actionLabel(
                        title: "Favori",
                        color: viewModel.isFavorite ? .Danger : .TextSecondary
                    ) {
                        Image(systemName: viewModel.isFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
            }
        }
    }

    private func actionLabel<Content: View>(
        title: String,
        color: Color,
        @ViewBuilder icon: () -> Content
    ) -> some View {
        HStack(spacing: 6) {
            icon()
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color.Surface)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.SurfaceBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct LegacyBackButtonHider: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
        } else {
            content.navigationBarBackButtonHidden(true)
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
