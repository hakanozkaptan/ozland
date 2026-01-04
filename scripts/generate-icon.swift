#!/usr/bin/env swift

import Cocoa
import CoreGraphics

// MARK: - Icon Generator for OzLand
// Creates a Dynamic Island style icon with equalizer bars

let iconSizes: [(name: String, size: Int)] = [
    ("icon_16x16", 16),
    ("icon_16x16@2x", 32),
    ("icon_32x32", 32),
    ("icon_32x32@2x", 64),
    ("icon_128x128", 128),
    ("icon_128x128@2x", 256),
    ("icon_256x256", 256),
    ("icon_256x256@2x", 512),
    ("icon_512x512", 512),
    ("icon_512x512@2x", 1024)
]

func drawEqualizerBars(context: CGContext, size: CGFloat, pillX: CGFloat, pillY: CGFloat, pillWidth: CGFloat, pillHeight: CGFloat) {
    let barCount = 5
    let barSpacing = pillHeight * 0.12
    let totalBarsWidth = pillWidth * 0.4
    let barWidth = (totalBarsWidth - (CGFloat(barCount - 1) * barSpacing)) / CGFloat(barCount)
    let barsStartX = pillX + pillWidth * 0.5 - totalBarsWidth / 2

    let barHeights: [CGFloat] = [0.35, 0.65, 0.85, 0.55, 0.45]

    let barColors: [CGColor] = [
        CGColor(red: 0.11, green: 0.73, blue: 0.33, alpha: 1.0),
        CGColor(red: 0.15, green: 0.80, blue: 0.40, alpha: 1.0),
        CGColor(red: 0.20, green: 0.85, blue: 0.45, alpha: 1.0),
        CGColor(red: 0.15, green: 0.80, blue: 0.40, alpha: 1.0),
        CGColor(red: 0.11, green: 0.73, blue: 0.33, alpha: 1.0)
    ]

    for index in 0..<barCount {
        let barX = barsStartX + CGFloat(index) * (barWidth + barSpacing)
        let maxBarHeight = pillHeight * 0.65
        let barHeight = maxBarHeight * barHeights[index]
        let barY = pillY + (pillHeight - barHeight) / 2
        let barRect = CGRect(x: barX, y: barY, width: barWidth, height: barHeight)
        let barCornerRadius = barWidth / 2
        let barPath = CGPath(roundedRect: barRect, cornerWidth: barCornerRadius, cornerHeight: barCornerRadius, transform: nil)

        context.saveGState()
        context.addPath(barPath)
        context.setFillColor(barColors[index])
        context.fillPath()

        context.addPath(barPath)
        context.setShadow(offset: CGSize(width: 0, height: 0), blur: size * 0.02, color: barColors[index].copy(alpha: 0.6))
        context.setFillColor(barColors[index])
        context.fillPath()
        context.restoreGState()
    }
}

func drawIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))

    image.lockFocus()

    guard let context = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    let padding = size * 0.08
    let availableSize = size - (padding * 2)

    // Background - rounded square with gradient
    let backgroundRect = CGRect(x: padding, y: padding, width: availableSize, height: availableSize)
    let cornerRadius = availableSize * 0.22
    let backgroundPath = CGPath(roundedRect: backgroundRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

    // Gradient background (dark)
    let gradientColors = [
        CGColor(red: 0.08, green: 0.08, blue: 0.12, alpha: 1.0),
        CGColor(red: 0.05, green: 0.05, blue: 0.08, alpha: 1.0)
    ]
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let gradient = CGGradient(colorsSpace: colorSpace, colors: gradientColors as CFArray, locations: [0, 1])!

    context.saveGState()
    context.addPath(backgroundPath)
    context.clip()
    context.drawLinearGradient(gradient, start: CGPoint(x: size/2, y: padding), end: CGPoint(x: size/2, y: size - padding), options: [])
    context.restoreGState()

    // Draw Dynamic Island pill shape
    let pillWidth = availableSize * 0.75
    let pillHeight = availableSize * 0.25
    let pillX = padding + (availableSize - pillWidth) / 2
    let pillY = padding + (availableSize - pillHeight) / 2
    let pillRect = CGRect(x: pillX, y: pillY, width: pillWidth, height: pillHeight)
    let pillPath = CGPath(roundedRect: pillRect, cornerWidth: pillHeight/2, cornerHeight: pillHeight/2, transform: nil)

    // Pill background - dark with subtle gradient
    let pillGradientColors = [
        CGColor(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0),
        CGColor(red: 0.08, green: 0.08, blue: 0.10, alpha: 1.0)
    ]
    let pillGradient = CGGradient(colorsSpace: colorSpace, colors: pillGradientColors as CFArray, locations: [0, 1])!

    context.saveGState()
    context.addPath(pillPath)
    context.clip()
    context.drawLinearGradient(pillGradient, start: CGPoint(x: size/2, y: pillY + pillHeight), end: CGPoint(x: size/2, y: pillY), options: [])
    context.restoreGState()

    // Pill border glow
    context.saveGState()
    context.addPath(pillPath)
    context.setStrokeColor(CGColor(red: 0.3, green: 0.3, blue: 0.35, alpha: 0.5))
    context.setLineWidth(size * 0.005)
    context.strokePath()
    context.restoreGState()

    // Draw equalizer bars inside the pill
    drawEqualizerBars(context: context, size: size, pillX: pillX, pillY: pillY, pillWidth: pillWidth, pillHeight: pillHeight)

    // Add small music note icon on the left side of pill
    let noteSize = pillHeight * 0.45
    let noteX = pillX + pillWidth * 0.12
    let noteY = pillY + (pillHeight - noteSize) / 2

    // Draw a simple music note
    context.saveGState()
    context.setFillColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.85))

    // Note head (oval)
    let noteHeadWidth = noteSize * 0.5
    let noteHeadHeight = noteSize * 0.35
    let noteHeadPath = CGPath(ellipseIn: CGRect(x: noteX, y: noteY, width: noteHeadWidth, height: noteHeadHeight), transform: nil)
    context.addPath(noteHeadPath)
    context.fillPath()

    // Note stem
    let stemWidth = noteSize * 0.1
    let stemHeight = noteSize * 0.7
    let stemX = noteX + noteHeadWidth - stemWidth
    let stemY = noteY + noteHeadHeight * 0.5
    let stemRect = CGRect(x: stemX, y: stemY, width: stemWidth, height: stemHeight)
    context.fill(stemRect)

    // Note flag
    let flagPath = CGMutablePath()
    flagPath.move(to: CGPoint(x: stemX + stemWidth, y: stemY + stemHeight))
    flagPath.addCurve(to: CGPoint(x: stemX + stemWidth + noteSize * 0.3, y: stemY + stemHeight * 0.5),
                      control1: CGPoint(x: stemX + stemWidth + noteSize * 0.2, y: stemY + stemHeight * 0.9),
                      control2: CGPoint(x: stemX + stemWidth + noteSize * 0.3, y: stemY + stemHeight * 0.7))
    flagPath.addLine(to: CGPoint(x: stemX + stemWidth, y: stemY + stemHeight * 0.6))
    flagPath.closeSubpath()
    context.addPath(flagPath)
    context.fillPath()

    context.restoreGState()

    image.unlockFocus()
    return image
}

func saveIconSet() {
    let fileManager = FileManager.default
    let currentPath = fileManager.currentDirectoryPath
    let iconsetPath = "\(currentPath)/Assets/AppIcon.iconset"

    // Create iconset directory if it doesn't exist
    try? fileManager.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true, attributes: nil)

    print("Generating icons...")

    for (name, size) in iconSizes {
        let image = drawIcon(size: CGFloat(size))
        let filePath = "\(iconsetPath)/\(name).png"

        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            print("Failed to generate \(name)")
            continue
        }

        do {
            try pngData.write(to: URL(fileURLWithPath: filePath))
            print("  Generated: \(name).png (\(size)x\(size))")
        } catch {
            print("  Failed to save \(name): \(error)")
        }
    }

    print("\nConverting to .icns...")

    // Convert iconset to icns
    let icnsPath = "\(currentPath)/Assets/AppIcon.icns"
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
    process.arguments = ["-c", "icns", "-o", icnsPath, iconsetPath]

    do {
        try process.run()
        process.waitUntilExit()

        if process.terminationStatus == 0 {
            print("Successfully created: Assets/AppIcon.icns")
        } else {
            print("iconutil failed with status: \(process.terminationStatus)")
        }
    } catch {
        print("Failed to run iconutil: \(error)")
    }
}

// Run the generator
saveIconSet()
print("\nDone! Run './scripts/create-dmg.sh' to build the app with the new icon.")
