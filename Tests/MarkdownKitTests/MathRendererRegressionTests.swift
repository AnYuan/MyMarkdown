import XCTest
@testable import MarkdownKit

#if canImport(WebKit)
import CoreGraphics

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@MainActor
final class MathRendererRegressionTests: XCTestCase {

    func testSVGRendererPreservesFillNoneTransparency() async throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 20 20">
          <rect x="1" y="1" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2"/>
        </svg>
        """

        let image = try await renderedImage(from: svg)
        let centerPixel = try pixel(in: image, x: 10, y: 10)
        let borderPixel = try pixel(in: image, x: 1, y: 10)

        XCTAssertLessThan(
            centerPixel.alpha,
            0.05,
            "SVG elements with fill=\"none\" must remain transparent after rasterization"
        )
        XCTAssertGreaterThan(
            borderPixel.alpha,
            0.2,
            "The renderer should still preserve stroked shapes"
        )
    }

    private func renderedImage(from svg: String) async throws -> NativeImage {
        let expectation = expectation(description: "render svg")
        var renderedImage: NativeImage?

        MathRenderer.shared.render(svg: svg) { image in
            renderedImage = image
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 5.0)

        guard let renderedImage else {
            throw XCTSkip("SVG rasterization is unavailable in this runtime environment")
        }

        return renderedImage
    }

    private func pixel(in image: NativeImage, x: Int, y: Int) throws -> PixelSample {
        guard let cgImage = cgImage(from: image) else {
            throw XCTSkip("Unable to extract CGImage from rasterized SVG output")
        }

        let width = cgImage.width
        let height = cgImage.height
        var data = [UInt8](repeating: 0, count: width * height * 4)
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        guard let context = CGContext(
            data: &data,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw XCTSkip("Unable to inspect rasterized SVG pixels")
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        let sampleX = min(max(x, 0), width - 1)
        let sampleY = min(max(y, 0), height - 1)
        let index = (sampleY * width + sampleX) * 4

        return PixelSample(
            red: CGFloat(data[index]) / 255,
            green: CGFloat(data[index + 1]) / 255,
            blue: CGFloat(data[index + 2]) / 255,
            alpha: CGFloat(data[index + 3]) / 255
        )
    }

    private func cgImage(from image: NativeImage) -> CGImage? {
        #if canImport(UIKit)
        return image.cgImage
        #elseif canImport(AppKit)
        var proposedRect = CGRect(origin: .zero, size: image.size)
        return image.cgImage(forProposedRect: &proposedRect, context: nil, hints: nil)
        #endif
    }
}

private struct PixelSample {
    let red: CGFloat
    let green: CGFloat
    let blue: CGFloat
    let alpha: CGFloat
}
#endif