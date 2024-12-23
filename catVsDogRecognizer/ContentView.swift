//
//  ContentView.swift
//  catVsDogRecognizer
//
//  Created by topeerz on 23/12/2024.
//

import SwiftUI

// TODO: move this outside of ui
import CoreML
import UIKit
import CoreVideo

extension UIImage {
    func toCVPixelBuffer() -> CVPixelBuffer? {
        let width = Int(self.size.width)
        let height = Int(self.size.height)

        // Create pixel buffer attributes
        let attributes: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]

        // Create the pixel buffer
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                          width,
                                          height,
                                          kCVPixelFormatType_32BGRA,
                                          attributes as CFDictionary,
                                          &pixelBuffer)

        guard status == noErr, let buffer = pixelBuffer else {
            return nil
        }

        // Lock the pixel buffer
        CVPixelBufferLockBaseAddress(buffer, [])

        // Create a context to draw the image
        let context = CGContext(data: CVPixelBufferGetBaseAddress(buffer),
                                width: width,
                                height: height,
                                bitsPerComponent: 8,
                                bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                                space: CGColorSpaceCreateDeviceRGB(),
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)

        // Draw the image into the context
        context?.draw(self.cgImage!, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Unlock the pixel buffer
        CVPixelBufferUnlockBaseAddress(buffer, [])

        return buffer
    }
}

struct ContentView: View {

    @State var isCat = false

    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            Image("cat.1")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 300, height: 300)
            Text(isCat ? "Cat" : "Dog")

        }
        .padding()
        .onAppear {
            classifyImage()
        }
    }

    private func classifyImage() {
        // TODO: get rid of !
        let imageToClassify = UIImage(named: "cat.1")!.toCVPixelBuffer()! // Load the image
        let animalRecognizer = try? animalRecognizer()
        
        let result = try? animalRecognizer?.prediction(image: imageToClassify)
        DispatchQueue.main.async {
            self.isCat = result!.target == "cat"
        }
    }
}

#Preview {
    ContentView()
}
