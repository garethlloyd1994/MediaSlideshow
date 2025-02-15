//
//  MediaSlideshow.swift
//  MediaSlideshow
//
//  Created by Petr Zvoníček on 30.07.15.
//

import UIKit

@objc
/// The delegate protocol informing about slideshow state changes
public protocol MediaSlideshowDelegate: AnyObject {
    /// Tells the delegate that the current page has changed
    ///
    /// - Parameters:
    ///   - mediaSlideshow: slideshow instance
    ///   - page: new page
    @objc optional func mediaSlideshow(_ mediaSlideshow: MediaSlideshow, didChangeCurrentPageTo page: Int)

    /// Tells the delegate that the slideshow will begin dragging
    ///
    /// - Parameter mediaSlideshow: slideshow instance
    @objc optional func mediaSlideshowWillBeginDragging(_ mediaSlideshow: MediaSlideshow)

    /// Tells the delegate that the slideshow did end decelerating
    ///
    /// - Parameter mediaSlideshow: slideshow instance
    @objc optional func mediaSlideshowDidEndDecelerating(_ mediaSlideshow: MediaSlideshow)
    
    @objc optional func shouldClose()
}

/** 
    Used to represent position of the Page Control
    - hidden: Page Control is hidden
    - insideScrollView: Page Control is inside image slideshow
    - underScrollView: Page Control is under image slideshow
    - custom: Custom vertical padding, relative to "insideScrollView" position
 */
public enum PageControlPosition {
    case hidden
    case insideScrollView
    case underScrollView
    case custom(padding: CGFloat)
}

/// Used to represent image preload strategy
///
/// - fixed: preload only fixed number of images before and after the current image
/// - all: preload all images in the slideshow
public enum ImagePreload {
    case fixed(offset: Int)
    case all
}

/// Main view containing the Slideshow
@objcMembers
public class MediaSlideshow: UIView {

    /// Scroll View to wrap the slideshow
    public let scrollView = UIScrollView()
       
    /// Activity indicator shown when loading image
    public var activityIndicator: ActivityIndicatorFactory? {
        didSet {
            reloadScrollView()
        }
    }

    public var pageIndicator: PageIndicatorView? {
        didSet {
            oldValue?.view.removeFromSuperview()
            if let pageIndicator = pageIndicator {
                addSubview(pageIndicator.view)
                if let pageIndicator = pageIndicator as? UIControl {
                    pageIndicator.addTarget(self, action: #selector(pageControlValueChanged), for: .valueChanged)
                }
            }
            setNeedsLayout()
        }
    }
    
    public var pageIndicatorPosition: PageIndicatorPosition = PageIndicatorPosition() {
        didSet {
            setNeedsLayout()
        }
    }

    // MARK: - State properties


    /// Current page
    public fileprivate(set) var currentPage: Int = 0 {
        didSet {
            if oldValue != currentPage {
                pageIndicator?.page = currentPage
                currentPageChanged?(currentPage)
                delegate?.mediaSlideshow?(self, didChangeCurrentPageTo: currentPage)
            }
        }
    }

    /// Delegate called on slideshow state change
    public weak var delegate: MediaSlideshowDelegate?

    /// Called on each currentPage change
    public var currentPageChanged: ((_ page: Int) -> Void)?

    /// Called on scrollViewWillBeginDragging
    public var willBeginDragging: (() -> Void)?

    /// Called on scrollViewDidEndDecelerating
    public var didEndDecelerating: (() -> Void)?

    /// Currenlty displayed slideshow item
    public var currentSlide: MediaSlideshowSlide? {
        if slides.count > scrollViewPage {
            return slides[scrollViewPage]
        } else {
            return nil
        }
    }

    /// Current scroll view page. This may differ from `currentPage` as circular slider has two more dummy pages at indexes 0 and n-1 to provide fluent scrolling between first and last item.
    public fileprivate(set) var scrollViewPage: Int = 0

    /// Input Sources loaded to slideshow
    public fileprivate(set) var sources = [MediaSource]()

    /// Image Slideshow Items loaded to slideshow
    public fileprivate(set) var slides = [MediaSlideshowSlide]()

    // MARK: - Preferences

    /// Enables/disables user interactions
    public var draggingEnabled = true {
        didSet {
            scrollView.isUserInteractionEnabled = draggingEnabled
        }
    }

    /// Enables/disables zoom
    public var zoomEnabled = false {
        didSet {
            reloadScrollView()
        }
    }

    /// Maximum zoom scale
    public var maximumScale: CGFloat = 2.0 {
        didSet {
            reloadScrollView()
        }
    }

    /// Image preload configuration, can be sed to .fixed to enable lazy load or .all
    public var preload = ImagePreload.all

    /// Content mode of each image in the slideshow
    open var contentScaleMode: UIView.ContentMode = .scaleAspectFit {
        didSet {
            for view in slides {
                view.mediaContentMode = contentScaleMode
            }
        }
    }
    
    fileprivate var isAnimating: Bool = false

    /// Transitioning delegate to manage the transition to full screen controller
    public internal(set) var slideshowTransitioningDelegate: ZoomAnimatedTransitioningDelegate? // swiftlint:disable:this weak_delegate

    private var primaryVisiblePage: Int {
        return scrollView.frame.size.width > 0 ? Int(scrollView.contentOffset.x + scrollView.frame.size.width / 2) / Int(scrollView.frame.size.width) : 0
    }

    // MARK: - Life cycle

    override public init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }

    convenience init() {
        self.init(frame: CGRect.zero)
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }

    fileprivate func initialize() {
        autoresizesSubviews = true
        clipsToBounds = true
        backgroundColor = .systemBackground
        scrollView.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height - 50.0)
        scrollView.delegate = self
        scrollView.isPagingEnabled = true
        scrollView.bounces = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.autoresizingMask = autoresizingMask
        scrollView.contentInsetAdjustmentBehavior = .never
        addSubview(scrollView)
        if pageIndicator == nil {
            pageIndicator = UIPageControl()
        }
        layoutScrollView()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        scrollView.contentInset = UIEdgeInsets.zero
        layoutPageControl()
        layoutScrollView()
    }

    public func layoutPageControl() {
        if let pageIndicatorView = pageIndicator?.view {
            pageIndicatorView.isHidden = sources.count < 2

            var edgeInsets: UIEdgeInsets = UIEdgeInsets.zero
            if #available(iOS 11.0, *) {
                edgeInsets = safeAreaInsets
            }

            pageIndicatorView.sizeToFit()
            pageIndicatorView.frame = pageIndicatorPosition.indicatorFrame(for: frame, indicatorSize: pageIndicatorView.frame.size, edgeInsets: edgeInsets)
        }
    }

    /// updates frame of the scroll view and its inner items
    func layoutScrollView() {
        let pageIndicatorViewSize = pageIndicator?.view.frame.size
        let scrollViewBottomPadding = pageIndicatorViewSize.flatMap { pageIndicatorPosition.underPadding(for: $0) } ?? 0
        scrollView.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height - scrollViewBottomPadding)
        scrollView.contentSize = CGSize(width: scrollView.frame.size.width * CGFloat(sources.count), height: scrollView.frame.size.height)
        for (index, view) in slides.enumerated() {
            if let zoomable = view as? ZoomableMediaSlideshowSlide, !zoomable.zoomInInitially {
                zoomable.zoomOut()
            }
            view.frame = CGRect(x: scrollView.frame.size.width * CGFloat(index), y: 0, width: scrollView.frame.size.width, height: scrollView.frame.size.height)
        }
        setScrollViewPage(scrollViewPage, animated: false)
    }

    /// reloads scroll view with latest slideshow items
    private func reloadScrollView() {
        // remove previous slideshow items
        for view in slides {
            view.removeFromSuperview()
        }
        slides = []
        for source in sources {
            let slide = source.slide(in: self)
            slides.append(slide)
            scrollView.addSubview(slide)
        }
        scrollViewPage = 0
        loadMedia(for: scrollViewPage)
        if !slides.isEmpty {
            delegate?.mediaSlideshow?(self, didChangeCurrentPageTo: 0)
            slides[0].didAppear()
        }
    }

    private func loadMedia(for scrollViewPage: Int) {
        let totalCount = slides.count

        for i in 0..<totalCount {
            let item = slides[i]
            switch preload {
            case .all:
                item.loadMedia()
            case .fixed(let offset):
                // load image if page is in range of loadOffset, else release image
                let shouldLoad = abs(scrollViewPage-i) <= offset || abs(scrollViewPage-i) > totalCount-offset
                shouldLoad ? item.loadMedia() : item.releaseMedia()
            }
        }
    }

    // MARK: - Media setting

    /**
     Set image inputs into the image slideshow
     - parameter inputs: Array of InputSource instances.
     */
    public func setMediaSources(_ sources: [MediaSource]) {
        self.sources = sources
        pageIndicator?.numberOfPages = sources.count
        reloadScrollView()
        layoutScrollView()
    }

    // MARK: paging methods

    /**
     Change the current page
     - parameter newPage: new page
     - parameter animated: true if animate the change
     */
    public func setCurrentPage(_ newPage: Int, animated: Bool) {
        setScrollViewPage(newPage, animated: animated)
    }

    /**
     Change the scroll view page. This may differ from `setCurrentPage` as circular slider has two more dummy pages at indexes 0 and n-1 to provide fluent scrolling between first and last item.
     - parameter newScrollViewPage: new scroll view page
     - parameter animated: true if animate the change
     */
    public func setScrollViewPage(_ newScrollViewPage: Int, animated: Bool) {
        if scrollViewPage < sources.count {
            scrollView.scrollRectToVisible(CGRect(x: scrollView.frame.size.width * CGFloat(newScrollViewPage), y: 0, width: scrollView.frame.size.width, height: scrollView.frame.size.height), animated: animated)
            setCurrentPageForScrollViewPage(newScrollViewPage)
            if animated {
                isAnimating = true
            }
        }
    }

    fileprivate func setCurrentPageForScrollViewPage(_ page: Int) {
        if scrollViewPage != page {
            if slides.count > scrollViewPage {
                slides[scrollViewPage].didDisappear()
            }
            if slides.count > page {
                slides[page].didAppear()
            }
        }

        if page != scrollViewPage {
            loadMedia(for: page)
        }
        scrollViewPage = page
        currentPage = currentPageForScrollViewPage(page)
    }

    fileprivate func currentPageForScrollViewPage(_ page: Int) -> Int {
        page
    }

    /**
     Change the page to the next one
     - Parameter animated: true if animate the change
     */
    public func nextPage(animated: Bool) {
        if isAnimating {
            return
        }
        setCurrentPage(currentPage + 1, animated: animated)
    }

    /**
     Change the page to the previous one
     - Parameter animated: true if animate the change
     */
    public func previousPage(animated: Bool) {
        if isAnimating {
            return
        }
        let newPage = scrollViewPage > 0 ? scrollViewPage - 1 : sources.count - 3
        setScrollViewPage(newPage, animated: animated)
    }

    @objc private func pageControlValueChanged() {
        if let currentPage = pageIndicator?.page {
            setCurrentPage(currentPage, animated: true)
        }
    }
    
    public func viewWillDisappear() {
        slides.forEach { $0.willBeRemoved(shouldRemovePlayer: true) }
    }
}

extension MediaSlideshow: UIScrollViewDelegate {

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        willBeginDragging?()
        delegate?.mediaSlideshowWillBeginDragging?(self)
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        setCurrentPageForScrollViewPage(primaryVisiblePage)
        didEndDecelerating?()
        delegate?.mediaSlideshowDidEndDecelerating?(self)
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Updates the page indicator as the user scrolls (#204). Not called when not dragging to prevent flickers
        // when interacting with PageControl directly (#376).
        if scrollView.isDragging {
            pageIndicator?.page = currentPageForScrollViewPage(primaryVisiblePage)
        }
    }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        isAnimating = false
    }
}
