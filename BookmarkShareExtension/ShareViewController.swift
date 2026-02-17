//
//  ShareViewController.swift
//  BookmarkShareExtension
//
//  Created by Narayanan VK on 16/02/2026.
//

import UIKit
import SwiftUI
import SwiftData
import UniformTypeIdentifiers

class ShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let itemProvider = extensionItem.attachments?.first else {
            close()
            return
        }

        if itemProvider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            itemProvider.loadItem(forTypeIdentifier: UTType.url.identifier) { [weak self] item, _ in
                guard let url = item as? URL else {
                    DispatchQueue.main.async { self?.close() }
                    return
                }
                DispatchQueue.main.async {
                    self?.showShareView(url: url)
                }
            }
        } else if itemProvider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
            itemProvider.loadItem(forTypeIdentifier: UTType.plainText.identifier) { [weak self] item, _ in
                guard let text = item as? String, let url = URL(string: text),
                      let scheme = url.scheme?.lowercased(),
                      (scheme == "http" || scheme == "https") else {
                    DispatchQueue.main.async { self?.close() }
                    return
                }
                DispatchQueue.main.async {
                    self?.showShareView(url: url)
                }
            }
        } else {
            close()
        }
    }

    private func showShareView(url: URL) {
        let container = SharedModelContainer.create()
        let shareView = ShareBookmarkView(url: url, onDismiss: { [weak self] in
            self?.close()
        })
        .modelContainer(container)

        let hostingController = UIHostingController(rootView: shareView)
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        hostingController.didMove(toParent: self)
    }

    private func close() {
        extensionContext?.completeRequest(returningItems: nil)
    }
}
