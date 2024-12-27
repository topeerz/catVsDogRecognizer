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

struct ContentView: View {

    @State private var label: String = "???"
    private var catURL = "https://cataas.com/cat"
    private var dogURL = "https://dog.ceo/api/breeds/image/random"
    @State private var imageURL: String = ""
    @State private var loadedImage: UIImage?

    var body: some View {
        VStack {
            TextField("Enter image URL", text: $imageURL)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .disabled(true)
                .padding()
            Button(action: {
                Task {
                    imageURL = await randomImageURL()
                    await loadImage()
                    classifyImage()
                }

            }) {
                Text("Load & Detect")
            }

            if ((loadedImage) != nil) {
                Image(uiImage: loadedImage!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 500, height: 500)
            }

            Text(label)
        }
        .padding()
    }

    private func randomImageURL() async -> String {
        let cat = Bool.random()
        if (cat) {
            return catURL
        }

        struct Dog: Codable {
            let message: String
        }        

        // TODO: get rid of !
        let result = try? await URLSession.shared.data(from: URL(string: dogURL)!)

        guard let data = result?.0 else {
            return ""
        }
        let dogURL = try! JSONDecoder().decode(Dog.self, from: data)

        return dogURL.message
    }

    private func loadImage() async {
        loadedImage = nil
        let result = try? await URLSession.shared.data(from: URL(string: self.imageURL)!)
        if let data = result?.0, let image = UIImage(data: data) {
            loadedImage = image;
        }
    }

    private func classifyImageViaVision() {
        guard let loadedImage else {
            return
        }

        let defaultConfig = MLModelConfiguration()
        let animalRecognizer = try? animalRecognizer(configuration: defaultConfig)
        let visionModel = try? VNCoreMLModel(for: animalRecognizer!.model)

        let imageToClassify = loadedImage
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
        guard let cgImageToClassify = loadedImage?.cgImage else {
            return
        }
        guard let input = try? animalRecognizerInput.init(imageWith: cgImageToClassify) else {
            return
        }
        guard let animalRecognizer = try? animalRecognizer() else {
            return
        }
        let result = try? animalRecognizer.prediction(input: input)

        print("\(result?.target)")
        DispatchQueue.main.async {
            label = result!.target
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
