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
    @State private var text:String = ""
    @State var selectedItem: PhotosPickerItem?
    @State var selectedImage: Image? = nil
    
    var body: some View {
        VStack {
            Spacer()
            imageWithFrame
            Spacer()
            TextField("fill in the text", text: $text)
                .padding()
                .background(Color.gray.opacity(0.1))
                .clipShape(.rect(.cornerRadius: 10))
                .padding(.bottom, 8)
                
        }
        .padding(.horizontal)
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
                            .scaledToFill()
                            .frame(width: 300, height: 400)
                            .clipped()
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
