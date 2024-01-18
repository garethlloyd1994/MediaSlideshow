//
//  FullScreenSlideshowViewController.swift
//  MediaSlideshow
//
//  Created by Petr Zvoníček on 31.08.15.
//

import UIKit

@objcMembers
public class FullScreenSlideshowViewController: UIViewController {

    public var slideshow: MediaSlideshow = {
        let slideshow = MediaSlideshow()
        slideshow.zoomEnabled = true
        slideshow.contentMode = .scaleAspectFit
        slideshow.pageIndicatorPosition = PageIndicatorPosition(horizontal: .center, vertical: .bottom)
        slideshow.autoresizingMask = [UIView.AutoresizingMask.flexibleWidth, UIView.AutoresizingMask.flexibleHeight]
        return slideshow
    }()

    /// Close button 
    public var closeButton = UIButton()

    /// Close button frame
    public var closeButtonFrame: CGRect?

    /// Closure called on page selection
    public var pageSelected: ((_ page: Int) -> Void)?

    /// Index of initial image
    public var initialPage: Int = 0

    /// Datasource
    public var sources: [MediaSource] {
        slideshow.sources
    }

    /// Background color
    public var backgroundColor = UIColor.black

    /// Enables/disable zoom
    public var zoomEnabled = true {
        didSet {
            slideshow.zoomEnabled = zoomEnabled
        }
    }

    fileprivate var isInit = true

    convenience init() {
        self.init(nibName: nil, bundle: nil)
        slideshow.delegate = self
        self.modalPresentationStyle = .custom
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = backgroundColor
        slideshow.backgroundColor = backgroundColor
        view.embed(slideshow)
        closeButton.setImage(UIImage(named: "ic_cross_white", in: .module, compatibleWith: nil), for: .normal)
        closeButton.addTarget(self, action: #selector(FullScreenSlideshowViewController.close), for: .touchUpInside)
        view.addSubview(closeButton)
    }

    override public var prefersStatusBarHidden: Bool {
        return true
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isInit {
            isInit = false
            slideshow.setCurrentPage(initialPage, animated: false)
        }
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        slideshow.slides.forEach { $0.willBeRemoved() }
        if let zoomable = slideshow.currentSlide as? ZoomableMediaSlideshowSlide {
            zoomable.zoomOut()
        }
    }

    public override func viewDidLayoutSubviews() {
        if !isBeingDismissed {
            let safeAreaInsets: UIEdgeInsets
            safeAreaInsets = view.safeAreaInsets
            closeButton.frame = closeButtonFrame ?? CGRect(x: max(10, safeAreaInsets.left), y: max(10, safeAreaInsets.top), width: 40, height: 40)
        }
        slideshow.frame = view.frame
    }

    public func setMediaSources(_ sources: [MediaSource]) {
        slideshow.setMediaSources(sources)
    }

    func close() {
        // if pageSelected closure set, send call it with current page
        if let pageSelected = pageSelected {
            pageSelected(slideshow.currentPage)
        }

        dismiss(animated: true, completion: nil)
    }
}
extension FullScreenSlideshowViewController: MediaSlideshowDelegate {
    public func mediaSlideshow(_ mediaSlideshow: MediaSlideshow, didChangeCurrentPageTo page: Int) {
        let isAVSource = sources[page] is AVSource
        UIView.animate(withDuration: 0.3) {
            self.slideshow.pageIndicator?.view.alpha = isAVSource ? 0.0 : 1.0
            self.closeButton.alpha = isAVSource ? 0.0 : 1.0
        }
    }
    
    public func shouldClose() {
        close()
    }
}
