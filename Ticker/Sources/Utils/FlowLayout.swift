//
//  FlowLayout.swift
//  fig
//
//  Created by Mayank Gandhi on 11/10/25.
//

import SwiftUI

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    init(spacing: CGFloat) {
        self.spacing = spacing
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        // Handle infinite width proposals properly
        let containerWidth: CGFloat
        if let proposedWidth = proposal.width, proposedWidth.isFinite {
            containerWidth = proposedWidth
        } else {
            // If width is infinite or unspecified, calculate based on subview sizes
            // Use a reasonable maximum (screen width) or calculate minimum required width
            let maxSubviewWidth = subviews.map { $0.sizeThatFits(.unspecified).width }.max() ?? 0
            let totalWidth = subviews.reduce(0) { $0 + $1.sizeThatFits(.unspecified).width + spacing } - spacing
            // Use the larger of: max subview width, or total width if all fit on one line
            // But cap at a reasonable maximum (e.g., 1000 points for very wide screens)
            containerWidth = min(max(maxSubviewWidth, totalWidth), 1000)
        }
        
        let result = FlowResult(
            in: containerWidth,
            subviews: subviews,
            spacing: spacing
        )
        
        // If proposal width is finite, expand to fill available width (like .frame(maxWidth: .infinity))
        // Otherwise return the calculated size
        if let proposedWidth = proposal.width, proposedWidth.isFinite {
            return CGSize(width: proposedWidth, height: result.size.height)
        }
        
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX, y: bounds.minY + result.frames[index].minY), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var frames: [CGRect] = []
        var size: CGSize = .zero
        
        init(in containerWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            var maxX: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > containerWidth && currentX > 0 {
                    // Move to next line
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
                
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
                maxX = max(maxX, currentX - spacing)
            }
            
            self.size = CGSize(width: maxX, height: currentY + lineHeight)
        }
    }
}
