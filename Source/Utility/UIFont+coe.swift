//
//  UIFont+coe.swift
//  SegementSlide
//
//  Created by Renford on 2020/5/3.
//

import Foundation

extension UIFont {
    
    /// 过度字体
    /// - Parameters:
    ///   - font: 目标字体
    ///   - coe: 过度系数
    func getFont(to font: UIFont, coe: CGFloat) -> UIFont {
        
        let size = self.pointSize + (font.pointSize - self.pointSize) * coe
        
        return UIFont.systemFont(ofSize: size)
    }
}
