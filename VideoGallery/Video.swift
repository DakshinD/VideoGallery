//
//  Video.swift
//  VideoGallery
//
//  Created by Dakshin Devanand on 2/12/25.
//

import SwiftUI
import AVKit
import SwiftData

@Model
class Video: Identifiable {
    
    var id: UUID
    var thumbnailFileName: String
    var videoFileName: String
    var duration: Double
    var date: Date
    
    init(id: UUID, thumbnailFileName: String, videoFileName: String, duration: Double, date: Date) {
        self.id = id
        self.thumbnailFileName = thumbnailFileName
        self.videoFileName = videoFileName
        self.duration = duration
        self.date = date
    }
    
    // Recreate full path on demand due to changing documentsDirectory path
    var thumbnailURL: URL {
        URL.documentsDirectory.appendingPathComponent(thumbnailFileName)
    }
    
    var videoURL: URL {
        URL.documentsDirectory.appendingPathComponent(videoFileName)
    }
}


struct VideoItem: View {
    
    var thumbnailFileName: String
    var duration: Double
    var size: CGFloat = 200
    var fontSize: CGFloat = 12
    
    // Recreate full path on demand due to changing documentsDirectory path
    var thumbnailURL: URL {
        URL.documentsDirectory.appendingPathComponent(thumbnailFileName)
    }
    
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            
            // Thumbnail
            AsyncImage(url: thumbnailURL) { res in
                res.image?
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
            .frame(width: size, height: size)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .shadow(radius: 2)
            
            // Duration text on bottom right
            Text("\(formatDuration(duration))")
                .font(.system(size: fontSize, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .padding(5)
                
            
        }
        
    }
    
    func formatDuration(_ durationInSeconds: Double) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = [.pad] // Ensures double digits for seconds (e.g., 0:09)
        formatter.unitsStyle = .positional        // Removes labels, keeps it like 1:34
        
        return formatter.string(from: durationInSeconds) ?? "0:00"
    }

}

//
//#Preview {
//    Video()
//}
