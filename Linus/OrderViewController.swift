//
//  OrderViewController
//  Linus
//
//  Created by Nina Yang on 5/13/17.
//  Copyright © 2017 Nina Yang. All rights reserved.
//

import UIKit
import ExpandingCollection
import ConversationV1
import AudioKit
import SpeechToTextV1

class OrderViewController: UIViewController {
    
    var recorder: AKNodeRecorder!
    var player: AKAudioPlayer!
    var delay: AKDelay!
    
    var recordingState = RecordingState.readyToRecord
    
    var speechToText: SpeechToText!
    var speechToTextSession: SpeechToTextSession!
    
    var isStreaming = false
    
    @IBOutlet fileprivate var inputPlot: AKNodeOutputPlot!
    @IBOutlet fileprivate weak var infoLabel: UILabel!
    @IBOutlet var recordLongPress: UILongPressGestureRecognizer!
    @IBOutlet fileprivate weak var recordButton: UIButton!
//    @IBOutlet fileprivate weak var textView: UITextView!
    @IBOutlet fileprivate weak var speechLabel: UILabel!

    enum RecordingState {
        case readyToRecord
        case recording
        case readyToPlay
        case playing
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //IBM Bluemix setup
        speechToText = SpeechToText(
            username: Credentials.SpeechToTextUsername,
            password: Credentials.SpeechToTextPassword
        )
        speechToTextSession = SpeechToTextSession(
            username: Credentials.SpeechToTextUsername,
            password: Credentials.SpeechToTextPassword
        )
        
        // Clean tempFiles !
        AKAudioFile.cleanTempDirectory()
        
        // Session settings
        AKSettings.bufferLength = .medium
        
        do {
            try AKSettings.setSession(category: .playAndRecord, with: .allowBluetoothA2DP)
        } catch {
            AKLog("Could not set session category.")
        }

        AKSettings.defaultToSpeaker = true
        
        // Patching
        let mic = AKMicrophone()
        inputPlot.node = mic
        let micMixer = AKMixer(mic)
        
        // Will set the level of microphone monitoring
        recorder = try? AKNodeRecorder(node: micMixer)
        if let file = recorder.audioFile {
            player = try? AKAudioPlayer(file: file)
        }
        player.looping = true
        player.completionHandler = playingEnded
        
        AudioKit.start()
        
        setupUIForRecording()
    }
    
    // CallBack triggered when playing has ended
    // Must be seipatched on the main queue as completionHandler
    // will be triggered by a background thread
    fileprivate func playingEnded() {
        DispatchQueue.main.async {
            self.setupUIForPlaying()
        }
    }
    
    fileprivate func setupUIForRecording() {
        recordingState = .readyToRecord
//        infoLabel.text = "Ready to record"
        recordButton.setTitle("Record", for: .normal)
    }
    
    fileprivate func setupUIForPlaying() {
        //TODO: FIX THIS
        let recordedDuration = player != nil ? player.audioFile.duration  : 0
//        infoLabel.text = "Recorded: \(String(format: "%0.1f", recordedDuration)) seconds"
        recordButton.setTitle("Play", for: .normal)
        recordingState = .readyToPlay
    }
    
    
    // MARK: Actions

    @IBAction func recordButtonPressed(_ sender: Any) {
        if self.recordLongPress.state == .began {
            if self.recordingState == .readyToRecord {
                // infoLabel.text = "Recording"
                recordButton.setTitle("Stop", for: .normal)
                recordingState = .recording
                
                do {
                    try recorder.record()
                } catch {
                    print("Errored recording.")
                }
                
                recordButton.setTitle("Stop Microphone", for: .normal)
            }
            self.beginLongPress()
        } else if self.recordLongPress.state == .ended {
            self.endLongPress()
        } else if self.recordLongPress.state == .failed {
            //handle error here basically do nothing
            return
        }
    }
    
    fileprivate func beginLongPress() {
        // Microphone monitoring is muted
        recordButton.setTitle("Start Microphone", for: .normal)
        
        do {
            try player.reloadFile()
        } catch { print("Errored reloading.") }
        
        let recordedDuration = player != nil ? player.audioFile.duration  : 0
        if recordedDuration > 0.0 {
            recorder.stop()
            player.audioFile.exportAsynchronously(name: "TempTestFile.m4a",
                                                  baseDir: .documents,
                                                  exportFormat: .m4a) {_, exportError in
                                                    if let error = exportError {
                                                        print("Export Failed \(error)")
                                                    } else {
                                                        print("Export succeeded")
                                                    }
            }
            setupUIForPlaying()
        }

        player.play()
        //            infoLabel.text = "Playing..."
        recordButton.setTitle("Stop", for: .normal)
        recordingState = .playing
    }
    
    fileprivate func endLongPress() {
        player.stop()
        setupUIForPlaying()
    }
    
    fileprivate func startStreamingMicrophone() {
        // define callbacks
        speechToTextSession.onConnect = { print("connected") }
        speechToTextSession.onDisconnect = { print("disconnected") }
        speechToTextSession.onError = { error in print(error) }
        speechToTextSession.onPowerData = { decibels in print(decibels) }
        speechToTextSession.onMicrophoneData = { data in print("received data") }
        speechToTextSession.onResults = { results in self.speechLabel.text = results.bestTranscript }
        
        // define recognition settings
        var settings = RecognitionSettings(contentType: .opus)
        settings.continuous = true
        settings.interimResults = true
        
        // start recognizing microphone audio
        speechToTextSession.connect()
        speechToTextSession.startRequest(settings: settings)
        speechToTextSession.startMicrophone()
    }
    
    fileprivate func stopStreamingMicrophone() {
        // stop recognizing microphone audio
        speechToTextSession.stopMicrophone()
        speechToTextSession.stopRequest()
        speechToTextSession.disconnect()
    }
    
    class func instanceFromNib() -> OrderViewController {
        return UINib(nibName: "OrderViewController", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! OrderViewController
    }
}

