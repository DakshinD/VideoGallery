//
//  VideoPlayer.swift
//  VideoGallery
//
//  Created by Dakshin Devanand on 2/12/25.
//

import SwiftUI
import AVFoundation

struct VideoPlayer: View {
    
    var vid: Video
    private var player: AVPlayer
    private var dateString: String
    
    
    
    init(video: Video) {
        self.vid = video
        self.player = AVPlayer(url: vid.videoURL)
        self.dateString = Self.formatDateForPlayer(vid.date)
    }
    
    
    @State private var isPlaying: Bool = false
    @State private var isDragging: Bool = false
    @State private var isMuted = false
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    
    @State private var previousPlayingState: Bool? = nil

    
    var body: some View {
        ZStack(alignment: .topLeading) {
            
            // Video
            VideoPlayerView(player: player)
                .background(.white)
                .edgesIgnoringSafeArea(.all)
                .onAppear {
                    duration = vid.duration
                    addTimeObserver()
                }
            
            // Date
            HStack {
                
                Text("\(dateString)")
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundStyle(.white)
                    .padding([.top, .leading], 16)
                
                Spacer()
            }
            
            
            // Playback controls
            VStack(spacing: 10) {
                
                Spacer()
                
                // Display the durations if we are dragging the slider
                if isDragging {
                    HStack {
                        // Time Elapsed on left
                        Text(formatTimeElapsed(currentTime))
                            .font(.subheadline)
                            .foregroundStyle(.white)
                        
                        Spacer()
                        
                        Text(formatTimeLeft(duration - currentTime))
                            .font(.subheadline)
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 16)
                    
                }
                
                // Display the play/mute button normally
                if !isDragging {
                    HStack {
                        // Play Button
                        Button(action: {
                            isPlaying.toggle()
                            if isPlaying { player.play() }
                            else { player.pause() }
                        }) {
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .foregroundStyle(.white)
                                .font(.title2)
                                .contentTransition(.symbolEffect(.automatic))
                        }
                        
                        Spacer()
                        
                        // Mute/Unmute button
                        Button(action: {
                            isMuted.toggle()
                            player.isMuted = isMuted
                        }) {
                            Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.3.fill")
                                .foregroundStyle(.white)
                                .font(.title2)
                                .contentTransition(.symbolEffect(.automatic))
                        }
                        
                    }
                    .padding(.horizontal, 16)
                }
                

                Slider(value: $currentTime, in: 0...duration) { editing in
                    isDragging = editing
                    if editing {
                        // When we edit, we want to pause the video
                        // If we were playing, we want to save that, and re-play when we are done
                        previousPlayingState = isPlaying
                        player.pause()
                    } else {
                        // If we were playing before editing, play now
                        if previousPlayingState ?? false {
                            isPlaying = true
                            player.play()
                        } else {
                            // Else, we were paused, so don't play
                            isPlaying = false
                        }
                        
                        previousPlayingState = nil
                        
                    }
                }
                .onChange(of: currentTime) { _, newTime in
                    if isDragging {
                        player.seek(to: CMTime(seconds: currentTime, preferredTimescale: 1000))
                    }
                }
                .tint(.white)
                .padding(.horizontal, 16)
                .padding(.bottom, 15)

            }
            
        }
        
    }
    
    private func addTimeObserver() {
        let interval = CMTime(seconds: 1/100, preferredTimescale: 1000)
        player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
            currentTime = time.seconds
        }
    }
    
    private func formatTimeLeft(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func formatTimeElapsed(_ time: Double) -> String {
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time - floor(time)) * 100)
        
        return String(format: "%02d:%02d:%02d", minutes, seconds, milliseconds)
    }
    
    static func formatDateForPlayer(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium  // Example: Jan 1, 2024
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
    


