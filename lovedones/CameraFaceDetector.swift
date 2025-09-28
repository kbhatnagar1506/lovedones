//
//  CameraFaceDetector.swift
//  lovedones
//
//  Created by krishna bhatnagar on 9/27/25.
//

import SwiftUI
import AVFoundation
import Vision
import UIKit

// MARK: - Camera Face Detector
class CameraFaceDetector: NSObject, ObservableObject {
    @Published var detectedFaces: [FaceDetectionResult] = []
    @Published var isDetecting = false
    @Published var errorMessage: String?
    
    let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let faceService = AzureFaceService.shared
    
    private var isSessionRunning = false
    private var lastDetectionTime = Date()
    private let detectionInterval: TimeInterval = 2.0 // Detect faces every 2 seconds
    
    override init() {
        super.init()
        // Don't setup camera immediately - wait until needed
    }
    
    // MARK: - Camera Setup
    private func setupCamera() {
        sessionQueue.async { [weak self] in
            self?.configureSession()
        }
    }
    
    private func configureSession() {
        guard !captureSession.isRunning else { return }
        
        captureSession.beginConfiguration()
        
        // Set session preset
        if captureSession.canSetSessionPreset(.medium) {
            captureSession.sessionPreset = .medium
        }
        
        // Add video input
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              captureSession.canAddInput(videoInput) else {
            captureSession.commitConfiguration()
            DispatchQueue.main.async {
                self.errorMessage = "Failed to setup camera input"
            }
            return
        }
        
        captureSession.addInput(videoInput)
        
        // Add video output
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
            videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
            videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        }
        
        captureSession.commitConfiguration()
    }
    
    // MARK: - Session Control
    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self, !self.isSessionRunning else { return }
            
            // Ensure configuration is complete before starting
            if self.captureSession.inputs.isEmpty {
                self.configureSession()
            }
            
            self.captureSession.startRunning()
            self.isSessionRunning = true
            
            DispatchQueue.main.async {
                self.isDetecting = true
            }
        }
    }
    
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self, self.isSessionRunning else { return }
            
            self.captureSession.stopRunning()
            self.isSessionRunning = false
            
            DispatchQueue.main.async {
                self.isDetecting = false
                self.detectedFaces = []
            }
        }
    }
    
    deinit {
        if isSessionRunning {
            captureSession.stopRunning()
        }
    }
    
    // MARK: - Face Detection
    private func detectFaces(in pixelBuffer: CVPixelBuffer) {
        let request = VNDetectFaceRectanglesRequest { [weak self] request, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.errorMessage = "Face detection error: \(error.localizedDescription)"
                }
                return
            }
            
            guard let observations = request.results as? [VNFaceObservation] else { return }
            
            // Process faces
            self?.processFaceObservations(observations, pixelBuffer: pixelBuffer)
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])
    }
    
    private func processFaceObservations(_ observations: [VNFaceObservation], pixelBuffer: CVPixelBuffer) {
        // Check if enough time has passed since last detection
        guard Date().timeIntervalSince(lastDetectionTime) >= detectionInterval else { return }
        lastDetectionTime = Date()
        
        // Convert pixel buffer to UIImage
        guard let image = pixelBufferToUIImage(pixelBuffer) else { return }
        
        // Send to Azure Face API for identification
        Task {
            do {
                let faceResults = try await faceService.detectFaces(in: image)
                
                await MainActor.run {
                    self.detectedFaces = faceResults
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Azure Face API error: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func pixelBufferToUIImage(_ pixelBuffer: CVPixelBuffer) -> UIImage? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraFaceDetector: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // Rotate the image for front camera
        if #available(iOS 17.0, *) {
            connection.videoRotationAngle = 90
        } else {
            connection.videoOrientation = .portrait
        }
        
        detectFaces(in: pixelBuffer)
    }
}

// MARK: - Camera Preview View
struct CameraPreviewView: UIViewRepresentable {
    let cameraDetector: CameraFaceDetector
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = .black
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: cameraDetector.captureSession)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update preview layer frame if needed
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = uiView.bounds
        }
    }
}

// MARK: - Face Detection Overlay
struct FaceDetectionOverlay: View {
    let detectedFaces: [FaceDetectionResult]
    let screenSize: CGSize
    
    var body: some View {
        ZStack {
            ForEach(Array(detectedFaces.enumerated()), id: \.offset) { index, face in
                FaceDetectionBox(
                    face: face,
                    screenSize: screenSize
                )
            }
        }
    }
}

// MARK: - Face Detection Box
struct FaceDetectionBox: View {
    let face: FaceDetectionResult
    let screenSize: CGSize
    
    var body: some View {
        VStack {
            // Face rectangle
            Rectangle()
                .stroke(face.personName != nil ? Color.green : Color.red, lineWidth: 2)
                .frame(
                    width: face.faceRectangle.width,
                    height: face.faceRectangle.height
                )
                .position(
                    x: face.faceRectangle.midX,
                    y: face.faceRectangle.midY
                )
            
            // Person name label
            if let personName = face.personName {
                Text(personName)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green)
                    .cornerRadius(8)
                    .position(
                        x: face.faceRectangle.midX,
                        y: face.faceRectangle.minY - 20
                    )
            } else {
                Text("Unknown")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red)
                    .cornerRadius(8)
                    .position(
                        x: face.faceRectangle.midX,
                        y: face.faceRectangle.minY - 20
                    )
            }
        }
    }
}

// MARK: - Real-time Face Detection View
struct RealTimeFaceDetectionView: View {
    @StateObject private var cameraDetector = CameraFaceDetector()
    @State private var screenSize = CGSize.zero
    
    var body: some View {
        ZStack {
            // Camera preview
            CameraPreviewView(cameraDetector: cameraDetector)
                .ignoresSafeArea()
            
            // Face detection overlay
            FaceDetectionOverlay(
                detectedFaces: cameraDetector.detectedFaces,
                screenSize: screenSize
            )
            
            // Controls overlay
            VStack {
                Spacer()
                
                HStack {
                    // Start/Stop button
                    Button(action: {
                        if cameraDetector.isDetecting {
                            cameraDetector.stopSession()
                        } else {
                            cameraDetector.startSession()
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(cameraDetector.isDetecting ? Color.red : Color.green)
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: cameraDetector.isDetecting ? "stop.fill" : "play.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                    }
                    
                    Spacer()
                    
                    // Status indicator
                    VStack {
                        Circle()
                            .fill(cameraDetector.isDetecting ? Color.green : Color.gray)
                            .frame(width: 12, height: 12)
                        
                        Text(cameraDetector.isDetecting ? "Detecting" : "Stopped")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }
                .padding()
                .background(Color.black.opacity(0.5))
                .cornerRadius(12)
                .padding()
            }
        }
        .onAppear {
            screenSize = UIScreen.main.bounds.size
            cameraDetector.startSession()
        }
        .onDisappear {
            cameraDetector.stopSession()
        }
        .alert("Error", isPresented: .constant(cameraDetector.errorMessage != nil)) {
            Button("OK") {
                cameraDetector.errorMessage = nil
            }
        } message: {
            if let error = cameraDetector.errorMessage {
                Text(error)
            }
        }
    }
}
