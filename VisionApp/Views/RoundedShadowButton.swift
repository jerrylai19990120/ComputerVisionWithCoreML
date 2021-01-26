//
//  RoundedShadowButton.swift
//  VisionApp
//
//  Created by Jerry Lai on 2021-01-26.
//  Copyright © 2021 Jerry Lai. All rights reserved.
//

import UIKit

class RoundedShadowButton: UIButton {

    override func awakeFromNib() {
        self.layer.shadowColor = UIColor.darkGray.cgColor
        self.layer.shadowRadius = 15
        self.layer.shadowOpacity = 0.75
        self.layer.cornerRadius = self.frame.height/2
    }

}
