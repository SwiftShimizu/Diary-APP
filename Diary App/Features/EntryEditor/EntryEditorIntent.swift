import Foundation

enum EntryEditorIntent {
    case updateTitle(String)
    case updateBody(String)
    case updateDate(Date)
    case updateAuthorName(String)
    case save
    case clearError
}
