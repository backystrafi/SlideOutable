//
//  SlideOutable.swift
//  SlideOutable
//
//  Created by Domas Nutautas on 20/05/16.
//  Copyright © 2016 Domas Nutautas. All rights reserved.
//

import UIKit

// MARK: - SlideOutable Implementation

/// View that presents header and scroll in a sliding manner.
public class SlideOutable: ClearContainerView {
    
    // MARK: Init
    
    /**
     Initializes and returns a newly allocated SlideOutable view object with specified scroll element.
     
     - Parameter frame: The `CGRect` to be passed for `UIView(frame:)` initializer. Defaults to `.zero`.
     - Parameter scroll: The `UIScrollView` that will be layed out in `SlideOutable` view's hierarchy.
     - Parameter header: The `UIView` to be added as a header above scroll - will be visible at all times. Make sure it's `bounds.height` is greater than 0 - it will be used as initial value for `minContentHeight`. Defaults to `nil`.
     
     - Returns: An initialized `SlideOutable` view object with `scroll` and optional `header` layed out in it's view hierarchy.
     */
    public init(frame: CGRect = .zero, scroll: UIScrollView, header: UIView? = nil) {
        
        super.init(frame: frame)
        
        self.header = header
        self.scroll = scroll
        self.lastScrollOffset = scroll.contentOffset.y
        
        setup()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override public func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }
    
    private func setup() {
        // Setup
        
        backgroundColor = .clearColor()
        
        // Scroll
        
        scroll.removeFromSuperview()
        scroll.translatesAutoresizingMaskIntoConstraints = true
        scroll.autoresizingMask = [.FlexibleWidth, .FlexibleTopMargin]
        scroll.frame = CGRect(x: 0, y: bounds.height - scroll.bounds.height,
                              width: bounds.width, height: scroll.bounds.height)
        scroll.alwaysBounceVertical = true
        scroll.keyboardDismissMode = .OnDrag
        addSubview(scroll)
        
        scroll.panGestureRecognizer.addTarget(self, action: #selector(SlideOutable.didPanScroll(_:)))
        
        scroll.addObserver(self, forKeyPath: "contentSize", options: .New, context: &scrollContentSizeContext)
        
        defer {
            updateScrollSize()
            update()
        }
        
        // Header
        
        guard let header = header else { return }
        
        assert(header.bounds.height >= 0, "`header` frame size height should be greater than 0")
        
        header.removeFromSuperview()
        header.translatesAutoresizingMaskIntoConstraints = true
        header.autoresizingMask = [.FlexibleWidth, .FlexibleTopMargin]
        header.frame = CGRect(x: 0, y: scroll.frame.minY - header.bounds.height,
                              width: bounds.width, height: header.bounds.height)
        minContentHeight = header.bounds.height
        addSubview(header)
        
        header.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(SlideOutable.didPanDrag(_:))))
    }
    
    deinit {
        scroll.removeObserver(self, forKeyPath: "contentSize", context: &scrollContentSizeContext)
    }
    
    // MARK: - Properties
    
    // MARK: Configurable

    /**
     The top padding that contents will not scroll on.
     
     Animatable.
     
     The default value is `0`.
     */
    @IBInspectable public dynamic var topPadding: CGFloat = 0 {
        didSet { update() }
    }
    
    /**
     The mid anchor fraction from `0` (the very bottom) to `1` the very top of the `SlideOutable` view bounds. Setting it to `nil` would disable the anchoring.
     
     Animatable.
     
     The default value is `0.4`.
     */
    @IBInspectable public var anchorFraction: CGFloat? = 0.4 {
        didSet { update() }
    }
    
    /**
     The minimum content visible content (header and scroll) height.
     
     Animatable.
     
     The default value is header's `bounds.height` or `120` if header is not set.
     */
    @IBInspectable public dynamic var minContentHeight: CGFloat = 120 {
        didSet { update() }
    }
    
    /**
     Proxy for `minimumContentHeight` without header's `bounds.height`.
     
     Animatable.
     */
    @IBInspectable public var minScrollHeight: CGFloat {
        get { return minContentHeight - (header?.bounds.height ?? 0) }
        set { minContentHeight = newValue + (header?.bounds.height ?? 0) }
    }
    
    /**
     Determens weather the scroll's `bounds.height` can get bigger than it's `contentSize.height`.
     
     Animatable.
     
     The default value is `true`.
     */
    @IBInspectable public var isScrollStretchable: Bool = true {
        didSet { update() }
    }
    
    /// The delegate of `SlideOutable` object.
    public weak var delegate: SlideOutableDelegate?
    
    // MARK: Private
    
    // UI
    @IBOutlet public var header: UIView?
    @IBOutlet public var scroll: UIScrollView!
    
    // Offsets
    var lastScrollOffset: CGFloat = 0
    var lastDragOffset: CGFloat = 0
    
    // MARK: Computed
    
    /// Returns the current offest of `SlideOutable` object.
    public internal(set) var currentOffset: CGFloat {
        get {
            return (header ?? scroll).frame.minY
        }
        set {
            guard newValue != currentOffset else { return }
            
            // Save last state
            lastState = state(forOffset: newValue)
            
            // Change state
            header?.frame.origin.y = newValue
            scroll.frame.origin.y = header?.frame.maxY ?? newValue
            
            // Notifies `delegate`
            delegate?.slideOutable(self, stateChanged: stateForDelegate)
        }
    }
    
    /// Returns the current visible height of `SlideOutable` object.
    public var currentVisibleHeight: CGFloat {
        return bounds.height - currentOffset
    }
    
    var minOffset: CGFloat { return isScrollStretchable ? topPadding : max(topPadding, bounds.height - (header?.bounds.height ?? 0) - scroll.contentSize.height) }
    var maxOffset: CGFloat { return max(minOffset, bounds.height - minContentHeight) }
    var anchorOffset: CGFloat? { return anchorFraction.flatMap { bounds.height * (1 - $0) } }
    
    var snapOffsets: [CGFloat] {
        return [maxOffset, anchorOffset].reduce([minOffset]) { offsets, offset in
            guard let offset = offset where offset > minOffset else { return offsets }
            return offsets + [offset]
        }
    }
    
    // MARK: - Scroll content size KVO
    
    private var scrollContentSizeContext = 0

    public override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        guard context == &scrollContentSizeContext else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
            return
        }
        guard !isScrollStretchable else { return }
        update()
    }
    
    // MARK: - State
    
    /// The state options of `SlideOutable` content.
    public enum State {
        public enum Settle {
            /// The contents are fully expanded.
            case expanded
            /// The contents are anchored to specified `anchorPoint`.
            case anchored
            /// The contents are fully collapsed.
            case collapsed
        }
        /// The contents are settled in one of the `Settle` cases.
        case settled(Settle)
        /// The contents are being interacted with.
        case dragging(offset: CGFloat)
    }
    
    /**
     Sets the `SlideOutable` view's state to specified `Settle` case. If there is no `anchorFraction` specified then `.anchored` will be ignored.
     
     Animatable.
     */
    public func set(state state: State.Settle) {
        lastState = .settled(state)
        guard let newOffset = offset(forState: state) else { return }
        currentOffset = newOffset
    }
    
    /// Returns the current state of `SlideOutable` view.
    public var state: State {
        return state(forOffset: currentOffset)
    }
    
    func state(forOffset offset: CGFloat) -> State {
        switch offset {
        case minOffset:
            return .settled(.expanded)
        case anchorOffset ?? minOffset: // Makes compiler happy, dev sad :(
            return .settled(.anchored)
        case maxOffset:
            return .settled(.collapsed)
        default:
            return .dragging(offset: currentOffset)
        }
    }
    
    lazy var lastState: State = self.state
    
    func offset(forState state: State.Settle) -> CGFloat? {
        switch state {
        case .expanded:
            return minOffset
        case .anchored:
            return anchorOffset
        case .collapsed:
            return maxOffset
        }
    }
    
    var stateForDelegate: State {
        let isAnyGestureActive = header?.gestureRecognizers?.first?.isActive ?? scroll.panGestureRecognizer.isActive
        guard isAnyGestureActive else { return state }
        return .dragging(offset: currentOffset)
    }
    
    // MARK: - Interaction
    
    enum Interaction {
        case scroll
        case drag
        
        enum Direction {
            case up
            case down
        }
        
        init(direction: Direction, in state: State, scrolledToTop: Bool) {
            let scrollingToContentTop = !scrolledToTop && direction == .down
            if scrollingToContentTop {
                self = .scroll
            } else if case .settled(let settle) = state where settle == .expanded {
                switch direction {
                case .up:   self = .scroll
                case .down: self = .drag
                }
            } else {
                self = .drag
            }
        }
    }
    
    func interaction(forDirection direction: Interaction.Direction) -> Interaction {
        return Interaction(direction: direction, in: state, scrolledToTop: scroll.contentOffset.y <= 0)
    }
    func interaction(scrollView scrollView: UIScrollView) -> Interaction {
        // Enable bouncing
        if case .settled = state where scrollView.decelerating {
            return .scroll
        } else {
            return interaction(forDirection: lastScrollOffset > scrollView.contentOffset.y ? .down : .up)
        }
    }
    func interaction(pan pan: UIPanGestureRecognizer) -> Interaction {
        return interaction(forDirection: pan.velocityInView(pan.view).y > 0 ? .down : .up)
    }
    
    // MARK: - Updates
    
    public override var frame: CGRect {
        didSet {
            updateScrollSize()
            update()
        }
    }
    
    public override var bounds: CGRect {
        didSet {
            updateScrollSize()
            update()
        }
    }
    
    func updateScrollSize() {
        scroll?.frame.size = CGSize(width: bounds.width, height: bounds.height - (header?.bounds.height ?? 0) - topPadding)
    }
    
    func update(animated animated: Bool = false, to targetOffset: CGFloat? = nil, velocity: CGFloat? = nil, keepLastState: Bool = true) {
        
        guard scroll != nil else { return }
        
        // Get actual target
        let target: CGFloat
        if let targetOffset = targetOffset {
            target = targetOffset
        } else if keepLastState, case .settled(let settled) = lastState, let settledOffset = self.offset(forState: settled) {
            target = settledOffset
        } else {
            target = currentOffset
        }
        
        // Get actual offset
        let offset: CGFloat = snapOffsets.dropFirst().reduce(snapOffsets[0]) { closest, current in
            let closestDiff = abs(target - closest)
            let currentDiff = abs(target - current)
            return closestDiff < currentDiff ? closest : current
        }
        
        guard offset != currentOffset else { return }
        
        guard animated else {
            currentOffset = offset
            return
        }
        
        // Stop scroll decelerate
        scroll.stopDecelerating()
        
        // To make sure scroll bottom does not get higher than container bottom during animation spring bounce.
        let antiBounce: CGFloat = 1000
        scroll.frame.size.height += antiBounce
        scroll.contentInset.bottom += antiBounce
        
        // Animate to new height
        UIView.animateWithDuration(0.5, delay: 0,
                                   usingSpringWithDamping: 0.8,
                                   initialSpringVelocity: velocity.flatMap { abs($0 / (currentOffset - offset)) } ?? 1,
                                   options: .CurveLinear,
                                   animations: { self.currentOffset = offset },
                                   completion: { _ in
                                    self.updateScrollSize()
                                    self.scroll.contentInset.bottom -= antiBounce
        })
    }
}

// MARK: - Scrolling

extension UIScrollView {
    func stopDecelerating() {
        setContentOffset(contentOffset, animated: false)
    }
}

extension SlideOutable {
    func didPanScroll(pan: UIPanGestureRecognizer) {
        if pan.state == .Began {
            header?.gestureRecognizers?.first?.stopCurrentGesture()
        }
        
        switch interaction(pan: pan) {
        case .scroll:
            
            scroll.scrollIndicatorInsets.bottom = max(0, scroll.frame.maxY - bounds.height)
            scroll.showsVerticalScrollIndicator = true
            
            lastScrollOffset = scroll.contentOffset.y
            lastDragOffset = pan.translationInView(pan.view).y
            
            guard pan.state == .Ended, case .dragging = state else { break }
            didPanDrag(pan)
            
        case .drag:
            if lastScrollOffset > 0 && 0 > scroll.contentOffset.y {
                // Accounts for missed content offset switching from .scroll to .drag
                lastDragOffset += lastScrollOffset
                
                lastScrollOffset = 0
            }
            scroll.showsVerticalScrollIndicator = false
            scroll.contentOffset.y = lastScrollOffset
            
            // Forwards interaction
            didPanDrag(pan)
        }
    }
}

// MARK: - Dragging

extension SlideOutable {
    func offset(forDiff diff: CGFloat) -> (value: CGFloat, clipped: CGFloat)? {
        guard diff != 0 else { return nil }
        
        let targetOffset = currentOffset - diff
        let offset = min(maxOffset, max(minOffset, targetOffset))
        return (offset, offset - targetOffset)
    }
    
    func didPanDrag(pan: UIPanGestureRecognizer) {
        let dragOffset = pan.translationInView(pan.view).y
        var diff = lastDragOffset - dragOffset
        
        let isScrollPan = scroll.panGestureRecognizer == pan
        
        switch pan.state {
        case .Began where !isScrollPan:
            scroll.panGestureRecognizer.stopCurrentGesture()
            
        case .Changed:
            // If starts dragging while scroll is in a bounce
            if lastScrollOffset < 0 {
                if isScrollPan {
                    diff -= lastScrollOffset
                }
                lastScrollOffset = 0
                scroll.contentOffset.y = 0
            }
            
            guard let offset = offset(forDiff: diff) else { break }
            currentOffset = offset.value
            
            // Accounts for clipped pan switching from .drag to .scroll
            guard offset.clipped != 0 && isScrollPan else { break }
            scroll.contentOffset.y += offset.clipped
            
        case .Ended:
            let velocity = pan.velocityInView(pan.view).y
            let targetOffset = currentOffset - diff + 0.2 * velocity
            update(animated: true, to: targetOffset, velocity: velocity, keepLastState: false)
        default: break
        }
        
        lastDragOffset = dragOffset
    }
}

extension UIGestureRecognizer {
    func stopCurrentGesture() {
        enabled = !enabled
        enabled = !enabled
    }
    var isActive: Bool {
        return [.Began, .Changed].contains(state)
    }
}
