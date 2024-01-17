//
//  AVPlayerView.swift
//  MediaSlideshow
//
//  Created by Peter Meyers on 1/7/21.
//

import AVFoundation
import Foundation
import UIKit

extension UIView {
    func embed(_ view: UIView, safeArea: Bool = true) {
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        let topInset = safeArea ? safeAreaInsets.top : 0
        let bottomInset = safeArea ? safeAreaInsets.bottom : 0
        let leadingInset = safeArea ? safeAreaInsets.left : 0
        let trailingInset = safeArea ? safeAreaInsets.right : 0
        view.topAnchor.constraint(equalTo: topAnchor, constant: topInset).isActive = true
        view.bottomAnchor.constraint(equalTo: bottomAnchor, constant: bottomInset).isActive = true
        view.leadingAnchor.constraint(equalTo: leadingAnchor, constant: leadingInset).isActive = true
        view.trailingAnchor.constraint(equalTo: trailingAnchor, constant: trailingInset).isActive = true
    }
}
