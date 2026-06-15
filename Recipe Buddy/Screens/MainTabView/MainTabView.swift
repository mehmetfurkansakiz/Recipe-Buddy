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
                .frame(maxWidth: 430)
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .navigationDestination(for: AppNavigation.self) { destination in
                switch destination {
                case .recipeDetail(let recipe):
                    RecipeDetailView(
                        viewModel: RecipeDetailViewModel(recipe: recipe),
                        navigationPath: $navigationPath,
                        onAuthRequired: { coordinator.showAuthenticationView() }
                    )
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
        .onReceive(NotificationCenter.default.publisher(for: .guestHomeRequested)) { _ in
            selectedTab = .home
            navigationPath = NavigationPath()
        }
    }
}

struct TabContent: View {
    let selectedTab: ContentTab
    @Binding var navigationPath: NavigationPath
    let coordinator: AppCoordinator
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        switch selectedTab {
        case .home:
            HomeView(viewModel: HomeViewModel(), navigationPath: $navigationPath)
        case .recipe:
            if dataManager.currentUser == nil {
                GuestAccessView(
                    title: "Tariflerini yönet",
                    message: "Tarif oluşturmak, favorilerini görmek ve kendi tariflerini düzenlemek için giriş yap.",
                    buttonTitle: "Giriş Yap",
                    action: { coordinator.showAuthenticationView() }
                )
            } else {
                RecipesView(viewModel: RecipesViewModel(), navigationPath: $navigationPath)
            }
        case .shoppingList:
            if dataManager.currentUser == nil {
                GuestAccessView(
                    title: "Alışveriş listelerini kullan",
                    message: "Malzemeleri kaydetmek ve listelerini cihazların arasında yönetmek için giriş yap.",
                    buttonTitle: "Giriş Yap",
                    action: { coordinator.showAuthenticationView() }
                )
            } else {
                ShoppingListView(viewModel: ShoppingListViewModel(), navigationPath: $navigationPath)
            }
        case .settings:
            if dataManager.currentUser == nil {
                GuestAccessView(
                    title: "Profilini aç",
                    message: "Profilini düzenlemek, ayarlarını yönetmek ve hesap özelliklerini kullanmak için giriş yap.",
                    buttonTitle: "Giriş Yap",
                    action: { coordinator.showAuthenticationView() }
                )
            } else {
                ProfileView(viewModel: ProfileViewModel(coordinator: coordinator), navigationPath: $navigationPath)
            }
        }
    }
}

struct GuestAccessView: View {
    let title: String
    let message: String
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        ZStack {
            Color.Background.ignoresSafeArea()

            VStack(spacing: 18) {
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 46, weight: .semibold))
                    .foregroundStyle(Color.AppPrimary)

                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.TextPrimary)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(Color.TextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)

                Button(action: action) {
                    Text(buttonTitle)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.AppPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.top, 4)
            }
            .padding(24)
            .frame(maxWidth: 360)
        }
    }
}

#Preview {
    MainTabView(coordinator: AppCoordinator())
        .environmentObject(DataManager())
}
