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
    
    public static func importFiles(from urls: [URL], toDirectory directory: FileManager.SearchPathDirectory = .documentDirectory, subdirectory: String = "Music") throws {
        let fileManager = FileManager.default
        let baseDirectory = try fileManager.url(for: directory, in: .userDomainMask, appropriateFor: nil, create: true)
        let destinationDirectory = baseDirectory.appendingPathComponent(subdirectory)

        if !fileManager.fileExists(atPath: destinationDirectory.path) {
            try fileManager.createDirectory(at: destinationDirectory, withIntermediateDirectories: true, attributes: nil)
        }

        var importedURLs: [URL] = []

        for url in urls {
            let shouldStopAccessing = url.startAccessingSecurityScopedResource()
            defer { if shouldStopAccessing { url.stopAccessingSecurityScopedResource() } }

            let destinationURL = destinationDirectory.appendingPathComponent(url.lastPathComponent)

            if fileManager.fileExists(atPath: destinationURL.path) {
                print("File already exists: \(destinationURL.path)")
                continue
            }

            do {
                try fileManager.copyItem(at: url, to: destinationURL)
                importedURLs.append(destinationURL)
            } catch {
                print("Failed to copy \(url.lastPathComponent): \(error.localizedDescription)")
            }
        }
    }
}


