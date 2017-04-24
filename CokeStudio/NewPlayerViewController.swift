//
//  NewPlayerViewController.swift
//  CokeStudio
//
//  Created by ajay singh thakur on 20/04/17.
//  Copyright © 2017 ajay singh thakur. All rights reserved.
//

import UIKit
import MediaPlayer
import Alamofire
import AlamofireImage
import SwiftyJSON
class NewPlayerViewController: UIViewController {
    @IBOutlet weak var thumbNailImageView: UIImageView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var prevButton: UIButton!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var playerSlider: UISlider!
//    @IBOutlet weak var sermonNameLabel: UILabel!
//    @IBOutlet weak var authorNameLabel: UILabel!
    @IBOutlet weak var backgroundToBlur: UIImageView!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var loadingLabel: UILabel!
    @IBOutlet weak var seekLoadingLabel: UILabel!
    @IBOutlet weak var progressLabel : UILabel!
    
    @IBOutlet weak var playerProgress: UIProgressView!
    //let audioPlayer: STKAudioPlayer = STKAudioPlayer()
    var playList: [JSON] = []
    var timer: Timer?
    var index: Int = Int()
    var avPlayer: AVPlayer!
    var isPaused: Bool!
    

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        isPaused = false
        playButton.setImage(UIImage(named:"pause"), for: .normal)
 
        
        
       
        self.play(url: URL.init(string: playList[self.index]["url"].stringValue)!)
        
//        sermonNameLabel.text = playList[self.index]["song"].stringValue
//        authorNameLabel.text = playList[self.index]["artists"].stringValue
        thumbNailImageView.af_setImage(withURL: URL(string:playList[self.index]["cover_image"].stringValue)!)
        self.backgroundToBlur.af_setImage(withURL: URL(string:playList[self.index]["cover_image"].stringValue)!)
        self.setupTimer()
    }
    
    func play(url:URL) {
        self.avPlayer = AVPlayer(playerItem: AVPlayerItem(url: url))
        if #available(iOS 10.0, *) {
            self.avPlayer.automaticallyWaitsToMinimizeStalling = false
        }
        avPlayer!.volume = 1.0
        avPlayer.play()
    }
    
    
    override func viewWillDisappear( _ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        self.avPlayer = nil
        self.timer?.invalidate()
        
        // making background transparent 
        let clearImage = UIImage().stretchableImage(withLeftCapWidth: 14, topCapHeight: 0)
        self.playerSlider.setMaximumTrackImage(clearImage, for: .normal)
        self.playerSlider.setMaximumTrackImage(clearImage, for: .normal)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var darkBlur:UIBlurEffect = UIBlurEffect()
        darkBlur = UIBlurEffect(style: UIBlurEffectStyle.light) //extraLight, light, dark
        let blurView = UIVisualEffectView(effect: darkBlur)
        blurView.frame = self.view.frame //your view that have any objects
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.backgroundToBlur.addSubview(blurView)
    }
    
    @IBAction func playButtonClicked(_ sender: UIButton) {
        if #available(iOS 10.0, *) {
            self.togglePlayPause()
        } else {
//            Utils.showAlert(message: "upgrade ios version to use this feature", action: {
//                
//            })
        }
    }
    
    @available(iOS 10.0, *)
    func togglePlayPause() {
        if avPlayer.timeControlStatus == .playing  {
            playButton.setImage(UIImage(named:"play"), for: .normal)
            avPlayer.pause()
            isPaused = true
        } else {
            playButton.setImage(UIImage(named:"pause"), for: .normal)
            avPlayer.play()
            isPaused = false
        }
    }
    
    @IBAction func nextButtonClicked(_ sender: Any) {
        self.nextTrack()
    }
    
    @IBAction func prevButtonClicked(_ sender: Any) {
        self.prevTrack()
    }
    
    @IBAction func sliderValueChange(_ sender: UISlider) {
        let seconds : Int64 = Int64(sender.value)
        let targetTime:CMTime = CMTimeMake(seconds, 1)
        avPlayer!.seek(to: targetTime)
        if(isPaused == false){
            seekLoadingLabel.alpha = 1
        }
    }
    
    @IBAction func sliderTapped(_ sender: UILongPressGestureRecognizer) {
        if let slider = sender.view as? UISlider {
            if slider.isHighlighted { return }
            let point = sender.location(in: slider)
            let percentage = Float(point.x / slider.bounds.width)
            let delta = percentage * (slider.maximumValue - slider.minimumValue)
            let value = slider.minimumValue + delta
            slider.setValue(value, animated: false)
            let seconds : Int64 = Int64(value)
            let targetTime:CMTime = CMTimeMake(seconds, 1)
            avPlayer!.seek(to: targetTime)
            if(isPaused == false){
                seekLoadingLabel.alpha = 1
            }
        }
    }
    
    func setupTimer(){
        NotificationCenter.default.addObserver(self, selector: #selector(self.didPlayToEnd), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        timer = Timer(timeInterval: 0.001, target: self, selector: #selector(self.tick), userInfo: nil, repeats: true)
        RunLoop.current.add(timer!, forMode: RunLoopMode.commonModes)
    }
    
    func didPlayToEnd() {
        self.nextTrack()
    }
//    - (NSTimeInterval) availableDuration;
//    {
//    NSArray *loadedTimeRanges = [[self.player currentItem] loadedTimeRanges];
//    CMTimeRange timeRange = [[loadedTimeRanges objectAtIndex:0] CMTimeRangeValue];
//    Float64 startSeconds = CMTimeGetSeconds(timeRange.start);
//    Float64 durationSeconds = CMTimeGetSeconds(timeRange.duration);
//    NSTimeInterval result = startSeconds + durationSeconds;
//    return result;
//    }
    func availableDurationNew() -> Float64 {
        
         let loadedTimeRanges = self.avPlayer.currentItem?.loadedTimeRanges
        if let timeRange = loadedTimeRanges?.first?.timeRangeValue {
        let startSecond = CMTimeGetSeconds((timeRange.start))//timeRange?.start
        let duration = CMTimeGetSeconds((timeRange.duration))//timeRange?.duration
        let result = startSecond + duration
        return result
        }
        return 0
    }
    func availableDuration() -> CMTime
    {
        if let range = self.avPlayer.currentItem?.loadedTimeRanges.first {
            return CMTimeRangeGetEnd(range.timeRangeValue)
        }
        return kCMTimeZero
    }
    func tick(){
        if(avPlayer.currentTime().seconds == 0.0){
            loadingLabel.alpha = 1
        }else{
            loadingLabel.alpha = 0
        }
        
        if(isPaused == false){
            if(avPlayer.rate == 0){
                avPlayer.play()
                seekLoadingLabel.alpha = 1
            }else{
                seekLoadingLabel.alpha = 0
            }
        }
        
        if((avPlayer.currentItem?.asset.duration) != nil){
            let currentTime1 : CMTime = (avPlayer.currentItem?.asset.duration)!
            let seconds1 : Float64 = CMTimeGetSeconds(currentTime1)
            let time1 : Float = Float(seconds1)
            playerSlider.minimumValue = 0
            playerSlider.maximumValue = time1
            
            let currentTime : CMTime = (self.avPlayer?.currentTime())!
            let seconds : Float64 = CMTimeGetSeconds(currentTime)
            let time : Float = Float(seconds)
            self.playerSlider.value = time
            timeLabel.text =  self.formatTimeFromSeconds(totalSeconds: Int32(Float(Float64(CMTimeGetSeconds((self.avPlayer?.currentItem?.asset.duration)!)))))
            currentTimeLabel.text = self.formatTimeFromSeconds(totalSeconds: Int32(Float(Float64(CMTimeGetSeconds((self.avPlayer?.currentItem?.currentTime())!)))))
            
            
            
            // progress
            let bufferedTime = self.availableDurationNew()
            let bufferedProgress : Float = Float ( bufferedTime / seconds1)
            playerProgress.progress = bufferedProgress
            progressLabel.text = "\(bufferedProgress)"//self.formatTimeFromSeconds(totalSeconds: Int32(self.availableDurationNew()))//self.formatTimeFromSeconds(totalSeconds: Int32(Float(Float64(CMTimeGetSeconds((self.avPlayer?.currentItem?.loadedTimeRanges.first as! CMTime))))))
        }else{
            playerSlider.value = 0
            playerSlider.minimumValue = 0
            playerSlider.maximumValue = 0
            timeLabel.text = "Live stream \(self.formatTimeFromSeconds(totalSeconds: Int32(CMTimeGetSeconds((avPlayer.currentItem?.currentTime())!))))"
        }
    }
    
    func Loader() {
        
    }
    
    func nextTrack(){
        if(index < playList.count-1){
            index = index + 1
            isPaused = false
            playButton.setImage(UIImage(named:"pause"), for: .normal)
//            self.play(url:URL(string:(playList[self.index] as! NSDictionary)["url"] as! String)!)
//            sermonNameLabel.text = (playList[self.index] as! NSDictionary)["title"] as? String
//            authorNameLabel.text = (playList[self.index] as! NSDictionary)["author"] as? String
//            thumbNailImageView.af_setImage(withURL: URL(string:(playList[self.index] as! NSDictionary)["img_link"] as! String)!)
//            self.backgroundToBlur.af_setImage(withURL: URL(string:(playList[self.index] as! NSDictionary)["img_link"] as! String)!)
            
        }else{
            index = 0
            isPaused = false
            playButton.setImage(UIImage(named:"pause"), for: .normal)
//            self.play(url:URL(string:(playList[self.index] as! NSDictionary)["url"] as! String)!)
//            sermonNameLabel.text = (playList[self.index] as! NSDictionary)["title"] as? String
//            authorNameLabel.text = (playList[self.index] as! NSDictionary)["author"] as? String
//            thumbNailImageView.af_setImage(withURL: URL(string:(playList[self.index] as! NSDictionary)["img_link"] as! String)!)
//            self.backgroundToBlur.af_setImage(withURL: URL(string:(playList[self.index] as! NSDictionary)["img_link"] as! String)!)
        }
    }
    
    func prevTrack(){
        if(index > 0){
            index = index - 1
            isPaused = false
            playButton.setImage(UIImage(named:"pause"), for: .normal)
//            self.play(url:URL(string:(playList[self.index] as! NSDictionary)["url"] as! String)!)
//            sermonNameLabel.text = (playList[self.index] as! NSDictionary)["title"] as? String
//            authorNameLabel.text = (playList[self.index] as! NSDictionary)["author"] as? String
//            thumbNailImageView.af_setImage(withURL: URL(string:(playList[self.index] as! NSDictionary)["img_link"] as! String)!)
//            self.backgroundToBlur.af_setImage(withURL: URL(string:(playList[self.index] as! NSDictionary)["img_link"] as! String)!)
            
        }
    }
    
    func formatTimeFromSeconds(totalSeconds: Int32) -> String {
        let seconds: Int32 = totalSeconds%60
        let minutes: Int32 = (totalSeconds/60)%60
        let hours: Int32 = totalSeconds/3600
        return String(format: "%02d:%02d:%02d", hours,minutes,seconds)
    }
    
    @IBAction func backButtonClicked(_ sender: Any) {
        self.dismiss(animated: true) {
            self.avPlayer = nil
            self.timer?.invalidate()
        }
    }
    
    func hideActivityIndicator(){
//        self.perform(#selector(PlayerViewController.hideActivityIndicator), with: nil, afterDelay: 2.0)
//        Utils.hideHUD()
    }
}
extension AVPlayer {
    var isPlaying: Bool {
        return rate != 0 && error == nil
    }
}
