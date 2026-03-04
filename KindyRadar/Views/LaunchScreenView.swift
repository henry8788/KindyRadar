import SwiftUI

struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            Image("launch")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        }
    }
}
