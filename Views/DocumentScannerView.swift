//
//  DocumentScannerView.swift
//  CareCircle
//
//  VisionKit document scanner wrapped for SwiftUI.
//

import SwiftUI
import VisionKit

struct DocumentScannerView: UIViewControllerRepresentable {
    let onScan: (Data, Int) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ controller: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan, dismiss: dismiss)
    }

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onScan: (Data, Int) -> Void
        let dismiss: DismissAction

        init(onScan: @escaping (Data, Int) -> Void, dismiss: DismissAction) {
            self.onScan = onScan
            self.dismiss = dismiss
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            // Combine all scanned pages into a single PDF
            let pdfData = NSMutableData()
            UIGraphicsBeginPDFContextToData(pdfData, .zero, nil)

            for i in 0..<scan.pageCount {
                let image = scan.imageOfPage(at: i)
                let pageRect = CGRect(origin: .zero, size: image.size)
                UIGraphicsBeginPDFPageWithInfo(pageRect, nil)
                image.draw(in: pageRect)
            }

            UIGraphicsEndPDFContext()

            onScan(pdfData as Data, scan.pageCount)
            dismiss()
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            dismiss()
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFailWithError error: Error
        ) {
            print("Scan failed: \(error.localizedDescription)")
            dismiss()
        }
    }
}
