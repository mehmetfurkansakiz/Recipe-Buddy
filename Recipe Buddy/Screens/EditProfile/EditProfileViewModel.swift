import SwiftUI
import PhotosUI

@MainActor
class EditProfileViewModel: ObservableObject {
    @Published var isSaving = false
    @Published var errorMessage: String? = nil

    // Form Alanları
    @Published var fullName: String = ""
    @Published var city: String = ""
    @Published var showCity: Bool = false
    @Published var bio: String = ""
    // Doğum Tarihi (Yaş yerine)
    @Published var birthDate: Date? = nil
    @Published var showBirthDate: Bool = false
    @Published var isProfessionEnabled: Bool = false
    @Published var professionText: String = ""

    // Date constraints for UI
    let earliestBirthDate: Date = Calendar.current.date(byAdding: .year, value: -120, to: Date()) ?? Date(timeIntervalSince1970: 0)
    let latestBirthDate: Date = Date()
    
    // Stored avatar path (if any)
    private var currentAvatarPath: String? = nil

    // Image state
    @Published var selectedImageData: Data? = nil
    @Published var selectedImagePreview: UIImage? = nil
    @Published var wantsToRemoveAvatar: Bool = false

    // Legacy PhotosPicker flow (kept for compatibility if needed)
    @Published var photoItem: PhotosPickerItem? = nil {
        didSet {
            guard let item = photoItem else { return }
            Task { await loadImage(from: item) }
        }
    }

    func loadInitial(from user: User?) {
        fullName = user?.fullName ?? ""
        city = user?.city ?? ""
        showCity = user?.showCity ?? false
        bio = user?.bio ?? ""
        birthDate = user?.birthDate
        showBirthDate = user?.showBirthDate ?? false
        let loadedProfession = user?.profession ?? ""
        self.professionText = loadedProfession
        self.isProfessionEnabled = user?.showProfession ?? !loadedProfession.isEmpty
        self.currentAvatarPath = user?.avatarUrl
        self.selectedImageData = nil
        self.wantsToRemoveAvatar = false
    }

    private func loadImage(from item: PhotosPickerItem) async {
        do {
            if let data = try await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                setImageFromPicker(image)
            }
        } catch {
            print("❌ Failed to load image: \(error.localizedDescription)")
        }
    }

    // Called by ImagePicker (cropped image)
    func setImageFromPicker(_ image: UIImage?) {
        guard let image else { return }
        self.wantsToRemoveAvatar = false
        // Resize to max 720 and compress around ~0.1 MB similar to ImageUploaderService
        let resized = resizeImageMaintainingAspect(image: image, maxLength: 720)
        if let compressed = resized.compressedData(maxSizeInMB: 0.1) {
            self.selectedImageData = compressed
        } else if let fallback = image.jpegData(compressionQuality: 0.7) {
            self.selectedImageData = fallback
        }
    }

    func removeAvatarSelection() {
        self.selectedImageData = nil
        self.selectedImagePreview = nil
        self.wantsToRemoveAvatar = true
    }

    func save(dataManager: DataManager) async -> Bool {
        isSaving = true
        defer { isSaving = false }

        let newImageData = selectedImageData
        let wantsRemoval = wantsToRemoveAvatar
        let oldPath = currentAvatarPath

        // NSFW check for avatar (if a new image is selected and not removing)
        if let data = newImageData, let uiImage = UIImage(data: data), !wantsRemoval {
            let decision = await NSFWModerationService.shared.check(image: uiImage)
            if case .rejected = decision {
                print("❌ NSFW detected for avatar.")
                self.errorMessage = "Uygunsuz içerik tespit edildi. Lütfen farklı bir görsel seçin."
                return false
            }
        }

        let professionToSave = isProfessionEnabled ? professionText.trimmingCharacters(in: .whitespacesAndNewlines) : nil

        if wantsRemoval, let oldPath, !oldPath.isEmpty {
            print("🗑️ Eski görsel siliniyor: \(oldPath)")
            try? await ImageUploaderService.shared.deleteImage(for: oldPath)
            self.currentAvatarPath = nil
        }
        else if newImageData != nil, let oldPath, !oldPath.isEmpty {
            print("🗑️ Eski görsel (değişim) siliniyor: \(oldPath)")
            try? await ImageUploaderService.shared.deleteImage(for: oldPath)
        }

        let didSave = await dataManager.updateProfileWithAvatarControl(
            fullName: fullName.trimmingCharacters(in: .whitespacesAndNewlines),
            city: city.trimmingCharacters(in: .whitespacesAndNewlines),
            showCity: showCity,
            bio: bio.trimmingCharacters(in: .whitespacesAndNewlines),
            birthDate: showBirthDate ? birthDate : nil,
            showBirthDate: showBirthDate,
            profession: professionToSave,
            showProfession: isProfessionEnabled,
            avatarImageData: newImageData,
            removeAvatar: wantsRemoval
        )
        if didSave {
            return true
        }

        self.errorMessage = "Profil güncellenemedi. Lütfen tekrar deneyin."
        return false
    }

    // MARK: - Image Helpers
    private func resizeImageMaintainingAspect(image: UIImage, maxLength: CGFloat) -> UIImage {
        let width = image.size.width
        let height = image.size.height
        let scale = (width > height) ? maxLength / width : maxLength / height
        if scale >= 1 { return image }
        let newSize = CGSize(width: width * scale, height: height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

