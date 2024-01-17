//
//  MediaSource.swift
//  MediaSlideshow
//
//  Created by Peter Meyers on 1/7/21.
//

import Foundation

/// A protocol that marks a media item in the slideshow.
public protocol MediaSource {

    func slide(in slideshow: MediaSlideshow) -> MediaSlideshowSlide
}
