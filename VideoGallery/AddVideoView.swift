//
//  AddVideoView.swift
//  VideoGallery
//
//  Created by Dakshin Devanand on 2/12/25.
//

import SwiftUI
import PhotosUI

enum VideoState {
    case unkown
    case loading
    case loaded
    case failed
}

struct AddVideoView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.presentationMode) var presentationMode
    
    // User selections
    @State private var date: Date = Date()
    @State private var selectedVideo: PhotosPickerItem?
    
    // Video properties
    @State private var videoURL: URL? = nil
    @State private var videoFileName: String? = nil
    @State private var videoDuration: Double? = 0.0
    
    @State private var thumbnailURL: URL? = nil
    @State private var thumbnailFileName: String? = nil
    
    @State private var videoState: VideoState = .unkown
    

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Video")) {
                    PhotosPicker("Select Video", selection: $selectedVideo, matching: .videos)
                        .onChange(of: selectedVideo) { _, _ in
                            if let selectedVideo {
                                Task {
                                    await loadSelectedVideo(from: selectedVideo)
                                }
                            }
                        }
                    
                    switch videoState {
                    case .unkown:
                        EmptyView()
                    case .loading:
                        ProgressView()
                    case .loaded:
                        VideoItem(thumbnailFileName: thumbnailFileName!, duration: videoDuration ?? 0.0, size: 100)
                    case .failed:
                        Text("Import failed")
                    }
                }

                Section(header: Text("Date")) {
                    DatePicker("Select Date", selection: $date, displayedComponents: .date)
                }

                Button("Save Video") {
                    saveVideo()
                }
                .disabled(videoURL == nil || thumbnailURL == nil)
            }
            .navigationTitle("Add Video")
        }
    }
    
    private func saveVideo() {
        // Logic to save video
        guard let videoFileName = videoFileName,
              let thumbnailFileName = thumbnailFileName,
              let videoDuration = videoDuration else { return }

        let newVideo = Video(
            id: UUID(),
            thumbnailFileName: thumbnailFileName,
            videoFileName: videoFileName,
            duration: videoDuration,
            date: date
        )

        modelContext.insert(newVideo) // Insert into SwiftData

        do {
            try modelContext.save() // Save changes
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Failed to save video: \(error)")
        }
        presentationMode.wrappedValue.dismiss()
    }
    
    private func loadSelectedVideo(from item: PhotosPickerItem) async {
        videoState = .loading

    // Try to download the item
      if let data = try? await item.loadTransferable(type: Data.self),
         let fileExtension = item.supportedContentTypes.first?.preferredFilenameExtension {
          
          // Now that we have the data, we need to save it locally
          let videoName = UUID().uuidString + ".\(fileExtension)"
          
          if let fileURL = saveDataToDocumentsDir(data, with: videoName) {
              // Success! Lets save our URL and video fileName
              videoURL = fileURL
              videoFileName = videoName
              
              // Let's generate our thumbnail while we're here!
              let result = await generateThumbnailURL(videoURL: fileURL)
              guard let thumbnailURL = result.0, let thumbnailName = result.1 else {
                  print("Failed to generate thumbnail from video: \(fileURL)")
                  return
              }
              
              self.thumbnailURL = thumbnailURL
              self.thumbnailFileName = thumbnailName
              
              // Done loading
              videoState = .loaded
          } else {
              print("Failed to save data item to directory.")
              videoState = .failed
          }
      } else {
          print("Failed to load media item as data")
          videoState = .failed
      }
    }

    private func saveDataToDocumentsDir(_ data: Data, with fileName: String) -> URL? {
        // We get the URL for the document directory
        let documentsURL = URL.documentsDirectory
        let fileURL = documentsURL.appendingPathComponent(fileName)

        // Now try saving our data to the fileURL
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Error saving file \(error)")
            return nil
        }
    }
     

    private func generateThumbnailURL(videoURL: URL) async -> (URL?, String?) {
        var finalURL: URL? = nil
        let fileName = UUID().uuidString + ".jpg"
        
        // Create a generator based on a video asset
        let asset = AVURLAsset(url: videoURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true // For rotation
        videoDuration = try? await asset.load(.duration).seconds // Get duration for fun?
        
        let time = CMTimeMakeWithSeconds(0.0, preferredTimescale: 500)
        
        do {
            // CGImage --> UIImage --> Data
            let cgImage = try await generateCGImageAsync(generator: generator, for: time)
            let uiImage = UIImage(cgImage: cgImage)
            
            // to Data
            if let imageData = uiImage.jpegData(compressionQuality: 0.8) {
                
                
                // Save our thumbnail
                if let savedURL = saveDataToDocumentsDir(imageData, with: fileName) {
                    print("Thumbnail saved at \(savedURL)")
                    finalURL = savedURL
                } else {
                    print("Failed to save thumbnail to directory.")
                }
            } else {
                print("Failed to convert UIImage to Data.")
            }
        } catch {
            print("Failed to generate thumbnail: \(error.localizedDescription)")
        }

        return (finalURL, fileName)
    }
    
    /* Wrapper around generateCGImageAsync
     * This converts the callback-based API into async/await using a continuation.
     * The continuation resumes execution when the image generation completes,
     * either with a CGImage or an error.
     */
    private func generateCGImageAsync(generator: AVAssetImageGenerator, for time: CMTime) async throws -> CGImage {
        try await withCheckedThrowingContinuation { continuation in
            generator.generateCGImageAsynchronously(for: time) { cgImage, _, error in
                if let error = error {
                    continuation.resume(throwing: error) // Resume with error
                } else if let cgImage = cgImage {
                    continuation.resume(returning: cgImage) // Resume with the image
                } else {
                    continuation.resume(throwing: NSError(domain: "ThumbnailError", code: -1, userInfo: nil))
                }
            }
        }
    }
    
}

#Preview {
    AddVideoView()
}
