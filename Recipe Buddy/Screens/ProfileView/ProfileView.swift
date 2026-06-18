import SwiftUI
import NukeUI

struct ProfileView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var dataManager: DataManager

    var body: some View {
        ZStack {
            Color.Background.ignoresSafeArea()

            GeometryReader { geometry in
                let contentWidth = min(geometry.size.width, 430)

                ScrollView(showsIndicators: false) {
                    Group {
                        if dataManager.currentUser == nil && !dataManager.areProfileStatsLoaded {
                            ProgressView()
                                .frame(maxWidth: .infinity, minHeight: 300)
                                .padding()
                        } else if let user = dataManager.currentUser {
                            ProfileContentView(
                                mode: .currentUser,
                                user: user,
                                recipes: dataManager.ownedRecipes,
                                totalFavoritesReceived: dataManager.totalFavoritesReceived,
                                averageRating: dataManager.averageRating,
                                categoryDistribution: viewModel.categoryDistribution,
                                navigationPath: $navigationPath,
                                onEditProfile: { navigationPath.append(AppNavigation.editProfile) },
                                onSeeAllRecipes: {
                                    NotificationCenter.default.post(name: .appTabSelectionRequested, object: ContentTab.recipe)
                                },
                                forceHidePersonalDetails: false
                            )
                        } else {
                            Text("Kullanıcı bilgileri yüklenemedi.")
                                .padding()
                        }
                    }
                    .frame(width: contentWidth)
                    .frame(maxWidth: .infinity)
                }
                .background(Color.Background)
                .refreshable {
                    await dataManager.refreshProfileData()
                }
            }
            .navigationTitle("Profilim")
            .inlineColoredNavigationBar(titleColor: .AppPrimary, textStyle: .headline, weight: .bold, hidesOnSwipe: true, transparentBackground: true)
            .onAppear {
                viewModel.updateCategoryDistribution(from: dataManager.ownedRecipes)
            }
            .onReceive(dataManager.$ownedRecipes) { recipes in
                viewModel.updateCategoryDistribution(from: recipes)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        navigationPath.append(AppNavigation.settings)
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(.AppPrimary)
                    }
                }
            }
        }
    }
}

// MARK: - Robust wrapping layout for tag chips
struct TagWrapLayout: Layout {
    var alignment: HorizontalAlignment = .leading
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var maxLineWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > maxWidth {
                maxLineWidth = max(maxLineWidth, x - spacing)
                x = 0
                totalHeight += lineHeight + lineSpacing
                lineHeight = 0
            }
            x += (x > 0 ? spacing : 0) + size.width
            lineHeight = max(lineHeight, size.height)
        }

        if !subviews.isEmpty {
            maxLineWidth = max(maxLineWidth, x)
            totalHeight += lineHeight
        }

        if maxWidth.isFinite {
            return CGSize(width: maxWidth, height: totalHeight)
        } else {
            return CGSize(width: maxLineWidth, height: totalHeight)
        }
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width

        var lines: [[(Int, CGSize)]] = []
        var current: [(Int, CGSize)] = []
        var currentWidth: CGFloat = 0

        for (i, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            let additional = current.isEmpty ? size.width : spacing + size.width
            if !current.isEmpty && currentWidth + additional > maxWidth {
                lines.append(current)
                current = [(i, size)]
                currentWidth = size.width
            } else {
                current.append((i, size))
                currentWidth += additional
            }
        }
        if !current.isEmpty { lines.append(current) }

        var y: CGFloat = 0
        for line in lines {
            let lineHeight = line.map { $0.1.height }.max() ?? 0
            let contentWidth = line.reduce(0) { $0 + $1.1.width } + CGFloat(max(0, line.count - 1)) * spacing

            var startX: CGFloat = 0
            switch alignment {
            case .center:
                startX = max(0, (maxWidth - contentWidth) / 2)
            case .trailing:
                startX = max(0, maxWidth - contentWidth)
            default:
                startX = 0
            }

            var x = startX
            for (index, size) in line {
                subviews[index].place(
                    at: CGPoint(x: bounds.minX + x, y: bounds.minY + y),
                    proposal: ProposedViewSize(width: size.width, height: size.height)
                )
                x += size.width + spacing
            }
            y += lineHeight + lineSpacing
        }
    }
}

struct ProfileStatView: View {
    let value: String
    let title: String

    init(count: Int, title: String) {
        self.value = "\(count)"
        self.title = title
    }

    init(value: String, title: String) {
        self.value = value
        self.title = title
    }

    var body: some View {
        VStack {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(LocalizedStringKey(title))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.thinMaterial.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.SurfaceBorder, lineWidth: 1))
    }
}

#Preview {
    let coordinator = AppCoordinator()
    return NavigationStack {
        ProfileView(viewModel: ProfileViewModel(coordinator: coordinator), navigationPath: .constant(NavigationPath()))
            .environmentObject(DataManager())
    }
}
