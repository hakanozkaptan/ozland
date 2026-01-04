import SwiftUI

/// Scrolling text view for long track/artist names
struct ScrollingText: View {
    let text: String
    let font: Font
    let color: Color
    @State private var scrollOffset: CGFloat = 0
    @State private var textWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Invisible text to measure width
                Text(text)
                    .font(font)
                    .background(GeometryReader { textGeometry in
                        Color.clear
                            .onAppear {
                                textWidth = textGeometry.size.width
                                containerWidth = geometry.size.width
                                if textWidth > containerWidth {
                                    startScrolling()
                                }
                            }
                            .onChange(of: text) {
                                textWidth = textGeometry.size.width
                                containerWidth = geometry.size.width
                                scrollOffset = 0
                                if textWidth > containerWidth {
                                    startScrolling()
                                }
                            }
                    })
                    .opacity(0)
                
                // Visible scrolling text
                Text(text)
                    .font(font)
                    .foregroundColor(color)
                    .offset(x: scrollOffset)
            }
            .clipped()
            .onAppear {
                containerWidth = geometry.size.width
            }
        }
    }
    
    private func startScrolling() {
        guard textWidth > containerWidth else { return }
        
        // Wait before starting scroll
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.linear(duration: Double(textWidth / 30))) {
                scrollOffset = containerWidth - textWidth - 20
            }
            
            // Wait at end, then scroll back
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(textWidth / 30) + 1.0) {
                withAnimation(.linear(duration: Double(textWidth / 30))) {
                    scrollOffset = 0
                }
                
                // Repeat after pause
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(textWidth / 30) + 1.5) {
                    startScrolling()
                }
            }
        }
    }
}

