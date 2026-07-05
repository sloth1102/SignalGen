import SwiftUI
import Combine

class AppSettings: ObservableObject {
    @Published var showAdvancedUnits: Bool = false
    @Published var showGlow: Bool = false
    @Published var showPiLabels: Bool = false
    @Published var showPhaseShift: Bool = false
}
