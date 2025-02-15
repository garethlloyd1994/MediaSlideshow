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
    var playerController: AVPlayerViewController?
    private let transitionView: UIImageView
    
    public init(playerController: AVPlayerViewController, mediaContentMode: UIView.ContentMode) {
        self.playerController = playerController
        self.transitionView = UIImageView()
        self.mediaContentMode = mediaContentMode
        super.init(frame: .zero)
        setPlayerViewVideoGravity()
        transitionView.isHidden = true
        embed(transitionView)
        embed(playerController.view, edgeInsets: UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0))
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setPlayerViewVideoGravity() {
          switch mediaContentMode {
          case .scaleAspectFill: playerController?.videoGravity = .resizeAspectFill
          case .scaleToFill: playerController?.videoGravity = .resize
          default: playerController?.videoGravity = .resizeAspect
          }
      }

      // MARK: - MediaSlideshowSlide

      public var mediaContentMode: UIView.ContentMode {
          didSet {
              setPlayerViewVideoGravity()
          }
      }

    public func willBeRemoved(shouldRemovePlayer: Bool = false) {
        playerController?.player?.pause()
        if shouldRemovePlayer {
            playerController?.player?.replaceCurrentItem(with: nil)
            playerController?.view.removeFromSuperview()
            playerController = nil
        }
    }

    public func loadMedia() {}
    public func releaseMedia() {}

    public func transitionImageView() -> UIImageView {
        transitionView.frame = playerController?.videoBounds ?? .zero
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
