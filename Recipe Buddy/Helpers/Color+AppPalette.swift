import SwiftUI

extension ShapeStyle where Self == Color {
    // Brand / Accent
    public static var AppPrimary: Color { Color("AppPrimary") }
    public static var AppSecondary: Color { Color("AppSecondary") }

    // Text
    public static var TextPrimary: Color { Color("TextPrimary") }
    public static var TextSecondary: Color { Color("TextSecondary") }

    // Surfaces
    public static var Background: Color { Color("Background") }
    public static var Surface: Color { Color("Surface") }
    public static var SurfaceBorder: Color { Color("SurfaceBorder") }
    public static var Separator: Color { Color("Separator") }

    // Status
    public static var Success: Color { Color("Success") }
    public static var Warning: Color { Color("Warning") }
    public static var Danger: Color { Color("Danger") }
}
