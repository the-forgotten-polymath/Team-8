import SwiftUI
import AVFoundation
import Vision

struct QRScannerView: View {
    @Environment(\.dismiss) var dismiss
    
    // Callback invoked when a code is scanned. Returns the result (Success, Wrong Product, or Unrecognized).
    var onScan: (String) -> QRScanResult
    
    @State private var manualInput = ""
    @State private var lastScannedCode = ""
    @State private var lastScanTime = Date.distantPast
    
    // UI state for showing success/error banners and haptics
    @State private var bannerState: BannerState? = nil
    @State private var cameraPermissionGranted = true
    @State private var isAnimatingLaser = false
    
    enum BannerState: Equatable {
        case success(String, expected: Int, received: Int)
        case wrongProduct
        case unrecognized
        
        var message: String {
            switch self {
            case .success(let name, let expected, let received):
                // expected == 0 signals cycle-count identify-only mode (no qty scan)
                if expected == 0 {
                    return "Identified: \(name) — Enter counted quantity"
                }
                return "Matched: \(name) (\(received)/\(expected))"
            case .wrongProduct:
                return "Wrong Product: Item is not in this shipment"
            case .unrecognized:
                return "Unrecognized QR Code"
            }
        }
        
        var color: Color {
            switch self {
            case .success: return .green
            case .wrongProduct: return .red
            case .unrecognized: return .orange
            }
        }
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .wrongProduct: return "xmark.octagon.fill"
            case .unrecognized: return "exclamationmark.triangle.fill"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                #if targetEnvironment(simulator)
                // --- SIMULATOR MODE ---
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color(UIColor.secondarySystemGroupedBackground))
                                .frame(height: 250)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(Color(.separator), lineWidth: 1)
                                )
                            
                            VStack(spacing: 16) {
                                Image(systemName: "qrcode.viewfinder")
                                    .font(.system(size: 64))
                                    .foregroundColor(.blue)
                                
                                Text("Simulator Camera Preview")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("Type the product QR code below to simulate a hardware scan.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                        }
                        .padding()
                    }
                    
                    // Manual typing text field card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Simulator Input")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 12) {
                            TextField("Enter QR Code (e.g. LUX-ROL-SUB-754)", text: $manualInput)
                                .padding(12)
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(10)
                                .foregroundColor(.primary)
                                .tint(.blue)
                                .autocorrectionDisabled()
                                .autocapitalization(.allCharacters)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                                )
                            
                            Button(action: {
                                let val = manualInput.trimmingCharacters(in: .whitespacesAndNewlines)
                                guard !val.isEmpty else { return }
                                triggerScan(code: val)
                                manualInput = ""
                            }) {
                                Text("Scan")
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(.separator), lineWidth: 1)
                    )
                    .padding(.horizontal)
                    
                    Spacer()
                }
                #else
                // --- HARDWARE DEVICE MODE ---
                ZStack {
                    if cameraPermissionGranted {
                        CameraScannerView(onScan: { code in
                            triggerScan(code: code)
                        })
                        .ignoresSafeArea()
                        
                        // Premium Viewfinder Overlay
                        ZStack {
                            Color.black.opacity(0.4)
                                .mask(
                                    ViewfinderMask(rectSize: CGSize(width: 260, height: 260))
                                        .fill(style: FillStyle(eoFill: true))
                                )
                            
                            // Viewfinder border
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(viewfinderColor, lineWidth: 3)
                                .frame(width: 260, height: 260)
                            
                            // Animated scanline
                            VStack {
                                Spacer()
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [viewfinderColor.opacity(0.01), viewfinderColor, viewfinderColor.opacity(0.01)]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(width: 250, height: 4)
                                    .offset(y: isAnimatingLaser ? 115 : -115)
                                    .animation(
                                        .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                                        value: isAnimatingLaser
                                    )
                                Spacer()
                            }
                            .frame(width: 260, height: 260)
                            .clipped()
                            .onAppear {
                                isAnimatingLaser = true
                            }
                        }
                    } else {
                        VStack(spacing: 20) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            
                            Text("Camera Access Required")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Please enable camera access in Settings to scan barcodes.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            
                            Button(action: {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Text("Open Settings")
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                    }
                }
                #endif
                
                // --- SUCCESS / ERROR HUD BANNER ---
                if let banner = bannerState {
                    VStack {
                        HStack(spacing: 12) {
                            Image(systemName: banner.icon)
                                .font(.title2)
                                .foregroundColor(banner.color)
                            
                            Text(banner.message)
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                        .padding()
                        .transition(.move(edge: .top).combined(with: .opacity))
                        
                        Spacer()
                    }
                }
            }
            .navigationTitle("QR Code Scanner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                    .fontWeight(.bold)
                }
            }
            .onAppear {
                checkCameraPermission()
            }
        }
    }
    
    private var viewfinderColor: Color {
        guard let banner = bannerState else { return .blue }
        return banner.color
    }
    
    private func checkCameraPermission() {
        #if !targetEnvironment(simulator)
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraPermissionGranted = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    cameraPermissionGranted = granted
                }
            }
        default:
            cameraPermissionGranted = false
        }
        #endif
    }
    
    private func triggerScan(code: String) {
        let now = Date()
        // Prevent duplicate scanning of same code too quickly
        if code == lastScannedCode && now.timeIntervalSince(lastScanTime) < 2.0 {
            return
        }
        
        lastScannedCode = code
        lastScanTime = now
        
        let result = onScan(code)
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            switch result {
            case .success(let productName, let expected, let received):
                bannerState = .success(productName, expected: expected, received: received)
                triggerHapticFeedback(.success)
            case .wrongProduct:
                bannerState = .wrongProduct
                triggerHapticFeedback(.error)
            case .unrecognized:
                bannerState = .unrecognized
                triggerHapticFeedback(.error)
            }
        }
        
        // Auto-dismiss banner after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                if bannerState == .success(lastScannedCode, expected: 0, received: 0) || bannerState == .wrongProduct || bannerState == .unrecognized {
                    // Check if it hasn't changed to a newer scan
                    bannerState = nil
                } else if case .success = bannerState {
                    bannerState = nil
                }
            }
        }
    }
    
    private func triggerHapticFeedback(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}

// Custom Viewfinder Mask to dim the outer screen
struct ViewfinderMask: Shape {
    let rectSize: CGSize
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Outer rectangle
        path.addRect(rect)
        // Inner viewfinder rectangle
        let origin = CGPoint(
            x: rect.midX - rectSize.width / 2,
            y: rect.midY - rectSize.height / 2
        )
        let innerRect = CGRect(origin: origin, size: rectSize)
        path.addRoundedRect(in: innerRect, cornerSize: CGSize(width: 16, height: 16))
        return path
    }
}

// UIViewControllerRepresentable bridge for AVFoundation and Vision
#if !targetEnvironment(simulator)
struct CameraScannerView: UIViewControllerRepresentable {
    var onScan: (String) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan)
    }
    
    func makeUIViewController(context: Context) -> ScannerViewController {
        let controller = ScannerViewController()
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}
    
    final class Coordinator: NSObject, ScannerViewControllerDelegate {
        private let onScan: (String) -> Void
        
        init(onScan: @escaping (String) -> Void) {
            self.onScan = onScan
        }
        
        func scanner(_ scanner: ScannerViewController, didScanCode code: String) {
            onScan(code)
        }
    }
}

protocol ScannerViewControllerDelegate: AnyObject {
    func scanner(_ scanner: ScannerViewController, didScanCode code: String)
}

final class ScannerViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    weak var delegate: ScannerViewControllerDelegate?
    
    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let videoOutput = AVCaptureVideoDataOutput()
    private let queue = DispatchQueue(label: "RSMS.Scanner.SessionQueue")
    private let visionQueue = DispatchQueue(label: "RSMS.Scanner.VisionQueue")
    
    private var isProcessingFrame = false
    private var lastProcessTime = Date.distantPast
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        configureSession()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        queue.async { [weak self] in
            guard let self = self else { return }
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        queue.async { [weak self] in
            guard let self = self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }
    
    private func configureSession() {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.session.beginConfiguration()
            self.session.sessionPreset = .high
            
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let input = try? AVCaptureDeviceInput(device: device),
                  self.session.canAddInput(input) else {
                self.session.commitConfiguration()
                return
            }
            
            self.session.addInput(input)
            
            self.videoOutput.alwaysDiscardsLateVideoFrames = true
            self.videoOutput.setSampleBufferDelegate(self, queue: self.visionQueue)
            
            let pixelFormat = kCVPixelFormatType_32BGRA
            self.videoOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: pixelFormat
            ]
            
            if self.session.canAddOutput(self.videoOutput) {
                self.session.addOutput(self.videoOutput)
            }
            
            if let connection = self.videoOutput.connection(with: .video),
               connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
            
            do {
                try device.lockForConfiguration()
                if device.isFocusModeSupported(.continuousAutoFocus) {
                    device.focusMode = .continuousAutoFocus
                }
                if device.isExposureModeSupported(.continuousAutoExposure) {
                    device.exposureMode = .continuousAutoExposure
                }
                device.unlockForConfiguration()
            } catch {
                print("Scanner camera configuration error:", error)
            }
            
            self.session.commitConfiguration()
            
            DispatchQueue.main.async {
                let layer = AVCaptureVideoPreviewLayer(session: self.session)
                layer.videoGravity = .resizeAspectFill
                layer.frame = self.view.bounds
                self.view.layer.addSublayer(layer)
                self.previewLayer = layer
            }
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let now = Date()
        // Limit processing to ~5 frames per second
        guard now.timeIntervalSince(lastProcessTime) > 0.2 else { return }
        guard !isProcessingFrame else { return }
        
        lastProcessTime = now
        isProcessingFrame = true
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            isProcessingFrame = false
            return
        }
        
        let request = VNDetectBarcodesRequest { [weak self] request, error in
            guard let self = self else { return }
            defer { self.isProcessingFrame = false }
            
            if let error = error { return }
            let observations = request.results as? [VNBarcodeObservation] ?? []
            guard let code = observations.first?.payloadStringValue else { return }
            
            DispatchQueue.main.async {
                self.delegate?.scanner(self, didScanCode: code)
            }
        }
        
        request.symbologies = [.qr, .ean13, .ean8, .upce, .code128, .code39, .code93, .pdf417, .dataMatrix]
        
        let handler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: .right,
            options: [:]
        )
        
        do {
            try handler.perform([request])
        } catch {
            print("Scanner Vision handler error:", error)
            isProcessingFrame = false
        }
    }
}
#endif
