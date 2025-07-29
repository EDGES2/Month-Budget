// Month Budget/Extensions/View+Styles.swift
import SwiftUI

extension Text {
    func categoryButtonStyle(isSelected: Bool, color: Color) -> some View {
        self
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(isSelected ? (color == Color(red: 0.9, green: 0.9, blue: 0.9) ? .black : .white) : .primary)
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
            .background(color.opacity(isSelected ? 1.0 : 0.2))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(color.opacity(0.8), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: color.opacity(isSelected ? 0.3 : 0.2),
                    radius: isSelected ? 4 : 2,
                    x: 0,
                    y: isSelected ? 2 : 1)
            .contentShape(Rectangle())
    }
    
    func transactionButtonStyle(isSelected: Bool, color: Color) -> some View {
        self
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(isSelected ? .white : .primary)
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: 35, alignment: .center)
            .background(color.opacity(isSelected ? 1.0 : 0.2))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(color.opacity(0.8), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: color.opacity(isSelected ? 0.3 : 0.2),
                    radius: isSelected ? 4 : 2,
                    x: 0,
                    y: isSelected ? 2 : 1)
            .contentShape(Rectangle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
