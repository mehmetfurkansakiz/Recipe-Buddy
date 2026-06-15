import Foundation
import SwiftUI

@MainActor
class ImageUploaderService {
    private struct ImageStorageRequest: Encodable {
        let action: String
        let folder: String?
        let imageBase64: String?
        let key: String?
        let contentType: String?
    }

    private struct ImageStorageResponse: Decodable {
        let key: String?
        let ok: Bool?
    }

    enum UploadFolder {
        case avatar
        case recipes
        case custom(String)
        
        var pathComponent: String {
            switch self {
            case .avatar: return "public/avatar"
            case .recipes: return "public/recipes"
            case .custom(let p): return p
            }
        }
    }
    
    static let shared = ImageUploaderService()
    
    private let cloudFrontURL = Secrets.cloudfrontDomain
    
    private init() {}
    
    // MARK: - Upload
    /// Uploads image data to the S3 bucket and returns the unique key (path).
    func uploadImage(imageData: Data, maxLength: CGFloat = 720, folder: UploadFolder = .recipes) async throws -> String {
        guard let image = UIImage(data: imageData) else {
            throw NSError(domain: "ImageUploader", code: -1, userInfo: [NSLocalizedDescriptionKey: "Image decoding failed"])
        }
        
        let resized = resizeImageMaintainingAspect(image: image, maxLength: maxLength)
                
        guard let finalData = resized.compressedData(maxSizeInMB: 0.1) else {
            throw NSError(domain: "ImageUploader", code: -2, userInfo: [NSLocalizedDescriptionKey: "JPEG compression failed"])
        }
        
        let response = try await callImageStorageFunction(
            ImageStorageRequest(
                action: "upload",
                folder: folder.pathComponent,
                imageBase64: finalData.base64EncodedString(),
                key: nil,
                contentType: "image/jpeg"
            )
        )

        guard let key = response.key else {
            throw NSError(domain: "ImageUploader", code: -3, userInfo: [NSLocalizedDescriptionKey: "Image upload response missing key"])
        }

        print("✅ Successfully uploaded image with key: \(key)")
        return key
    }
    
    /// Convenience: Uploads an avatar image to the avatar folder
    func uploadAvatar(imageData: Data, maxLength: CGFloat = 720) async throws -> String {
        return try await uploadImage(imageData: imageData, maxLength: maxLength, folder: .avatar)
    }

    /// Convenience: Uploads a recipe image to the recipes folder
    func uploadRecipeImage(imageData: Data, maxLength: CGFloat = 720) async throws -> String {
        return try await uploadImage(imageData: imageData, maxLength: maxLength, folder: .recipes)
    }
    
    private func resizeImageMaintainingAspect(image: UIImage, maxLength: CGFloat) -> UIImage {
        let width = image.size.width
        let height = image.size.height
        
        let scale = (width > height) ? maxLength / width : maxLength / height
        if scale >= 1 { return image } // no scaling needed
        
        let newSize = CGSize(width: width * scale, height: height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    // MARK: - Fetch
    func fetchImageURL(for key: String) -> URL? {
        return URL(string: "\(cloudFrontURL)/\(key)")
    }
    
    // MARK: - Delete
    func deleteImage(for key: String) async throws {
        _ = try await callImageStorageFunction(
            ImageStorageRequest(
                action: "delete",
                folder: nil,
                imageBase64: nil,
                key: key,
                contentType: nil
            )
        )
        print("🗑️ Deleted image with key: \(key)")
    }

    private func callImageStorageFunction(_ payload: ImageStorageRequest) async throws -> ImageStorageResponse {
        let session = try await supabase.auth.session
        let endpoint = Secrets.supabaseURL.appendingPathComponent("functions/v1/image-storage")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(Secrets.supabaseKey, forHTTPHeaderField: "apikey")
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Image storage request failed"
            throw NSError(domain: "ImageUploader", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
        }

        return try JSONDecoder().decode(ImageStorageResponse.self, from: data)
    }
}
