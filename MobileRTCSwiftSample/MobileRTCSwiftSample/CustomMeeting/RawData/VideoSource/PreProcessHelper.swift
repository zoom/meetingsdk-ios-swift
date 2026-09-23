//
//  PreProcessHelper.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 5/12/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.
//

import CoreGraphics
import MobileRTC
import UIKit

final class PreProcessHelper: NSObject, MobileRTCPreProcessorDelegate {

    var videoSourceHelper: MobileRTCVideoSourceHelper?
    private var wateri420: UnsafeMutablePointer<UInt8>?
    private var waterImage: UIImage?

    override init() {
        super.init()
        videoSourceHelper = MobileRTCVideoSourceHelper()
    }

    deinit {
        cleanVideoCapturePreProcessor()
    }

    func onPreProcessRawData(_ rawData: MobileRTCPreProcessRawData) {
        if waterImage == nil { waterImage = UIImage(named: "waterMark") }
        guard let waterImage else { return }
        if wateri420 == nil { wateri420 = PreProcessHelper.imageToi420(waterImage) }
        guard let wateri420 else { return }
        PreProcessHelper.addWaterMark(
            rawData: rawData,
            waterImage: waterImage,
            wateri420: wateri420,
            offX: Int(rawData.size.width) / 2,
            offY: Int(rawData.size.height) / 2,
            enableTransparent: true
        )
    }

    func setPreProcessor() {
        _ = videoSourceHelper?.setPreProcessor(self)
    }

    func cleanVideoCapturePreProcessor() {
        _ = videoSourceHelper?.setPreProcessor(nil)
        wateri420?.deallocate()
        wateri420 = nil
    }

    static func addWaterMark(rawData: MobileRTCPreProcessRawData,
                             waterImage: UIImage,
                             wateri420: UnsafeMutablePointer<UInt8>,
                             offX: Int, offY: Int,
                             enableTransparent: Bool) {
        let waterWidth = Int(waterImage.size.width)
        let waterHeight = Int(waterImage.size.height)
        let rawW = Int(rawData.size.width)
        let rawH = Int(rawData.size.height)
        if offX + waterWidth > rawW || offY + waterHeight > rawH { return }

        let waterUVWidth = waterWidth / 2
        let waterUVHeight = waterHeight / 2
        let waterYBuffer = wateri420
        let waterUBuffer = wateri420.advanced(by: waterWidth * waterHeight)
        let waterVBuffer = wateri420.advanced(by: waterWidth * waterHeight + waterUVWidth * waterUVHeight)

        for i in 0..<waterHeight {
            let row = Int32(offY + i)
            guard let yBuffer = rawData.getYBuffer(row) else { continue }
            if enableTransparent {
                for j in 0..<waterWidth {
                    let offset = i * waterWidth + j
                    let y = Int8(bitPattern: wateri420[offset])
                    if y != 16 && y != -128 {
                        yBuffer[offX + j] = CChar(bitPattern: wateri420[offset])
                    }
                }
            } else {
                memcpy(yBuffer.advanced(by: offX), waterYBuffer.advanced(by: i * waterWidth), waterWidth)
            }
        }

        for i in 0..<waterUVHeight {
            let row = Int32(offY / 2 + i)
            guard let uBuffer = rawData.getUBuffer(row), let vBuffer = rawData.getVBuffer(row) else { continue }
            if enableTransparent {
                for j in 0..<waterUVWidth {
                    let u = Int8(bitPattern: wateri420[waterWidth * waterHeight + i * waterUVWidth + j])
                    let v = Int8(bitPattern: wateri420[waterWidth * waterHeight * 5 / 4 + i * waterUVWidth + j])
                    if u != 16 && u != -128 && u != -21 {
                        uBuffer[offX / 2 + j] = CChar(bitPattern: wateri420[waterWidth * waterHeight + i * waterUVWidth + j])
                    }
                    if v != 16 && v != -128 && v != -21 {
                        vBuffer[offX / 2 + j] = CChar(bitPattern: wateri420[waterWidth * waterHeight * 5 / 4 + i * waterUVWidth + j])
                    }
                }
            } else {
                memcpy(uBuffer.advanced(by: offX / 2), waterUBuffer.advanced(by: i * waterUVWidth), waterUVWidth)
                memcpy(vBuffer.advanced(by: offX / 2), waterVBuffer.advanced(by: i * waterUVWidth), waterUVWidth)
            }
        }
    }

    static func imageToi420(_ image: UIImage) -> UnsafeMutablePointer<UInt8>? {
        guard let cgImage = image.cgImage else { return nil }
        let width = Int(image.size.width)
        let height = Int(image.size.height)
        let pixelCount = width * height
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let argb = UnsafeMutablePointer<UInt8>.allocate(capacity: pixelCount * 4)
        defer { argb.deallocate() }
        guard let context = CGContext(
            data: argb,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 4 * width,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
        ) else { return nil }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        let i420Length = pixelCount + (width / 2) * (height / 2) * 2
        let i420 = UnsafeMutablePointer<UInt8>.allocate(capacity: i420Length)

        var yIndex = 0
        var uIndex = pixelCount
        var vIndex = pixelCount + (width / 2) * (height / 2)
        var index = 0
        for j in 0..<height {
            for i in 0..<width {
                let r = Int(argb[index * 4 + 1])
                let g = Int(argb[index * 4 + 2])
                let b = Int(argb[index * 4 + 3])
                let y = Int(Double(r) * 0.299 + Double(g) * 0.587 + Double(b) * 0.114 + 16)
                let u = Int(Double(r) * -0.169 + Double(g) * -0.331 + Double(b) * 0.499 + 128)
                let v = Int(Double(r) * 0.499 + Double(g) * -0.418 + Double(b) * -0.0813 + 128)
                i420[yIndex] = UInt8(clamping: y); yIndex += 1
                if j % 2 == 0, i % 2 == 0 {
                    i420[uIndex] = UInt8(clamping: u); uIndex += 1
                    i420[vIndex] = UInt8(clamping: v); vIndex += 1
                }
                index += 1
            }
        }

        yuvFrameMirror(data: i420, width: width, height: height)
        return i420
    }

    private static func yuvFrameMirror(data: UnsafeMutablePointer<UInt8>, width: Int, height: Int) {
        for i in 0..<(height * 3 / 2) {
            for j in 0..<(width / 2) {
                let temp = data[i * width + j]
                data[i * width + j] = data[(i + 1) * width - 1 - j]
                data[(i + 1) * width - 1 - j] = temp
            }
        }
    }
}
