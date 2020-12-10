//
//  QRView.swift
//  flutter_qr
//
//  Created by Julius Canute on 21/12/18.
//

import Foundation
import MTBBarcodeScanner

public class QRView:NSObject,FlutterPlatformView {
    @IBOutlet var previewView: UIView!
    var scanner: MTBBarcodeScanner?
    var registrar: FlutterPluginRegistrar
    var channel: FlutterMethodChannel
    
    public init(withFrame frame: CGRect, withRegistrar registrar: FlutterPluginRegistrar, withId id: Int64){
        self.registrar = registrar
        previewView = UIView(frame: frame)
        channel = FlutterMethodChannel(name: "net.touchcapture.qr.flutterqr/qrview_\(id)", binaryMessenger: registrar.messenger())
    }
    
    func isCameraAvailable(success: Bool) -> Void {
        if success {
            do {
                try scanner?.startScanning(resultBlock: { codes in
                    if let codes = codes {
                        for code in codes {
                            guard let stringValue = code.stringValue else { continue }
                            self.channel.invokeMethod("onRecognizeQR", arguments: stringValue)
                        }
                    }
                })
            } catch {
                NSLog("Unable to start scanning")
            }
        } else {
            UIAlertView(title: "Scanning Unavailable", message: "This app does not have permission to access the camera", delegate: nil, cancelButtonTitle: nil, otherButtonTitles: "Ok").show()
        }
    }
    
    public func view() -> UIView {
        channel.setMethodCallHandler({
            [weak self] (call: FlutterMethodCall, result: FlutterResult) -> Void in
            switch(call.method){
                case "setDimensions":
                    var arguments = call.arguments as! Dictionary<String, Double>
                    self?.setDimensions(width: arguments["width"] ?? 0,height: arguments["height"] ?? 0)
                case "flipCamera":
                    self?.flipCamera()
                case "toggleFlash":
                    self?.toggleFlash()
                case "pauseCamera":
                    self?.pauseCamera()
                case "resumeCamera":
                    self?.resumeCamera()
                case "getCameraFacing":
                    let cameraFacingName = self?.getCameraFacing()
                    result(cameraFacingName)
                case "setCameraFacing":
                    let cameraFacingName = call.arguments as! String
                    if let success: Bool = self?.setCameraFacing(cameraFacingName: cameraFacingName) {
                        result(success)
                    }
                default:
                    result(FlutterMethodNotImplemented)
                    return
            }
        })
        return previewView
    }
    
    func setDimensions(width: Double, height: Double) -> Void {
        previewView.frame = CGRect(x: 0, y: 0, width: width, height: height)

        if let sc: MTBBarcodeScanner = scanner {
            if let previewLayer = sc.previewLayer {
                previewLayer.frame = previewView.bounds;
            }
        } else {
            scanner = MTBBarcodeScanner(metadataObjectTypes: [AVMetadataObject.ObjectType.qr.rawValue], previewView: previewView)
            MTBBarcodeScanner.requestCameraPermission(success: isCameraAvailable)
        }
    }
    
    func flipCamera(){
        if let sc: MTBBarcodeScanner = scanner {
            if sc.hasOppositeCamera() {
                sc.flipCamera()
            }
        }
    }

    func getCameraFacing() -> String {
        if let sc: MTBBarcodeScanner = scanner {
            return sc.camera == MTBCamera.front
                ? "front"
                : "back"
        }
        return ""
    }

    func setCameraFacing(cameraFacingName: String) -> Bool {
        if let sc: MTBBarcodeScanner = scanner {
            let facing: MTBCamera = cameraFacingName == "front" ? MTBCamera.front : MTBCamera.back
            do {
                try sc.setCamera(facing)
            } catch {
                // failed to set camera
                return false;
            }
        }
        return true
    }

    func toggleFlash(){
        if let sc: MTBBarcodeScanner = scanner {
            if sc.hasTorch() {
                sc.toggleTorch()
            }
        }
    }
    
    func pauseCamera() {
        if let sc: MTBBarcodeScanner = scanner {
            if sc.isScanning() {
                sc.freezeCapture()
            }
        }
    }
    
    func resumeCamera() {
        if let sc: MTBBarcodeScanner = scanner {
            if !sc.isScanning() {
                sc.unfreezeCapture()
            }
        }
    }
}
