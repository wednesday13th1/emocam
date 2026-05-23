//
//  ContentView.swift
//  emocam
//
//  Created by 井上　希稟 on 2026/05/22.
//

import SwiftUI
import PhotosUI

struct ContentView: View {
    //    setting up variables for selected image
    @State var frameWidth: CGFloat = 300
    @State var frameHeight: CGFloat = 400
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero /*alter size of image*/
    @State var selectedItem: PhotosPickerItem?
    @State var selectedImage: Image? = nil
    @State private var frameScale: CGFloat = 1.0
    @State private var lastFrameScale: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: 25) {
            imageWithFrame
        }
        .padding(.horizontal)
        .onChange(of: selectedItem, initial: true) {
            loadImage()
        }
    }
    
    //    setting up frame
    var imageWithFrame: some View {
            VStack {
                ZStack {
                    Rectangle()
                        .fill(.white)
                        .frame(width: 350 * frameScale, height: 520 * frameScale)
                        .shadow(radius: 10)
                    
                    Rectangle()
                        .fill(.black)
                        .frame(width: frameWidth, height: frameHeight)
                    
                    if let displayImage = selectedImage {
                        displayImage
                            .resizable()
                            .scaledToFill()
                            .frame(width: frameWidth, height: frameHeight)
                            .scaleEffect(scale)
                            .offset(offset)
                            .clipped()
                            .gesture(
                                SimultaneousGesture(
                                    MagnificationGesture()
                                        .onChanged { value in
                                            scale = lastScale * value
                                        }
                                        .onEnded { _ in
                                            lastScale = scale
                                        },
                                    DragGesture()
                                        .onChanged { value in
                                            offset = CGSize(
                                                width: lastOffset.width + value.translation.width,
                                                height: lastOffset.height + value.translation.height
                                            )
                                        }
                                        .onEnded { _ in
                                            lastOffset = offset
                                        }
                                )
                            )
                    } else {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundStyle(.white)
                            .padding(20)
                            .background(Color.gray.opacity(0.7))
                            .clipShape(.circle)
                    }
                }
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            frameScale = lastFrameScale * value
                        }
                        .onEnded { _ in
                            lastFrameScale = frameScale
                        }
                )
                
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Text("Choose Photo")
                }
            }
        }

        
    private func loadImage() {
        guard let item = selectedItem else { return }
        item.loadTransferable(type: Data.self) {result in
            switch result {
            case .success(let data):
                if let data = data, let uiImage = UIImage(data: data) {
                    selectedImage = Image(uiImage: uiImage)
                } else {
                }
            case.failure(let error):
                print("failed to get Image: \(error.localizedDescription)")
                
            }
        }
    }
}

    #Preview {
        ContentView()
    }

