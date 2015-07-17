//
//  ViewController.swift
//  RealtimeFaceDetection
//

import UIKit
import AVFoundation
import Foundation

class ViewController: UIViewController{

    @IBOutlet weak var imageView: UIImageView!
    
    var session : AVCaptureSession!
    var device : AVCaptureDevice!
    var output : AVCaptureVideoDataOutput!
    
    let ocvDetector = FaceDetectWrapper()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if initialize() {
            session.startRunning()
        }
        
//        imageView.image = recognize(imageView.image!)
    }
    
    //カメラの初期化処理
    func initialize() -> Bool {
        session = AVCaptureSession()
        session.sessionPreset = AVCaptureSessionPresetMedium
        
        //デバイスの取得　フロント：バック
        let devices = AVCaptureDevice.devices()
        for d in devices {
            if(d.position == AVCaptureDevicePosition.Back){
                device = d as? AVCaptureDevice
            }
        }
        
        //取得できない場合はfalse
        if device == nil {
            return false
        }
        
        //動画、画像取得先の設定
        let input = AVCaptureDeviceInput.deviceInputWithDevice(device, error: nil) as? AVCaptureDeviceInput
        
        if session.canAddInput(input) {
            session.addInput(input)
        } else {
            return false
        }

        //動画の出力先の設定 画像の生データ取得してdelegate呼び出し
        output = AVCaptureVideoDataOutput()
        output.videoSettings = [ kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA ]
        
        var error: NSError?
        if device.lockForConfiguration(&error) {
            if let e = error {
                return false
            } else {
                device.activeVideoMinFrameDuration = CMTimeMake(1, 30)
                device.unlockForConfiguration()
            }
        }
        
        //output処理用のキューを作成
        let queue: dispatch_queue_t = dispatch_queue_create("com.facedetect.queue",  nil)
        //delegate の設定　フレーム更新毎に呼ばれる
        output.setSampleBufferDelegate(self, queue: queue)
        output.alwaysDiscardsLateVideoFrames = true
        
        if session.canAddOutput(output) {
            session.addOutput(output)
        } else {
            return false
        }
        
        //端末の向きを固定
        for connection in output.connections {
            if let conn = connection as? AVCaptureConnection {
                if conn.supportsVideoOrientation {
                    conn.videoOrientation = AVCaptureVideoOrientation.Portrait
                }
            }
        }
        
        return true
    }
    
    //CIDetector経由で顔検出を行い顔に四角を描いて返す
    private func recognize(image:UIImage) -> UIImage{
        let ciImage = CIImage(image: image)


        let detector = CIDetector(ofType:CIDetectorTypeFace
            ,context:nil
            ,options:[
                CIDetectorAccuracy:CIDetectorAccuracyHigh
            ]
        )
        let features = detector.featuresInImage(ciImage)

        UIGraphicsBeginImageContext(image.size)
        image.drawInRect(CGRectMake(0,0,image.size.width,image.size.height))

        for feature in features{
            let context = UIGraphicsGetCurrentContext()
            var rect = (feature as! CIFaceFeature).bounds
            rect.origin.y = image.size.height - rect.origin.y - rect.size.height
            CGContextSetStrokeColorWithColor(context, UIColor.redColor().CGColor)
            CGContextStrokeRect(context,rect)
        }
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate{
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!)
    {
        dispatch_sync(dispatch_get_main_queue(), {
            let originalImage = CameraUtil.imageFromSampleBuffer(sampleBuffer)
            
            // OpenCV face detection
            let image = self.ocvDetector.recognize(originalImage)
            // CIDetector face detection
//            let image = self.recognize(originalImage)
            self.imageView.image = image
        })
    }
}


class CameraUtil {
    //buffer -> UIImageへの変換コード
    class func imageFromSampleBuffer(sampleBuffer: CMSampleBufferRef) -> UIImage {
        let imageBuffer: CVImageBufferRef = CMSampleBufferGetImageBuffer(sampleBuffer)
        
        CVPixelBufferLockBaseAddress(imageBuffer, 0)
        let address = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        let bitsPerCompornent: UInt = 8
        let bitmapInfo = CGBitmapInfo((CGBitmapInfo.ByteOrder32Little.rawValue | CGImageAlphaInfo.PremultipliedFirst.rawValue) as UInt32)
        
        let context = CGBitmapContextCreate(address, width, height, 8, bytesPerRow, colorSpace, bitmapInfo)
        let imageRef = CGBitmapContextCreateImage(context)
        
        CVPixelBufferUnlockBaseAddress(imageBuffer, 0)
        let resultImage: UIImage = UIImage(CGImage: imageRef)!
        
        return resultImage
    }
}

