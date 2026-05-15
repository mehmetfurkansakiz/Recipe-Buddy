import SwiftUI

struct MainTabView: View {
    @ObservedObject var coordinator: AppCoordinator
    @State private var selectedTab: ContentTab = .home
    @State private var navigationPath = NavigationPath()
    @State private var selectedTheme: ThemeOption = ThemePreferencesViewModel().selected
    
    private let tabs = [
        TabItem(icon: "home.icon"),
        TabItem(icon: "cupcake.icon"),
        TabItem(icon: "cart.icon"),
        TabItem(icon: "user.icon")
    ]
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            TabContent(
                selectedTab: selectedTab,
                navigationPath: $navigationPath,
                coordinator: coordinator
            )
            .safeAreaInset(edge: .bottom, spacing: 0) {
                CustomTabBar(
                    selectedTab: Binding(
                        get: { selectedTab.rawValue },
                        set: { selectedTab = ContentTab(rawValue: $0)! }
                    ),
                    tabs: tabs
                )
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .navigationDestination(for: AppNavigation.self) { destination in
                switch destination {
                case .recipeDetail(let recipe):
                    RecipeDetailView(viewModel: RecipeDetailViewModel(recipe: recipe), navigationPath: $navigationPath)
                case .recipeCreate:
                    RecipeCreateView(viewModel: RecipeCreateViewModel())
                case .recipeEdit(let recipe):
                    RecipeCreateView(viewModel: RecipeCreateViewModel(recipeToEdit: recipe))
                case .profile:
                    ProfileView(viewModel: ProfileViewModel(coordinator: coordinator), navigationPath: $navigationPath)
                case .userProfile(let user):
                    PublicProfileView(user: user, navigationPath: $navigationPath)
                case .editProfile:
                    EditProfileView(viewModel: EditProfileViewModel())
                case .favoriteRecipes:
                    FavoriteRecipesView(navigationPath: $navigationPath)
                case .settings:
                    SettingsView(viewModel: SettingsViewModel(coordinator: coordinator), navigationPath: $navigationPath)
                case .changePassword:
                    ChangePasswordView(viewModel: ChangePasswordViewModel())
                case .emailPreferences:
                    EmailPreferencesView(viewModel: EmailPreferencesViewModel())
                case .notificationPreferences:
                    NotificationPreferencesView(viewModel: NotificationPreferencesViewModel())
                case .themePreferences:
                    ThemePreferencesView(viewModel: ThemePreferencesViewModel())
                case .helpCenter:
                    HelpCenterView(viewModel: HelpCenterViewModel())
                case .sendFeedback:
                    FeedbackView(viewModel: FeedbackViewModel())
                case .advancedSettings:
                    AdvancedSettingsView(viewModel: SettingsViewModel(coordinator: coordinator), navigationPath: $navigationPath)
                case .deleteAccount:
                    DeleteAccountView(viewModel: DeleteAccountViewModel())
                }
            }
        }
        .preferredColorScheme(selectedTheme.colorScheme)
        .onReceive(NotificationCenter.default.publisher(for: .themeChanged)) { notification in
            if let option = notification.object as? ThemeOption {
                selectedTheme = option
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .appTabSelectionRequested)) { notification in
            if let tab = notification.object as? ContentTab {
                selectedTab = tab
                navigationPath = NavigationPath()
            }
        }
    }
}

struct TabContent: View {
    let selectedTab: ContentTab
    @Binding var navigationPath: NavigationPath
    let coordinator: AppCoordinator
    
    var body: some View {
        switch selectedTab {
        case .home:
            HomeView(viewModel: HomeViewModel(), navigationPath: $navigationPath)
        case .recipe:
            RecipesView(viewModel: RecipesViewModel(), navigationPath: $navigationPath)
        case .shoppingList:
            ShoppingListView(viewModel: ShoppingListViewModel(), navigationPath: $navigationPath)
        case .settings:
            ProfileView(viewModel: ProfileViewModel(coordinator: coordinator), navigationPath: $navigationPath)
        }
    }
}

#Preview {
    MainTabView(coordinator: AppCoordinator())
        .environmentObject(DataManager())
}
