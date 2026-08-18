import Foundation
import SwiftUI

@MainActor
final class IslandifyAppModel: ObservableObject {
    @Published var previewActivity = PreviewActivity.sample

    init() {}
}
