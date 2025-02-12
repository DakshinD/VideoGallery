//
//  ContentView.swift
//  VideoGallery
//
//  Created by Dakshin Devanand on 2/12/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Namespace private var namespace
    
    @Query private var items: [Item]
    
    @State private var isShowingAddView: Bool = false
    
    @Query var videos: [Video]
    var clipSize: CGFloat = 150
    var columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 5), count: 3)
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                GeometryReader { geo in
                    LazyVGrid(columns: columns) {
                        ForEach(videos, id: \.self) { vid in
                            NavigationLink {
                                VideoPlayer(video: vid)
                                    .navigationTransition(.zoom(sourceID: vid.id, in: namespace))
                            } label: {
                                VideoItem(thumbnailFileName: vid.thumbnailFileName, duration: vid.duration, size: (geo.size.width - 50)/3, fontSize: 12)
                                    .matchedTransitionSource(id: vid.id, in: namespace)
                            }
                            
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Gallery")
            .toolbar {
                Button(action: {
                    isShowingAddView.toggle()
                }) {
                    HStack {
                        Image(systemName: "plus")
                            .resizable()
                            .frame(width: 15, height: 15)
                        Text("Add")
                    }
                    .padding(.horizontal, 15)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.3))
                    .clipShape(Capsule())
                    
                }
            }
            .sheet(isPresented: $isShowingAddView) {
                AddVideoView()
            }
            
        }
        
    }
    
    
}

#Preview {
    ContentView()
        .modelContainer(for: Video.self, inMemory: true)
}
