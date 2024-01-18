//
//  OdeumPlayerSlide.swift
//
//
//  Created by Gareth Lloyd on 18/1/2024.
//

import Odeum
import UIKit

public protocol OdeumPlayerSlideDelegate: AnyObject {
    func currentThumbnail(_ slide: OdeumPlayerSlide) -> UIImage?
    func slideDidAppear(_ slide: OdeumPlayerSlide)
    func slideDidDisappear(_ slide: OdeumPlayerSlide)
}

public class OdeumPlayerSlide: UIView, MediaSlideshowSlide {
    weak var delegate: OdeumPlayerSlideDelegate?

    public let player: OdeumPlayerView
    private let transitionView: UIImageView
    
    public init(player: OdeumPlayerView, mediaContentMode: UIView.ContentMode) {
        self.player = player
        player.playerControl.fullScreenButton.isHidden = true
        self.transitionView = UIImageView()
        self.mediaContentMode = mediaContentMode
        super.init(frame: .zero)
        transitionView.isHidden = true
        embed(transitionView)
        embed(player)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setPlayerViewVideoGravity() {
        player.contentMode = mediaContentMode
    }

    // MARK: - MediaSlideshowSlide

      public var mediaContentMode: UIView.ContentMode {
          didSet {
              setPlayerViewVideoGravity()
          }
      }

    public func willBeRemoved() {
        player.pause()
    }

    public func loadMedia() {}

    public func releaseMedia() {}

    public func transitionImageView() -> UIImageView {
        transitionView.frame = player.bounds
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
}
