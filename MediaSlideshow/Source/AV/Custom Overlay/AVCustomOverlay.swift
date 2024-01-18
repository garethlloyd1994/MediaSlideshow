//
//  AVCustomOverlay.swift
//  
//
//  Created by Gareth Lloyd on 18/1/2024.
//

import UIKit
import AVFoundation
import AVKit

protocol AVCustomOverlayDelegate: AnyObject {
    func updateMuteStatus(to newStatus: MuteStatus)
    func updatePlayPauseStatus(to newStatus: PlayPauseStatus)
    func didForwardSkip()
    func didBackwardsSkip()
    func seek(to value: TimeInterval, shouldPause: Bool, shouldPlay: Bool)
}

class AVCustomOverlay: UIView {
    
    private var buttonsStackView: UIStackView?
    private var progressBarStackView: UIStackView?
    private var audioButton: UIButton?
    private var playPauseButton: UIButton?
    private var forwardSkipButton: UIButton?
    private var reverseSkipButton: UIButton?
    private var progressSlider: UISlider?
    private var currentTimeLabel: UILabel?
    private var totalTimeLabel: UILabel?
    
    public weak var delegate: AVCustomOverlayDelegate?
    
    public var muteStatus: MuteStatus = .unmuted {
        didSet {
            audioButton?.setImage(muteStatus.icon, for: .normal)
        }
    }
    public var playPauseStatus: PlayPauseStatus = .play {
        didSet {
            playPauseButton?.setImage(playPauseStatus.icon, for: .normal)
        }
    }
    private let player: AVPlayer
    private var playerTimeObserver: Any?
    private let item: AVPlayerItem
    
    init(item: AVPlayerItem, player: AVPlayer) {
        self.player = player
        self.item = item
        super.init(frame: .zero)
        setupUI()
        setupTimer()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        let buttonsStackView = setupButtonStackView()
        let progressSliderStackView = setupProgressSliderStackView()
        progressSliderStackView.topAnchor.constraint(equalTo: buttonsStackView.bottomAnchor, constant: 20).isActive = true
    }
    
    func setupTimer() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        playerTimeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak item, weak self] time in
            guard let self = self, let item = item else { return }
            let currentTime = item.currentTime().seconds
            self.playerDidUpdateToTime(currentTime)
        }
    }
    
    func updateButtonsStatus() {
        muteStatus = player.isMuted ? .muted : .unmuted
    }
    
    func setupButtonStackView() -> UIStackView {
        let stackView = UIStackView()
        stackView.spacing = 20
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        leadingAnchor.constraint(greaterThanOrEqualTo: stackView.leadingAnchor, constant: 10).isActive = true
        trailingAnchor.constraint(greaterThanOrEqualTo: stackView.trailingAnchor, constant: 10).isActive = true
        centerXAnchor.constraint(equalTo: stackView.centerXAnchor, constant: 0).isActive = true
        self.buttonsStackView = stackView
        addMuteButton()
        addPlayPauseButton()
        addReverseSkipButton()
        addForwardSkipButton()
        return stackView
    }
    
    func addMuteButton() {
        let audioButton = UIButton()
        audioButton.backgroundColor = .clear
        audioButton.setImage(muteStatus.icon, for: .normal)
        audioButton.imageView?.contentMode = .scaleAspectFit
        audioButton.addTarget(self, action: #selector(muteButtonAction), for: .touchUpInside)
        audioButton.translatesAutoresizingMaskIntoConstraints = false
        buttonsStackView?.addArrangedSubview(audioButton)
        self.audioButton = audioButton
    }
    
    func addPlayPauseButton() {
        let playPauseButton = UIButton()
        playPauseButton.backgroundColor = .clear
        playPauseButton.setImage(playPauseStatus.icon, for: .normal)
        playPauseButton.imageView?.contentMode = .scaleAspectFit
        playPauseButton.addTarget(self, action: #selector(playPauseButtonAction), for: .touchUpInside)
        playPauseButton.translatesAutoresizingMaskIntoConstraints = false
        buttonsStackView?.addArrangedSubview(playPauseButton)
        self.playPauseButton = playPauseButton
    }
    
    func addForwardSkipButton() {
        let forwardSkipButton = UIButton()
        forwardSkipButton.backgroundColor = .clear
        let icon = UIImage(systemName: "forward.fill")?.withTintColor(.white).withRenderingMode(.alwaysOriginal)
        forwardSkipButton.setImage(icon, for: .normal)
        forwardSkipButton.imageView?.contentMode = .scaleAspectFit
        forwardSkipButton.addTarget(self, action: #selector(forwardSkipButtonAction), for: .touchUpInside)
        forwardSkipButton.translatesAutoresizingMaskIntoConstraints = false
        buttonsStackView?.addArrangedSubview(forwardSkipButton)
        self.forwardSkipButton = forwardSkipButton
    }
    
    func addReverseSkipButton() {
        let reverseSkipButton = UIButton()
        reverseSkipButton.backgroundColor = .clear
        let icon = UIImage(systemName: "backward.fill")?.withTintColor(.white).withRenderingMode(.alwaysOriginal)
        reverseSkipButton.setImage(icon, for: .normal)
        reverseSkipButton.imageView?.contentMode = .scaleAspectFit
        reverseSkipButton.addTarget(self, action: #selector(reverseSkipButtonAction), for: .touchUpInside)
        reverseSkipButton.translatesAutoresizingMaskIntoConstraints = false
        buttonsStackView?.addArrangedSubview(reverseSkipButton)
        self.reverseSkipButton = reverseSkipButton
    }

    @objc func muteButtonAction() {
        muteStatus = muteStatus.reverseValue
        delegate?.updateMuteStatus(to: muteStatus)
    }

    @objc func playPauseButtonAction() {
        playPauseStatus = playPauseStatus.reverseValue
        delegate?.updatePlayPauseStatus(to: playPauseStatus)
    }
    
    @objc func forwardSkipButtonAction() {
        delegate?.didForwardSkip()
    }
    
    @objc func reverseSkipButtonAction() {
        delegate?.didBackwardsSkip()
    }
    
    
    // MARK: - Slider
    
    func setupProgressSliderStackView() -> UIStackView {
        let stackView = UIStackView()
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.backgroundColor = .clear
        addSubview(stackView)
        stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10).isActive = true
        trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: 10).isActive = true
        bottomAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 100).isActive = true
        self.progressBarStackView = stackView
        setupProgressSlider()
        setupTimeLabels()
        return stackView
        
    }
    
    func setupProgressSlider() {
        let slider = UISlider()
        slider.thumbTintColor = .white
        slider.minimumTrackTintColor = .red
        slider.maximumTrackTintColor = UIColor.white.withAlphaComponent(0.5)
        slider.minimumValue = 0
        let fullDuration = item.duration.seconds
        if !fullDuration.isNaN && !fullDuration.isInfinite {
            slider.maximumValue = Float(item.duration.seconds)
        }
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.setThumbImage(makeCircle(), for: .normal)
        slider.setThumbImage(makeCircle(withSize: .init(width: 16, height: 16)), for: .highlighted)
        slider.addTarget(self, action: #selector(slided), for: .valueChanged)
        slider.addTarget(self, action: #selector(didSlide), for: .touchUpInside)
        slider.addTarget(self, action: #selector(didSlide), for: .touchUpOutside)
        self.progressSlider = slider
        progressBarStackView?.addArrangedSubview(slider)
    }
    
    func setupTimeLabels() {
        let currentTimeLabel = UILabel()
        currentTimeLabel.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        currentTimeLabel.textColor = .white
        currentTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        progressBarStackView?.insertArrangedSubview(currentTimeLabel, at: 0)
        self.currentTimeLabel = currentTimeLabel
        
        let totalTimeLabel = UILabel()
        totalTimeLabel.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        totalTimeLabel.textColor = .white
        totalTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        progressBarStackView?.addArrangedSubview(totalTimeLabel)
        let fullDuration = item.duration.seconds
        if !fullDuration.isNaN && !fullDuration.isInfinite {
            updateText(for: totalTimeLabel, with: item.duration.seconds)
        }
        self.totalTimeLabel = totalTimeLabel
    }
    
    func makeCircle(withSize size: CGSize = .init(width: 8, height: 8)) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        defer {
            UIGraphicsEndImageContext()
        }
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        context.setFillColor(UIColor.white.cgColor)
        context.setStrokeColor(UIColor.clear.cgColor)
        let bounds = CGRect(origin: .zero, size: size)
        context.addEllipse(in: bounds)
        context.drawPath(using: .fill)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        return image
    }
    
    @objc func slided() {
        guard let value =  progressSlider?.value else { return }
        delegate?.seek(to: TimeInterval(value), shouldPause: true, shouldPlay: false)
        playerDidUpdateToTime(Double(value))
    }
    
    @objc func didSlide() {
        guard let value =  progressSlider?.value else { return }
        delegate?.seek(to: TimeInterval(value), shouldPause: false, shouldPlay: true)
        playerDidUpdateToTime(Double(value))
    }
    
    public func playerDidUpdateToTime(_ currentTime: TimeInterval) {
        updateText(for: currentTimeLabel, with: currentTime)
        progressSlider?.value = Float(currentTime)
    }
    
    func updateText(for label: UILabel?, with time: TimeInterval) {
        let secondsPlayed = Int(time)
        let minutes = String(secondsPlayed / 60)
        let seconds = String(secondsPlayed % 60)
        let under10 = secondsPlayed % 60 < 10
        label?.text = minutes + (under10 ? ":0" : ":") + seconds
    }
}

enum MuteStatus {
    case muted
    case unmuted
    
    var reverseValue: MuteStatus {
        switch self {
        case .muted: return .unmuted
        case .unmuted: return .muted
        }
    }
    
    var icon: UIImage? {
        switch self {
        case .muted: return UIImage(systemName: "speaker.slash.fill")?.withTintColor(.white).withRenderingMode(.alwaysOriginal)
        case .unmuted: return UIImage(systemName: "speaker.fill")?.withTintColor(.white).withRenderingMode(.alwaysOriginal)
        }
    }
}

enum PlayPauseStatus {
    case play
    case pause
    
    var reverseValue: PlayPauseStatus {
        switch self {
        case .play: return .pause
        case .pause: return .play
        }
    }
    
    var icon: UIImage? {
        switch self {
        case .play: return UIImage(systemName: "pause.fill")?.withTintColor(.white).withRenderingMode(.alwaysOriginal)
        case .pause: return UIImage(systemName: "play.fill")?.withTintColor(.white).withRenderingMode(.alwaysOriginal)
        }
    }
}
