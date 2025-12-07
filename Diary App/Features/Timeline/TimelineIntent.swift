import Foundation

enum TimelineIntent {
    case onAppear
    case reload
    case delete(EntryEntity)
}
