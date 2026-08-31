import AVFoundation
import SwiftUI

struct QRCodeScannerView: UIViewControllerRepresentable {
    let onScan: (String) -> Void
    let onCancel: (() -> Void)?

    init(onScan: @escaping (String) -> Void, onCancel: (() -> Void)? = nil) {
        self.onScan = onScan
        self.onCancel = onCancel
    }

    func makeUIViewController(context: Context) -> QRScannerViewController {
        let controller = QRScannerViewController()
        controller.onScan = onScan
        controller.onCancel = onCancel
        return controller
    }

    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {}
}

final class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onScan: ((String) -> Void)?
    var onCancel: (() -> Void)?

    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var metadataOutput: AVCaptureMetadataOutput?
    private let overlayView = QRScanOverlayView()
    private var didScan = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        configureOverlay()
        configureCamera()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
        updateScanRegion()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if session.isRunning {
            session.stopRunning()
        }
    }

    private func configureOverlay() {
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlayView)
        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        if onCancel != nil {
            let cancelButton = UIButton(type: .system)
            cancelButton.setTitle("Cancel", for: .normal)
            cancelButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
            cancelButton.tintColor = .white
            cancelButton.translatesAutoresizingMaskIntoConstraints = false
            cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
            view.addSubview(cancelButton)
            NSLayoutConstraint.activate([
                cancelButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
                cancelButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
            ])
        }
    }

    @objc private func cancelTapped() {
        onCancel?()
    }

    private func configureCamera() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.setupSession()
                    } else {
                        self?.showPermissionDenied()
                    }
                }
            }
        default:
            showPermissionDenied()
        }
    }

    private func setupSession() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            showPermissionDenied()
            return
        }

        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else {
            showPermissionDenied()
            return
        }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        output.metadataObjectTypes = [.qr]
        metadataOutput = output

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.layer.bounds
        view.layer.insertSublayer(preview, at: 0)
        previewLayer = preview
        view.bringSubviewToFront(overlayView)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
            DispatchQueue.main.async {
                self?.updateScanRegion()
            }
        }
    }

    private func updateScanRegion() {
        guard let previewLayer, let metadataOutput else { return }
        let scanRect = overlayView.scanRect(in: view.bounds)
        metadataOutput.rectOfInterest = previewLayer.metadataOutputRectConverted(
            fromLayerRect: scanRect
        )
    }

    private func showPermissionDenied() {
        let label = UILabel()
        label.text = "Camera access is required to scan QR codes. Enable it in Settings."
        label.textColor = .white
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard !didScan,
              let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              object.type == .qr,
              let value = object.stringValue else { return }

        didScan = true
        session.stopRunning()
        onScan?(value)
    }
}

private final class QRScanOverlayView: UIView {
    private let dimLayer = CAShapeLayer()
    private let frameLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear

        dimLayer.fillColor = UIColor.black.withAlphaComponent(0.55).cgColor
        dimLayer.fillRule = .evenOdd
        layer.addSublayer(dimLayer)

        frameLayer.fillColor = UIColor.clear.cgColor
        frameLayer.strokeColor = UIColor.white.cgColor
        frameLayer.lineWidth = 3
        frameLayer.lineJoin = .round
        layer.addSublayer(frameLayer)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updatePaths()
    }

    func scanRect(in bounds: CGRect) -> CGRect {
        let side = min(bounds.width, bounds.height) * 0.62
        return CGRect(
            x: (bounds.width - side) / 2,
            y: (bounds.height - side) / 2,
            width: side,
            height: side
        )
    }

    private func updatePaths() {
        let scanRect = scanRect(in: bounds)
        let dimPath = UIBezierPath(rect: bounds)
        dimPath.append(UIBezierPath(roundedRect: scanRect, cornerRadius: 12))
        dimLayer.path = dimPath.cgPath

        let cornerLength = scanRect.width * 0.14
        let framePath = UIBezierPath()
        addCorner(to: framePath, at: scanRect.origin, cornerLength: cornerLength, corner: .topLeft)
        addCorner(
            to: framePath,
            at: CGPoint(x: scanRect.maxX, y: scanRect.minY),
            cornerLength: cornerLength,
            corner: .topRight
        )
        addCorner(
            to: framePath,
            at: CGPoint(x: scanRect.minX, y: scanRect.maxY),
            cornerLength: cornerLength,
            corner: .bottomLeft
        )
        addCorner(
            to: framePath,
            at: CGPoint(x: scanRect.maxX, y: scanRect.maxY),
            cornerLength: cornerLength,
            corner: .bottomRight
        )
        frameLayer.path = framePath.cgPath
    }

    private enum Corner {
        case topLeft, topRight, bottomLeft, bottomRight
    }

    private func addCorner(
        to path: UIBezierPath,
        at point: CGPoint,
        cornerLength: CGFloat,
        corner: Corner
    ) {
        switch corner {
        case .topLeft:
            path.move(to: CGPoint(x: point.x, y: point.y + cornerLength))
            path.addLine(to: point)
            path.addLine(to: CGPoint(x: point.x + cornerLength, y: point.y))
        case .topRight:
            path.move(to: CGPoint(x: point.x - cornerLength, y: point.y))
            path.addLine(to: point)
            path.addLine(to: CGPoint(x: point.x, y: point.y + cornerLength))
        case .bottomLeft:
            path.move(to: CGPoint(x: point.x, y: point.y - cornerLength))
            path.addLine(to: point)
            path.addLine(to: CGPoint(x: point.x + cornerLength, y: point.y))
        case .bottomRight:
            path.move(to: CGPoint(x: point.x - cornerLength, y: point.y))
            path.addLine(to: point)
            path.addLine(to: CGPoint(x: point.x, y: point.y - cornerLength))
        }
    }
}
