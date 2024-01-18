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
    func embed(_ view: UIView, edgeInsets: UIEdgeInsets? = nil) {
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        let viewInsets = edgeInsets ?? safeAreaInsets
        view.topAnchor.constraint(equalTo: topAnchor, constant: viewInsets.top).isActive = true
        view.bottomAnchor.constraint(equalTo: bottomAnchor, constant: viewInsets.bottom).isActive = true
        view.leadingAnchor.constraint(equalTo: leadingAnchor, constant: viewInsets.left).isActive = true
        view.trailingAnchor.constraint(equalTo: trailingAnchor, constant: viewInsets.right).isActive = true
    }
}
