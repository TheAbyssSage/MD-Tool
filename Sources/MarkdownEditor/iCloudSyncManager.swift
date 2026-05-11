import Foundation
import SwiftUI

enum iCloudSyncManager {
    static var isAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }

    static var iCloudContainerURL: URL? {
        FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents")
    }

    static func saveToiCloud(_ data: Data, filename: String) throws -> URL {
        guard let containerURL = iCloudContainerURL else {
            throw iCloudError.notAvailable
        }

        try FileManager.default.createDirectory(at: containerURL, withIntermediateDirectories: true)
        let fileURL = containerURL.appendingPathComponent(filename)
        try data.write(to: fileURL)
        return fileURL
    }

    static func listiCloudDocuments() -> [URL] {
        guard let containerURL = iCloudContainerURL else { return [] }
        guard let contents = try? FileManager.default.contentsOfDirectory(at: containerURL, includingPropertiesForKeys: nil) else { return [] }
        return contents.filter { $0.pathExtension == "md" }
    }

    static func startMonitoring() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name.NSUbiquityIdentityDidChange,
            object: nil,
            queue: .main
        ) { _ in
            print("iCloud identity changed. Available: \(isAvailable)")
        }
    }
}

enum iCloudError: LocalizedError {
    case notAvailable

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "iCloud Drive is not available. Please sign in to iCloud in System Settings."
        }
    }
}
