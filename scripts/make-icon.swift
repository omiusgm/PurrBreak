#!/usr/bin/env swift

import AppKit
import Foundation

let outputPath = CommandLine.arguments.dropFirst().first ?? ".build/PurrBreak.icns"
let fileManager = FileManager.default
let outputURL = URL(fileURLWithPath: outputPath)
let iconsetURL = outputURL.deletingPathExtension().appendingPathExtension("iconset")

try? fileManager.removeItem(at: iconsetURL)
try fileManager.createDirectory(at: iconsetURL, withIntermediateDirectories: true)
try fileManager.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)

let iconFiles: [(name: String, pixels: Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for iconFile in iconFiles {
    let image = drawIcon(size: iconFile.pixels)
    let data = try pngData(from: image, pixels: iconFile.pixels)
    try data.write(to: iconsetURL.appendingPathComponent(iconFile.name), options: .atomic)
}

try? fileManager.removeItem(at: outputURL)

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconsetURL.path, "-o", outputURL.path]
try process.run()
process.waitUntilExit()

guard process.terminationStatus == 0 else {
    fputs("iconutil failed\n", stderr)
    exit(Int32(process.terminationStatus))
}

func drawIcon(size: Int) -> NSImage {
    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let scale = CGFloat(size) / 1024.0
    let image = NSImage(size: rect.size)

    image.lockFocus()
    NSGraphicsContext.current?.imageInterpolation = .high

    let background = NSBezierPath(roundedRect: rect.insetBy(dx: 42 * scale, dy: 42 * scale), xRadius: 210 * scale, yRadius: 210 * scale)
    NSColor(red: 0.055, green: 0.095, blue: 0.105, alpha: 1.0).setFill()
    background.fill()

    let glow = NSBezierPath(ovalIn: NSRect(x: 130 * scale, y: 165 * scale, width: 760 * scale, height: 650 * scale))
    NSColor(red: 0.98, green: 0.54, blue: 0.25, alpha: 0.18).setFill()
    glow.fill()

    let catColor = NSColor(red: 0.96, green: 0.62, blue: 0.34, alpha: 1.0)
    let catDark = NSColor(red: 0.34, green: 0.15, blue: 0.10, alpha: 1.0)
    let catLight = NSColor(red: 1.00, green: 0.78, blue: 0.48, alpha: 1.0)

    drawEar(points: [
        NSPoint(x: 275 * scale, y: 670 * scale),
        NSPoint(x: 350 * scale, y: 895 * scale),
        NSPoint(x: 450 * scale, y: 690 * scale)
    ], fill: catColor)

    drawEar(points: [
        NSPoint(x: 575 * scale, y: 690 * scale),
        NSPoint(x: 680 * scale, y: 895 * scale),
        NSPoint(x: 750 * scale, y: 670 * scale)
    ], fill: catColor)

    let head = NSBezierPath(ovalIn: NSRect(x: 230 * scale, y: 250 * scale, width: 565 * scale, height: 565 * scale))
    catColor.setFill()
    head.fill()

    let muzzle = NSBezierPath(ovalIn: NSRect(x: 355 * scale, y: 330 * scale, width: 315 * scale, height: 230 * scale))
    catLight.setFill()
    muzzle.fill()

    catDark.setStroke()
    let lineWidth = max(4, 24 * scale)

    drawClosedEye(from: NSPoint(x: 335 * scale, y: 575 * scale), to: NSPoint(x: 455 * scale, y: 575 * scale), control: NSPoint(x: 395 * scale, y: 515 * scale), lineWidth: lineWidth)
    drawClosedEye(from: NSPoint(x: 570 * scale, y: 575 * scale), to: NSPoint(x: 690 * scale, y: 575 * scale), control: NSPoint(x: 630 * scale, y: 515 * scale), lineWidth: lineWidth)

    let nose = NSBezierPath(ovalIn: NSRect(x: 495 * scale, y: 465 * scale, width: 38 * scale, height: 30 * scale))
    catDark.setFill()
    nose.fill()

    drawWhisker(from: NSPoint(x: 470 * scale, y: 450 * scale), to: NSPoint(x: 260 * scale, y: 500 * scale), lineWidth: max(3, 11 * scale))
    drawWhisker(from: NSPoint(x: 468 * scale, y: 420 * scale), to: NSPoint(x: 250 * scale, y: 410 * scale), lineWidth: max(3, 11 * scale))
    drawWhisker(from: NSPoint(x: 555 * scale, y: 450 * scale), to: NSPoint(x: 765 * scale, y: 500 * scale), lineWidth: max(3, 11 * scale))
    drawWhisker(from: NSPoint(x: 557 * scale, y: 420 * scale), to: NSPoint(x: 775 * scale, y: 410 * scale), lineWidth: max(3, 11 * scale))

    let paw = NSBezierPath(roundedRect: NSRect(x: 350 * scale, y: 150 * scale, width: 330 * scale, height: 140 * scale), xRadius: 70 * scale, yRadius: 70 * scale)
    catLight.setFill()
    paw.fill()

    for x in [395, 475, 555, 635] {
        let toe = NSBezierPath(ovalIn: NSRect(x: CGFloat(x) * scale, y: 255 * scale, width: 54 * scale, height: 62 * scale))
        catColor.setFill()
        toe.fill()
    }

    image.unlockFocus()
    return image
}

func drawEar(points: [NSPoint], fill: NSColor) {
    let path = NSBezierPath()
    path.move(to: points[0])
    path.line(to: points[1])
    path.line(to: points[2])
    path.close()
    fill.setFill()
    path.fill()
}

func drawClosedEye(from start: NSPoint, to end: NSPoint, control: NSPoint, lineWidth: CGFloat) {
    let path = NSBezierPath()
    path.move(to: start)
    path.curve(to: end, controlPoint1: control, controlPoint2: control)
    path.lineWidth = lineWidth
    path.lineCapStyle = .round
    path.stroke()
}

func drawWhisker(from start: NSPoint, to end: NSPoint, lineWidth: CGFloat) {
    let path = NSBezierPath()
    path.move(to: start)
    path.line(to: end)
    path.lineWidth = lineWidth
    path.lineCapStyle = .round
    path.stroke()
}

func pngData(from image: NSImage, pixels: Int) throws -> Data {
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let data = bitmap.representation(using: .png, properties: [:]) else {
        throw CocoaError(.fileWriteUnknown)
    }

    bitmap.size = NSSize(width: pixels, height: pixels)
    return data
}
