import SwiftUI
import AVFoundation
import UIKit

struct FaceRecognitionCameraView: View {
    @StateObject private var faceManager = FaceRecognitionManager()
    @StateObject private var cameraManager = CameraManager()
    @State private var showingRegistrationSheet = false
    @State private var showingRegisteredFaces = false
    @State private var selectedFace: FaceRecognitionResult?
    
    var body: some View {
        ZStack {
            // Camera Preview or Permission State
            if cameraManager.cameraPermissionStatus == .authorized {
                CameraPreview(session: cameraManager.session)
                    .ignoresSafeArea()
                    .onAppear {
                        cameraManager.startSession()
                        // Set up real-time face detection
                        cameraManager.onFrameCaptured = { [weak faceManager] image in
                            Task {
                                await faceManager?.processFrameForRecognition(image)
                            }
                        }
                    }
                    .onDisappear {
                        cameraManager.stopSession()
                        cameraManager.onFrameCaptured = nil
                    }
            } else {
                // Camera Permission State
                CameraPermissionView(cameraManager: cameraManager)
                    .ignoresSafeArea()
            }
            
            // Face Recognition Overlay
            FaceRecognitionOverlay(
                recognitionResults: faceManager.recognitionResults,
                faceLandmarks: faceManager.faceLandmarks,
                isProcessing: faceManager.isRecognizing,
                isRecognizing: faceManager.isRecognizing,
                showGreenFlash: faceManager.showGreenFlash,
                lastRecognizedFace: faceManager.lastRecognizedFace,
                recognitionConfidence: faceManager.recognitionConfidence,
                processingTime: faceManager.processingTime,
                retryCount: faceManager.retryCount,
                isRetrying: faceManager.isRetrying,
                detectionQuality: faceManager.detectionQuality
            )
            
            // Top Controls
            VStack {
                HStack {
                    Button(action: {
                        showingRegisteredFaces = true
                    }) {
                        Image(systemName: "person.2.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    // Test Vectorization Button
                    Button(action: {
                        if let currentImage = cameraManager.capturedImage {
                            Task {
                                await faceManager.testFaceVectorization(image: currentImage)
                            }
                        }
                    }) {
                        Image(systemName: "brain.head.profile")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    
                    Button(action: {
                        showingRegistrationSheet = true
                    }) {
                        Image(systemName: "person.badge.plus")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                }
                .padding()
                
                Spacer()
                
                // Recognition Status
                if faceManager.isRecognizing {
                    HStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Text("Recognizing faces...")
                            .foregroundColor(.white)
                            .font(.headline)
                    }
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(12)
                }
                
                // Recognition Results
                if !faceManager.recognitionResults.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(faceManager.recognitionResults) { result in
                                RecognitionResultCard(result: result) {
                                    selectedFace = result
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 20)
                }
                
                // Error Message
                if let errorMessage = faceManager.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(8)
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                }
            }
        }
        .onAppear {
            cameraManager.startSession()
            Task {
                await faceManager.loadRegisteredFaces()
            }
        }
        .onDisappear {
            cameraManager.stopSession()
        }
        .onChange(of: cameraManager.capturedImage) { image in
            if let image = image {
                Task {
                    await faceManager.recognizeFaces(from: image)
                }
            }
        }
        .sheet(isPresented: $showingRegistrationSheet) {
            FaceRegistrationView(faceManager: faceManager)
        }
        .sheet(isPresented: $showingRegisteredFaces) {
            RegisteredFacesView(faceManager: faceManager)
        }
        .sheet(item: $selectedFace) { face in
            FaceDetailView(face: face)
        }
    }
}

// MARK: - Camera Manager
class CameraManager: NSObject, ObservableObject {
    @Published var session = AVCaptureSession()
    @Published var capturedImage: UIImage?
    @Published var cameraPermissionStatus: AVAuthorizationStatus = .notDetermined
    @Published var isSessionRunning = false
    @Published var frameCount = 0
    @Published var lastFrameTime = Date()
    
    private let photoOutput = AVCapturePhotoOutput()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let frameProcessingQueue = DispatchQueue(label: "frame.processing.queue", qos: .userInitiated)
    
    // Callback for real-time frame processing
    var onFrameCaptured: ((UIImage) -> Void)?
    
    // Frame processing control
    private var lastProcessingTime = Date()
    private let processingInterval: TimeInterval = 0.5 // Process every 500ms
    private var isProcessingFrame = false
    
    override init() {
        super.init()
        checkCameraPermission()
    }
    
    func checkCameraPermission() {
        cameraPermissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch cameraPermissionStatus {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.cameraPermissionStatus = granted ? .authorized : .denied
                    if granted {
                        self?.setupCamera()
                    }
                }
            }
        case .denied, .restricted:
            print("❌ Camera access denied or restricted")
        @unknown default:
            print("❌ Unknown camera permission status")
        }
    }
    
    private func setupCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            
            self.session.beginConfiguration()
            
            // Add video input
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
                  let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
                self.session.commitConfiguration()
                return
            }
            
            if self.session.canAddInput(videoInput) {
                self.session.addInput(videoInput)
            }
            
            // Add photo output
            if self.session.canAddOutput(self.photoOutput) {
                self.session.addOutput(self.photoOutput)
            }
            
            // Add video output for real-time processing
            if self.session.canAddOutput(self.videoOutput) {
                self.session.addOutput(self.videoOutput)
                
                // Configure video output for optimal performance
                self.videoOutput.videoSettings = [
                    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
                ]
                self.videoOutput.alwaysDiscardsLateVideoFrames = true
                
                // Set delegate with dedicated queue
                self.videoOutput.setSampleBufferDelegate(self, queue: self.frameProcessingQueue)
            }
            
            self.session.commitConfiguration()
        }
    }
    
    func startSession() {
        guard cameraPermissionStatus == .authorized else {
            print("❌ Cannot start camera session - permission not granted")
            return
        }
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            if !self.session.isRunning {
                self.session.startRunning()
                DispatchQueue.main.async {
                    self.isSessionRunning = true
                }
                print("✅ Camera session started")
            }
        }
    }
    
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
                DispatchQueue.main.async {
                    self.isSessionRunning = false
                }
                print("⏹️ Camera session stopped")
            }
        }
    }
    
    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
}

// MARK: - Camera Delegate Extensions
extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else { return }
        
        DispatchQueue.main.async {
            self.capturedImage = image
        }
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Throttle frame processing to avoid overwhelming the system
        let currentTime = Date()
        guard currentTime.timeIntervalSince(lastProcessingTime) >= processingInterval,
              !isProcessingFrame else { return }
        
        isProcessingFrame = true
        lastProcessingTime = currentTime
        
        // This is called for each video frame
        // Process the frame for real-time face detection
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            isProcessingFrame = false
            return
        }
        
        // Convert to UIImage for processing
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            isProcessingFrame = false
            return
        }
        let image = UIImage(cgImage: cgImage)
        
        // Update frame statistics
        DispatchQueue.main.async {
            self.frameCount += 1
            self.lastFrameTime = currentTime
        }
        
        // Notify the face manager to process this frame
        DispatchQueue.main.async {
            self.onFrameCaptured?(image)
            self.isProcessingFrame = false
        }
    }
}

// MARK: - Camera Preview
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = .black
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        print("📷 Camera preview layer created")
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
                previewLayer.frame = uiView.bounds
                print("📷 Camera preview layer updated with frame: \(uiView.bounds)")
            }
        }
    }
}

// MARK: - Face Recognition Overlay
struct FaceRecognitionOverlay: View {
    let recognitionResults: [FaceRecognitionResult]
    let faceLandmarks: [FaceLandmarkData]
    let isProcessing: Bool
    let isRecognizing: Bool
    let showGreenFlash: Bool
    let lastRecognizedFace: FaceRecognitionResult?
    let recognitionConfidence: Double
    let processingTime: TimeInterval
    let retryCount: Int
    let isRetrying: Bool
    let detectionQuality: String
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Face bounding boxes
                ForEach(Array(recognitionResults.enumerated()), id: \.offset) { index, result in
                    if let boundingBox = getBoundingBox(for: result.faceLocation, in: geometry.size) {
                        FaceBoundingBox(
                            rect: boundingBox,
                            personName: result.personName,
                            relationship: result.relationship,
                            confidence: result.confidence,
                            isRecognized: result.personName != "Unknown"
                        )
                    }
                }
                
                // Face landmarks
                ForEach(Array(faceLandmarks.enumerated()), id: \.offset) { faceIndex, landmarkData in
                    ForEach(getLandmarkPoints(for: landmarkData, in: geometry.size), id: \.id) { point in
                        Circle()
                            .fill(point.landmarkType == "chin" ? Color.blue : Color.green)
                            .frame(width: 4, height: 4)
                            .position(x: point.x, y: point.y)
                    }
                }
                
                // Green Flash Effect for Successful Recognition
                if showGreenFlash {
                    Rectangle()
                        .fill(Color.green.opacity(0.3))
                        .ignoresSafeArea()
                        .animation(.easeInOut(duration: 0.3), value: showGreenFlash)
                }
                
                // Recognition Success Message
                if showGreenFlash, let recognizedFace = lastRecognizedFace {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            VStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.green)
                                
                                Text("Face Recognized!")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text(recognizedFace.personName)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.green)
                                
                                Text(recognizedFace.relationship)
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.black.opacity(0.8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.green, lineWidth: 2)
                                    )
                            )
                            Spacer()
                        }
                        .padding()
                    }
                    .animation(.easeInOut(duration: 0.5), value: showGreenFlash)
                }
                
                // Status Indicator
                VStack {
                    HStack {
                        Spacer()
                        StatusIndicator(
                            isProcessing: isProcessing || isRecognizing,
                            isRetrying: isRetrying,
                            retryCount: retryCount,
                            recognitionConfidence: recognitionConfidence,
                            processingTime: processingTime,
                            detectionQuality: detectionQuality
                        )
                        .padding(.top, 50)
                        .padding(.trailing, 20)
                    }
                    Spacer()
                }
                
                // Processing indicator
                if isRecognizing && !showGreenFlash {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            VStack(spacing: 8) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.5)
                                Text("Detecting faces...")
                                    .foregroundColor(.white)
                                    .font(.headline)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(12)
                        .padding()
                    }
                }
            }
        }
    }
    
    private func getBoundingBox(for faceLocation: [Int], in size: CGSize) -> CGRect? {
        guard faceLocation.count >= 4 else { return nil }
        
        // face_location format: [top, right, bottom, left]
        let left = CGFloat(faceLocation[3])
        let top = CGFloat(faceLocation[0])
        let right = CGFloat(faceLocation[1])
        let bottom = CGFloat(faceLocation[2])
        
        return CGRect(
            x: left,
            y: top,
            width: right - left,
            height: bottom - top
        )
    }
    
    private func getLandmarkPoints(for landmarkData: FaceLandmarkData, in size: CGSize) -> [LandmarkPoint] {
        var points: [LandmarkPoint] = []
        
        for (landmarkType, coordinates) in landmarkData.landmarks {
            for coordinate in coordinates {
                if coordinate.count >= 2 {
                    points.append(LandmarkPoint(
                        x: coordinate[0],
                        y: coordinate[1],
                        landmarkType: landmarkType
                    ))
                }
            }
        }
        
        return points
    }
}

struct LandmarkPoint: Identifiable {
    let id = UUID()
    let x: Double
    let y: Double
    let landmarkType: String
}

// MARK: - Face Bounding Box with Vector Lines
struct FaceBoundingBox: View {
    let rect: CGRect
    let personName: String
    let relationship: String
    let confidence: Double
    let isRecognized: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ZStack {
                // Main bounding rectangle
                Rectangle()
                    .stroke(isRecognized ? Color.green : Color.red, lineWidth: 3)
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)
                
                // Vector lines around the face
                FaceVectorLines(rect: rect, isRecognized: isRecognized)
            }
            
            // Name and relationship label
            VStack(alignment: .leading, spacing: 2) {
                Text(personName)
                    .font(.headline)
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                
                Text(relationship)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                
                if isRecognized {
                    Text("\(Int(confidence * 100))% match")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            .padding(8)
            .background(Color.black.opacity(0.7))
            .cornerRadius(8)
            .position(x: rect.midX, y: rect.maxY + 30)
        }
    }
}

// MARK: - Face Vector Lines
struct FaceVectorLines: View {
    let rect: CGRect
    let isRecognized: Bool
    
    var body: some View {
        ZStack {
            // Corner vectors
            ForEach(0..<4) { corner in
                CornerVector(
                    rect: rect,
                    corner: corner,
                    color: isRecognized ? Color.green : Color.red
                )
            }
            
            // Center crosshair
            CenterCrosshair(
                rect: rect,
                color: isRecognized ? Color.green : Color.red
            )
            
            // Side vectors
            ForEach(0..<4) { side in
                SideVector(
                    rect: rect,
                    side: side,
                    color: isRecognized ? Color.green : Color.red
                )
            }
        }
    }
}

// MARK: - Corner Vector
struct CornerVector: View {
    let rect: CGRect
    let corner: Int
    let color: Color
    
    private var cornerPoint: CGPoint {
        switch corner {
        case 0: return CGPoint(x: rect.minX, y: rect.minY) // Top-left
        case 1: return CGPoint(x: rect.maxX, y: rect.minY) // Top-right
        case 2: return CGPoint(x: rect.maxX, y: rect.maxY) // Bottom-right
        case 3: return CGPoint(x: rect.minX, y: rect.maxY) // Bottom-left
        default: return CGPoint(x: rect.midX, y: rect.midY)
        }
    }
    
    private var vectorEnd: CGPoint {
        let vectorLength: CGFloat = 20
        switch corner {
        case 0: return CGPoint(x: rect.minX - vectorLength, y: rect.minY - vectorLength)
        case 1: return CGPoint(x: rect.maxX + vectorLength, y: rect.minY - vectorLength)
        case 2: return CGPoint(x: rect.maxX + vectorLength, y: rect.maxY + vectorLength)
        case 3: return CGPoint(x: rect.minX - vectorLength, y: rect.maxY + vectorLength)
        default: return cornerPoint
        }
    }
    
    var body: some View {
        Path { path in
            path.move(to: cornerPoint)
            path.addLine(to: vectorEnd)
        }
        .stroke(color, lineWidth: 2)
        .position(x: rect.midX, y: rect.midY)
    }
}

// MARK: - Center Crosshair
struct CenterCrosshair: View {
    let rect: CGRect
    let color: Color
    
    var body: some View {
        ZStack {
            // Horizontal line
            Rectangle()
                .fill(color)
                .frame(width: rect.width * 0.6, height: 1)
                .position(x: rect.midX, y: rect.midY)
            
            // Vertical line
            Rectangle()
                .fill(color)
                .frame(width: 1, height: rect.height * 0.6)
                .position(x: rect.midX, y: rect.midY)
            
            // Center dot
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
                .position(x: rect.midX, y: rect.midY)
        }
    }
}

// MARK: - Side Vector
struct SideVector: View {
    let rect: CGRect
    let side: Int
    let color: Color
    
    private var sideCenter: CGPoint {
        switch side {
        case 0: return CGPoint(x: rect.midX, y: rect.minY) // Top
        case 1: return CGPoint(x: rect.maxX, y: rect.midY) // Right
        case 2: return CGPoint(x: rect.midX, y: rect.maxY) // Bottom
        case 3: return CGPoint(x: rect.minX, y: rect.midY) // Left
        default: return CGPoint(x: rect.midX, y: rect.midY)
        }
    }
    
    private var vectorEnd: CGPoint {
        let vectorLength: CGFloat = 15
        switch side {
        case 0: return CGPoint(x: rect.midX, y: rect.minY - vectorLength)
        case 1: return CGPoint(x: rect.maxX + vectorLength, y: rect.midY)
        case 2: return CGPoint(x: rect.midX, y: rect.maxY + vectorLength)
        case 3: return CGPoint(x: rect.minX - vectorLength, y: rect.midY)
        default: return sideCenter
        }
    }
    
    var body: some View {
        Path { path in
            path.move(to: sideCenter)
            path.addLine(to: vectorEnd)
        }
        .stroke(color, lineWidth: 1.5)
        .position(x: rect.midX, y: rect.midY)
    }
}

// MARK: - Recognition Result Card
struct RecognitionResultCard: View {
    let result: FaceRecognitionResult
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: result.personName == "Unknown" ? "person.fill" : "person.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(result.personName == "Unknown" ? .red : .green)
                
                Text(result.personName)
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(result.relationship)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                
                if result.personName != "Unknown" {
                    Text("\(Int(result.confidence * 100))%")
                        .font(.caption)
                        .foregroundColor(.green)
                        .fontWeight(.bold)
                }
            }
            .padding()
            .frame(width: 120, height: 120)
            .background(Color.black.opacity(0.7))
            .cornerRadius(12)
        }
    }
}

// MARK: - Face Detail View
struct FaceDetailView: View {
    let face: FaceRecognitionResult
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                VStack(spacing: 12) {
                    Text(face.personName)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(face.relationship)
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    if let additionalInfo = face.additionalInfo, !additionalInfo.isEmpty {
                        Text(additionalInfo)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    HStack {
                        Text("Confidence:")
                        Spacer()
                        Text("\(Int(face.confidence * 100))%")
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Face Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Camera Permission View
struct CameraPermissionView: View {
    @ObservedObject var cameraManager: CameraManager
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Camera Access Required")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("LovedOnes needs camera access to enable face recognition features.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if cameraManager.cameraPermissionStatus == .denied {
                VStack(spacing: 12) {
                    Text("Camera access was denied.")
                        .foregroundColor(.red)
                    
                    Text("Please go to Settings > Privacy & Security > Camera and enable access for LovedOnes.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            } else if cameraManager.cameraPermissionStatus == .notDetermined {
                Button("Grant Camera Access") {
                    cameraManager.checkCameraPermission()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

// MARK: - Status Indicator
struct StatusIndicator: View {
    let isProcessing: Bool
    let isRetrying: Bool
    let retryCount: Int
    let recognitionConfidence: Double
    let processingTime: TimeInterval
    let detectionQuality: String
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            // Quality Indicator
            HStack(spacing: 4) {
                Image(systemName: qualityIcon)
                    .foregroundColor(qualityColor)
                Text(detectionQuality)
                    .font(.caption)
                    .foregroundColor(qualityColor)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(qualityColor.opacity(0.2))
            .cornerRadius(8)
            
            // Processing Status
            if isProcessing {
                HStack(spacing: 4) {
                    if isRetrying {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.orange)
                        Text("Retry \(retryCount)")
                            .font(.caption)
                            .foregroundColor(.orange)
                    } else {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Processing...")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.6))
                .cornerRadius(8)
            }
            
            // Performance Metrics
            if recognitionConfidence > 0 {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Confidence: \(Int(recognitionConfidence * 100))%")
                        .font(.caption2)
                        .foregroundColor(.white)
                    Text("Time: \(String(format: "%.1f", processingTime))s")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.6))
                .cornerRadius(8)
            }
        }
    }
    
    private var qualityIcon: String {
        switch detectionQuality {
        case "Excellent": return "star.fill"
        case "Good": return "star"
        case "Fair": return "star.leadinghalf.filled"
        default: return "exclamationmark.triangle"
        }
    }
    
    private var qualityColor: Color {
        switch detectionQuality {
        case "Excellent": return .green
        case "Good": return .blue
        case "Fair": return .orange
        default: return .red
        }
    }
}

#Preview {
    FaceRecognitionCameraView()
}
