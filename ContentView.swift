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
    @State var selectedItem: PhotosPickerItem?
    @State var selectedImage: Image? = nil
    
    var body: some View {
        VStack {
            imageWithFrame
        }
        .onChange(of: selectedItem, initial: true) {
            loadImage() //image loading function
        }
    }
    
//    setting up frame
    var imageWithFrame: some View {
        Rectangle()
            .fill(.white)
            .frame(width: 350, height: 520)
            .shadow(radius: 10)
            .overlay {
                ZStack {
                    Rectangle()
                        .frame(width: 300, height: 400)
                    if let displayImage = selectedImage {
                        displayImage
                            .resizable()
                            .scaledToFit()
                            .padding(20)
                    }
                    //                photo icon circle and grey
                    else {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundStyle(.white)
                            .padding(20)
                            .background(Color.gray.opacity(0.7))
                            .clipShape(.circle)
                    }
                }
//                clear photopicker
                PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()){
                    Color.clear
                        .contentShape(.rect)
                }
                    
            }
        }
    }
    private func loadImage() {
    guard let item = selectedItem else { return }
    item.loadTransferable(type: Data.self)
    switch result {
    case.success(let data):
        if let data = data, let uiImage = UIImage(data: data) {
            selectedImage = Image(uiImage: UIImage)
        } else {
        }
    case.failure(let error):
        print("failed to get Image: \(error.localizedDescription)")
    }
}

#Preview {
    ContentView()
}
