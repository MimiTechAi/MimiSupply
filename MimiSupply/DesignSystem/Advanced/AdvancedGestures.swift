//
//  AdvancedGestures.swift
//  MimiSupply
//
//  Created by Alex on 15.08.25.
//

import SwiftUI

// MARK: - Gesture Value Types

/// Multi-touch gesture value
struct MultiTouchValue: Equatable {
    var touches: [CGPoint] = []
    var center: CGPoint = .zero
    var distance: CGFloat = 0
    var angle: Angle = .zero
    
    static func == (lhs: MultiTouchValue, rhs: MultiTouchValue) -> Bool {
        return lhs.center == rhs.center &&
               lhs.distance == rhs.distance &&
               lhs.angle == rhs.angle
    }
}

/// Swipe gesture value with velocity and direction
struct SwipeValue: Equatable {
    var startLocation: CGPoint = .zero
    var location: CGPoint = .zero
    var translation: CGSize = .zero
    var velocity: CGSize = .zero
    var direction: SwipeDirection = .none
    var distance: CGFloat = 0
    
    enum SwipeDirection: Equatable {
        case none, up, down, left, right
        
        static func from(translation: CGSize) -> SwipeDirection {
            let angle = atan2(translation.height, translation.width)
            let degrees = angle * 180 / .pi
            
            switch degrees {
            case -45...45: return .right
            case 45...135: return .down
            case 135...180, -180...(-135): return .left
            case -135...(-45): return .up
            default: return .none
            }
        }
    }
    
    static func == (lhs: SwipeValue, rhs: SwipeValue) -> Bool {
        return lhs.location == rhs.location &&
               lhs.translation == rhs.translation &&
               lhs.direction == rhs.direction
    }
}

/// Progress-based long press value
struct ProgressValue: Equatable {
    var isActive: Bool = false
    var progress: Double = 0.0
    var location: CGPoint = .zero
    var startTime: Date = Date()
    
    var elapsed: TimeInterval {
        Date().timeIntervalSince(startTime)
    }
    
    static func == (lhs: ProgressValue, rhs: ProgressValue) -> Bool {
        return lhs.isActive == rhs.isActive &&
               abs(lhs.progress - rhs.progress) < 0.001 &&
               lhs.location == rhs.location
    }
}

/// Drawing gesture value
struct DrawingValue: Equatable {
    var points: [CGPoint] = []
    var currentStroke: [CGPoint] = []
    var isDrawing: Bool = false
    var boundingBox: CGRect = .zero
    var totalDistance: CGFloat = 0
    
    var recognizedShape: RecognizedShape? {
        return ShapeRecognizer.recognize(points: points)
    }
    
    static func == (lhs: DrawingValue, rhs: DrawingValue) -> Bool {
        return lhs.points == rhs.points &&
               lhs.isDrawing == rhs.isDrawing &&
               lhs.boundingBox == rhs.boundingBox
    }
}

// MARK: - Shape Recognition System

struct ShapeRecognizer {
    static func recognize(points: [CGPoint]) -> RecognizedShape? {
        guard points.count > 10 else { return nil }
        
        let boundingBox = calculateBoundingBox(points: points)
        
        // Simple shape recognition logic
        if isCircleShape(points: points, boundingBox: boundingBox) {
            return .circle
        } else if isRectangleShape(points: points, boundingBox: boundingBox) {
            return .rectangle
        } else if isLineShape(points: points) {
            return .line
        }
        
        return .unknown
    }
    
    private static func calculateBoundingBox(points: [CGPoint]) -> CGRect {
        guard !points.isEmpty else { return .zero }
        
        let minX = points.map { $0.x }.min() ?? 0
        let maxX = points.map { $0.x }.max() ?? 0
        let minY = points.map { $0.y }.min() ?? 0
        let maxY = points.map { $0.y }.max() ?? 0
        
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
    
    private static func isCircleShape(points: [CGPoint], boundingBox: CGRect) -> Bool {
        let center = CGPoint(x: boundingBox.midX, y: boundingBox.midY)
        let radius = min(boundingBox.width, boundingBox.height) / 2
        
        let distances = points.map { point in
            sqrt(pow(point.x - center.x, 2) + pow(point.y - center.y, 2))
        }
        
        let averageDistance = distances.reduce(0, +) / Double(distances.count)
        let variance = distances.map { pow($0 - averageDistance, 2.0) }.reduce(0, +) / Double(distances.count)
        
        return variance < radius * 0.3 // Tolerance for circle detection
    }
    
    private static func isRectangleShape(points: [CGPoint], boundingBox: CGRect) -> Bool {
        // Check if points roughly follow rectangle edges
        let tolerance: CGFloat = 20
        let nearEdgeCount = points.filter { point in
            abs(point.x - boundingBox.minX) < tolerance ||
            abs(point.x - boundingBox.maxX) < tolerance ||
            abs(point.y - boundingBox.minY) < tolerance ||
            abs(point.y - boundingBox.maxY) < tolerance
        }.count
        
        return Double(nearEdgeCount) / Double(points.count) > 0.7
    }
    
    private static func isLineShape(points: [CGPoint]) -> Bool {
        guard points.count >= 2 else { return false }
        
        let firstPoint = points.first!
        let lastPoint = points.last!
        
        // Check if most points are close to the line between first and last point
        let tolerance: CGFloat = 15
        let onLineCount = points.filter { point in
            distanceFromPointToLine(point: point, lineStart: firstPoint, lineEnd: lastPoint) < tolerance
        }.count
        
        return Double(onLineCount) / Double(points.count) > 0.8
    }
    
    private static func distanceFromPointToLine(point: CGPoint, lineStart: CGPoint, lineEnd: CGPoint) -> CGFloat {
        let A = point.x - lineStart.x
        let B = point.y - lineStart.y
        let C = lineEnd.x - lineStart.x
        let D = lineEnd.y - lineStart.y
        
        let dot = A * C + B * D
        let lenSq = C * C + D * D
        
        guard lenSq != 0 else { return sqrt(A * A + B * B) }
        
        let param = dot / lenSq
        
        let xx: CGFloat
        let yy: CGFloat
        
        if param < 0 {
            xx = lineStart.x
            yy = lineStart.y
        } else if param > 1 {
            xx = lineEnd.x
            yy = lineEnd.y
        } else {
            xx = lineStart.x + param * C
            yy = lineStart.y + param * D
        }
        
        let dx = point.x - xx
        let dy = point.y - yy
        
        return sqrt(dx * dx + dy * dy)
    }
}

// MARK: - Advanced Gesture Modifiers

struct InteractiveCardModifier: ViewModifier {
    @State private var dragOffset = CGSize.zero
    @State private var scale: CGFloat = 1.0
    @State private var rotation: Angle = .zero
    @State private var isLongPressed = false
    
    let onSwipe: ((SwipeValue.SwipeDirection) -> Void)?
    let onLongPress: (() -> Void)?
    let onDoubleTap: (() -> Void)?
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .rotationEffect(rotation)
            .offset(dragOffset)
            .scaleEffect(isLongPressed ? 1.1 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: dragOffset)
            .animation(.spring(response: 0.2, dampingFraction: 0.9), value: scale)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isLongPressed)
            .gesture(
                SimultaneousGesture(
                    // Drag gesture
                    DragGesture()
                        .onChanged { value in
                            dragOffset = value.translation
                        }
                        .onEnded { value in
                            let swipeDirection = SwipeValue.SwipeDirection.from(translation: value.translation)
                            
                            if abs(value.translation.width) > 100 || abs(value.translation.height) > 100 {
                                onSwipe?(swipeDirection)
                            }
                            
                            withAnimation(.spring()) {
                                dragOffset = .zero
                            }
                        },
                    
                    // Magnification gesture
                    MagnifyGesture()
                        .onChanged { value in
                            scale = value.magnification
                        }
                        .onEnded { _ in
                            withAnimation(.spring()) {
                                scale = 1.0
                            }
                        }
                )
            )
            .simultaneousGesture(
                // Rotation gesture
                RotateGesture()
                    .onChanged { value in
                        rotation = value.rotation
                    }
                    .onEnded { _ in
                        withAnimation(.spring()) {
                            rotation = .zero
                        }
                    }
            )
            .onLongPressGesture(minimumDuration: 0.5) {
                onLongPress?()
                withAnimation(.spring()) {
                    isLongPressed = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.spring()) {
                        isLongPressed = false
                    }
                }
            }
            .onTapGesture(count: 2) {
                onDoubleTap?()
            }
    }
}

/// Magnetic snap gesture
struct MagneticSnapModifier: ViewModifier {
    let snapPoints: [CGPoint]
    let snapDistance: CGFloat
    
    @State private var currentPosition = CGPoint.zero
    @State private var dragOffset = CGSize.zero
    
    func body(content: Content) -> some View {
        content
            .position(x: currentPosition.x + dragOffset.width, y: currentPosition.y + dragOffset.height)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                        let finalPosition = CGPoint(
                            x: currentPosition.x + value.translation.width,
                            y: currentPosition.y + value.translation.height
                        )
                        
                        // Find nearest snap point
                        if let nearestSnap = findNearestSnapPoint(to: finalPosition) {
                            withAnimation(.spring()) {
                                currentPosition = nearestSnap
                                dragOffset = .zero
                            }
                        } else {
                            withAnimation(.spring()) {
                                currentPosition = finalPosition
                                dragOffset = .zero
                            }
                        }
                    }
            )
    }
    
    private func findNearestSnapPoint(to position: CGPoint) -> CGPoint? {
        return snapPoints.first { snapPoint in
            let distance = sqrt(
                pow(position.x - snapPoint.x, 2) + pow(position.y - snapPoint.y, 2)
            )
            return distance <= snapDistance
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Add advanced interactive card gestures
    func interactiveCard(
        onSwipe: ((SwipeValue.SwipeDirection) -> Void)? = nil,
        onLongPress: (() -> Void)? = nil,
        onDoubleTap: (() -> Void)? = nil
    ) -> some View {
        self.modifier(InteractiveCardModifier(
            onSwipe: onSwipe,
            onLongPress: onLongPress,
            onDoubleTap: onDoubleTap
        ))
    }
    
    /// Add magnetic snap behavior
    func magneticSnap(
        to points: [CGPoint],
        distance: CGFloat = 50
    ) -> some View {
        self.modifier(MagneticSnapModifier(
            snapPoints: points,
            snapDistance: distance
        ))
    }
    
    /// Add velocity-based swipe detection
    func velocitySwipe(
        minimumDistance: CGFloat = 20,
        coordinateSpace: CoordinateSpace = .local,
        onSwipe: @escaping (SwipeValue) -> Void
    ) -> some View {
        self.gesture(
            DragGesture(minimumDistance: minimumDistance, coordinateSpace: coordinateSpace)
                .onEnded { value in
                    let swipeValue = SwipeValue(
                        startLocation: value.startLocation,
                        location: value.location,
                        translation: value.translation,
                        velocity: CGSize(
                            width: value.predictedEndLocation.x - value.location.x,
                            height: value.predictedEndLocation.y - value.location.y
                        ),
                        direction: SwipeValue.SwipeDirection.from(translation: value.translation),
                        distance: sqrt(pow(value.translation.width, 2) + pow(value.translation.height, 2))
                    )
                    onSwipe(swipeValue)
                }
        )
    }
    
    /// Add progress-based long press
    func progressLongPress(
        minimumDuration: Double = 0.5,
        maximumDistance: CGFloat = 10,
        onProgress: @escaping (ProgressValue) -> Void
    ) -> some View {
        self.gesture(
            LongPressGesture(minimumDuration: minimumDuration, maximumDistance: maximumDistance)
                .onEnded { _ in
                    let progressValue = ProgressValue(
                        isActive: true,
                        progress: 1.0,
                        location: .zero,
                        startTime: Date()
                    )
                    onProgress(progressValue)
                }
        )
    }
    
    /// Add drawing gesture recognition
    func drawingGesture(
        onDraw: @escaping (DrawingValue) -> Void
    ) -> some View {
        self.gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let drawingValue = DrawingValue(
                        points: [value.location],
                        currentStroke: [value.location],
                        isDrawing: true,
                        boundingBox: CGRect(origin: value.location, size: .zero),
                        totalDistance: 0
                    )
                    onDraw(drawingValue)
                }
        )
    }
}