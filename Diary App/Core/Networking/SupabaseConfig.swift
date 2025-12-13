import Foundation

enum SupabaseConfig {
    static var projectURL: URL {
        guard let string = SupabasePlist.value(forKey: "SUPABASE_URL") as? String,
              let url = URL(string: string)
        else {
            fatalError("Missing SUPABASE_URL in Supabase.plist (create Diary App/Supabase.plist from Diary App/Supabase.plist.example).")
        }
        return url
    }

    static var publishableKey: String {
        guard let key = SupabasePlist.value(forKey: "SUPABASE_PUBLISHABLE_KEY") as? String,
              !key.isEmpty
        else {
            fatalError("Missing SUPABASE_PUBLISHABLE_KEY in Supabase.plist (create Diary App/Supabase.plist from Diary App/Supabase.plist.example).")
        }
        return key
    }
}

private enum SupabasePlist {
    static func value(forKey key: String) -> Any? {
        guard let url = Bundle.main.url(forResource: "Supabase", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any]
        else {
            return nil
        }
        return plist[key]
    }
}
