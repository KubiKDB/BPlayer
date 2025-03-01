import SwiftUI
import UIKit

struct TextInputAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    @Binding var text: String
    let title: String
    let message: String
    let placeholder: String
    let onSubmit: () -> Void

    func body(content: Content) -> some View {
        content
            .onChange(of: isPresented) { newValue in
                if newValue {
                    showAlert()
                }
            }
    }

    private func showAlert() {
        guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else { return }

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        alert.addTextField { textField in
            textField.placeholder = placeholder
            textField.text = text
        }

        let submitAction = UIAlertAction(title: "OK", style: .default) { _ in
            if let inputText = alert.textFields?.first?.text {
                text = inputText
            }
            isPresented = false
            onSubmit()
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            isPresented = false
        }

        alert.addAction(submitAction)
        alert.addAction(cancelAction)

        DispatchQueue.main.async {
            rootViewController.present(alert, animated: true)
        }
    }
}
extension View {
    func textInputAlert(isPresented: Binding<Bool>, text: Binding<String>, title: String, message: String, placeholder: String, onSubmit: @escaping () -> Void) -> some View {
        self.modifier(TextInputAlertModifier(isPresented: isPresented, text: text, title: title, message: message, placeholder: placeholder, onSubmit: onSubmit))
    }
}

