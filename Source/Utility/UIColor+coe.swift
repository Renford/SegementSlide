//
//  UIColor.swift
//  SegementSlide
//
//  Created by Renford on 2020/5/3.
//

import Foundation

extension UIColor {
    
    /// 生成线性过度色
    /// - Parameters:
    ///   - toCcolor: 目标颜色
    ///   - coe: 系数
    func getColor(to color: UIColor, coe: CGFloat) -> UIColor {
        
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        
        self.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        color.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        let r = r1 + (r2 - r1) * coe
        let g = g1 + (g2 - g1) * coe
        let b = b1 + (b2 - b1) * coe
        let a = a1 + (a2 - a1) * coe
        
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }

}
