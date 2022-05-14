//
//  MainViewModel.swift
//  Visio
//
//  Created by Kirill Pukhov on 20.04.2022.
//

import Foundation
import AVFoundation
import Vision
import RxSwift
import RxCocoa

final class MainViewModel: NSObject {
    private let captureSessionSercvice: CaptureSessionServiceProtocol
    private let cameraService: CameraServiceProtocol
    private let disposeBag: DisposeBag
    
    public lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        var previewLayer = AVCaptureVideoPreviewLayer(session: captureSessionSercvice.captureSession)
        previewLayer.videoGravity = .resizeAspect
        return previewLayer
    }()
    
    public var hasUltraWide: Bool { cameraService.hasUltrawide }
    public var cameraAngle: CameraAngle { cameraService.angle }
    
    public var faceNumber: PublishSubject<Int>!
    public var faceFrames: PublishSubject<[CGRect]>!
    
    override init() {
        captureSessionSercvice = CaptureSessionService()
        cameraService = CameraService(captureSessionService: captureSessionSercvice)
        disposeBag = DisposeBag()
        
        faceNumber = PublishSubject<Int>()
        faceFrames = PublishSubject<[CGRect]>()
        
        super.init()
    }
    
    public func startSession() -> Completable {
        Completable.create { [weak self] completable in
            guard let strongSelf = self else {
                print("Memory leak!")
                return Disposables.create { }
            }

            strongSelf.captureSessionSercvice.requestCameraAuthorization(for: strongSelf.cameraService.mediaType)
                .subscribe(onCompleted: {
                        strongSelf.cameraService.changeCamera(for: .video, position: .back, angle: .wide)
                            .subscribe(onCompleted: {
                                strongSelf.setSampleBufferDelegate()
                                completable(.completed)
                            }, onError: { completable(.error($0)) })
                            .disposed(by: strongSelf.disposeBag)
                }, onError: { completable(.error($0)) })
                .disposed(by: strongSelf.disposeBag)
            
            return Disposables.create { }
        }
    }
    
    private func setSampleBufferDelegate() {
        (captureSessionSercvice.captureSession.outputs.first as! AVCaptureVideoDataOutput).setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: .userInteractive))
    }
    
    enum Error: Swift.Error {
        case camerasNotFound
    }
    
    public func rotateCamera() -> Completable {
        Completable.create { [weak self] completable in
            guard let strongSelf = self else {
                print("Memory leak!")
                return Disposables.create { }
            }
            
            strongSelf.cameraService.changePosition(to: strongSelf.cameraService.position == .back ? .front : .back)
                .subscribe(onCompleted: {
                    strongSelf.setSampleBufferDelegate()
                    completable(.completed)
                }, onError: { completable(.error($0)) })
                .disposed(by: strongSelf.disposeBag)
            
            return Disposables.create { }
        }
    }
    
    public func changeCameraAngle() -> Completable {
        Completable.create { [weak self] completable in
            guard let strongSelf = self else {
                print("Memory leak!")
                return Disposables.create { }
            }
            
            strongSelf.cameraService.changeAngle(to: strongSelf.cameraService.angle == .wide ? .ultraWide : .wide)
                .subscribe(onCompleted: {
                    strongSelf.setSampleBufferDelegate()
                    completable(.completed)
                }, onError: { completable(.error($0)) })
                .disposed(by: strongSelf.disposeBag)
            
            return Disposables.create { }
        }
    }
}

extension MainViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    internal func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let cvImage = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("Can't convert sample buffer to image buffer")
            return
        }
        detectFaceRectangles(in: cvImage)
    }
}

extension MainViewModel {
    private func detectFaceRectangles(in image: CVPixelBuffer) {
        let faceDetectionRequest = VNDetectFaceRectanglesRequest { [weak self] request, error in
            guard error == nil else {
                print("\(Date().formatted(date: .abbreviated, time: .standard)) Error: \(error!.localizedDescription)")
                self?.faceNumber.onNext(0)
                return
            }
            
            if let results = request.results,
               let faces = results as? [VNFaceObservation] {
                self?.faceNumber.onNext(faces.count)
                if UserDefaults.standard.bool(forKey: "FaceRectangles") {
                    self?.faceFrames.onNext(faces.map { $0.boundingBox })
                } else {
                    self?.faceFrames.onNext([])
                }
            }
        }
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: image, orientation: .downMirrored)
        try? imageRequestHandler.perform([faceDetectionRequest])
    }
}
