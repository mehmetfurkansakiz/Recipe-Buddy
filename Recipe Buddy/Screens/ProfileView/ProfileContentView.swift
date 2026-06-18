import SwiftUI
import NukeUI

struct ProfileContentView: View {
    enum Mode {
        case currentUser
        case publicUser
    }

    let mode: Mode
    let user: User
    let recipes: [Recipe]
    let totalFavoritesReceived: Int
    let averageRating: Double
    let categoryDistribution: [CategoryDistributionItem]
    @Binding var navigationPath: NavigationPath
    let onEditProfile: (() -> Void)?
    let onSeeAllRecipes: (() -> Void)?
    let forceHidePersonalDetails: Bool

    var body: some View {
        VStack(spacing: 32) {
            profileHeader(user: user)
            statsSection

            VStack(alignment: .leading, spacing: 24) {
                aboutSection
                recentRecipesSection
                topLikedSection
                ratingDistributionSection
                activitySection
                categoryDistributionSection
            }
            .padding(.bottom, 48)

            Spacer(minLength: 40)
        }
        .padding()
    }

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

            if mode == .currentUser, let onEditProfile {
                Button(action: onEditProfile) {
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
        }
        .frame(maxWidth: .infinity)
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("İSTATİSTİKLER")
                .font(.caption).foregroundStyle(.secondary).padding(.leading, 4)

            HStack(spacing: 12) {
                ProfileStatView(count: recipes.count, title: mode == .currentUser ? "Tariflerim" : "Tarifler")
                ProfileStatView(count: totalFavoritesReceived, title: "Alınan Favori")
                ProfileStatView(value: String(format: "%.1f", averageRating), title: "Ort. Puan")
            }
        }
    }

    private var aboutSection: some View {
        let hidePersonal = forceHidePersonalDetails
        let bioText = hidePersonal ? "" : (user.bio?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")
        let hasProfession = !hidePersonal && (user.showProfession ?? false) && !(user.profession?.isEmpty ?? true)
        let hasCity = !hidePersonal && (user.showCity ?? false) && !(user.city?.isEmpty ?? true)
        let hasBirthDate = !hidePersonal && (user.showBirthDate ?? false) && user.birthDate != nil
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
                    if (user.showProfession ?? false), let profession = user.profession, !profession.isEmpty {
                        Label(profession, systemImage: "briefcase")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    if (user.showCity ?? false), let city = user.city, !city.isEmpty {
                        Label(city, systemImage: "mappin.and.ellipse")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    if (user.showBirthDate ?? false), let date = user.birthDate {
                        let age = Calendar.current.dateComponents([.year], from: date, to: .now).year ?? 0
                        Label(LocalizedText.age(age), systemImage: "calendar")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                if isAboutEmpty {
                    Text(forceHidePersonalDetails ? "Bu hesapta kişisel profil bilgileri gizlenmiştir." : "Henüz hakkımda bilgisi eklenmemiş.")
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

    private var recentRecipesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(LocalizedStringKey(mode == .currentUser ? "SON TARİFLERİM" : "SON TARİFLER"))
                    .font(.caption).foregroundStyle(.secondary).padding(.leading, 4)
                Spacer()
                if let onSeeAllRecipes {
                    Button("Tümünü Gör") { onSeeAllRecipes() }
                        .font(.footnote)
                        .tint(.AppPrimary)
                }
            }

            if recipes.isEmpty {
                Text(LocalizedStringKey(mode == .currentUser ? "Henüz tarifin yok." : "Henüz tarif yok."))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.thinMaterial.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.SurfaceBorder, lineWidth: 1))
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(recipes.prefix(6))) { recipe in
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
                                        Text(LocalizedText.minutesShort(recipe.cookingTime)).font(.caption2)
                                    }
                                    .foregroundStyle(.secondary)
                                }
                                .frame(width: 140)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private var topLikedSection: some View {
        let top = recipes.sorted { $0.favoritedCount > $1.favoritedCount }.prefix(3)
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

    private var ratingDistributionSection: some View {
        let total = user.totalRatingsReceived ?? 0
        return VStack(alignment: .leading, spacing: 8) {
            Text("DEĞERLENDİRME DAĞILIMI")
                .font(.caption).foregroundStyle(.secondary).padding(.leading, 4)
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading) {
                    Text(String(format: "Ort. Puan: %.1f", averageRating))
                        .font(.headline)
                    Text("Toplam Oy: \(total)")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                VStack(spacing: 6) {
                    ForEach((1...5).reversed(), id: \.self) { star in
                        HStack {
                            Text("\(star)★").font(.caption).frame(width: 28, alignment: .leading)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.AppPrimary.opacity(0.4))
                                .frame(width: 140 * (star == Int(round(averageRating)) ? 0.8 : 0.3), height: 8)
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

    private var categoryDistributionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("KATEGORİLERE GÖRE DAĞILIM")
                .font(.caption).foregroundStyle(.secondary).padding(.leading, 4)
            if categoryDistribution.isEmpty {
                Text("Henüz kategori verisi yok.")
                    .font(.footnote).foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.thinMaterial.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.SurfaceBorder, lineWidth: 1))
            } else {
                TagWrapLayout(alignment: .center, spacing: 8, lineSpacing: 8) {
                    ForEach(categoryDistribution) { item in
                        HStack(spacing: 6) {
                            Text(item.category.name)
                                .font(.footnote)
                            Text("\(item.count)")
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
