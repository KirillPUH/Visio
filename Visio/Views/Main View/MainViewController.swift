//
//  MainViewController.swift
//  Visio
//
//  Created by Kirill Pukhov on 18.04.2022.
//

import UIKit
import AVFoundation
import RxSwift
import RxCocoa

final class MainViewController: UIViewController {
    private var viewModel: MainViewModel!
    private var disposeBag: DisposeBag!
    
    var previewView: UIView!
    var overlayLayer: CALayer!
    @IBOutlet var rotateCameraButton: UIButton!
    @IBOutlet var settingsButton: UIButton!
    @IBOutlet var angleButton: UIButton!
    @IBOutlet var faceCountLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = MainViewModel()
        disposeBag = DisposeBag()
        
        rotateCameraButton.setTitle("", for: .normal)
        settingsButton.setTitle("", for: .normal)
        
        rotateCameraButton.applyStyle()
        settingsButton.applyStyle()
        angleButton.applyStyle()
        faceCountLabel.applyStyle()
        
        viewModel.startSession()
            .observe(on: MainScheduler.instance)
            .subscribe(onCompleted: { [weak self] in
                guard let self = self else { return }
                
                self.configureLabels()
                self.configureButtons()
                
                self.viewModel.faceFrames
                    .asDriver(onErrorJustReturn: [])
                    .drive(onNext: { rectangles in
                        self.drawFaceRectangles(rectangles)
                    })
                    .disposed(by: self.disposeBag)
                
            }, onError: { [weak self] error in
                self?.showAlert(with: error)
            })
            .disposed(by: disposeBag)
        configurePreview()
        
        overlayLayer = CALayer()
        overlayLayer.frame = previewView.bounds
        previewView.layer.addSublayer(overlayLayer)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        // Prevent previewView from rotation #1
        previewView.center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        // Prevent previewView from rotation #2
        coordinator.animate { [weak self] _ in
            guard let self = self else { return }
            
            let deltaTransform = coordinator.targetTransform
            let deltaAngle = atan2f(Float(deltaTransform.b), Float(deltaTransform.a))
            
            var currentRotation = self.previewView.layer.value(forKeyPath: "transform.rotation.z") as! CGFloat
            
            currentRotation += CGFloat(-1 * deltaAngle + 0.0001)
            self.previewView.layer.setValue(currentRotation, forKeyPath: "transform.rotation.z")
        } completion: { [weak self] _ in
            guard let self = self else { return }
            
            var currentTransform = self.previewView.transform;
            currentTransform.a = round(currentTransform.a)
            currentTransform.b = round(currentTransform.b)
            currentTransform.c = round(currentTransform.c)
            currentTransform.d = round(currentTransform.d)
            self.previewView.transform = currentTransform
        }
    }
    
    override var prefersStatusBarHidden: Bool { true }
}

extension MainViewController {
    private func configurePreview() {
        previewView = UIView()
        previewView.frame = view.frame
        previewView.layer.addSublayer(viewModel.previewLayer)
        viewModel.previewLayer.frame = previewView.bounds
        viewModel.previewLayer.connection?.videoOrientation = portrateOrientation()
        view.insertSubview(previewView, at: 0)
    }
    
    private func configureButtons() {
        rotateCameraButton.rx.tap
            .asDriver()
            .drive(onNext: { [weak self] in
                guard let strongSelf = self else { return }
                
                self?.viewModel.rotateCamera()
                    .subscribe(onCompleted: { })
                    .disposed(by: strongSelf.disposeBag)
                self?.angleButton.isHidden = strongSelf.viewModel.hasUltraWide ? false : true
            })
            .disposed(by: disposeBag)
        
        settingsButton.isHidden = false
        settingsButton.rx.tap
            .asDriver()
            .drive(onNext: { [weak self] in
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: SettingsTableViewController.identifier)
                
                self?.navigationController?.pushViewController(vc, animated: true)
            })
            .disposed(by: disposeBag)
        
        angleButton.isHidden = !viewModel.hasUltraWide
        changeAngleButtonImage()
        angleButton.rx.tap
            .asDriver()
            .drive(onNext: { [weak self] in
                self?.viewModel.changeCameraAngle()
                    .subscribe(onCompleted: { })
                    .disposed(by: self!.disposeBag)
                self?.changeAngleButtonImage()
            })
            .disposed(by: disposeBag)
    }
    
    private func configureLabels() {
        viewModel.faceNumber
            .asDriver(onErrorJustReturn: 0)
            .drive(onNext: { [weak self] count in
                self?.faceCountLabel.text = "\(count)"
            })
            .disposed(by: disposeBag)
    }
    
    private func drawFaceRectangles(_ rectangles: [CGRect]) {
        overlayLayer.sublayers = []
        for rectangle in rectangles {
            let scaledRectangle = viewModel.previewLayer.layerRectConverted(fromMetadataOutputRect: rectangle)
            let layer = CAShapeLayer()
            layer.frame = previewView.bounds
            layer.fillColor = UIColor.clear.cgColor
            layer.strokeColor = UIColor.green.cgColor
            layer.lineWidth = 1
            layer.path = UIBezierPath(rect: scaledRectangle).cgPath
            overlayLayer.addSublayer(layer)
        }
    }
    
    private func showAlert(with error: Error) {
        let alert = UIAlertController(title: "Error", message: nil, preferredStyle: .alert)
        
        var message = String(describing: error)
        if let error = error as? MainViewModel.Error,
           error == MainViewModel.Error.camerasNotFound {
            message = "Cameras not found on your \(UIDevice.current.name)"
        }
        
        alert.message = message
        alert.addAction(UIAlertAction(title: "Ok", style: .default))
        
        self.present(alert, animated: false, completion: nil)
    }
    
    private func changeAngleButtonImage() {
        let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: 21, weight: .thin)
        
        let scaleUpSymbol = UIImage(systemName: "arrow.up.backward.and.arrow.down.forward", withConfiguration: symbolConfiguration)?.withTintColor(.black, renderingMode: .alwaysOriginal)
        
        let scaleDownSymbol = UIImage(systemName: "arrow.down.forward.and.arrow.up.backward", withConfiguration: symbolConfiguration)?.withTintColor(.black, renderingMode: .alwaysOriginal)
        scaleDownSymbol?.withTintColor(.black)
        
        angleButton.setImage(viewModel.cameraAngle == .wide ? scaleUpSymbol : scaleDownSymbol, for: .normal)
    }
    
    private func portrateOrientation() -> AVCaptureVideoOrientation {
        var deviceOrientation = UIDevice.current.orientation
        
        if deviceOrientation == .unknown ||
            deviceOrientation == .faceUp ||
            deviceOrientation == .faceDown {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
                fatalError()
            }
            
            switch windowScene.interfaceOrientation {
            case .unknown:
                deviceOrientation = .unknown
            case .portrait:
                deviceOrientation = .portrait
            case .portraitUpsideDown:
                deviceOrientation = .portraitUpsideDown
            case .landscapeLeft:
                deviceOrientation = .landscapeRight
            case .landscapeRight:
                deviceOrientation = .landscapeLeft
            @unknown default:
                fatalError()
            }
        }
        
        switch deviceOrientation {
        case .portrait:
            return .portrait
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .landscapeLeft:
            return .landscapeRight
        case .landscapeRight:
            return .landscapeLeft
        case .faceUp, .faceDown, .unknown:
            fatalError()
        @unknown default:
            fatalError()
        }
    }
}

extension UIView {
    fileprivate func applyStyle() {
        self.layer.cornerRadius = 9
        self.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.25)
        self.clipsToBounds = true
    }
}
