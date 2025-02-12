//
//  VideoPlayerView.swift
//  VideoGallery
//
//  Created by Dakshin Devanand on 2/12/25.
//

import UIKit
import AVKit
import SwiftUI

struct VideoPlayerView: UIViewControllerRepresentable {
    
    typealias UIViewControllerType = AVPlayerViewController
    
    let player: AVPlayer
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        
    }
    
}
