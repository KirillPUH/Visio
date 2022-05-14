//
//  CaptureSessionServiceProtocol.swift
//  Visio
//
//  Created by Kirill Pukhov on 20.04.2022.
//

import Foundation
import AVFoundation
import RxSwift

protocol CaptureSessionServiceProtocol {
    var captureSession: AVCaptureSession { get }
    
    func requestCameraAuthorization(for mediaType: AVMediaType) -> Completable
    
    func configure(with devices: [AVCaptureDevice], for dataOutputType: CaptureSessionOutputType) throws
}
