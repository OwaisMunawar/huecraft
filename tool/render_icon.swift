import AppKit

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
precondition(root.lastPathComponent == "huecraft")
let colors: [NSColor] = [
  NSColor(srgbRed: 0.08, green: 0.42, blue: 0.36, alpha: 1),
  NSColor(srgbRed: 0.83, green: 0.93, blue: 0.48, alpha: 1),
  NSColor(srgbRed: 0.22, green: 0.36, blue: 0.85, alpha: 1),
  NSColor(srgbRed: 0.55, green: 0.25, blue: 0.41, alpha: 1)
]
func render(size: Int, to destination: URL) throws {
  guard let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8,
    bytesPerRow: size * 4, space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { throw CocoaError(.fileWriteUnknown) }
  NSGraphicsContext.saveGraphicsState()
  NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
  let scale = CGFloat(size) / 1024
  NSColor(srgbRed: 0.09, green: 0.16, blue: 0.15, alpha: 1).setFill()
  NSRect(x: 0, y: 0, width: size, height: size).fill()
  for (index, color) in colors.enumerated() {
    color.setFill()
    NSBezierPath(roundedRect: NSRect(x: CGFloat(168 + index * 170) * scale,
      y: CGFloat(index % 2 == 0 ? 220 : 330) * scale, width: 142 * scale,
      height: 480 * scale), xRadius: 71 * scale, yRadius: 71 * scale).fill()
  }
  NSGraphicsContext.restoreGraphicsState()
  guard let output = context.makeImage(),
    let png = NSBitmapImageRep(cgImage: output).representation(using: .png, properties: [:]) else {
    throw CocoaError(.fileWriteUnknown)
  }
  try png.write(to: destination)
}
let iconDirectory = root.appendingPathComponent("ios/Runner/Assets.xcassets/AppIcon.appiconset")
for file in try FileManager.default.contentsOfDirectory(at: iconDirectory, includingPropertiesForKeys: nil)
where file.pathExtension == "png" {
  guard let image = NSImage(contentsOf: file) else { continue }
  try render(size: Int(image.size.width), to: file)
}
for (density, size) in [("mdpi", 48), ("hdpi", 72), ("xhdpi", 96), ("xxhdpi", 144), ("xxxhdpi", 192)] {
  try render(size: size, to: root.appendingPathComponent("android/app/src/main/res/mipmap-\(density)/ic_launcher.png"))
}
