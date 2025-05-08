import SwiftUI

struct Theme {
    // MARK: - Colors
    
    static let primaryPurple = Color(red: 0.6, green: 0.2, blue: 0.8)
    static let electricBlue = Color(red: 0.2, green: 0.6, blue: 1.0)
    static let neonPink = Color(red: 1.0, green: 0.2, blue: 0.6)
    
    static let backgroundDark = Color(red: 0.1, green: 0.1, blue: 0.12)
    static let backgroundLight = Color(red: 0.95, green: 0.95, blue: 0.97)
    
    static let textPrimary = Color.white
    static let textSecondary = Color.gray
    
    // MARK: - Gradients
    
    static let primaryGradient = LinearGradient(
        colors: [primaryPurple, electricBlue],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let swipeLeftGradient = LinearGradient(
        colors: [Color.red.opacity(0.7), Color.red.opacity(0.3)],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let swipeRightGradient = LinearGradient(
        colors: [Color.green.opacity(0.7), Color.green.opacity(0.3)],
        startPoint: .trailing,
        endPoint: .leading
    )
    
    static let swipeUpGradient = LinearGradient(
        colors: [neonPink.opacity(0.7), neonPink.opacity(0.3)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // MARK: - Typography
    
    struct Typography {
        static let titleFont = Font.system(size: 28, weight: .bold, design: .rounded)
        static let headlineFont = Font.system(size: 20, weight: .semibold, design: .rounded)
        static let bodyFont = Font.system(size: 16, weight: .regular, design: .rounded)
        static let captionFont = Font.system(size: 14, weight: .medium, design: .rounded)
    }
    
    // MARK: - Layout
    
    struct Layout {
        static let cornerRadius: CGFloat = 16
        static let padding: CGFloat = 16
        static let smallPadding: CGFloat = 8
        static let iconSize: CGFloat = 24
        static let swipeThreshold: CGFloat = 100
    }
    
    // MARK: - Animation
    
    struct Animation {
        static let spring = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)
        static let easeOut = SwiftUI.Animation.easeOut(duration: 0.2)
        static let easeIn = SwiftUI.Animation.easeIn(duration: 0.2)
    }
} 