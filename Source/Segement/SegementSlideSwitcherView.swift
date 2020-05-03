//
//  SegementSlideSwitcherView.swift
//  SegementSlide
//
//  Created by Jiar on 2018/12/7.
//  Copyright © 2018 Jiar. All rights reserved.
//

import UIKit

public enum SwitcherType {
    case tab
    case segement
}

public enum SwitcherAnimateType {
    case normal
    case progress
}

public protocol SegementSlideSwitcherViewDelegate: class {
    var titlesInSegementSlideSwitcherView: [String] { get }
    
    func segementSwitcherView(_ segementSlideSwitcherView: SegementSlideSwitcherView, didSelectAtIndex index: Int, animated: Bool)
    func segementSwitcherView(_ segementSlideSwitcherView: SegementSlideSwitcherView, showBadgeAtIndex index: Int) -> BadgeType
}

public class SegementSlideSwitcherView: UIView {
    
    private let scrollView = UIScrollView()
    private let indicatorView = UIView()
    private var titleButtons: [UIButton] = []
    private var initSelectedIndex: Int?
    private var innerConfig: SegementSlideSwitcherConfig = SegementSlideSwitcherConfig.shared
    internal var gestureRecognizersInScrollView: [UIGestureRecognizer]? {
        return scrollView.gestureRecognizers
    }
    
    public private(set) var selectedIndex: Int?
    public weak var delegate: SegementSlideSwitcherViewDelegate?
    
    /// you must call `reloadData()` to make it work, after the assignment.
    public var config: SegementSlideSwitcherConfig = SegementSlideSwitcherConfig.shared
    
    public override var intrinsicContentSize: CGSize {
        return scrollView.contentSize
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        addSubview(scrollView)
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        }
        scrollView.constraintToSuperview()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .clear
        backgroundColor = .white
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        layoutTitleButtons()
        reloadBadges()
        recoverInitSelectedIndex()
        updateSelectedIndex()
    }
    
    /// relayout subViews
    ///
    /// you should call `selectSwitcher(at index: Int, animated: Bool)` after call the method.
    /// otherwise, none of them will be selected.
    /// However, if an item was previously selected, it will be reSelected.
    public func reloadData() {
        for titleButton in titleButtons {
            titleButton.removeFromSuperview()
            titleButton.frame = .zero
        }
        titleButtons.removeAll()
        indicatorView.removeFromSuperview()
        indicatorView.frame = .zero
        scrollView.isScrollEnabled = innerConfig.type == .segement
        innerConfig = config
        guard let titles = delegate?.titlesInSegementSlideSwitcherView else { return }
        guard !titles.isEmpty else { return }
        for (index, title) in titles.enumerated() {
            let button = UIButton(type: .custom)
            button.clipsToBounds = false
            button.titleLabel?.font = innerConfig.normalTitleFont
            button.backgroundColor = .clear
            button.setTitle(title, for: .normal)
            button.tag = index
            button.setTitleColor(innerConfig.normalTitleColor, for: .normal)
            button.addTarget(self, action: #selector(didClickTitleButton), for: .touchUpInside)
            scrollView.addSubview(button)
            titleButtons.append(button)
        }
        guard !titleButtons.isEmpty else { return }
        scrollView.addSubview(indicatorView)
        indicatorView.layer.masksToBounds = true
        indicatorView.layer.cornerRadius = innerConfig.indicatorHeight/2
        indicatorView.backgroundColor = innerConfig.indicatorColor
        layoutTitleButtons()
        reloadBadges()
        updateSelectedIndex()
    }
    
    /// reload all badges in `SegementSlideSwitcherView`
    public func reloadBadges() {
        for (index, titleButton) in titleButtons.enumerated() {
            guard let type = delegate?.segementSwitcherView(self, showBadgeAtIndex: index) else {
                titleButton.badge.type = .none
                continue
            }
            titleButton.badge.type = type
            if case .none = type {
                continue
            }
            let titleLabelText = titleButton.titleLabel?.text ?? ""
            let width: CGFloat
            if selectedIndex == index {
                width = titleLabelText.boundingWidth(with: innerConfig.selectedTitleFont)
            } else {
                width = titleLabelText.boundingWidth(with: innerConfig.normalTitleFont)
            }
            let height = titleButton.titleLabel?.font.lineHeight ?? titleButton.bounds.height
            switch type {
            case .none:
                break
            case .point:
                titleButton.badge.height = innerConfig.badgeHeightForPointType
                titleButton.badge.offset = CGPoint(x: width/2+titleButton.badge.height/2, y: -height/2)
            case .count:
                titleButton.badge.font = innerConfig.badgeFontForCountType
                titleButton.badge.height = innerConfig.badgeHeightForCountType
                titleButton.badge.offset = CGPoint(x: width/2+titleButton.badge.height/2, y: -height/2)
            case .custom:
                titleButton.badge.height = innerConfig.badgeHeightForCustomType
                titleButton.badge.offset = CGPoint(x: width/2+titleButton.badge.height/2, y: -height/2)
            }
        }
    }
    
    /// select one item by index
    public func selectSwitcher(at index: Int, animated: Bool) {
//        updateSelectedButton(at: index, animated: animated)
        selectSwitcherEvent(at: index, animated: animated)
        if animated == false {
            updateSwitcher(at: index)
        }
    }
    
    /// effect during slide
    public func selectSwitcher(fromIndex: Int, toIndex: Int, progress: CGFloat) {
        updateSwitcherBySlide(fromIndex: fromIndex, toIndex: toIndex, progress: progress)
    }
}

extension SegementSlideSwitcherView {
    
    private func recoverInitSelectedIndex() {
        guard let initSelectedIndex = initSelectedIndex else { return }
        self.initSelectedIndex = nil
        updateSwitcher(at: initSelectedIndex)
//        updateSelectedButton(at: initSelectedIndex, animated: false)
    }
    
    private func updateSelectedIndex() {
//        guard let selectedIndex = selectedIndex else { return }
//        updateSelectedButton(at: selectedIndex, animated: false)
    }
    
    private func layoutTitleButtons() {
        guard scrollView.frame != .zero else { return }
        guard !titleButtons.isEmpty else {
            scrollView.contentSize = CGSize(width: bounds.width, height: bounds.height)
            return
        }
        var offsetX = innerConfig.horizontalMargin
        for titleButton in titleButtons {
            let buttonWidth: CGFloat
            switch innerConfig.type {
            case .tab:
                buttonWidth = (bounds.width-innerConfig.horizontalMargin*2)/CGFloat(titleButtons.count)
            case .segement:
                let title = titleButton.title(for: .normal) ?? ""
                let normalButtonWidth = title.boundingWidth(with: innerConfig.normalTitleFont)
                let selectedButtonWidth = title.boundingWidth(with: innerConfig.selectedTitleFont)
                buttonWidth = selectedButtonWidth > normalButtonWidth ? selectedButtonWidth : normalButtonWidth
            }
            titleButton.frame = CGRect(x: offsetX, y: 0, width: buttonWidth, height: scrollView.bounds.height)
            switch innerConfig.type {
            case .tab:
                offsetX += buttonWidth
            case .segement:
                offsetX += buttonWidth+innerConfig.horizontalSpace
            }
        }
        switch innerConfig.type {
        case .tab:
            scrollView.contentSize = CGSize(width: bounds.width, height: bounds.height)
        case .segement:
            scrollView.contentSize = CGSize(width: offsetX-innerConfig.horizontalSpace+innerConfig.horizontalMargin, height: bounds.height)
        }
    }
    
//    private func updateSelectedButton(at index: Int, animated: Bool) {
//        guard scrollView.frame != .zero else {
//            initSelectedIndex = index
//            return
//        }
//        guard titleButtons.count != 0 else { return }
//        if let selectedIndex = selectedIndex, selectedIndex >= 0, selectedIndex < titleButtons.count {
//            let titleButton = titleButtons[selectedIndex]
//            titleButton.setTitleColor(innerConfig.normalTitleColor, for: .normal)
//            titleButton.titleLabel?.font = innerConfig.normalTitleFont
//        }
//        guard index >= 0, index < titleButtons.count else { return }
//        let titleButton = titleButtons[index]
//        titleButton.setTitleColor(innerConfig.selectedTitleColor, for: .normal)
//        titleButton.titleLabel?.font = innerConfig.selectedTitleFont
//        var indicatorWidth = self.innerConfig.indicatorWidth
//        if indicatorWidth == 0 {
//            let title = titleButton.title(for: .normal) ?? ""
//            indicatorWidth = title.boundingWidth(with: self.innerConfig.normalTitleFont)
//        }
//        self.indicatorView.frame = CGRect(x: titleButton.frame.origin.x+(titleButton.bounds.width-indicatorWidth)/2, y: self.frame.height-self.innerConfig.indicatorHeight, width: indicatorWidth, height: self.innerConfig.indicatorHeight)
        
//        if case .segement = innerConfig.type {
//            let titleButton = titleButtons[index]
//            var offsetX = titleButton.frame.origin.x-(scrollView.bounds.width-titleButton.bounds.width)/2
//            if offsetX < 0 {
//                offsetX = 0
//            } else if (offsetX+scrollView.bounds.width) > scrollView.contentSize.width {
//                offsetX = scrollView.contentSize.width-scrollView.bounds.width
//            }
//            if scrollView.contentSize.width > scrollView.bounds.width {
//                scrollView.setContentOffset(CGPoint(x: offsetX, y: scrollView.contentOffset.y), animated: animated)
//            }
//        }
        
//        guard index != selectedIndex else { return }
//        selectedIndex = index
//        delegate?.segementSwitcherView(self, didSelectAtIndex: index, animated: animated)
//    }
    
    private func updateSwitcher(at index: Int) {
        guard scrollView.frame != .zero else {
            initSelectedIndex = index
            return
        }
        guard titleButtons.count != 0 else { return }
        if let selectedIndex = selectedIndex, selectedIndex >= 0, selectedIndex < titleButtons.count {
            let titleButton = titleButtons[selectedIndex]
            titleButton.setTitleColor(innerConfig.normalTitleColor, for: .normal)
            titleButton.titleLabel?.font = innerConfig.normalTitleFont
        }
        guard index >= 0, index < titleButtons.count else { return }
        let titleButton = titleButtons[index]
        titleButton.setTitleColor(innerConfig.selectedTitleColor, for: .normal)
        titleButton.titleLabel?.font = innerConfig.selectedTitleFont
        
        var indicatorWidth = self.innerConfig.indicatorWidth
        if indicatorWidth == 0 {
            let title = titleButton.title(for: .normal) ?? ""
            indicatorWidth = title.boundingWidth(with: self.innerConfig.normalTitleFont)
        }
        self.indicatorView.frame = CGRect(x: titleButton.frame.origin.x+(titleButton.bounds.width-indicatorWidth)/2, y: self.frame.height-self.innerConfig.indicatorHeight, width: indicatorWidth, height: self.innerConfig.indicatorHeight)
    }
    
    private func updateSwitcherBySlide(fromIndex: Int, toIndex: Int, progress: CGFloat) {
        guard scrollView.frame != .zero, titleButtons.count != 0 else {
            return
        }
        
        let fromColor = config.selectedTitleColor.getColor(to: config.normalTitleColor, coe: progress)
        let toColor = config.normalTitleColor.getColor(to: config.selectedTitleColor, coe: progress)
        let fromFont = config.selectedTitleFont.getFont(to: config.normalTitleFont, coe: progress)
        let toFont = config.normalTitleFont.getFont(to: config.selectedTitleFont, coe: progress)
        titleButtons[fromIndex].setTitleColor(fromColor, for: .normal)
        titleButtons[toIndex].setTitleColor(toColor, for: .normal)
        titleButtons[fromIndex].titleLabel?.font = fromFont
        titleButtons[toIndex].titleLabel?.font = toFont
        
        let indicatorY = self.frame.height - self.innerConfig.indicatorHeight
        let indicatorHeight = self.innerConfig.indicatorHeight
        
        var fromWidth = self.innerConfig.indicatorWidth
        var toWidth = self.innerConfig.indicatorWidth
        if fromWidth == 0 {
            let fromTitle = titleButtons[fromIndex].title(for: .normal) ?? ""
            let toTitle = titleButtons[toIndex].title(for: .normal) ?? ""
            fromWidth = fromTitle.boundingWidth(with: self.innerConfig.normalTitleFont)
            toWidth = toTitle.boundingWidth(with: self.innerConfig.normalTitleFont)
        }
        
        let fromX = titleButtons[fromIndex].frame.midX - fromWidth/2
        let toX = titleButtons[toIndex].frame.midX - toWidth/2
        
        var frame = CGRect.zero
        if config.animateType == .progress {
            if fromIndex < toIndex {
                if progress < 0.5 {
                    let tX = fromX
                    let tWidth = fromWidth + (toX + toWidth - fromX - fromWidth) * 2 * progress
                    frame = CGRect(x: tX, y: indicatorY, width: tWidth, height: indicatorHeight)
                } else {
                    let tWidth = toWidth + (toX - fromX) * (1 - progress) * 2
                    let tX = toX + toWidth - tWidth
                    frame = CGRect(x: tX, y: indicatorY, width: tWidth, height: indicatorHeight)
                }
            } else {
                if progress < 0.5 {
                    let tX = fromX - (fromX - toX) * progress * 2
                    let tWidth = fromX - tX + fromWidth
                    frame = CGRect(x: tX, y: indicatorY, width: tWidth, height: indicatorHeight)
                } else {
                    let tX = toX
                    let tWidth = (fromX + fromWidth - toX - toWidth) * (progress - 0.5) * 2 + toWidth
                    frame = CGRect(x: tX, y: indicatorY, width: tWidth, height: indicatorHeight)
                }
            }
        } else {
            let tFromX = fromX + (toX - fromX) * progress
            let tWidth = fromWidth + (toWidth - fromWidth) * progress
            frame = CGRect(x: tFromX, y: indicatorY, width: tWidth, height:indicatorHeight)
        }
        
        self.indicatorView.frame = frame
    }
    
    private func selectSwitcherEvent(at index: Int, animated: Bool) {
        updateContentOffset(at: index, animated: animated)
        
        guard index != selectedIndex else { return }
        selectedIndex = index
        delegate?.segementSwitcherView(self, didSelectAtIndex: index, animated: animated)
    }
    
    private func updateContentOffset(at index: Int, animated: Bool) {
        if case .segement = innerConfig.type {
            let titleButton = titleButtons[index]
            var offsetX = titleButton.frame.origin.x-(scrollView.bounds.width-titleButton.bounds.width)/2
            if offsetX < 0 {
                offsetX = 0
            } else if (offsetX+scrollView.bounds.width) > scrollView.contentSize.width {
                offsetX = scrollView.contentSize.width-scrollView.bounds.width
            }
            if scrollView.contentSize.width > scrollView.bounds.width {
                scrollView.setContentOffset(CGPoint(x: offsetX, y: scrollView.contentOffset.y), animated: animated)
            }
        }
    }
    
    @objc private func didClickTitleButton(_ button: UIButton) {
//        selectSwitcher(at: button.tag, animated: true)
        selectSwitcherEvent(at: button.tag, animated: true)
    }
    
}
