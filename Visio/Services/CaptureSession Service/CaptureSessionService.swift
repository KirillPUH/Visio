//
//  CaptureSessionService.swift
//  Visio
//
//  Created by Kirill Pukhov on 20.04.2022.
//

import Foundation
import AVFoundation
import RxSwift

enum CaptureSessionOutputType {
    case video
    case photo
}

class CaptureSessionService: CaptureSessionServiceProtocol {
    let captureSession = AVCaptureSession()
    
    func requestCameraAuthorization(for mediaType: AVMediaType) -> Completable {
        Completable.create { completable in
            switch AVCaptureDevice.authorizationStatus(for: mediaType) {
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: mediaType) {
                    completable( $0 ? .completed : .error(ServiceError.cameraAuthorizationDenied))
                }
            case .authorized:
                completable(.completed)
            case .restricted, .denied:
                completable(.error(ServiceError.cameraAuthorizationDenied))
            @unknown default:
                fatalError()
            }
            
            return Disposables.create { }
        }
    }
    
    func configure(with devices: [AVCaptureDevice], for outputType: CaptureSessionOutputType) throws {
        captureSession.stopRunning()
        captureSession.beginConfiguration()
        
        captureSession.removeAllInputs()
        captureSession.removeAllOutputs()
        
        for device in devices {
            let deviceInput = try AVCaptureDeviceInput(device: device)
            
            guard captureSession.canAddInput(deviceInput) else {
                throw ServiceError.canNotAddCaptureDeviceInput
            }
            
            captureSession.addInput(deviceInput)
        }
        
        switch outputType {
        case .video:
            let dataOutput = AVCaptureVideoDataOutput()
            
            guard captureSession.canAddOutput(dataOutput) else {
                throw ServiceError.canNotAddCaptureOutput
            }
            
            captureSession.addOutput(dataOutput)
        case .photo:
            let dataOutput = AVCapturePhotoOutput()
            
            guard captureSession.canAddOutput(dataOutput) else {
                throw ServiceError.canNotAddCaptureOutput
            }
            
            captureSession.addOutput(dataOutput)
        }
        
        captureSession.commitConfiguration()
        captureSession.startRunning()
    }
    
    enum ServiceError: Error {
        case cameraAuthorizationDenied
        case canNotAddCaptureDeviceInput
        case canNotAddCaptureOutput
    }
}

extension AVCaptureSession {
    func removeAllInputs() {
        for input in self.inputs {
            self.removeInput(input)
        }
    }
    
    func removeAllOutputs() {
        for output in self.outputs {
            self.removeOutput(output)
        }
    }
}
