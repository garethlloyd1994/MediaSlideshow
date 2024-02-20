//
//  AVSource.swift
//  MediaSlideshow
//
//  Created by Peter Meyers on 1/5/21.
//

import AVFoundation
import AVKit
import Foundation

public protocol AVSourceDelegate: AnyObject {
    func didStartPlaying(url: String)
    func didCompletePlaying(url: String)
}

public class AVSource: NSObject, MediaSource {
    public enum Playback: Equatable {
        case play // will be muted when playback controls are hidden
        case paused
    }
    private let onAppear: Playback
    private var initialURL: URL?
    private let asset: AVAsset
    private lazy var item = AVPlayerItem(asset: asset)
    private lazy var player = AVPlayer(playerItem: item)
    private var customOverlay: AVCustomOverlay?
    weak var delegate: AVSourceDelegate?
    var isCurrentlyPlaying = false
    var isCompleted = false

    public init(asset: AVAsset, onAppear: Playback, delegate: AVSourceDelegate?) {
        self.asset = asset
        self.onAppear = onAppear
        self.delegate = delegate
        super.init()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerItemDidPlayToEndTime(notification:)),
                                               name: .AVPlayerItemDidPlayToEndTime,
                                               object: item)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    public convenience init(url: URL, onAppear: Playback, delegate: AVSourceDelegate?) {
        self.init(asset: AVAsset(url: url), onAppear: onAppear, delegate: delegate)
        self.initialURL = url
    }
    
    public func slide(in slideshow: MediaSlideshow) -> MediaSlideshowSlide {
        let playerController = AVPlayerViewController()
        playerController.player = player
        playerController.showsPlaybackControls = false
        if slideshow.zoomEnabled {
            addFullScreenOverlay(to: playerController)
        } else {
            addSmallOverlay(to: playerController, slideshow: slideshow)
        }
        let slide = AVPlayerSlide(playerController: playerController, mediaContentMode: slideshow.contentScaleMode)
        slide.delegate = self
        return slide
    }
    
    func addSmallOverlay(to playerController: AVPlayerViewController, slideshow: MediaSlideshow) {
        var playView: AVSlidePlayingOverlayView?
        var pauseView: AVSlidePausedOverlayView?
        if !playerController.showsPlaybackControls {
            playView = AVSlidePlayingOverlayView()
            pauseView = AVSlidePausedOverlayView()
        }
        let overlay = StandardAVSlideOverlayView(item: item,
                                                 player: player,
                                                 playView: playView,
                                                 pauseView: pauseView,
                                                 activityView: slideshow.activityIndicator?.create())
        playerController.contentOverlayView?.embed(overlay)
    }
    
    func addFullScreenOverlay(to playerController: AVPlayerViewController) {
        let customOverlay = AVCustomOverlay(item: item, player: player)
        customOverlay.delegate = self
        self.customOverlay = customOverlay
        playerController.contentOverlayView?.embed(customOverlay)
    }

    @objc public func playerItemDidPlayToEndTime(notification: Notification) {
        player.seek(to: .zero)
        player.play()
        self.customOverlay?.playPauseStatus = .play
        if !isCompleted {
            delegate?.didCompletePlaying(url: initialURL?.absoluteString ?? "")
            isCompleted = true
        }
    }
    
    @objc func didBecomeActive() {
        player.play()
    }
}

extension AVSource: AVPlayerSlideDelegate {
 
    public func slideDidAppear(_ slide: AVPlayerSlide) {
        switch onAppear {
        case .play:
            player.play()
            player.isMuted = true
            self.customOverlay?.updateButtonsStatus()
            if !isCurrentlyPlaying {
                delegate?.didStartPlaying(url: initialURL?.absoluteString ?? "")
                isCurrentlyPlaying = true
            }
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
    
    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 1000)
        player.seek(to: cmTime)
    }
}

extension AVSource: AVCustomOverlayDelegate {
    
    func updateMuteStatus(to newStatus: MuteStatus) {
        switch newStatus {
        case .muted: player.isMuted = true
        case .unmuted: player.isMuted = false
        }
    }
    
    func updatePlayPauseStatus(to newStatus: PlayPauseStatus) {
        switch newStatus {
        case .play: player.play()
        case .pause: player.pause()
        }
    }
    
    func didForwardSkip() {
        let currentTime = player.currentTime().seconds
        let newTime = currentTime + 5
        seek(to: newTime)
    }
    
    func didBackwardsSkip() {
        let currentTime = player.currentTime().seconds
        let newTime = currentTime - 5
        seek(to: newTime)
    }
    
    func seek(to value: TimeInterval, shouldPause: Bool, shouldPlay: Bool) {
        if shouldPause {
            player.pause()
        }
        seek(to: value)
        if shouldPlay {
            player.play()
        }
    }
}
