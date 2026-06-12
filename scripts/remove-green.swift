#!/usr/bin/env swift

import AppKit
import CoreGraphics
import Foundation
import ImageIO

guard CommandLine.arguments.count == 3 else {
    fputs("Usage: remove-green.swift <input.png> <output.png>\n", stderr)
    exit(64)
}

let inputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])

guard let image = NSImage(contentsOf: inputURL),
      let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    fputs("Could not read image: \(inputURL.path)\n", stderr)
    exit(1)
}

let width = cgImage.width
let height = cgImage.height
let bytesPerPixel = 4
let bytesPerRow = width * bytesPerPixel
var pixels = [UInt8](repeating: 0, count: height * bytesPerRow)
let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
    | CGBitmapInfo.byteOrder32Big.rawValue

guard let context = CGContext(
    data: &pixels,
    width: width,
    height: height,
    bitsPerComponent: 8,
    bytesPerRow: bytesPerRow,
    space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: bitmapInfo
) else {
    fputs("Could not create bitmap context\n", stderr)
    exit(1)
}

context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

for y in 0..<height {
    for x in 0..<width {
        let offset = y * bytesPerRow + x * bytesPerPixel
        let red = Double(pixels[offset])
        let green = Double(pixels[offset + 1])
        let blue = Double(pixels[offset + 2])

        let distanceToKey = sqrt(red * red + pow(green - 255.0, 2.0) + blue * blue)
        let maxNonGreen = max(red, blue)
        let stronglyGreen = green > 135.0 && green > maxNonGreen + 20.0

        if distanceToKey < 54.0 || stronglyGreen {
            let edge = max(0.0, min(1.0, (distanceToKey - 68.0) / 96.0))
            let alpha = UInt8(edge * 255.0)

            if alpha < 20 {
                pixels[offset] = 0
                pixels[offset + 1] = 0
                pixels[offset + 2] = 0
                pixels[offset + 3] = 0
            } else {
                let alphaScale = Double(alpha) / 255.0
                let despilledGreen = min(green, maxNonGreen * 0.90)
                pixels[offset] = UInt8(red * alphaScale)
                pixels[offset + 1] = UInt8(despilledGreen * alphaScale)
                pixels[offset + 2] = UInt8(blue * alphaScale)
                pixels[offset + 3] = alpha
            }
        } else if green > maxNonGreen + 8.0 {
            pixels[offset + 1] = UInt8(min(green, maxNonGreen * 0.98))
        }
    }
}

guard let outputContext = CGContext(
    data: &pixels,
    width: width,
    height: height,
    bitsPerComponent: 8,
    bytesPerRow: bytesPerRow,
    space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: bitmapInfo
),
let outputImage = outputContext.makeImage(),
let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, "public.png" as CFString, 1, nil) else {
    fputs("Could not create output image\n", stderr)
    exit(1)
}

CGImageDestinationAddImage(destination, outputImage, nil)

if !CGImageDestinationFinalize(destination) {
    fputs("Could not write image: \(outputURL.path)\n", stderr)
    exit(1)
}
