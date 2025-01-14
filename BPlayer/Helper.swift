import Foundation
import CryptoKit
import AVFoundation
import SwiftUI
import MobileCoreServices
import MediaPlayer

public struct Helper {
    public static func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    public static func generateFileHash(fileURL: URL) -> String {
        do {
            let fileData = try Data(contentsOf: fileURL)
            let hash = SHA256.hash(data: fileData)
            return hash.compactMap { String(format: "%02x", $0) }.joined()
        } catch {
            print("Error reading file: \(error)")
            return ""
        }
    }
    
    public static func listFilesInDirectory(directoryName: URL) -> [String]{
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: directoryName, includingPropertiesForKeys: nil)
            
            var list:[String] = []
            for fileURL in fileURLs {
                list.append(fileURL.lastPathComponent)
            }
            return list
        } catch {
            print("Error reading contents of directory: \(error)")
            return []
        }
    }
    
    public static func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error.localizedDescription)")
        }
    }
    
    //TODO: replace deprecation
    public static func fetchAlbumArtwork(from url: URL) -> UIImage? {
        let asset = AVAsset(url: url)
        let metadata = asset.commonMetadata
        var art:UIImage? = nil
        if let artworkItem = metadata.first(where: { $0.commonKey == .commonKeyArtwork }),
        let artworkData = artworkItem.dataValue,
        let image = UIImage(data: artworkData) {
            art = image
        }
        return art
    }
    
    public static func textSize(for text: String, font: Font) -> CGSize {
            let label = UILabel()
            label.text = text
            label.font = UIFont.preferredFont(forTextStyle: .body)
            label.sizeToFit()
            return label.frame.size
    }
}


