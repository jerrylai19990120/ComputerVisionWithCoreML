//
//  RoundedShadowImageView.swift
//  VisionApp
//
//  Created by Jerry Lai on 2021-01-26.
//  Copyright © 2021 Jerry Lai. All rights reserved.
//

import UIKit

class RoundedShadowImageView: UIImageView {

    override func awakeFromNib() {
        self.layer.shadowColor = UIColor.darkGray.cgColor
        self.layer.shadowRadius = 15
        self.layer.shadowOpacity = 0.75
        self.layer.cornerRadius = 15
    }

}
