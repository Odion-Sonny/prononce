import AppKit
import CoreGraphics

func createIconImage(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    let rect = CGRect(x: 0, y: 0, width: size, height: size)

    // Corner radius for modern macOS squircle style
    let cornerRadius = size * 0.224
    let bgPath = CGPath(roundedRect: rect.insetBy(dx: size * 0.05, dy: size * 0.05),
                        cornerWidth: cornerRadius,
                        cornerHeight: cornerRadius,
                        transform: nil)

    ctx.saveGState()
    ctx.addPath(bgPath)
    ctx.clip()

    // Background: elegant deep midnight slate
    let darkBlue = NSColor(calibratedRed: 0.08, green: 0.11, blue: 0.16, alpha: 1.0)
    let lightNavy = NSColor(calibratedRed: 0.12, green: 0.16, blue: 0.24, alpha: 1.0)
    let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                              colors: [lightNavy.cgColor, darkBlue.cgColor] as CFArray,
                              locations: [0.0, 1.0])!
    ctx.drawLinearGradient(gradient,
                           start: CGPoint(x: 0, y: size),
                           end: CGPoint(x: 0, y: 0),
                           options: [])

    // French tricolor accent stripe on the left/top
    let stripeHeight = size * 0.04
    let blueColor = NSColor(calibratedRed: 0.0, green: 0.33, blue: 0.75, alpha: 0.95).cgColor
    let whiteColor = NSColor(calibratedWhite: 0.95, alpha: 0.95).cgColor
    let redColor = NSColor(calibratedRed: 0.93, green: 0.18, blue: 0.25, alpha: 0.95).cgColor

    let stripeWidth = (size * 0.9) / 3.0
    let startX = size * 0.05
    let stripeY = size * 0.05

    ctx.setFillColor(blueColor)
    ctx.fill(CGRect(x: startX, y: stripeY, width: stripeWidth, height: stripeHeight))
    ctx.setFillColor(whiteColor)
    ctx.fill(CGRect(x: startX + stripeWidth, y: stripeY, width: stripeWidth, height: stripeHeight))
    ctx.setFillColor(redColor)
    ctx.fill(CGRect(x: startX + stripeWidth * 2, y: stripeY, width: stripeWidth, height: stripeHeight))

    ctx.restoreGState()

    // Subtle outer border
    ctx.saveGState()
    ctx.addPath(bgPath)
    ctx.setStrokeColor(NSColor(calibratedWhite: 1.0, alpha: 0.18).cgColor)
    ctx.setLineWidth(max(1.0, size * 0.015))
    ctx.strokePath()
    ctx.restoreGState()

    // Draw central speech waveform symbol
    let center = CGPoint(x: size * 0.5, y: size * 0.54)
    let barWidth = size * 0.045
    let barSpacing = size * 0.035
    let heights: [CGFloat] = [0.18, 0.32, 0.46, 0.36, 0.22]

    let totalWidth = CGFloat(heights.count) * barWidth + CGFloat(heights.count - 1) * barSpacing
    var currentX = center.x - totalWidth / 2.0

    for h in heights {
        let barHeight = size * h
        let barRect = CGRect(x: currentX, y: center.y - barHeight / 2.0, width: barWidth, height: barHeight)
        let barPath = CGPath(roundedRect: barRect, cornerWidth: barWidth / 2.0, cornerHeight: barWidth / 2.0, transform: nil)

        ctx.saveGState()
        ctx.addPath(barPath)
        // French-inspired vibrant gradient on the bars
        let barGrad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                 colors: [NSColor.white.cgColor, NSColor(calibratedRed: 0.4, green: 0.7, blue: 1.0, alpha: 1.0).cgColor] as CFArray,
                                 locations: [0.0, 1.0])!
        ctx.clip()
        ctx.drawLinearGradient(barGrad,
                               start: CGPoint(x: currentX, y: center.y + barHeight / 2.0),
                               end: CGPoint(x: currentX, y: center.y - barHeight / 2.0),
                               options: [])
        ctx.restoreGState()

        currentX += barWidth + barSpacing
    }

    image.unlockFocus()
    return image
}

let fileManager = FileManager.default
let iconsetDir = "Resources/AppIcon.iconset"
try? fileManager.removeItem(atPath: iconsetDir)
try? fileManager.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

let specs: [(String, CGFloat)] = [
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

for (filename, size) in specs {
    let img = createIconImage(size: size)
    if let tiff = img.tiffRepresentation,
       let bitmap = NSBitmapImageRep(data: tiff),
       let png = bitmap.representation(using: .png, properties: [:]) {
        let path = "\(iconsetDir)/\(filename)"
        try? png.write(to: URL(fileURLWithPath: path))
    }
}

print("Iconset created successfully at \(iconsetDir)")
