//
//  CameraService.swift
//  Visio
//
//  Created by Kirill Pukhov on 12.05.2022.
//

import Foundation
import AVFoundation
import RxSwift
import RxCocoa

class CameraService: CameraServiceProtocol {
    private var captureSessionService: CaptureSessionServiceProtocol
    
    private(set) var mediaType: AVMediaType
    private(set) var position: AVCaptureDevice.Position
    private(set) var angle: CameraAngle
    
    init(captureSessionService: CaptureSessionServiceProtocol) {
        self.captureSessionService = captureSessionService
        
        mediaType = .video
        position = .back
        angle = .wide
    }
    
    public var hasUltrawide: Bool { (try? getCameras(for: mediaType, position: position, angle: .ultraWide)) != nil }
    
    private func getCameras(for mediaType: AVMediaType, position: AVCaptureDevice.Position, angle: CameraAngle) throws -> [AVCaptureDevice] {
        let devices = AVCaptureDevice.DiscoverySession(deviceTypes: angle.devices, mediaType: mediaType, position: position).devices
        
        guard !devices.isEmpty else { throw CameraError.error }
        
        return devices
    }
    
    private func updateCaptureSession(_ camera: AVCaptureDevice) throws {
        try captureSessionService.configure(with: [camera],
                                            for:  mediaType == .video ? .video : .photo)
    }
    
    public func changeCamera(for mediaType: AVMediaType, position: AVCaptureDevice.Position, angle: CameraAngle) -> Completable {
        Completable.create { [weak self] completable in
            guard let strongSelf = self else {
                print("Memory leak!")
                return Disposables.create { }
            }
            
            do {
                let cameras = try strongSelf.getCameras(for: strongSelf.mediaType,
                                                        position: strongSelf.position,
                                                        angle: strongSelf.angle)
                try strongSelf.updateCaptureSession(cameras.first!)
                completable(.completed)
            } catch {
                completable(.error(CameraError.error))
            }
            
            return Disposables.create { }
        }
    }
    
    public func changeAngle(to newAngle: CameraAngle) -> Completable {
        Completable.create { [weak self] completable in
            guard let strongSelf = self else {
                print("Memory leak!")
                return Disposables.create { }
            }
            
            do {
                let cameras = try strongSelf.getCameras(for: strongSelf.mediaType,
                                                        position: strongSelf.position,
                                                        angle: newAngle)
                
                strongSelf.angle = newAngle
                
                try strongSelf.updateCaptureSession(cameras.first!)
                completable(.completed)
            } catch {
                completable(.error(CameraError.error))
            }
            
            return Disposables.create { }
        }
    }
    
    public func changePosition(to newPosition: AVCaptureDevice.Position) -> Completable {
        Completable.create { [weak self] completable in
            guard let strongSelf = self else {
                print("Memory leak!")
                return Disposables.create { }
            }
            
            do {
                let cameras = try strongSelf.getCameras(for: strongSelf.mediaType,
                                                        position: newPosition,
                                                        angle: .wide)
                
                strongSelf.angle = .wide
                strongSelf.position = newPosition
                
                try strongSelf.updateCaptureSession(cameras.first!)
                completable(.completed)
            } catch {
                completable(.error(CameraError.error))
            }
            
            return Disposables.create { }
        }
    }
}
