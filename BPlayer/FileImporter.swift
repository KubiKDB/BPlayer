import SwiftUI
import UniformTypeIdentifiers

///Allows user to load their files into internal storage
struct FilePicker: UIViewControllerRepresentable {
    var completion: ([URL]) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.mp3], asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: FilePicker

        init(_ parent: FilePicker) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            let mp3Files = urls.filter { $0.pathExtension.lowercased() == "mp3" }  
            parent.completion(mp3Files)
        }
    }
}
