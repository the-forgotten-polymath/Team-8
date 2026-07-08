//
//  SwipeToOrderButton.swift
//  RSMS_Project
//
//  Created by Antigravity on 02/07/26.
//

import SwiftUI

struct SwipeToOrderButton: View {
    @State private var dragOffset: CGFloat = 0
    @State private var isCompleted = false
    
    let isLocked: Bool
    let onSwipeSuccess: () -> Void
    
    private let buttonHeight: CGFloat = 58
    private let thumbSize: CGFloat = 50
    private let padding: CGFloat = 4
    
    var body: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let maxDragDistance = totalWidth - thumbSize - (padding * 2)
            
            ZStack(alignment: .leading) {
                // Background Track
                Capsule()
                    .fill(Color(.systemGray5))
                
                // Track Fill (Left to right)
                Capsule()
                    .fill(Color.blue)
                    .frame(width: max(thumbSize + (padding * 2), dragOffset + thumbSize + (padding * 2)))
                
                // Track Text "Swipe to Order"
                Text(isCompleted ? "Submitting Request..." : "Swipe to Order")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(isCompleted ? .white : .primary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    // Fade out text as we slide
                    .opacity(isCompleted ? 1.0 : Double(1.0 - (dragOffset / maxDragDistance)))
                
                // Drag Thumb
                Circle()
                    .fill(Color.white)
                    .frame(width: thumbSize, height: thumbSize)
                    .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                    .overlay(
                        Image(systemName: isCompleted ? "checkmark" : "chevron.right.2")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.blue)
                    )
                    .padding(.leading, padding)
                    .offset(x: dragOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                guard !isLocked && !isCompleted else { return }
                                if value.translation.width > 0 {
                                    dragOffset = min(value.translation.width, maxDragDistance)
                                }
                            }
                            .onEnded { value in
                                guard !isLocked && !isCompleted else { return }
                                if dragOffset >= maxDragDistance * 0.9 {
                                    // Trigger success
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        dragOffset = maxDragDistance
                                        isCompleted = true
                                    }
                                    let generator = UINotificationFeedbackGenerator()
                                    generator.notificationOccurred(.success)
                                    onSwipeSuccess()
                                } else {
                                    // Snap back
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                        dragOffset = 0
                                    }
                                }
                            }
                    )
            }
        }
        .frame(height: buttonHeight)
        .disabled(isLocked || isCompleted)
        .onChange(of: isLocked) { _, locked in
            if !locked {
                // If unlocked/reset, reset the button state
                withAnimation {
                    dragOffset = 0
                    isCompleted = false
                }
            }
        }
    }
}
