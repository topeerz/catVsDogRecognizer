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
import Vision

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

struct ContentView: View {

    @State var isCat = false
    @State private var imageURL: String =
    /// test strings
//        "https://images.pexels.com/photos/257540/pexels-photo-257540.jpeg"
        "https://upload.wikimedia.org/wikipedia/commons/c/c4/Cat-bg.jpg"
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

    private func classifyImageViaVision() {
        // TODO: get rid of !
        guard let loadedImage else {
            return
        }

        let defaultConfig = MLModelConfiguration()
        let animalRecognizer = try? animalRecognizer(configuration: defaultConfig)
        let visionModel = try? VNCoreMLModel(for: animalRecognizer!.model)

        let imageToClassify = UIImage(named: "dog.1")!

        // VNCoreMLRequest works only on actual device ...
        let imageClassificationRequest = VNCoreMLRequest(model: visionModel!, completionHandler: { request, error in
            guard let results = request.results as? [VNClassificationObservation] else {
                return
            }
            guard let firstResult = results.first else {
                return
            }
            print(firstResult.identifier)
        })

        let cgImage = imageToClassify.cgImage!
        let orientation = CGImagePropertyOrientation.up
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation)
        try! requestHandler.perform([imageClassificationRequest])
    }

    private func classifyImageDirect() {
        // TODO: get rid of !
        guard let loadedImage else {
            return
        }

        let animalRecognizer = try? animalRecognizer()
        let imageToClassify = loadedImage
        let input = try! animalRecognizerInput.init(imageWith: imageToClassify.cgImage!)
        let result = try? animalRecognizer?.prediction(input: input)

        print("\(result?.target)")
        DispatchQueue.main.async {
            self.isCat = result!.target == "cat"
        }
    }

    private func classifyImage() {
//        classifyImageViaVision()
        classifyImageDirect()
    }
}

#Preview {
    ContentView()
}
