//
//  ClearContainerView.swift
//  SlideOutable
//
//  Created by Domas Nutautas on 20/05/16.
//  Copyright © 2016 Domas Nutautas. All rights reserved.
//

import UIKit

// MARK: - ContainterView

///
/// Passes touches if background is clear and point is not inside one of its subviews
///
public class ClearContainerView: UIView {

    public override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        
        guard backgroundColor == .clearColor() else { return super.pointInside(point, withEvent: event) }
        
        for subview in subviews where subview.pointInside(convertPoint(point, toView: subview), withEvent: event) {
            return true
        }
        
        return false
    }
}
