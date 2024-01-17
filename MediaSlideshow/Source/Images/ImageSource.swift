//
//  InputSource.swift
//  MediaSlideshow
//
//  Created by Petr Zvoníček on 14.01.16.
//
//

import UIKit

/// A protocol that can be adapted by different Input Source providers
public protocol ImageSource: MediaSource {
    /**
     Load image from the source to image view.
     - parameter imageView: Image view to load the image into.
     - parameter callback: Callback called after image was set to the image view.
     - parameter image: Image that was set to the image view.
     */
    func load(to imageView: UIImageView, with callback: @escaping (_ image: UIImage?) -> Void)

    /**
     Cancel image load on the image view
     - parameter imageView: Image view that is loading the image
    */
    func cancelLoad(on imageView: UIImageView)
}

extension ImageSource {
    public func slide(in slideshow: MediaSlideshow) -> MediaSlideshowSlide {
        let slide = ImageSlide(
            image: self,
            zoomEnabled: slideshow.zoomEnabled,
            activityIndicator: slideshow.activityIndicator?.create(),
            maximumScale: slideshow.maximumScale)
        slide.imageView.contentMode = .scaleAspectFill
        return slide
    }
}

/// Input Source to load plain UIImage
@objcMembers
public class UIImageSource: NSObject, ImageSource {
    var image: UIImage

    /// Initializes a new Image Source with UIImage
    /// - parameter image: Image to be loaded
    public init(image: UIImage) {
        self.image = image
    }

    /// Initializes a new Image Source with an image name from the main bundle
    /// - parameter imageString: name of the file in the application's main bundle
    @available(*, deprecated, message: "Use `BundleImageSource` instead")
    public init?(imageString: String) {
        if let image = UIImage(named: imageString) {
            self.image = image
            super.init()
        } else {
            return nil
        }
    }

    public func load(to imageView: UIImageView, with callback: @escaping (UIImage?) -> Void) {
        imageView.image = image
        callback(image)
    }

    public func cancelLoad(on imageView: UIImageView) {}
}

/// Input Source to load an image from the main bundle
@objcMembers
public class BundleImageSource: NSObject, ImageSource {
    var imageString: String

    /// Initializes a new Image Source with an image name from the main bundle
    /// - parameter imageString: name of the file in the application's main bundle
    public init(imageString: String) {
        self.imageString = imageString
        super.init()
    }

    public func load(to imageView: UIImageView, with callback: @escaping (UIImage?) -> Void) {
        let image = UIImage(named: imageString)
        imageView.image = image
        callback(image)
    }

    public func cancelLoad(on imageView: UIImageView) {}
}

/// Input Source to load an image from a local file path
@objcMembers
public class FileImageSource: NSObject, ImageSource {
    var path: String

    /// Initializes a new Image Source with an image name from the main bundle
    /// - parameter imageString: name of the file in the application's main bundle
    public init(path: String) {
        self.path = path
        super.init()
    }

    public func load(to imageView: UIImageView, with callback: @escaping (UIImage?) -> Void) {
        let image = UIImage(contentsOfFile: path)
        imageView.image = image
        callback(image)
    }

    public func cancelLoad(on imageView: UIImageView) {}
}
