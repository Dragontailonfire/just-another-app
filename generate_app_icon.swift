#!/usr/bin/env swift
//
//  generate_app_icon.swift
//  Generates light, dark, and tinted app icon variants using CoreGraphics.
//
//  Usage: swift generate_app_icon.swift
//

import CoreGraphics
import Foundation
#if canImport(ImageIO)
import ImageIO
#endif

let size = 1024
let cgSize = CGSize(width: size, height: size)
let outputDir = "just-another-app/Assets.xcassets/AppIcon.appiconset"

// MARK: - Helpers

func createContext() -> CGContext {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let context = CGContext(
        data: nil,
        width: size,
        height: size,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    return context
}

func savePNG(_ context: CGContext, filename: String) {
    let image = context.makeImage()!
    let url = URL(fileURLWithPath: "\(outputDir)/\(filename)")
    let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, image, nil)
    CGImageDestinationFinalize(dest)
    print("Created \(url.path)")
}

func drawGradient(_ context: CGContext, from fromColor: [CGFloat], to toColor: [CGFloat]) {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let colors = [
        CGColor(colorSpace: colorSpace, components: fromColor)!,
        CGColor(colorSpace: colorSpace, components: toColor)!
    ] as CFArray
    let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 1.0])!
    context.drawLinearGradient(
        gradient,
        start: CGPoint(x: 0, y: CGFloat(size)),
        end: CGPoint(x: CGFloat(size), y: 0),
        options: []
    )
}

func drawBookmarkSymbol(_ context: CGContext, color: [CGFloat], alpha: CGFloat = 1.0) {
    // Bookmark shape: a rectangle with a notch at the bottom center
    let w = CGFloat(size)
    let margin = w * 0.28
    let left = margin
    let right = w - margin
    let top = w * 0.20
    let bottom = w * 0.80
    let notchDepth = w * 0.10
    let midX = w / 2

    var colorWithAlpha = color
    colorWithAlpha[3] = alpha
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let cgColor = CGColor(colorSpace: colorSpace, components: colorWithAlpha)!
    context.setFillColor(cgColor)

    context.beginPath()
    // Top-left with rounded corner
    let cornerRadius = w * 0.04
    context.move(to: CGPoint(x: left + cornerRadius, y: top))
    context.addLine(to: CGPoint(x: right - cornerRadius, y: top))
    context.addQuadCurve(to: CGPoint(x: right, y: top + cornerRadius), control: CGPoint(x: right, y: top))
    context.addLine(to: CGPoint(x: right, y: bottom))
    // Notch at bottom
    context.addLine(to: CGPoint(x: midX + w * 0.02, y: bottom - notchDepth))
    context.addLine(to: CGPoint(x: midX - w * 0.02, y: bottom - notchDepth))
    context.addLine(to: CGPoint(x: left, y: bottom))
    context.addLine(to: CGPoint(x: left, y: top + cornerRadius))
    context.addQuadCurve(to: CGPoint(x: left + cornerRadius, y: top), control: CGPoint(x: left, y: top))
    context.closePath()
    context.fillPath()
}

// MARK: - Light Icon

func generateLight() {
    let ctx = createContext()
    // Blue-to-indigo gradient: #007AFF → #5856D6
    drawGradient(ctx,
        from: [0.0, 0.478, 1.0, 1.0],    // #007AFF
        to: [0.345, 0.337, 0.839, 1.0]     // #5856D6
    )
    drawBookmarkSymbol(ctx, color: [1, 1, 1, 1])
    savePNG(ctx, filename: "AppIcon-Light.png")
}

// MARK: - Dark Icon

func generateDark() {
    let ctx = createContext()
    // Darker gradient on near-black: #1C1C1E → #2C2C2E
    drawGradient(ctx,
        from: [0.11, 0.11, 0.118, 1.0],   // #1C1C1E
        to: [0.173, 0.173, 0.18, 1.0]      // #2C2C2E
    )
    drawBookmarkSymbol(ctx, color: [1, 1, 1, 1], alpha: 0.9)
    savePNG(ctx, filename: "AppIcon-Dark.png")
}

// MARK: - Tinted Icon

func generateTinted() {
    let ctx = createContext()
    // Medium gray background
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let gray = CGColor(colorSpace: colorSpace, components: [0.55, 0.55, 0.55, 1.0])!
    ctx.setFillColor(gray)
    ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))
    drawBookmarkSymbol(ctx, color: [1, 1, 1, 1])
    savePNG(ctx, filename: "AppIcon-Tinted.png")
}

// MARK: - Main

// Ensure output directory exists
let fm = FileManager.default
if !fm.fileExists(atPath: outputDir) {
    try fm.createDirectory(atPath: outputDir, withIntermediateDirectories: true)
}

generateLight()
generateDark()
generateTinted()
print("Done — 3 icon variants generated.")
