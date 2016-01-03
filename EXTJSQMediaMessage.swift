//
//  EXTJSQMediaMessage.swift
//  SmartHome_Flat
//
//  Created by Lijie on 15/12/14.
//  Copyright © 2015年 HuatengIOT. All rights reserved.
//

import Foundation
import UIKit

private let AudioMediaItemSize = CGSize(width: 210, height: 44)

class AudioMediaItem: JSQMediaItem {
    var fileURL: NSURL!
    var timeInterval: Int32!
    var isReadyToPlay: Bool = true
    var cachedAudioImage: UIImage?
    var cachedAudioImageView: UIView?
    
    init(fileURL: NSURL, timeInterval: Int32, cachedImage: UIImage?, isReadyToPlay: Bool, maskAsOutgoing: Bool) {
        super.init(maskAsOutgoing: maskAsOutgoing)
        
        self.fileURL = fileURL
        self.timeInterval = timeInterval
        self.cachedAudioImage = cachedImage
        self.isReadyToPlay = isReadyToPlay
        self.cachedAudioImageView = nil
        
    }
    func startAudioPlayerAnimation() {
        if let imageView = self.cachedAudioImageView as? UIImageView {
            imageView.image = nil
            
            imageView.animationImages = [
                UIImage(named: "aia1")!,
                UIImage(named: "aia2")!,
                UIImage(named: "aia3")!,
                UIImage(named: "aia4")!,
                UIImage(named: "aia5")!,
                UIImage(named: "aia1")!
            ]
            imageView.animationDuration = 1
            imageView.startAnimating()
        }
    }
    func stopAudioPlayerAnimation() {
        if let imageView = self.cachedAudioImageView as? UIImageView {
            if let image = self.cachedAudioImage {
                imageView.image = image
            } else {
                imageView.image = UIImage(named: "ail")
            }
            if imageView.isAnimating() {
                imageView.stopAnimating()
            }
            imageView.animationImages = nil
        }
    }
    override func clearCachedMediaViews() {
        super.clearCachedMediaViews()
        self.cachedAudioImageView = nil
    }
    
    // MARK: - JSQMesssageMediaData protocol
    
    override func mediaViewDisplaySize() -> CGSize {
        return AudioMediaItemSize
    }

    override func mediaView() -> UIView! {
        if self.fileURL == nil || !self.isReadyToPlay {
            return nil
        }
        if self.cachedAudioImageView == nil {
//            let playIcon = UIImage.jsq_defaultPlayImage()
            let size = self.mediaViewDisplaySize()
            let imageView = UIImageView()
            if let image = self.cachedAudioImage {
                imageView.image = image
            } else {
                imageView.image = UIImage(named: "ail")
            }
            imageView.backgroundColor = UIColor.blueColor()
            imageView.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            imageView.contentMode = .ScaleAspectFit
            imageView.clipsToBounds = true
            JSQMessagesMediaViewBubbleImageMasker.applyBubbleImageMaskToMediaView(imageView, isOutgoing: self.appliesMediaViewMaskAsOutgoing)
            self.cachedAudioImageView = imageView
        }
        
        return self.cachedAudioImageView
    }
    
    override func mediaHash() -> UInt {
        let hs = abs(self.hash)
        return UInt(hs)
    }
    
    // MARK: - NSObject -- NSObjectProtocol
    
    override func isEqual(object: AnyObject?) -> Bool {
        if !super.isEqual(object) {
            return false
        }
        
        let audioItem = object as? AudioMediaItem
        
        return self.fileURL.isEqual(audioItem?.fileURL) && self.isReadyToPlay == audioItem?.isReadyToPlay
    }
    
    override var hash: Int {
        return super.hash ^ self.fileURL.hash
    }
    
    override var description: String {
        return String(format: "<%@: fileURL=%@, isReadyToPlay=%@, appliesMediaViewMaskAsOutgoing=%@", self, self.fileURL, self.isReadyToPlay, self.appliesMediaViewMaskAsOutgoing)
    }
    
    // MARK: - NSCoding
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.fileURL = aDecoder.decodeObjectForKey(NSStringFromSelector(Selector("fileURL"))) as! NSURL
        self.isReadyToPlay = aDecoder.decodeObjectForKey(NSStringFromSelector(Selector("isReadyToPlay"))) as! Bool
    }
    override func encodeWithCoder(aCoder: NSCoder) {
        super.encodeWithCoder(aCoder)
        aCoder.encodeObject(self.fileURL, forKey: NSStringFromSelector(Selector("fileURL")))
        aCoder.encodeObject(self.isReadyToPlay, forKey: NSStringFromSelector(Selector("isReadyToPlay")))
    }
    
    // MARK: - NSCopying
    
    override func copyWithZone(zone: NSZone) -> AnyObject {
        return AudioMediaItem(fileURL: self.fileURL, timeInterval: self.timeInterval, cachedImage: self.cachedAudioImage, isReadyToPlay: self.isReadyToPlay, maskAsOutgoing: self.appliesMediaViewMaskAsOutgoing)
    }
}

/*******************************************************************************/

import AVFoundation

protocol AudioRecorderDelegate {
    func audioRecorderUpdateMetra(metra: Float)
}

private let AoundPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first!

private let AudioSettings: [String: AnyObject] = [AVLinearPCMIsFloatKey: NSNumber(bool: false),
    AVLinearPCMIsBigEndianKey: NSNumber(bool: false),
    AVLinearPCMBitDepthKey: NSNumber(int: 16),
    AVFormatIDKey: NSNumber(unsignedInt: kAudioFormatLinearPCM),
    AVNumberOfChannelsKey: NSNumber(int: 1), AVSampleRateKey: NSNumber(int: 16000),
    AVEncoderAudioQualityKey: NSNumber(integer: AVAudioQuality.High.rawValue)]
 
class AudioRecorder: NSObject, AVAudioRecorderDelegate {
    
    var audioData: NSData!
    var operationQueue: NSOperationQueue!
    var recorder: AVAudioRecorder!
    
    var startTime: Double!
    var endTimer: Double!
    var timeInterval: NSNumber!
    
    var delegate: AudioRecorderDelegate?
    
    convenience init(fileName: String) {
        self.init()
        
        let filePath = NSURL(fileURLWithPath: (AoundPath as NSString).stringByAppendingPathComponent(fileName))
        
        recorder = try! AVAudioRecorder(URL: filePath, settings: AudioSettings)
        recorder.delegate = self
        recorder.meteringEnabled = true
    }
    
    override init() {
        operationQueue = NSOperationQueue()
        super.init()
    }
    
    func startRecord() {
        startTime = NSDate().timeIntervalSince1970
        performSelector("readyStartRecord", withObject: self, afterDelay: 0.5)
    }
    
    func readyStartRecord() {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
        } catch {
            NSLog("setCategory fail")
            return
        }
        
        do {
            try audioSession.setActive(true)
        } catch {
            NSLog("setActive fail")
            return
        }
        recorder.record()
        let operation = NSBlockOperation()
        operation.addExecutionBlock(updateMeters)
        operationQueue.addOperation(operation)
    }
    
    func stopRecord() {
        endTimer = NSDate().timeIntervalSince1970
        timeInterval = nil
        if (endTimer - startTime) < 0.5 {
            NSObject.cancelPreviousPerformRequestsWithTarget(self, selector: "readyStartRecord", object: self)
        } else {
            timeInterval = NSNumber(int: NSNumber(double: recorder.currentTime).intValue)
            if timeInterval.intValue < 1 {
                performSelector("readyStopRecord", withObject: self, afterDelay: 0.4)
            } else {
                readyStopRecord()
            }
        }
        operationQueue.cancelAllOperations()
    }
    
    func readyStopRecord() {
        recorder.stop()
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setActive(false, withOptions: .NotifyOthersOnDeactivation)
        } catch {
            // no-op
        }
        audioData = NSData(contentsOfURL: recorder.url)
    }
    
    func updateMeters() {
        repeat {
            recorder.updateMeters()
            timeInterval = NSNumber(float: NSNumber(double: recorder.currentTime).floatValue)
            let averagePower = recorder.averagePowerForChannel(0)
            // let pearPower = recorder.peakPowerForChannel(0)
            //  NSLog("%@   %f  %f", timeInterval, averagePower, pearPower)
            delegate?.audioRecorderUpdateMetra(averagePower)
            NSThread.sleepForTimeInterval(0.2)
        } while(recorder.recording)
    }
    
    // MARK: audio delegate
    func audioRecorderEncodeErrorDidOccur(recorder: AVAudioRecorder, error: NSError?) {
        NSLog("%@", (error?.localizedDescription)!)
    }
}
 
/******************************** AudioPlayer ***********************************/

class AudioMediaItemPlayer: NSObject, AVAudioPlayerDelegate {
    static let sharedPlayer: AudioMediaItemPlayer = AudioMediaItemPlayer()
    
    var audioPlayer: AVAudioPlayer!
    
    private override init() {
        
    }
    
    func startPlaying(url: NSURL) {
        if (audioPlayer != nil && audioPlayer.playing) {
            stopPlaying()
        }
        
        do {
            let data = NSData(contentsOfURL: url)
            try audioPlayer = AVAudioPlayer(data: data!)
        } catch{
            print("AudioPlayer: AVAudioPlayer initilization error")
            return
        }
        
        audioPlayer.delegate = self
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategorySoloAmbient)
        } catch {
            // no-op
            print("AudioPlayer: set session category")
        }
        audioPlayer.play()
    }
    
    func stopPlaying() {
        audioPlayer.stop()
    }
}

/******************************** AudioRecordIndicatorView ***********************************/


class AudioRecordIndicatorView: UIView {
    
    let imageView: UIImageView
    let textLabel: UILabel
    let images:[UIImage]
    
    override init(frame: CGRect) {
        textLabel = UILabel()
        textLabel.textAlignment = .Center
        textLabel.font = UIFont.systemFontOfSize(13.0)
        textLabel.text = "正在录音，上滑取消"
        textLabel.textColor = UIColor.blackColor()
        
        images = [UIImage(named: "record_animate_01")!,
            UIImage(named: "record_animate_02")!,
            UIImage(named: "record_animate_03")!,
            UIImage(named: "record_animate_04")!,
            UIImage(named: "record_animate_05")!,
            UIImage(named: "record_animate_06")!,
            UIImage(named: "record_animate_07")!,
            UIImage(named: "record_animate_08")!,
            UIImage(named: "record_animate_09")!]
        
        imageView = UIImageView(frame: CGRectZero)
        imageView.image = images[0]
        
        super.init(frame: frame)
        backgroundColor = UIColor(hex: "365560").colorWithAlphaComponent(0.6)
        // 增加毛玻璃效果
        if #available(iOS 8.0, *) {
            let visualView = UIVisualEffectView(effect: UIBlurEffect(style: .Light))
            visualView.frame = self.bounds
            visualView.layer.cornerRadius = 10.0
            visualView.layer.masksToBounds = true
            addSubview(visualView)
        } else {
            // Fallback on earlier versions
        }
        
        self.layer.cornerRadius = 10.0
        addSubview(imageView)
        addSubview(textLabel)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        
        self.addConstraint(NSLayoutConstraint(item: imageView, attribute: .CenterX, relatedBy: .Equal, toItem: self, attribute: .CenterX, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: imageView, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1, constant: -15))
        
        self.addConstraint(NSLayoutConstraint(item: textLabel, attribute: .Left, relatedBy: .Equal, toItem: self, attribute: .Left, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: textLabel, attribute: .Top, relatedBy: .Equal, toItem: imageView, attribute: .Bottom, multiplier: 1, constant: 10))
        self.addConstraint(NSLayoutConstraint(item: textLabel, attribute: .Width, relatedBy: .Equal, toItem: self, attribute: .Width, multiplier: 1, constant: 0))
        
        translatesAutoresizingMaskIntoConstraints = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showText(text: String, textColor: UIColor = UIColor.blackColor()) {
        textLabel.textColor = textColor
        textLabel.text = text
    }
    
    func updateLevelMetra(levelMetra: Float) {
        if levelMetra > -20 {
            showMetraLevel(8)
        } else if levelMetra > -25 {
            showMetraLevel(7)
        }else if levelMetra > -30 {
            showMetraLevel(6)
        } else if levelMetra > -35 {
            showMetraLevel(5)
        } else if levelMetra > -40 {
            showMetraLevel(4)
        } else if levelMetra > -45 {
            showMetraLevel(3)
        } else if levelMetra > -50 {
            showMetraLevel(2)
        } else if levelMetra > -55 {
            showMetraLevel(1)
        } else if levelMetra > -60 {
            showMetraLevel(0)
        }
    }
    
    
    func showMetraLevel(level: Int) {
        if level > images.count {
            return
        }
        performSelectorOnMainThread("showIndicatorImage:", withObject: NSNumber(integer: level), waitUntilDone: false)
    }
    
    func showIndicatorImage(level: NSNumber) {
        imageView.image = images[level.integerValue]
    }
    
}

