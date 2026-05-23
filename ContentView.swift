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
    @State var frameWidth: CGFloat = 350
    @State var frameHeight: CGFloat = 420
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
                    .fill(.white)
                    .frame(width: frameWidth, height: frameHeight)
                
                if let displayImage = selectedImage {
                    displayImage
                        .resizable()
                        .scaledToFill()
                        .frame(width: frameWidth, height: frameHeight)
                        .scaleEffect(scale)
                        .offset(offset)
                        .clipped()
                } else {
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundStyle(.white)
                        .padding(20)
                        .background(Color.gray.opacity(0.7))
                        .clipShape(.circle)
                }
                
                Circle()
                    .fill(.blue)
                    .frame(width: 25, height: 25)
                    .offset(
                        x: frameWidth / 2,
                        y: frameHeight / 2
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                frameWidth = max(250, frameWidth + value.translation.width)
                                frameHeight = max(350, frameHeight + value.translation.height)
                            }
                    )
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

