import SwiftUI

extension Color {
    static let ttcRed = Color(red: 0xDA / 255, green: 0x29 / 255, blue: 0x1C / 255)
}

extension ShapeStyle where Self == Color {
    static var ttcRed: Color { .ttcRed }
}
