import SwiftUI

// MARK: - Theme System
enum AppTheme: String, CaseIterable, Codable {
    case oledBlack = "OLED Black"
    case psychedelicNeon = "Psychedelic Neon"

    var colorPalette: ThemeColorPalette {
        switch self {
        case .oledBlack:
            return OLEDBlackPalette()
        case .psychedelicNeon:
            return PsychedelicNeonPalette()
        }
    }
}

// MARK: - Theme Color Palette Protocol
protocol ThemeColorPalette {
    var background: Color { get }
    var sidebar: Color { get }
    var surface: Color { get }
    var surfaceHover: Color { get }
    var surfaceSelected: Color { get }

    var textPrimary: Color { get }
    var textSecondary: Color { get }
    var textTertiary: Color { get }

    var accentGreen: Color { get }
    var accentBlue: Color { get }
    var accentOrange: Color { get }
    var accentRed: Color { get }

    var divider: Color { get }
    var border: Color { get }
}

// MARK: - OLED Black Theme
struct OLEDBlackPalette: ThemeColorPalette {
    let background = Color(hex: "#000000")
    let sidebar = Color(hex: "#000000")
    let surface = Color.white.opacity(0.02)
    let surfaceHover = Color.white.opacity(0.04)
    let surfaceSelected = Color.white.opacity(0.06)

    let textPrimary = Color.white
    let textSecondary = Color(hex: "#B3B3B3")
    let textTertiary = Color(hex: "#7F7F7F")

    let accentGreen = Color(hex: "#1DB954")
    let accentBlue = Color(hex: "#1E90FF")
    let accentOrange = Color(hex: "#FF9500")
    let accentRed = Color(hex: "#FF3B30")

    let divider = Color.white.opacity(0.1)
    let border = Color.white.opacity(0.15)
}

// MARK: - Daylight White Theme
struct DaylightWhitePalette: ThemeColorPalette {
    let background = Color(hex: "#FFFFFF")
    let sidebar = Color(hex: "#F5F5F5")
    let surface = Color(hex: "#FCFCFC")
    let surfaceHover = Color(hex: "#F8F8F8")
    let surfaceSelected = Color(hex: "#F2F2F2")

    let textPrimary = Color(hex: "#000000")
    let textSecondary = Color(hex: "#666666")
    let textTertiary = Color(hex: "#999999")

    let accentGreen = Color(hex: "#28A745")
    let accentBlue = Color(hex: "#007AFF")
    let accentOrange = Color(hex: "#FF9500")
    let accentRed = Color(hex: "#DC3545")

    let divider = Color.black.opacity(0.1)
    let border = Color.black.opacity(0.2)
}

// MARK: - Millennial Greige Theme
struct MillennialGreigePalette: ThemeColorPalette {
    let background = Color(hex: "#E8E2DB")
    let sidebar = Color(hex: "#D4CFC7")
    let surface = Color(hex: "#E0DAD3")
    let surfaceHover = Color(hex: "#DDD7D0")
    let surfaceSelected = Color(hex: "#C9BCA8")

    let textPrimary = Color(hex: "#4A4A4A")
    let textSecondary = Color(hex: "#787878")
    let textTertiary = Color(hex: "#6B6860")

    let accentGreen = Color(hex: "#8B9D83")
    let accentBlue = Color(hex: "#7B9AA8")
    let accentOrange = Color(hex: "#D4A574")
    let accentRed = Color(hex: "#C17B6C")

    let divider = Color(hex: "#C9BCA8").opacity(0.5)
    let border = Color(hex: "#A89B8C").opacity(0.3)
}

// MARK: - Psychedelic Neon Theme
struct PsychedelicNeonPalette: ThemeColorPalette {
    let background = Color(hex: "#0A0E27")
    let sidebar = Color(hex: "#1A1F3A")
    let surface = Color(hex: "#1F2440")
    let surfaceHover = Color(hex: "#282E4A")
    let surfaceSelected = Color(hex: "#323850")

    let textPrimary = Color(hex: "#00FF00")
    let textSecondary = Color(hex: "#FF00FF")
    let textTertiary = Color(hex: "#00FFFF")

    let accentGreen = Color(hex: "#00FF00")
    let accentBlue = Color(hex: "#00FFFF")
    let accentOrange = Color(hex: "#FFFF00")
    let accentRed = Color(hex: "#FF0080")

    let divider = Color(hex: "#FF00FF").opacity(0.3)
    let border = Color(hex: "#00FFFF").opacity(0.5)
}

// MARK: - Theme Manager (ObservableObject for SwiftUI)
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published var currentTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "selectedTheme")
        }
    }

    private init() {
        let savedTheme = UserDefaults.standard.string(forKey: "selectedTheme") ?? AppTheme.oledBlack.rawValue
        self.currentTheme = AppTheme(rawValue: savedTheme) ?? .oledBlack
    }

    var colors: ThemeColorPalette {
        currentTheme.colorPalette
    }
}

// MARK: - FreshUI Design System
struct FreshUI {
    // MARK: - Colors (Dynamic based on current theme)
    struct Colors {
        static var background: Color { ThemeManager.shared.colors.background }
        static var sidebar: Color { ThemeManager.shared.colors.sidebar }
        static var surface: Color { ThemeManager.shared.colors.surface }
        static var surfaceHover: Color { ThemeManager.shared.colors.surfaceHover }
        static var surfaceSelected: Color { ThemeManager.shared.colors.surfaceSelected }

        static var textPrimary: Color { ThemeManager.shared.colors.textPrimary }
        static var textSecondary: Color { ThemeManager.shared.colors.textSecondary }
        static var textTertiary: Color { ThemeManager.shared.colors.textTertiary }

        static var accentGreen: Color { ThemeManager.shared.colors.accentGreen }
        static var accentBlue: Color { ThemeManager.shared.colors.accentBlue }
        static var accentOrange: Color { ThemeManager.shared.colors.accentOrange }
        static var accentRed: Color { ThemeManager.shared.colors.accentRed }

        // Semantic colors
        static var success: Color { accentGreen }
        static var info: Color { accentBlue }
        static var warning: Color { accentOrange }
        static var error: Color { accentRed }

        static var divider: Color { ThemeManager.shared.colors.divider }
        static var border: Color { ThemeManager.shared.colors.border }
    }

    // MARK: - Typography
    struct Typography {
        static let largeTitle = Font.system(size: 32, weight: .bold)
        static let title = Font.system(size: 24, weight: .semibold)
        static let headline = Font.system(size: 18, weight: .semibold)
        static let body = Font.system(size: 14, weight: .regular)
        static let bodyBold = Font.system(size: 14, weight: .semibold)
        static let caption = Font.system(size: 12, weight: .regular)
        static let captionBold = Font.system(size: 12, weight: .medium)
        static let small = Font.system(size: 11, weight: .regular)
    }

    // MARK: - Spacing
    struct Spacing {
        static let xxxs: CGFloat = 2
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: - Radii
    struct Radii {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 6
        static let md: CGFloat = 8
        static let lg: CGFloat = 12
        static let xl: CGFloat = 16
        static let full: CGFloat = 1000
    }

    // MARK: - Sizes
    struct Sizes {
        static let sidebarWidth: CGFloat = 280
        static let detailsPanelWidth: CGFloat = 340
        static let minWindowWidth: CGFloat = 1000
        static let minWindowHeight: CGFloat = 600
        static let thumbnailSmall: CGFloat = 48
        static let thumbnailMedium: CGFloat = 64
        static let thumbnailLarge: CGFloat = 180
    }

    // MARK: - Animation
    struct Animation {
        static let fast = SwiftUI.Animation.easeInOut(duration: 0.15)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.25)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.35)
    }
}

// MARK: - Color Extension for Hex Support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Modifiers
extension View {
    func freshCard() -> some View {
        self
            .background(FreshUI.Colors.surface)
            .cornerRadius(FreshUI.Radii.md)
    }

    func freshHoverEffect() -> some View {
        self.modifier(FreshHoverModifier())
    }

    func freshSidebar() -> some View {
        self
            .frame(width: FreshUI.Sizes.sidebarWidth)
            .background(FreshUI.Colors.sidebar)
    }

    func freshDetailsPanel() -> some View {
        self
            .frame(width: FreshUI.Sizes.detailsPanelWidth)
            .background(FreshUI.Colors.background)
    }
}

// MARK: - Custom Modifiers
struct FreshHoverModifier: ViewModifier {
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .background(isHovered ? FreshUI.Colors.surfaceHover : Color.clear)
            .cornerRadius(FreshUI.Radii.sm)
            .onHover { hovering in
                withAnimation(FreshUI.Animation.fast) {
                    isHovered = hovering
                }
            }
    }
}

// MARK: - Custom Button Styles
struct FreshPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, FreshUI.Spacing.md)
            .padding(.vertical, FreshUI.Spacing.xs)
            .background(FreshUI.Colors.accentGreen)
            .foregroundColor(.white)
            .cornerRadius(FreshUI.Radii.full)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
    }
}

struct FreshSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, FreshUI.Spacing.md)
            .padding(.vertical, FreshUI.Spacing.xs)
            .background(FreshUI.Colors.surface)
            .foregroundColor(FreshUI.Colors.textPrimary)
            .cornerRadius(FreshUI.Radii.full)
            .overlay(
                RoundedRectangle(cornerRadius: FreshUI.Radii.full)
                    .stroke(FreshUI.Colors.border, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct FreshGhostButtonStyle: ButtonStyle {
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(FreshUI.Spacing.xs)
            .foregroundColor(isHovered ? FreshUI.Colors.textPrimary : FreshUI.Colors.textSecondary)
            .background(isHovered ? FreshUI.Colors.surfaceHover : Color.clear)
            .cornerRadius(FreshUI.Radii.sm)
            .onHover { hovering in
                withAnimation(FreshUI.Animation.fast) {
                    isHovered = hovering
                }
            }
    }
}
