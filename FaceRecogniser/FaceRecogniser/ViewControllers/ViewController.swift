//
//  ViewController.swift
//  FaceRecogniser
//
//  Created by Piotr Wesołowski on 03/10/2023.
//

import UIKit
import AVFoundation
import Vision
import CoreImage

class ViewController: UIViewController {

    private lazy var detectionView = UIView()
    private lazy var previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
    private let captureSession = AVCaptureSession()
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private var faceHasBeenDetected = false
    
    override func viewWillAppear(_ animated: Bool) {
        faceHasBeenDetected = false
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Camera View"
        
        self.addCameraInput()
        self.showCameraFeed()
        self.getCameraFrames()
        self.setupDetectionFrame()
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.previewLayer.frame = self.view.frame
    }

    private func addCameraInput() {
        guard let device = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera],
            mediaType: .video,
            position: .front).devices.first else {
               fatalError("No back camera device found")
        }
        let cameraInput = try! AVCaptureDeviceInput(device: device)
        self.captureSession.addInput(cameraInput)
    }
    
    private func showCameraFeed() {
        self.previewLayer.videoGravity = .resizeAspectFill
        self.view.layer.addSublayer(self.previewLayer)
        self.previewLayer.frame = self.view.frame
    }
    
    private func getCameraFrames() {
        self.videoDataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_32BGRA)] as [String : Any]
        self.videoDataOutput.alwaysDiscardsLateVideoFrames = true
        self.videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera_frame_processing_queue"))
        self.captureSession.addOutput(self.videoDataOutput)
        guard let connection = self.videoDataOutput.connection(with: AVMediaType.video),
              connection.isVideoRotationAngleSupported(0.0) else { return }
        connection.videoRotationAngle = 0
    }
    
    private func detectFace(in image: CVPixelBuffer) {
        let faceDetectionRequest = VNDetectFaceLandmarksRequest(completionHandler: { (request: VNRequest, error: Error?) in
            DispatchQueue.main.async {
                if let results = request.results as? [VNFaceObservation], results.count > 0 {
                    self.faceHasBeenDetected = true
                    self.detectionView.layer.borderColor = UIColor.green.cgColor
                    self.captureSession.stopRunning()
                    self.showSpinnerLoader()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.showHistogramViewController(image)
                    }
                } else {
                    self.detectionView.layer.borderColor = UIColor.red.cgColor
                }
            }
        })
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: image, orientation: .leftMirrored, options: [:])
        faceDetectionRequest.regionOfInterest = CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5)
        try? imageRequestHandler.perform([faceDetectionRequest])
    }

    private func setupDetectionFrame() {
        let screenSize = UIScreen.main.bounds
        let padding: CGFloat = 50.0
        let detectionFrame = CGRect(
            x: padding,
            y: padding * 3,
            width: screenSize.width - 2 * padding,
            height: screenSize.height - 6 * padding
        )
        
        detectionView = UIView(frame: detectionFrame)
        detectionView.layer.borderColor = UIColor.red.cgColor
        detectionView.layer.borderWidth = 2.0

        self.view.addSubview(detectionView)
    }
    
    private func showHistogramViewController(_ image: CVPixelBuffer) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let histogramVC = storyboard.instantiateViewController(withIdentifier: "HistogramViewController") as? HistogramViewController {
            histogramVC.captureImage = convert(pixelBuffer: image)
            self.navigationController?.pushViewController(histogramVC, animated: true)
        }
    }
    
    private func convert(pixelBuffer: CVPixelBuffer) -> UIImage? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext(options: nil)
        
        if let cgImage = context.createCGImage(ciImage, from: CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))) {
            return UIImage(cgImage: cgImage)
        }
        
        return nil
    }
    
    private func showSpinnerLoader() {
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true
        detectionView.addSubview(spinner)
        
        spinner.centerXAnchor.constraint(equalTo: detectionView.centerXAnchor).isActive = true
        spinner.centerYAnchor.constraint(equalTo: detectionView.centerYAnchor).isActive = true

        spinner.startAnimating()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            spinner.stopAnimating()
        }
    }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let frame = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            debugPrint("unable to get image from sample buffer")
            return
        }
        if !faceHasBeenDetected {
            self.detectFace(in: frame)
        }
    }
}
