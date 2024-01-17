//
//  AVSource.swift
//  MediaSlideshow
//
//  Created by Peter Meyers on 1/5/21.
//

import AVFoundation
import AVKit
import Foundation

public class AVSource: NSObject, MediaSource {
    public enum Playback: Equatable {
        case play // will be muted when playback controls are hidden
        case paused
    }
    private let onAppear: Playback
    private let asset: AVAsset
    private lazy var item = AVPlayerItem(asset: asset)
    private lazy var player = AVPlayer(playerItem: item)

    public init(asset: AVAsset, onAppear: Playback) {
        self.asset = asset
        self.onAppear = onAppear
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemDidPlayToEndTime(notification:)),
            name: .AVPlayerItemDidPlayToEndTime,
            object: item)
    }

    public convenience init(url: URL, onAppear: Playback) {
        self.init(asset: AVAsset(url: url), onAppear: onAppear)
    }

    public func slide(in slideshow: MediaSlideshow) -> MediaSlideshowSlide {
        let playerController = AVPlayerViewController()
        playerController.player = player
        playerController.showsPlaybackControls = onAppear == .paused || slideshow.zoomEnabled
        var playView: AVSlidePlayingOverlayView?
        var pauseView: AVSlidePausedOverlayView?
        if !playerController.showsPlaybackControls {
            playView = AVSlidePlayingOverlayView()
            pauseView = AVSlidePausedOverlayView()
        }
        let overlay = StandardAVSlideOverlayView(
            item: item,
            player: player,
            playView: playView,
            pauseView: pauseView,
            activityView: slideshow.activityIndicator?.create())
        playerController.contentOverlayView?.embed(overlay)
        let slide = AVPlayerSlide(playerController: playerController, mediaContentMode: slideshow.contentScaleMode)
        slide.delegate = self
        return slide
    }

    @objc public func playerItemDidPlayToEndTime(notification: Notification) {
        player.seek(to: .zero)
    }
}

extension AVSource: AVPlayerSlideDelegate {
    public func slideDidAppear(_ slide: AVPlayerSlide) {
        switch onAppear {
        case .play:
            player.play()
            player.isMuted = !slide.playerController.showsPlaybackControls
        case .paused:
            player.pause()
        }
    }

    public func slideDidDisappear(_ slide: AVPlayerSlide) {
        player.pause()
    }

    public func currentThumbnail(_ slide: AVPlayerSlide) -> UIImage? {
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        if let imageRef = try? generator.copyCGImage(at: player.currentTime(), actualTime: nil) {
            return UIImage(cgImage: imageRef)
        }
        return nil
    }
}
