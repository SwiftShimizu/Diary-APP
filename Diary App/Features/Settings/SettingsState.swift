struct SettingsState {
    var name: String = ""
    var colorHex: String = "#FF6B6B"
    var availableColors: [String] = []
    var isSaving: Bool = false
    var errorMessage: String?
    var infoMessage: String?
}
