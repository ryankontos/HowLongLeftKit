//
//  ProgressCircle.swift
//  HowLongLeftKit
//
//  Created by Ryan on 21/11/2024.
//

import SwiftUI

public struct ProgressCircle<Content: View>: View {
    // Customisation properties
    var progress: CGFloat
    var lineWidth: CGFloat
    var trackColor: Color
    var progressColor: Color
    var isRounded: Bool
    var size: CGFloat
    let content: Content
    
    // Initializer
    public init(progress: CGFloat,
         lineWidth: CGFloat = 10,
         trackColor: Color = Color.gray.opacity(0.3),
         progressColor: Color = .blue,
         isRounded: Bool = true,
         size: CGFloat = 100,
         @ViewBuilder content: () -> Content) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.trackColor = trackColor
        self.progressColor = progressColor
        self.isRounded = isRounded
        self.size = size
        self.content = content()
    }
    
    public var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(trackColor, style: StrokeStyle(lineWidth: lineWidth))
            
            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(progressColor.gradient, style: StrokeStyle(
                    lineWidth: lineWidth,
                    lineCap: isRounded ? .round : .square
                ))
                .rotationEffect(.degrees(-90)) // Start at top
                .animation(.easeInOut, value: progress) // Animate changes
            
            // Center content
            content
        }
        .frame(width: size, height: size)
    }
}

// Preview for testing
struct CircularProgressView_Previews: PreviewProvider {
    static var previews: some View {
        ProgressCircle(progress: 0.75,
                             lineWidth: 15,
                             trackColor: .gray,
                             progressColor: .green,
                             isRounded: true,
                             size: 150) {
            Text("75%")
                .font(.title)
                .bold()
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
