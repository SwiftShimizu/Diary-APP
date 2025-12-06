import Foundation

struct EntryEditorState {
    var title: String = ""
    var body: String = ""
    var diaryDate: Date = .now
    var authorName: String = "You"
    var authorID: String = "you"
    var authorColorHex: String = "#FF6B6B"
    var errorMessage: String?
    var isSaving: Bool = false
}
