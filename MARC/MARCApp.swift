//
//  MARCApp.swift
//  MARC
//
//  Created by c0gm4n on 11/10/26.
//

import SwiftUI

@main
struct MARCApp: App {
    init() {
        Task.detached(priority: .utility) {
            // A later file request retries preparation if protection is unavailable.
            try? MARCTemporaryFileStore.shared.prepare()
        }
    }

    var body: some Scene {
        WindowGroup {
            MARCLockedRoot()
        }
    }
}
