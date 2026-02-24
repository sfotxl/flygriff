import Foundation

enum SupabaseConfig {
    static var url: String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
              !value.isEmpty else {
            fatalError("Missing SUPABASE_URL in Info.plist")
        }
        return value
    }

    static var anonKey: String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
              !value.isEmpty else {
            fatalError("Missing SUPABASE_ANON_KEY in Info.plist")
        }
        return value
    }
}