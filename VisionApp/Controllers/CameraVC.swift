//
//  ViewController.swift
//  VisionApp
//
//  Created by Jerry Lai on 2021-01-26.
//  Copyright © 2021 Jerry Lai. All rights reserved.
//

import UIKit
import AVFoundation
import CoreML
import Vision

enum FlashState {
    case off
    case on
}

class CameraVC: UIViewController {
    
    var captureSession: AVCaptureSession!
    var cameraOutput: AVCapturePhotoOutput!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    var photoData: Data?
    
    var flashState: FlashState = .off
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    var speechSynthesizer = AVSpeechSynthesizer()
    
    @IBOutlet weak var roundedView: RoundedShadowView!
    
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var captureImgView: RoundedShadowImageView!
    
    @IBOutlet weak var flashBtn: RoundedShadowButton!
    
    @IBOutlet weak var identificationLbl: UILabel!
    
    @IBOutlet weak var confidenceLbl: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    
    @IBAction func onFlashBtnTapped(_ sender: Any) {
        switch flashState {
        case .off:
            flashBtn.setTitle("FLASH ON", for: .normal)
            flashState = .on
        case .on:
            flashBtn.setTitle("FLASH OFF", for: .normal)
            flashState = .off
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        previewLayer.frame = cameraView.bounds
        speechSynthesizer.delegate = self
        spinner.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapCameraView))
        tap.numberOfTapsRequired = 1
        
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = AVCaptureSession.Preset.hd1920x1080
        
        let backCamera = AVCaptureDevice.default(for: AVMediaType.video)
        
        do {
            let input = try AVCaptureDeviceInput(device: backCamera!)
            if captureSession.canAddInput(input)==true{
                captureSession.addInput(input)
            }
            
            cameraOutput = AVCapturePhotoOutput()
            if captureSession.canAddOutput(cameraOutput) == true{
                captureSession.addOutput(cameraOutput!)
                
                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
                previewLayer.videoGravity = AVLayerVideoGravity.resizeAspect
                previewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
                
                cameraView.layer.addSublayer(previewLayer!)
                cameraView.addGestureRecognizer(tap)
                captureSession.startRunning()
            }
        } catch {
            debugPrint(error)
        }
    }
    
    @objc func didTapCameraView(){
        self.cameraView.isUserInteractionEnabled = false
        self.spinner.isHidden = false
        self.spinner.startAnimating()
        let settings = AVCapturePhotoSettings()
        
        
        settings.previewPhotoFormat = settings.embeddedThumbnailPhotoFormat
        
        if flashState == .off{
            settings.flashMode = .off
        } else if flashState == .on {
            settings.flashMode = .on
        }
        
        cameraOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func synthesizeSpeech(fromString string: String){
        let speechUtterance = AVSpeechUtterance(string: string)
        speechSynthesizer.speak(speechUtterance)
    }

    func resultsMethod(request: VNRequest, error: Error?){
        guard let results = request.results as? [VNClassificationObservation] else {
            return
        }
        for classification in results {
            if classification.confidence < 0.5{
                self.identificationLbl.text = "I am not sure what this is"
                synthesizeSpeech(fromString: "I am not sure what this is")
                self.confidenceLbl.text = ""
                break
            }else{
                self.identificationLbl.text = classification.identifier
                self.confidenceLbl.text = "CONFIDENCE: \(Int(classification.confidence*100))%"
                let sentence = "This looks like a \(classification.identifier) and I am \(Int(classification.confidence*100)) sure."
                synthesizeSpeech(fromString: sentence)
                break
            }
        }
    }

}

extension CameraVC: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            debugPrint(error)
        }else{
            photoData = photo.fileDataRepresentation()
            
            do {
                let model = try VNCoreMLModel(for: SqueezeNet().model)
                let request = VNCoreMLRequest(model: model, completionHandler: resultsMethod)
                let handler = VNImageRequestHandler(data: photoData!)
                try handler.perform([request])
            } catch {
                debugPrint(error)
            }
            
            let image = UIImage(data: photoData!)
            self.captureImgView.image = image
        }
    }
}

extension CameraVC: AVSpeechSynthesizerDelegate{
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        self.cameraView.isUserInteractionEnabled = true
        self.spinner.isHidden = true
        self.spinner.stopAnimating()
    }
}
