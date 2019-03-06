//
//  ViewController.swift
//  CoreMLImageRecognition
//
//  Created by Roman Efimov on 06/03/2019.
//  Copyright © 2019 Roman Efimov. All rights reserved.
//

import AVFoundation
import UIKit

class ViewController: UIViewController {
    
    // MARK: - ... @IBOutlet
    /// Label which will hold the most likely object recognized
    @IBOutlet weak var descriptionLabel: UILabel!
    
    /// Capture activity manager and coordinator
    var captureSession = AVCaptureSession()
    
    /// Core animation layer to display captured video
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    
    /// Prediction model from https://developer.apple.com/machine-learning/build-run-models/
    var mlModel = Inceptionv3()
    
    // MARK: - ... UIViewController Methods
    // Configure the capturing when loaded
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
    
    // Start capturing session when view appears
    override func viewDidAppear(_ animated: Bool) {
        captureSession.startRunning()
    }
    
    // Stop capturing session when view disappears
    override func viewDidDisappear(_ animated: Bool) {
        captureSession.stopRunning()
    }
    
    // MARK: - ... Custom Methods
    /// Configure the capturing
    func configure() {
        // Get the default device for capturing video
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            print("ERROR in \(#function) at line \(#line): Can't get capture device")
            return
        }
        
        // Get input from video to capture session
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            
            captureSession.addInput(input)
            
            let videoDataOutput = AVCaptureVideoDataOutput()
            videoDataOutput.setSampleBufferDelegate(self as? AVCaptureVideoDataOutputSampleBufferDelegate, queue: DispatchQueue(label: "imageRecognition.queue"))
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            captureSession.addOutput(videoDataOutput)
        } catch {
            print("ERROR in \(#function) at line \(#line): \(error.localizedDescription)")
            return
        }
        
        // Setup video preview layer
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer?.videoGravity = .resizeAspectFill
        videoPreviewLayer?.frame = view.layer.bounds
        view.layer.addSublayer(videoPreviewLayer!)
        
        // Setup description label
        descriptionLabel.text = "Looking for objects..."
        view.bringSubviewToFront(descriptionLabel)
    }
}


