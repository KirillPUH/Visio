//
//  CameraServiceProtocol.swift
//  Visio
//
//  Created by Kirill Pukhov on 12.05.2022.
//

import Foundation
import AVFoundation
import RxSwift
import RxCocoa

protocol CameraServiceProtocol {
    var mediaType: AVMediaType { get }
    var position: AVCaptureDevice.Position { get }
    var angle: CameraAngle { get }
    var hasUltrawide: Bool { get }
    
    func changeCamera(for mediaType: AVMediaType, position: AVCaptureDevice.Position, angle: CameraAngle) -> Completable
    func changeAngle(to angle: CameraAngle) -> Completable
    func changePosition(to position: AVCaptureDevice.Position) -> Completable
}
