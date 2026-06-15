import Foundation

enum Secrets {
    private static var keys: [String: Any]? {
        guard let path = Bundle.main.path(forResource: "Keys", ofType: "plist"),
              let xml = FileManager.default.contents(atPath: path) else {
            fatalError("❌ Keys.plist dosyası bulunamadı. Lütfen kontrol edin.")
        }
        return (try? PropertyListSerialization.propertyList(from: xml, options: .mutableContainersAndLeaves, format: nil)) as? [String: Any]
    }

    private static func getValue(forKey key: String) -> String {
        guard let value = keys?[key] as? String else {
            fatalError("❌ \(key) anahtarı Keys.plist dosyasında bulunamadı veya formatı yanlış.")
        }
        return value
    }
    
    // --- Supabase Keys ---
    static let supabaseURL = URL(string: getValue(forKey: "SupabaseURL"))!
    static let supabaseKey = getValue(forKey: "SupabaseKey")
    
    // --- CloudFront Key ---
    static let cloudfrontDomain = getValue(forKey: "CloudFrontDomain")
}
