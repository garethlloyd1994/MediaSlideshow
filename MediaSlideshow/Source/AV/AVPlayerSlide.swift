//
//  AVSlideshowItem.swift
//  ImageSlideshow
//
//  Created by Peter Meyers on 1/5/21.
//

import AVFoundation
import AVKit
import UIKit

public protocol AVPlayerSlideDelegate: AnyObject {
    func currentThumbnail(_ slide: AVPlayerSlide) -> UIImage?
    func slideDidAppear(_ slide: AVPlayerSlide)
    func slideDidDisappear(_ slide: AVPlayerSlide)
}

public class AVPlayerSlide: UIView, MediaSlideshowSlide {
    weak var delegate: AVPlayerSlideDelegate?

    public let playerController: AVPlayerViewController
    private let transitionView: UIImageView

    public init(playerController: AVPlayerViewController) {
        self.playerController = playerController
        self.transitionView = UIImageView()
        super.init(frame: .zero)
            playerController.videoGravity = .resizeAspectFill
        // Stays hidden, but needs to be apart of the view heirarchy due to how the zoom animation works.
        transitionView.isHidden = true
        embed(transitionView)
        embed(playerController.view)
        if playerController.showsPlaybackControls {
            addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didSingleTap)))
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    public func willBeRemoved() {
        playerController.player?.pause()
    }

    public func loadMedia() {}

    public func releaseMedia() {}

    public func transitionImageView() -> UIImageView {
        transitionView.frame = playerController.videoBounds
        transitionView.contentMode = .scaleAspectFill
        transitionView.image = delegate?.currentThumbnail(self)
        return transitionView
    }

    public func didAppear() {
        delegate?.slideDidAppear(self)
    }

    public func didDisappear() {
        delegate?.slideDidDisappear(self)
    }

    @objc
    private func didSingleTap() {}
}
