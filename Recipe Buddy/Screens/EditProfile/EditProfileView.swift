import SwiftUI
import PhotosUI
import NukeUI
import UIKit

struct EditProfileView: View {
    @ObservedObject var viewModel: EditProfileViewModel
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss

    // Image Picker (with editing/cropping)
    @State private var showImagePicker = false
    @State private var showRemoveAvatarAlert = false

    var body: some View {
        ZStack {
            Color.Background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    avatarSection
                    personalInfoSection
                    aboutSection
                    saveSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical)
            }
            .navigationTitle("Profili Düzenle")
            .inlineColoredNavigationBar(titleColor: .AppPrimary, textStyle: .headline, weight: .bold, hidesOnSwipe: true, transparentBackground: true)
            .onAppear { viewModel.loadInitial(from: dataManager.currentUser) }
            .alert("Kaydedildi", isPresented: $viewModel.showSavedAlert) {
                Button("Tamam") { dismiss() }
            } message: {
                Text("Profil bilgilerin güncellendi.")
            }
            .alert("Fotoğrafı kaldır?", isPresented: $showRemoveAvatarAlert) {
                Button("Kaldır", role: .destructive) {
                    viewModel.removeAvatarSelection()
                }
                Button("Vazgeç", role: .cancel) {}
            } message: {
                Text("Profil fotoğrafın kaldırılacak. İşlem Kaydet'e bastığında uygulanır.")
            }

            if viewModel.isSaving {
                Color.black.opacity(0.2).ignoresSafeArea()
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(allowsEditing: true) { image in
                viewModel.setImageFromPicker(image)
            }
            .ignoresSafeArea()
        }
        .toast(message: $viewModel.errorMessage)
    }

    // MARK: - Sections

    private var headerSection: some View {
        HStack {
            Text("Profil Bilgileri")
                .font(.title2).bold()
                .foregroundStyle(.AppPrimary)
            Spacer()
        }
    }

    private var avatarSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PROFİL FOTOĞRAFI")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            HStack(spacing: 16) {
                ZStack {
                    Group {
                        if let data = viewModel.selectedImageData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                        } else if let url = dataManager.currentUser?.avatarPublicURL() {
                            LazyImage(url: url) { state in
                                if let image = state.image {
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } else {
                                    Color.gray.opacity(0.15)
                                }
                            }
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .foregroundStyle(.gray.opacity(0.3))
                        }
                    }
                    .frame(width: 84, height: 84)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.SurfaceBorder, lineWidth: 1))

                    // Dark overlay on preview to make edited image appear slightly dim
                    Circle()
                        .fill(Color.black.opacity(0.12))
                        .frame(width: 84, height: 84)
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Button(action: { showImagePicker = true }) {
                            HStack(spacing: 8) {
                                Image(systemName: "photo.on.rectangle.angled")
                                Text("Fotoğrafı Değiştir")
                                    .fontWeight(.semibold)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                    .truncationMode(.tail)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(.thinMaterial)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.SurfaceBorder, lineWidth: 1))
                        }
                        .tint(.AppPrimary)
                        .layoutPriority(1)

                        Button(role: .destructive, action: { showRemoveAvatarAlert = true }) {
                            Image(systemName: "trash")
                                .font(.body)
                                .padding(10)
                                .background(.thinMaterial)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.SurfaceBorder, lineWidth: 1))
                                .accessibilityLabel("Fotoğrafı Kaldır")
                        }
                        .disabled(!(viewModel.selectedImageData != nil || dataManager.currentUser?.avatarPublicURL() != nil) || viewModel.wantsToRemoveAvatar)
                        .tint(.red)
                    }

                    Text("Fotoğraf seçtikten sonra kırpma ekranı açılır.")
                        .font(.caption)
                        .foregroundStyle(.TextSecondary)

                    if viewModel.wantsToRemoveAvatar {
                        Text("Fotoğraf kaldırılacak. Kaydet'e bastığınızda uygulanır.")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
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

    private var personalInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("KİŞİSEL BİLGİLER")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            VStack(spacing: 12) {
                TextField("Ad Soyad", text: $viewModel.fullName)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .textFieldStyle(CustomTextFieldStyle())

                Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                    GridRow {
                        TextField("Şehir", text: $viewModel.city)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .textFieldStyle(CustomTextFieldStyle())
                            .frame(maxWidth: .infinity)

                        Toggle("Şehri göster", isOn: $viewModel.showCity)
                            .tint(.AppPrimary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .gridColumnAlignment(.trailing)
                    }

                    GridRow {
                        TextField("Mesleğiniz", text: $viewModel.professionText)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .textFieldStyle(CustomTextFieldStyle())
                            .frame(maxWidth: .infinity)

                        Toggle(isOn: $viewModel.isProfessionEnabled) {
                            Text("Meslek bilgisini göster")
                                .lineLimit(2)
                                .minimumScaleFactor(0.2)
                        }
                        .tint(.AppPrimary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .gridColumnAlignment(.trailing)
                    }

                    GridRow {
                        DatePicker(
                            "Doğum Tarihi",
                            selection: Binding(
                                get: { viewModel.birthDate ?? Date() },
                                set: { viewModel.birthDate = $0 }
                            ),
                            in: viewModel.earliestBirthDate...viewModel.latestBirthDate,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Toggle("Yaşı göster", isOn: $viewModel.showBirthDate)
                            .tint(.AppPrimary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .gridColumnAlignment(.trailing)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.SurfaceBorder, lineWidth: 1))
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("HAKKIMDA")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            VStack(alignment: .leading, spacing: 12) {
                TextEditor(text: $viewModel.bio)
                    .frame(minHeight: 120)
                    .overlay(alignment: .topLeading) {
                        if viewModel.bio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text("Kendinden bahset...")
                                .foregroundStyle(.TextSecondary)
                                .padding(12)
                        }
                    }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.SurfaceBorder, lineWidth: 1))
        }
    }

    private var saveSection: some View {
        VStack(spacing: 12) {
            AuthButton(
                title: "Kaydet",
                action: { Task { await viewModel.save(dataManager: dataManager) } },
                isDisabled: viewModel.isSaving,
                isLoading: viewModel.isSaving
            )
        }
    }
}

#Preview {
    NavigationStack {
        EditProfileView(viewModel: EditProfileViewModel())
            .environmentObject(DataManager())
    }
}
