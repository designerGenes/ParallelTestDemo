import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Parallel Test Demo")
                .font(.largeTitle)
                .accessibilityIdentifier("titleLabel")

            Text("Hello from Playground!")
                .accessibilityIdentifier("greetingLabel")

            Button("Tap Me") {
                // no-op for demo
            }
            .accessibilityIdentifier("tapButton")

            Toggle("Enable Feature", isOn: .constant(true))
                .accessibilityIdentifier("featureToggle")
                .padding(.horizontal, 40)

            TextField("Enter text", text: .constant(""))
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("inputField")
                .padding(.horizontal, 40)
        }
        .padding()
    }
}
