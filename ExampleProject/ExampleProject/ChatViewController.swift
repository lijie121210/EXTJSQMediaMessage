//
//  ChatViewController.swift
//  Example
//
//  Created by Lijie on 16/2/24.
//  Copyright © 2016年 HuatengIOT. All rights reserved.
//

import UIKit


private let reuseIdentifier = "Cell"
private let sendername = "sender"
private let senderid = "sender 0517"


class ChatViewController: JSQMessagesViewController {
    
    var messages = [JSQMessage]()
    
    lazy var leftBarButtonItem: UIButton = {
        let button = UIButton(frame: CGRectZero)
        button.setImage(UIImage(named: "相机"), forState: .Normal)
        button.imageView?.contentMode = .ScaleAspectFit
        return button
    }()
    
    lazy var longPressRightGesture: UILongPressGestureRecognizer = {
        return UILongPressGestureRecognizer(target: self, action: "didLongPressRightBarButtonItem:")
    }()
    lazy var rightBarButtonItem: UIButton = {
        let button = UIButton(frame: CGRectZero)
        button.setImage(UIImage(named: "录音"), forState: .Normal)
        button.imageView?.contentMode = .ScaleAspectFit
        button.addGestureRecognizer(self.longPressRightGesture)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Redo, target: self, action: "fake_receivingMessage:")
        
        self.senderId = senderid
        self.senderDisplayName = sendername
        
        
        self.inputToolbar?.contentView?.textView?.pasteDelegate = self
        self.inputToolbar?.contentView?.leftBarButtonItem = self.leftBarButtonItem
        self.inputToolbar?.contentView?.rightBarButtonItem = self.rightBarButtonItem
        
        JSQMessagesCollectionViewCell.registerMenuAction("delete:")
        
        /* more operations
        JSQMessagesCollectionViewCell.registerMenuAction("customAction:")
        UIMenuController.sharedMenuController().menuItems = [UIMenuItem(title: "more", action: "customAction:")]
        */
        /* head image view size
        self.collectionView?.collectionViewLayout.incomingAvatarViewSize = CGSize(width: 60, height: 60)
        self.collectionView?.collectionViewLayout.outgoingAvatarViewSize = CGSize(width: 60, height: 60)
        */
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        /** 📷，🔊 this two buttons' size
        * self.inputToolbar?.contentView?.leftBarButtonItemWidth = 60
        */
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        /**
         * depend on your project
         */
        self.inputToolbar?.contentView?.rightBarButtonItem?.enabled = true
        
        /**
         * UIDynamic effect (may cause bug)
         */
        if #available(iOS 9.0, *) {
            self.collectionView?.collectionViewLayout.springinessEnabled = false
        } else {
            self.collectionView?.collectionViewLayout.springinessEnabled = true
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Navigation
    
    @IBAction func close(segue: UIStoryboardSegue) {
        print("unwind segue")
    }
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == photoSkimSegue {
            if let controller = segue.destinationViewController as? PhotoSkimViewController {
                controller.skimingImage = sender!["image"] as! UIImage
            }
        }
    }
    
    // MARK: - Actions
    
    // tapped right item ➡️
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        
        if text != nil && text != "" {
            JSQSystemSoundPlayer.jsq_playMessageSentSound()
            
            let newmessage = JSQMessage(senderId: self.senderId, senderDisplayName: self.senderDisplayName, date: NSDate(), text: text)
            self.messages.append(newmessage)
            self.finishSendingMessageAnimated(true)
        }
        
        self.checkRightBarButtonItemStatus()
    }
    
    // tapped left item 📷
    override func didPressAccessoryButton(sender: UIButton!) {
        let imagePicker = JSImagePickerViewController()
        imagePicker.delegate = self
        imagePicker.showImagePickerInController(self)
    }
    
    /** 
     * Responding to collection view tap events
     */
    override func collectionView(collectionView: JSQMessagesCollectionView!, header headerView: JSQMessagesLoadEarlierHeaderView!, didTapLoadEarlierMessagesButton sender: UIButton!) {
        print("didTapLoadEarlierMessagesButton")
        self.inputToolbar?.contentView?.textView?.resignFirstResponder()
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, didTapAvatarImageView avatarImageView: UIImageView!, atIndexPath indexPath: NSIndexPath!) {
        let message = self.messages[indexPath.row]
        let name = message.senderDisplayName
        UIAlertView(title: nil, message: name, delegate: nil, cancelButtonTitle: "cancel").show()
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAtIndexPath indexPath: NSIndexPath!) {
        let message = self.messages[indexPath.row]
        if message.isMediaMessage {
            if let audio = message.media as? AudioMediaItem {
                self.playAudioRecoderMessage(audio)
            }
            if let photo = message.media as? JSQPhotoMediaItem {
                self.playPhotoMessageSkimming(photo)
            }
        }
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, didTapCellAtIndexPath indexPath: NSIndexPath!, touchLocation: CGPoint) {
        print("didTapCellAtIndexPath")
        
        self.inputToolbar?.contentView?.textView?.resignFirstResponder()
        
    }
    
    // MARK: - customAction
    /*
    func customAction(sender: AnyObject?) {
        UIAlertView(title: "custom action", message: "\(sender)", delegate: nil, cancelButtonTitle: "okay").show()
    }
    
    override func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
        if action == Selector("customAction:") {
            return true
        }
        return super.collectionView(collectionView, canPerformAction: action, forItemAtIndexPath: indexPath, withSender: sender)
    }
    override func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
        if action == Selector("customAction:") {
            self.customAction(sender)
            return
        }
        super.collectionView(collectionView, performAction: action, forItemAtIndexPath: indexPath, withSender: sender)
    }
    */
    
    // 录音 和 播放
    
    var longPressBeganLocation: CGPoint = CGPointZero
    let distanceBerrier: CGFloat = 90
    var audioRecoder: AudioRecorder? = nil
    var audioRecoderIndicator: AudioRecordIndicatorView? = nil
    
    private func calculateDistanceBetweenTwoPoints(point1: CGPoint, point2: CGPoint) -> CGFloat {
        let offsetx = point1.x - point2.x
        let offsety = point1.y - point2.y
        let offset = offsetx * offsetx + offsety * offsety
        return sqrt(offset)
    }
    func didLongPressRightBarButtonItem(gesture: UILongPressGestureRecognizer) {
        if gesture.state == .Began {
            self.longPressBeganLocation = gesture.locationInView(self.view)
            // 开始录音
            let currentTime = NSDate().timeIntervalSinceReferenceDate
            self.audioRecoder = AudioRecorder(fileName: "\(currentTime).wav")
            self.audioRecoder!.delegate = self
            self.audioRecoder!.startRecord()
            
            self.audioRecoderIndicator = AudioRecordIndicatorView(frame: CGRect(origin: CGPointZero, size: CGSize(width: 120, height: 150)))
            self.audioRecoderIndicator!.center = self.view.center
            self.view.addSubview(self.audioRecoderIndicator!)
            self.view.bringSubviewToFront(self.audioRecoderIndicator!)
        }
        if gesture.state == .Changed {
            let longPressChangedLocation = gesture.locationInView(self.view)
            
            let distance = self.calculateDistanceBetweenTwoPoints(self.longPressBeganLocation, point2: longPressChangedLocation)
            
            if distance > distanceBerrier {
                self.audioRecoderIndicator?.textLabel.text = "Openhand，Cancel"
            } else {
                self.audioRecoderIndicator?.textLabel.text = "Recording"
            }
        }
        if gesture.state == .Ended {
            let longPressEndedLocation = gesture.locationInView(self.view)
            let distance = self.calculateDistanceBetweenTwoPoints(self.longPressBeganLocation, point2: longPressEndedLocation)
            
            if distance > distanceBerrier {
                // cancel
                self.audioRecoder!.stopRecord()
                self.audioRecoder!.delegate = nil
                self.audioRecoderIndicator!.removeFromSuperview()
                self.audioRecoderIndicator = nil
                
                
            } else {
                // success
                self.audioRecoder!.stopRecord()
                self.audioRecoder!.delegate = nil
                self.audioRecoderIndicator!.removeFromSuperview()
                self.audioRecoderIndicator = nil
                
                
                guard self.audioRecoder!.timeInterval != nil else {
                    return
                }
                // 根据时长 更换背景图
                var name = "ail"
                if self.audioRecoder!.timeInterval.intValue < 4 {
                    name = "ais"
                }
                let audioItem = AudioMediaItem(
                    fileURL: self.audioRecoder!.recorder.url,
                    timeInterval: self.audioRecoder!.timeInterval.intValue,
                    cachedImage: UIImage(named: name),
                    isReadyToPlay: true,
                    maskAsOutgoing: true
                )
                
                let audioMessage = JSQMessage(
                    senderId: self.senderId,
                    displayName: self.senderDisplayName,
                    media: audioItem
                )
                
                self.sendAudioMessage(audioMessage)
            }
            longPressBeganLocation = CGPointZero
        }
        
    }
    
    private func sendAudioMessage(audioMessage: JSQMessage) {
        
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        
        self.messages.append(audioMessage)
        
        self.finishSendingMessage()
        
        self.checkRightBarButtonItemStatus()
    }
    
    private func playAudioRecoderMessage(audio: AudioMediaItem) {
        let fileURL = audio.fileURL
        let timeInterval = UInt64(audio.timeInterval)
        AudioMediaItemPlayer.sharedPlayer.startPlaying(fileURL)
        
        // animation start
        audio.startAudioPlayerAnimation()
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_SEC * timeInterval)), dispatch_get_main_queue(), { () -> Void in
            // animation stop
            audio.stopAudioPlayerAnimation()
        })
    }
    
    // skim bigger image
    
    private func playPhotoMessageSkimming(photo: JSQPhotoMediaItem) {
        let image = photo.image
        
        self.performSegueWithIdentifier(photoSkimSegue, sender: ["image":image])
    }
}

// MARK: - Collection View

extension ChatViewController {

    // Collection View Data Source
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.messages.count
    }
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        return self.messages[indexPath.item]
    }
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as! JSQMessagesCollectionViewCell
        
        let message = self.messages[indexPath.item]
        
        if !message.isMediaMessage {
            if message.senderId == self.senderId {
                cell.textView?.textColor = UIColor.whiteColor() // sending text color
            } else {
                cell.textView?.textColor = UIColor.blackColor() // receving text color
            }
            cell.textView?.selectable = false
            cell.textView?.editable = false
            
            /*
            cell.textView?.linkTextAttributes = [
            NSForegroundColorAttributeName:(cell.textView?.textColor)!,
            NSUnderlineStyleAttributeName:NSUnderlineStyle(rawValue: NSUnderlineStyle.StyleSingle.rawValue |  NSUnderlineStyle.PatternSolid.rawValue)!.rawValue
            ]
            */
        }
        
        return cell
    }
    
    // Collection View - delete message
    override func collectionView(collectionView: JSQMessagesCollectionView!, didDeleteMessageAtIndexPath indexPath: NSIndexPath!) {
        self.messages.removeAtIndex(indexPath.item)
    }
    
    // Collection View - message bubble background
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
        
        if self.messages[indexPath.item].isMediaMessage {
            return nil
        }
        let outgoingimage = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImageWithColor(UIColor.blueColor().colorWithAlphaComponent(0.7))
        let incomingimage = JSQMessagesBubbleImageFactory().incomingMessagesBubbleImageWithColor(UIColor(white: 0.85, alpha: 1))
        
        let messageid = self.messages[indexPath.item].senderId
        if messageid == self.senderId {
            return outgoingimage
        } else {
            return incomingimage
        }
    }
    
    // CollectionView - head view
    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
        
        let outgoingavatar = JSQMessagesAvatarImageFactory.avatarImageWithUserInitials("me", backgroundColor: UIColor.blueColor().colorWithAlphaComponent(0.7), textColor: UIColor.whiteColor(), font: UIFont.systemFontOfSize(12), diameter: UInt(kJSQMessagesCollectionViewAvatarSizeDefault))
        let incomingavatar = JSQMessagesAvatarImageFactory.avatarImageWithUserInitials("other", backgroundColor: UIColor(white: 0.85, alpha: 1), textColor: UIColor.blackColor(), font: UIFont.systemFontOfSize(12), diameter: UInt(kJSQMessagesCollectionViewAvatarSizeDefault))
        
        let messageid = self.messages[indexPath.item].senderId
        
        if messageid == self.senderId {
            return outgoingavatar
        } else {
            return incomingavatar
        }
    }
    
    // Collection View Layout - height of elements (time, name...)
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        if indexPath.item % 3 == 0 {
            return JSQMessagesTimestampFormatter.sharedFormatter().attributedTimestampForDate(self.messages[indexPath.item].date)
        } else {
            return nil
        }
    }
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellTopLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        if indexPath.item % 3 == 0 {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        } else {
            return 0
        }
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        let message = self.messages[indexPath.item]
        if message.senderId == self.senderId {
            return nil
        }
        
        if indexPath.item > 1 {
            let previousmessage = self.messages[indexPath.item - 1]
            if previousmessage.senderId == message.senderId {
                return nil
            }
        }
        
        return NSAttributedString(string: message.senderDisplayName)
    }
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        let message = self.messages[indexPath.item]
        if message.senderId == self.senderId {
            return 0
        }
        
        if indexPath.item > 1 {
            let previousmessage = self.messages[indexPath.item - 1]
            if previousmessage.senderId == message.senderId {
                return 0
            }
        }
        
        return kJSQMessagesCollectionViewCellLabelHeightDefault
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForCellBottomLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        let message = self.messages[indexPath.row]
        if message.isMediaMessage {
            if let audio = message.media as? AudioMediaItem {
                return NSAttributedString(string: "\(audio.timeInterval)s")
            }
        }
        return nil
    }
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellBottomLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        let message = self.messages[indexPath.row]
        if message.isMediaMessage {
            if let _ = message.media as? AudioMediaItem {
                return kJSQMessagesCollectionViewCellLabelHeightDefault
            }
        }
        return 0
    }
    
    // Scroll delegate
    override func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if velocity.y < -0.1 {
            self.inputToolbar?.contentView?.textView?.resignFirstResponder()
        }
    }
}

// MARK: - Text View Delegate

extension ChatViewController {
    
    override func textViewDidChange(textView: UITextView) {
        self.checkRightBarButtonItemStatus()
        super.textViewDidChange(textView)
    }
    
    // enable [return] to send message，the returned code write here
    override func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        
        guard text == "\n" else {
            return true
        }
        
        // returned
        
        return false
    }
    
    /**
     * input content == nil : rightBarButtonItem -> send 
     * input content != nil : rightBarButtonItem -> record
     */
    private func checkRightBarButtonItemStatus() {
        guard let tv = self.inputToolbar?.contentView?.textView else {
            return
        }
        
        self.inputToolbar?.contentView?.rightBarButtonItem?.enabled = true

        if tv.hasText() {
            self.inputToolbar?.contentView?.rightBarButtonItem?.setImage(nil, forState: .Normal)
            self.inputToolbar?.contentView?.rightBarButtonItem?.setTitle("发送", forState: .Normal)
            self.inputToolbar?.contentView?.rightBarButtonItem?.setTitleColor(UIColor.blueColor(), forState: .Normal)
            self.longPressRightGesture.enabled = false
        } else {
            self.inputToolbar?.contentView?.rightBarButtonItem?.setTitle(nil, forState: .Normal)
            self.inputToolbar?.contentView?.rightBarButtonItem?.setImage(UIImage(named: "录音"), forState: .Normal)
            self.longPressRightGesture.enabled = true
        }
    }
}

// MARK: - AudioRecorderDelegate

extension ChatViewController: AudioRecorderDelegate {
    func audioRecorderUpdateMetra(metra: Float) {
        if self.audioRecoderIndicator != nil {
            self.audioRecoderIndicator!.updateLevelMetra(metra)
        }
    }
}


// MARK: - JSQMessagesComposerTextViewPasteDelegate

extension ChatViewController: JSQMessagesComposerTextViewPasteDelegate {
    
    func composerTextView(textView: JSQMessagesComposerTextView!, shouldPasteWithSender sender: AnyObject!) -> Bool {
        if let image = UIPasteboard.generalPasteboard().image {
            let item = JSQPhotoMediaItem(image: image)
            let message = JSQMessage(senderId: self.senderId, senderDisplayName: self.senderDisplayName, date: NSDate(), media: item)
            self.messages.append(message)
            self.finishSendingMessage()
            return false
        }
        return true
    }
}


// MARK: - JSImagePickerViewControllerDelegate

extension ChatViewController: JSImagePickerViewControllerDelegate {
    
    func imagePickerDidSelectImage(image: UIImage!) {
        
        self.scrollToBottomAnimated(true)
        
        let imageitem = JSQPhotoMediaItem(image: image)
        imageitem.appliesMediaViewMaskAsOutgoing = true
        let imagemessage = JSQMessage(senderId: self.senderId, displayName: self.senderDisplayName, media: imageitem)
        
        self.sendImageMessage(imagemessage)
    }
    
    private func sendImageMessage(imageMessage: JSQMessage) {
        
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        
        self.messages.append(imageMessage)
        
        self.finishSendingMessageAnimated(true)
        
        self.checkRightBarButtonItemStatus()
    }
}

// MARK: - Receive Fake Message

private var iflag = 0

extension ChatViewController {
    func fake_receivingMessage(sender: AnyObject?) {
        iflag++
        
        self.showTypingIndicator = true
        self.scrollToBottomAnimated(true)
        
        if iflag % 2 == 0 {
            let textmessage = JSQMessage(senderId: "sender 0212", displayName: "text sender", text: "received!")
            JSQSystemSoundPlayer.jsq_playMessageReceivedSound()
            self.messages.append(textmessage)
            self.finishReceivingMessage()
            return
        }
        // 显示预加载视图
        let imageItem = JSQPhotoMediaItem(maskAsOutgoing: false)
        let imagemessage = JSQMessage(senderId: "sender 0212", displayName: "image sender", media: imageItem)
        self.messages.append(imagemessage)
        self.finishReceivingMessage()
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_SEC * 2)), dispatch_get_main_queue()) { () -> Void in
            // 显示真正的媒体视图
            imageItem.image = UIImage(named: "lowpoly1")
            JSQSystemSoundPlayer.jsq_playMessageReceivedSound()
            self.collectionView?.reloadData()
        }
    }
}


// MARK: - 图片浏览管理器

private let photoSkimSegue = "Photo Skim Segue"

class PhotoSkimViewController: UIViewController {
    var skimingImage: UIImage!
    
    @IBOutlet weak var dismissButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let skimView = VIPhotoView(frame: self.view.bounds, andImage: self.skimingImage)
        self.view.addSubview(skimView)
        
        self.view.bringSubviewToFront(self.dismissButton)
    }
}
