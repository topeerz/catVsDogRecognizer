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

import UIKit
import CoreVideo

extension CVPixelBuffer {
    func toUIImage() -> UIImage? {
        // Lock the base address of the pixel buffer
        CVPixelBufferLockBaseAddress(self, .readOnly)

        defer {
            // Unlock the pixel buffer
            CVPixelBufferUnlockBaseAddress(self, .readOnly)
        }

        // Get the pixel buffer's width and height
        let width = CVPixelBufferGetWidth(self)
        let height = CVPixelBufferGetHeight(self)

        // Create a color space
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        // Create a CGContext
        guard let context = CGContext(data: CVPixelBufferGetBaseAddress(self),
                                      width: width,
                                      height: height,
                                      bitsPerComponent: 8,
                                      bytesPerRow: CVPixelBufferGetBytesPerRow(self),
                                      space: colorSpace,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return nil
        }

        // Create a CGImage from the context
        guard let cgImage = context.makeImage() else {
            return nil
        }

        // Create a UIImage from the CGImage
        return UIImage(cgImage: cgImage)
    }
}

extension UIImage {
    func resized(to targetSize: CGSize) -> UIImage {
        let size = self.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Determine what ratio to use to ensure the image is scaled properly
        let ratio = min(widthRatio, heightRatio)
        
        // Calculate the new size
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        // Create a new graphics context
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: CGRect(origin: .zero, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
}

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
    @State private var imageURL: String = "https://images.pexels.com/photos/257540/pexels-photo-257540.jpeg"
    /// test strings
    /// https://upload.wikimedia.org/wikipedia/commons/c/c4/Cat-bg.jpg
    /// https://images.pexels.com/photos/257540/pexels-photo-257540.jpeg
    /// https://upload.wikimedia.org/wikipedia/commons/4/43/Cute_dog.jpg
    @State private var loadedImage: UIImage?

    var body: some View {
        VStack {
            TextField("Enter image URL", text: $imageURL)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            Button(action: {
                Task {
                    await loadImage()
                    classifyImage()
                }

            }) {
                Text("Load & Detect")
            }

            // TODO: improve the check
            if ((loadedImage) != nil) {
                Image(uiImage: loadedImage!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 300, height: 300)

            } else {
//                Image("dog.1")
//                .resizable()
//                .aspectRatio(contentMode: .fit)
//                .frame(width: 300, height: 300)
//                .onAppear {
//                    classifyImage()
//                }
            }

            Text(isCat ? "Cat" : "Dog")
        }
        .padding()
        .onAppear {
            loadedImage = UIImage(named: "dog.1")
            classifyImage()
        }
    }

    private func loadImage() async {
        loadedImage = nil
        let result = try? await URLSession.shared.data(from: URL(string: self.imageURL)!)
        if let data = result?.0, let image = UIImage(data: data) {
            loadedImage = image;
        }
    }

    private func classifyImage() {
        // TODO: get rid of !
        guard let loadedImage else {
            return
        }

//        let imageToClassify = loadedImage
        let imageToClassify = UIImage(named: "dog.1")!.resized(to: CGSize(width: 360, height: 360))

        let input = try! animalRecognizerInput.init(imageWith: imageToClassify.cgImage!)
        let animalRecognizer = try? animalRecognizer()

        let result = try? animalRecognizer?.prediction(input: input)
        print("\(result?.target)")
        DispatchQueue.main.async {
            self.isCat = result!.target == "cat"
        }
    }
}

#Preview {
    ContentView()
}
