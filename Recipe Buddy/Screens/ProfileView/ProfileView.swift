import SwiftUI
import NukeUI

struct ProfileView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var dataManager: DataManager
    @StateObject private var editProfileViewModel = EditProfileViewModel()
    @State private var goToSettings = false
    
    var body: some View {
        ZStack {
            Color.Background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    if dataManager.currentUser == nil && !dataManager.areProfileStatsLoaded {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 300)
                    } else if let user = dataManager.currentUser {
                        profileHeader(user: user)
                        statsSection
                        // Additional profile sections
                        VStack(alignment: .leading, spacing: 24) {
                            aboutSection
                            recentRecipesSection
                            topLikedSection
                            ratingDistributionSection
                            activitySection
                            categoryDistributionSection
                        }
                        .padding(.bottom, 48)
                        
                        Spacer()
                    } else {
                        Text("Kullanıcı bilgileri yüklenemedi.")
                    }
                    Spacer(minLength: 40)
                }
                .padding()
            }
            .background(Color.Background)
            .refreshable {
                await dataManager.refreshProfileData()
            }
            .navigationTitle("Profilim")
            .inlineColoredNavigationBar(titleColor: .AppPrimary, textStyle: .headline, weight: .bold, hidesOnSwipe: true, transparentBackground: true)
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
    
    /// The main header with avatar, name, and username.
    private func profileHeader(user: User) -> some View {
        VStack(spacing: 16) {
            LazyImage(url: user.avatarPublicURL()) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.gray.opacity(0.3))
                }
            }
            .frame(width: 80, height: 80)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.SurfaceBorder, lineWidth: 1))
            
            VStack {
                Text(user.fullName ?? "İsimsiz")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("@\(user.username ?? "")")
                    .font(.subheadline)
                    .foregroundStyle(.TextSecondary)
            }
            
            NavigationLink {
                EditProfileView(viewModel: editProfileViewModel)
            } label: {
                Text("Profili Düzenle")
                    .tint(.AppPrimary)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .background(.thinMaterial.opacity(0.3))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color(.systemGray4), lineWidth: 1))
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    /// The section with user stats like recipe and favorite counts.
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("İSTATİSTİKLER")
                .font(.caption).foregroundStyle(.secondary).padding(.leading, 4)
            
            HStack(spacing: 12) {
                ProfileStatView(count: dataManager.ownedRecipesTotalCount, title: "Tariflerim")
                ProfileStatView(count: dataManager.totalFavoritesReceived, title: "Alınan Favori")
                ProfileStatView(value: String(format: "%.1f", dataManager.averageRating), title: "Ort. Puan")
            }
        }
    }
    
    // MARK: - About / Bio
    private var aboutSection: some View {
        let user = dataManager.currentUser
        let bioText = user?.bio?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let hasProfession = (user?.showProfession ?? false) && !(user?.profession?.isEmpty ?? true)
        let hasCity = (user?.showCity ?? false) && !(user?.city?.isEmpty ?? true)
        let hasBirthDate = (user?.showBirthDate ?? false) && user?.birthDate != nil
        let isAboutEmpty = bioText.isEmpty && !hasProfession && !hasCity && !hasBirthDate

        return VStack(alignment: .leading, spacing: 8) {
            Text("HAKKIMDA")
                .font(.caption).foregroundStyle(.secondary).padding(.leading, 4)
            
            VStack(alignment: .leading, spacing: 6) {
                if !bioText.isEmpty {
                    Text(bioText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 12) {
                    if (user?.showProfession ?? false), let profession = user?.profession, !profession.isEmpty {
                        Label(profession, systemImage: "briefcase")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    if (user?.showCity ?? false), let city = user?.city, !city.isEmpty {
                        Label(city, systemImage: "mappin.and.ellipse")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    if (user?.showBirthDate ?? false), let date = user?.birthDate {
                        let age = Calendar.current.dateComponents([.year], from: date, to: .now).year ?? 0
                        Label("\(age) yaş", systemImage: "calendar")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                if isAboutEmpty {
                    Text("Henüz hakkımda bilgisi eklenmemiş.")
                        .font(.subheadline)
                        .foregroundStyle(.TextSecondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.SurfaceBorder, lineWidth: 1))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Recent Recipes (Horizontal)
    private var recentRecipesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("SON TARİFLERİM")
                    .font(.caption).foregroundStyle(.secondary).padding(.leading, 4)
                Spacer()
                Button("Tümünü Gör") {
                    NotificationCenter.default.post(name: .appTabSelectionRequested, object: ContentTab.recipe)
                }
                .font(.footnote)
                .tint(.AppPrimary)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(dataManager.ownedRecipes.prefix(6))) { recipe in
                        Button {
                            navigationPath.append(AppNavigation.recipeDetail(recipe))
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                if let url = recipe.imagePublicURL() {
                                    AsyncImage(url: url) { image in
                                        image.resizable().scaledToFill()
                                    } placeholder: {
                                        Color.gray.opacity(0.15)
                                    }
                                    .frame(width: 140, height: 90)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                } else {
                                    Color.gray.opacity(0.15)
                                        .frame(width: 140, height: 90)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                Text(recipe.name)
                                    .font(.footnote)
                                    .lineLimit(1)
                                HStack(spacing: 6) {
                                    Image(systemName: "heart.fill").font(.caption2)
                                    Text("\(recipe.favoritedCount)").font(.caption2)
                                    Spacer()
                                    Image(systemName: "clock").font(.caption2)
                                    Text("\(recipe.cookingTime) dk").font(.caption2)
                                }
                                .foregroundStyle(.secondary)
                            }
                            .frame(width: 140)
                        }
                        .buttonStyle(.plain)
                    }
                    if dataManager.ownedRecipes.isEmpty {
                        Text("Henüz tarifin yok.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.thinMaterial.opacity(0.3))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.SurfaceBorder, lineWidth: 1))
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    // MARK: - Top Liked Recipes
    private var topLikedSection: some View {
        let top = dataManager.ownedRecipes.sorted { $0.favoritedCount > $1.favoritedCount }.prefix(3)
        return VStack(alignment: .leading, spacing: 8) {
            Text("EN ÇOK BEĞENİLENLER")
                .font(.caption).foregroundStyle(.secondary).padding(.leading, 4)
            if top.isEmpty {
                Text("Gösterilecek tarif yok.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.thinMaterial.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.SurfaceBorder, lineWidth: 1))
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(top.enumerated()), id: \.offset) { idx, recipe in
                        HStack(spacing: 12) {
                            Text("\(idx+1).")
                                .font(.subheadline).fontWeight(.bold)
                                .frame(width: 24)
                            Text(recipe.name)
                                .font(.subheadline)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            HStack(spacing: 6) {
                                Image(systemName: "heart.fill").font(.caption)
                                Text("\(recipe.favoritedCount)").font(.caption)
                            }
                            .foregroundStyle(.secondary)
                        }
                        .padding(12)
                        .background(.thinMaterial.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.SurfaceBorder, lineWidth: 1))
                    }
                }
            }
        }
    }
    
    // MARK: - Rating Distribution
    private var ratingDistributionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("DEĞERLENDİRME DAĞILIMI")
                .font(.caption).foregroundStyle(.secondary).padding(.leading, 4)
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading) {
                    Text(String(format: "Ort. Puan: %.1f", dataManager.averageRating))
                        .font(.headline)
                    let total = dataManager.currentUser?.totalRatingsReceived ?? 0
                    Text("Toplam Oy: \(total)")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                // Basit 5 çubuklu görselleştirme (placeholder)
                VStack(spacing: 6) {
                    ForEach((1...5).reversed(), id: \.self) { star in
                        HStack {
                            Text("\(star)★").font(.caption).frame(width: 28, alignment: .leading)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.AppPrimary.opacity(0.4))
                                .frame(width: 140 * (star == Int(round(dataManager.averageRating)) ? 0.8 : 0.3), height: 8)
                        }
                    }
                }
            }
            .padding()
            .background(.thinMaterial.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.SurfaceBorder, lineWidth: 1))
        }
    }
    
    // MARK: - Activity (Placeholder)
    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TOPLULUK AKTİVİTESİ")
                .font(.caption).foregroundStyle(.secondary).padding(.leading, 4)
            Text("Yakında: Son favoriler ve yorumlar burada görünecek.")
                .font(.footnote).foregroundStyle(.secondary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.thinMaterial.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.SurfaceBorder, lineWidth: 1))
        }
    }
    
    // MARK: - Categories Distribution
    private var categoryDistributionSection: some View {
        // Basit bir etiket listesi: ownedRecipes içindeki kategorileri say ve en çoktan aza sırala
        let pairs: [(Category, Int)] = {
            var counts: [Category: Int] = [:]
            for r in dataManager.ownedRecipes {
                for c in r.categories.map({ $0.category }) {
                    counts[c, default: 0] += 1
                }
            }
            return counts.sorted { $0.value > $1.value }
        }()
        return VStack(alignment: .leading, spacing: 8) {
            Text("KATEGORİLERE GÖRE DAĞILIM")
                .font(.caption).foregroundStyle(.secondary).padding(.leading, 4)
            if pairs.isEmpty {
                Text("Henüz kategori verisi yok.")
                    .font(.footnote).foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.thinMaterial.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.SurfaceBorder, lineWidth: 1))
            } else {
                // chip-like tags (centered cluster)
                TagWrapLayout(alignment: .center, spacing: 8, lineSpacing: 8) {
                    ForEach(pairs, id: \.0.id) { pair in
                        HStack(spacing: 6) {
                            Text(pair.0.name)
                                .font(.footnote)
                            Text("\(pair.1)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.thinMaterial)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.SurfaceBorder, lineWidth: 1))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
}

// MARK: - Robust wrapping layout for tag chips
private struct TagWrapLayout: Layout {
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

        // Group subviews into lines with their sizes
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

            // Determine start X per alignment
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

/// A reusable view for displaying a single statistic.
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
                .font(.title)
                .fontWeight(.bold)
            Text(title)
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
