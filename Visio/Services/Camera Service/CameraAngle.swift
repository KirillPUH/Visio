//
//  CameraAngle.swift
//  Visio
//
//  Created by Kirill Pukhov on 12.05.2022.
//

import AVFoundation

enum CameraAngle {
    case none, wide, ultraWide
    
    var devices: [AVCaptureDevice.DeviceType] {
        switch self {
        case .none:
            return []
        case .wide:
            return [.builtInWideAngleCamera, .builtInDualWideCamera]
        case .ultraWide:
            return [.builtInUltraWideCamera]
        }
    }
}
