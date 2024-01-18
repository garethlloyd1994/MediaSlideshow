//
//  OdeumPlayerSource.swift
//
//
//  Created by Gareth Lloyd on 18/1/2024.
//

import Foundation
import Odeum
import UIKit

public class OdeumPlayerSource: NSObject, MediaSource {
    
    let url: URL
    let player = OdeumPlayerView()
    
    public init(url: URL) {
        self.url = url
    }
    
    public func slide(in slideshow: MediaSlideshow) -> MediaSlideshowSlide {
        player.delegate = self
        player.set(url: url)
        let slide = OdeumPlayerSlide(player: player, mediaContentMode: slideshow.contentScaleMode)
        slide.delegate = self
        return slide
    }
}

extension OdeumPlayerSource: OdeumPlayerViewDelegate {
    public func odeum(_ player: OdeumPlayerView, progressingBy percent: Double) {
        if percent == 100 {
            player.set(url: url)
        }
    }
}

extension OdeumPlayerSource: OdeumPlayerSlideDelegate {
    public func slideDidAppear(_ slide: OdeumPlayerSlide) {
        player.play()
    }
    
    public func slideDidDisappear(_ slide: OdeumPlayerSlide) {
        player.pause()
    }
    
    public func currentThumbnail(_ slide: OdeumPlayerSlide) -> UIImage? {
        return nil
    }
}
