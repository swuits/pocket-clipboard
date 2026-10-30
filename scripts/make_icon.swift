// Draws the Pocket app icon and writes an .iconset. Usage: swift make_icon.swift <out.iconset>
import AppKit

func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: r, green: g, blue: b, alpha: a)
}

func render(size: Int) -> Data {
    let s = CGFloat(size)
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8,
        samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let ctx = NSGraphicsContext.current!.cgContext
    ctx.scaleBy(x: s / 1024, y: s / 1024)

    // Tile
    let tile = NSBezierPath(roundedRect: NSRect(x: 40, y: 40, width: 944, height: 944), xRadius: 215, yRadius: 215)
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = color(0, 0, 0, 0.45); shadow.shadowBlurRadius = 24; shadow.shadowOffset = NSSize(width: 0, height: -12)
    shadow.set()
    color(0.1, 0.08, 0.13).setFill(); tile.fill()
    NSGraphicsContext.restoreGraphicsState()
    tile.addClip()
    NSGradient(colors: [color(0.2, 0.12, 0.3), color(0.075, 0.063, 0.086)], atLocations: [0, 1], colorSpace: .sRGB)!
        .draw(in: tile, angle: -60)
    NSGradient(colors: [color(1, 0.42, 0.24, 0.55), color(1, 0.42, 0.24, 0)], atLocations: [0, 1], colorSpace: .sRGB)!
        .draw(fromCenter: NSPoint(x: 220, y: 900), radius: 0, toCenter: NSPoint(x: 220, y: 900), radius: 620, options: [])

    // Cards peeking out of the pocket
    func card(rotation: CGFloat, dx: CGFloat, colors: [NSColor], lines: NSColor) {
        let t = NSAffineTransform()
        t.translateX(by: 512 + dx, yBy: 420); t.rotate(byDegrees: rotation); t.translateX(by: -512 - dx, yBy: -420)
        NSGraphicsContext.saveGraphicsState()
        t.concat()
        let rect = NSRect(x: 300 + dx, y: 330, width: 424, height: 470)
        let p = NSBezierPath(roundedRect: rect, xRadius: 56, yRadius: 56)
        let sh = NSShadow(); sh.shadowColor = color(0, 0, 0, 0.35); sh.shadowBlurRadius = 28; sh.shadowOffset = NSSize(width: 0, height: -8); sh.set()
        NSGradient(colors: colors)!.draw(in: p, angle: -60)
        NSShadow().set()
        lines.setFill()
        for (i, w) in [260.0, 200.0, 230.0].enumerated() {
            NSBezierPath(roundedRect: NSRect(x: 348 + dx, y: 720 - CGFloat(i) * 62, width: w, height: 22), xRadius: 11, yRadius: 11).fill()
        }
        NSGraphicsContext.restoreGraphicsState()
    }
    card(rotation: 9, dx: 30, colors: [color(0.93, 0.89, 0.97), color(0.78, 0.7, 0.95)], lines: color(0.3, 0.2, 0.5, 0.35))
    card(rotation: -7, dx: -20, colors: [color(1, 0.7, 0.4), color(1, 0.38, 0.22)], lines: color(0.35, 0.1, 0.05, 0.35))

    // Pocket front
    let pocket = NSBezierPath()
    pocket.move(to: NSPoint(x: 150, y: 520))
    pocket.curve(to: NSPoint(x: 210, y: 470), controlPoint1: NSPoint(x: 150, y: 490), controlPoint2: NSPoint(x: 175, y: 470))
    pocket.line(to: NSPoint(x: 814, y: 470))
    pocket.curve(to: NSPoint(x: 874, y: 520), controlPoint1: NSPoint(x: 849, y: 470), controlPoint2: NSPoint(x: 874, y: 490))
    pocket.line(to: NSPoint(x: 874, y: 330))
    pocket.curve(to: NSPoint(x: 700, y: 120), controlPoint1: NSPoint(x: 874, y: 220), controlPoint2: NSPoint(x: 800, y: 120))
    pocket.line(to: NSPoint(x: 324, y: 120))
    pocket.curve(to: NSPoint(x: 150, y: 330), controlPoint1: NSPoint(x: 224, y: 120), controlPoint2: NSPoint(x: 150, y: 220))
    pocket.close()
    NSGraphicsContext.saveGraphicsState()
    let ps = NSShadow(); ps.shadowColor = color(0, 0, 0, 0.5); ps.shadowBlurRadius = 36; ps.shadowOffset = NSSize(width: 0, height: 14); ps.set()
    NSGradient(colors: [color(0.2, 0.15, 0.27), color(0.11, 0.09, 0.15)])!.draw(in: pocket, angle: -90)
    NSGraphicsContext.restoreGraphicsState()
    color(1, 1, 1, 0.12).setStroke(); pocket.lineWidth = 3; pocket.stroke()

    // Stitching
    let stitch = NSBezierPath()
    stitch.move(to: NSPoint(x: 200, y: 440))
    stitch.line(to: NSPoint(x: 824, y: 440))
    stitch.setLineDash([26, 22], count: 2, phase: 0)
    stitch.lineWidth = 9; stitch.lineCapStyle = .round
    color(1, 0.55, 0.32).setStroke(); stitch.stroke()

    // Ember dot
    let dot = NSBezierPath(ovalIn: NSRect(x: 462, y: 230, width: 100, height: 100))
    NSGradient(colors: [color(1, 0.66, 0.36), color(1, 0.42, 0.24)])!.draw(in: dot, angle: -60)

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

let out = URL(fileURLWithPath: CommandLine.arguments[1])
try? FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
let sizes: [(String, Int)] = [
    ("16x16", 16), ("16x16@2x", 32), ("32x32", 32), ("32x32@2x", 64), ("128x128", 128), ("128x128@2x", 256),
    ("256x256", 256), ("256x256@2x", 512), ("512x512", 512), ("512x512@2x", 1024),
]
for (name, px) in sizes {
    try render(size: px).write(to: out.appendingPathComponent("icon_\(name).png"))
}
