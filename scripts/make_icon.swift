#!/usr/bin/env swift
import AppKit

let sizes: [(pixels: Int, name: String)] = [
    (16, "icon_16x16.png"),
    (32, "icon_16x16@2x.png"),
    (32, "icon_32x32.png"),
    (64, "icon_32x32@2x.png"),
    (128, "icon_128x128.png"),
    (256, "icon_128x128@2x.png"),
    (256, "icon_256x256.png"),
    (512, "icon_256x256@2x.png"),
    (512, "icon_512x512.png"),
    (1024, "icon_512x512@2x.png"),
]

func drawIcon(pixels: Int) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    rep.size = NSSize(width: pixels, height: pixels)

    NSGraphicsContext.saveGraphicsState()
    defer { NSGraphicsContext.restoreGraphicsState() }
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    let rect = NSRect(x: 0, y: 0, width: pixels, height: pixels)
    let corner = CGFloat(pixels) * 0.2237
    let path = NSBezierPath(roundedRect: rect, xRadius: corner, yRadius: corner)

    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.16, green: 0.66, blue: 0.44, alpha: 1.0),
        NSColor(calibratedRed: 0.02, green: 0.30, blue: 0.22, alpha: 1.0),
    ])!
    gradient.draw(in: path, angle: -90)

    let linePoints: [CGFloat] = [0.30, 0.44, 0.38, 0.58, 0.53, 0.72, 0.66, 0.84]
    let inset = CGFloat(pixels) * 0.20
    let w = CGFloat(pixels) - inset * 2
    let line = NSBezierPath()
    for (i, p) in linePoints.enumerated() {
        let x = inset + w * CGFloat(i) / CGFloat(linePoints.count - 1)
        let y = inset + w * (1.0 - p)
        if i == 0 {
            line.move(to: NSPoint(x: x, y: y))
        } else {
            line.line(to: NSPoint(x: x, y: y))
        }
    }
    line.lineWidth = CGFloat(pixels) * 0.055
    line.lineCapStyle = .round
    line.lineJoinStyle = .round
    NSColor.white.withAlphaComponent(0.95).setStroke()
    line.stroke()

    return rep
}

let iconset = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "/tmp/AppIcon.iconset")
try? FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
for s in sizes {
    let rep = drawIcon(pixels: s.pixels)
    let data = rep.representation(using: .png, properties: [:])!
    let url = iconset.appendingPathComponent(s.name)
    try data.write(to: url)
    print("wrote \(url.path)")
}
