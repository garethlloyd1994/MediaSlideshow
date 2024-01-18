//
//  AVSlideOverlayView.swift
//  MediaSlideshow_framework
//
//  Created by Peter Meyers on 1/14/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import AVFoundation
import Foundation
import UIKit

public protocol AVSlideOverlayView: UIView {
    func playerDidUpdateToTime(_ currentTime: TimeInterval, duration: TimeInterval?)
    func playerDidUpdateStatus(_ status: AVPlayer.TimeControlStatus)
}

public class StandardAVSlideOverlayView: UIView, AVSlideOverlayView {
    
    private let playView: AVSlideOverlayView?
    private let pauseView: AVSlideOverlayView?
    private let activityView: ActivityIndicatorView?
    private var playerTimeControlStatusObservation: NSKeyValueObservation?
    private var playerTimeObserver: Any?
    
    public init(item: AVPlayerItem,
                player: AVPlayer,
                playView: AVSlideOverlayView? = AVSlidePlayingOverlayView(),
                pauseView: AVSlideOverlayView? = AVSlidePausedOverlayView(),
                activityView: ActivityIndicatorView? = nil) {
        self.playView = playView
        self.pauseView = pauseView
        self.activityView = activityView
        super.init(frame: .zero)
        if let playView = playView {
            embed(playView)
        }
        if let pauseView = pauseView {
            embed(pauseView)
        }
        if let activityView = activityView {
            embed(activityView.view)
        }
        playerDidUpdateStatus(.paused)
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        playerTimeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak item, weak self] time in
            guard let self = self, let item = item else { return }
            let currentTime = item.currentTime().seconds
            let duration = item.duration.seconds
            self.playerDidUpdateToTime(currentTime,
                                       duration: (duration.isNaN || duration.isInfinite) ? nil : duration)
        }
        playerTimeControlStatusObservation = player.observe(\.timeControlStatus) { [weak self] player, _ in
            self?.playerDidUpdateStatus(player.timeControlStatus)
        }
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func playerDidUpdateToTime(_ currentTime: TimeInterval, duration: TimeInterval?) {
        playView?.playerDidUpdateToTime(currentTime, duration: duration)
        pauseView?.playerDidUpdateToTime(currentTime, duration: duration)
    }
    
    public func playerDidUpdateStatus(_ status: AVPlayer.TimeControlStatus) {
        playView?.playerDidUpdateStatus(status)
        pauseView?.playerDidUpdateStatus(status)
        switch status {
        case .waitingToPlayAtSpecifiedRate:
            activityView?.show()
        case .playing:
            activityView?.hide()
        case .paused:
            activityView?.hide()
        @unknown default: break
        }
    }
}

public class AVSlidePlayingOverlayView: UIView, AVSlideOverlayView {
    
    private let countdownLabel: UILabel = {
        var label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.layer.cornerRadius = 4
        label.layer.masksToBounds = true
        label.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        label.textAlignment = .center
        let height = NSLayoutConstraint( item: label,
                                         attribute: .height,
                                         relatedBy: .equal,
                                         toItem: nil,
                                         attribute: .notAnAttribute,
                                         multiplier: 1,
                                         constant: 20)
        height.isActive = true
        return label
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        countdownLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(countdownLabel)
        NSLayoutConstraint.activate([
            countdownLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -20),
            countdownLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        var labelFrame = countdownLabel.frame
        labelFrame.size.width = countdownLabel.intrinsicContentSize.width * 1.2
        countdownLabel.frame = labelFrame
    }
    
    public func playerDidUpdateToTime(_ currentTime: TimeInterval, duration: TimeInterval?) {
        guard let duration = duration else {
            countdownLabel.text = nil
            return
        }
        let secondsRemaining = Int(duration - currentTime)
        let minutes = String(secondsRemaining / 60)
        let seconds = String(secondsRemaining % 60)
        let under10 = secondsRemaining % 60 < 10
        countdownLabel.text = minutes + (under10 ? ":0" : ":") + seconds
    }
    
    public func playerDidUpdateStatus(_ status: AVPlayer.TimeControlStatus) {
        switch status {
        case .paused: isHidden = true
        default: isHidden = false
        }
    }
}

public class AVSlidePausedOverlayView: UIView, AVSlideOverlayView {
    
    private let playImageView = UIImageView()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        playImageView.image = UIImage(named: "video-play", in: Bundle(for: Self.self), compatibleWith: nil)
        playImageView.contentMode = .center
        embed(playImageView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func playerDidUpdateToTime(_ currentTime: TimeInterval, duration: TimeInterval?) {}
    
    public func playerDidUpdateStatus(_ status: AVPlayer.TimeControlStatus) {
        switch status {
        case .paused: isHidden = false
        default: isHidden = true
        }
    }
}
