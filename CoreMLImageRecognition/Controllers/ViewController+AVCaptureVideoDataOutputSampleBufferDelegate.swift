//
//  ViewController+AVCaptureVideoDataOutputSampleBufferDelegate.swift
//  CoreMLImageRecognition
//
//  Created by Roman Efimov on 06/03/2019.
//  Copyright © 2019 Roman Efimov. All rights reserved.
//
import AVFoundation
import UIKit
extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        connection.videoOrientation = .portrait
        
        // Resize the frame to 299x299 as required by inceptionv3 model
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        
        let image = UIImage(ciImage: ciImage)
        
        UIGraphicsBeginImageContext(CGSize(width: 299, height: 299))
        image.draw(in: CGRect(x: 0, y: 0, width: 299, height: 299))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        // Convert UIImage to CVPixelBuffer
        
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
            ] as CFDictionary
        
        var pixelBuffer: CVPixelBuffer?
        
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(resizedImage.size.width),
            Int(resizedImage.size.height),
            kCVPixelFormatType_32ARGB,
            attrs,
            &pixelBuffer
        )
        
        guard status == kCVReturnSuccess else { return }
        
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: pixelData,
            width: Int(resizedImage.size.width),
            height: Int(resizedImage.size.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!),
            space: rgbColorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        )
        
        context?.translateBy(x: 0, y: resizedImage.size.height)
        context?.scaleBy(x: 1, y: -1)
        
        UIGraphicsPushContext(context!)
        resizedImage.draw(in: CGRect(x: 0, y: 0, width: resizedImage.size.width, height: resizedImage.size.height))
        UIGraphicsPopContext()
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        // Pass pixel buffer to Core ML model for predictions
        if let pixelBuffer = pixelBuffer {
            guard let output = try? mlModel.prediction(image: pixelBuffer) else {
                return
            }
            
            // Update the label with most likely category
            DispatchQueue.main.async {
                let label = output.classLabel
                let value = output.classLabelProbs[label] ?? 0
                let intValue = Int(round(100 * value))
                
                self.descriptionLabel.text = "\(intValue)% \(label)"
            }
            
            // Print all other categories detected
            for (key, value) in output.classLabelProbs {
                print("\(key) = \(value)")
            }
        }
    }
}
