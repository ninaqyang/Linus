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
import Speech

//struct Conversation {
//    fileprivate let username: String = Credentials.username
//    fileprivate let password: String = Credentials.password
//    fileprivate let workspaceId: String = Credentials.workspaceId
//    fileprivate let version = Date().getCurrentDate()
//}

class OrderViewController: UIViewController, SFSpeechRecognizerDelegate {
    
    @IBOutlet fileprivate weak var textView: UITextView!
    @IBOutlet fileprivate weak var microphoneButton: UIButton!
    @IBOutlet fileprivate weak var watsonLabel: UILabel!
    
    fileprivate let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))

    fileprivate var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    fileprivate var recognitionTask: SFSpeechRecognitionTask?
    fileprivate let audioEngine = AVAudioEngine()
    
//    fileprivate let username: String = Credentials.username
//    fileprivate let password: String = Credentials.password
    fileprivate let workspaceId: String = Credentials.workspaceId

    fileprivate var version: String {
        get {
            return Date().getCurrentDate()
        }
    }
    
    fileprivate var context: Context?

    fileprivate var recordingDone: Bool = false
    
    fileprivate var conversation: Conversation?

    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        microphoneButton.isEnabled = false  //2
        
        speechRecognizer?.delegate = self  //3
        
        SFSpeechRecognizer.requestAuthorization { (authStatus) in  //4
            
            var isButtonEnabled = false
            
            switch authStatus {  //5
            case .authorized:
                isButtonEnabled = true
                
            case .denied:
                isButtonEnabled = false
                print("User denied access to speech recognition")
                
            case .restricted:
                isButtonEnabled = false
                print("Speech recognition restricted on this device")
                
            case .notDetermined:
                isButtonEnabled = false
                print("Speech recognition not yet authorized")
            }
            
            OperationQueue.main.addOperation() {
                self.microphoneButton.isEnabled = isButtonEnabled
            }
        }
        
        self.setupWatson()
    }
    
    fileprivate func startRecording() {
        
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let inputNode = audioEngine.inputNode else {
            fatalError("Audio engine has no input node")
        }
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            
            var isFinal = false
            
            if result != nil {
                
                self.textView.text = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.microphoneButton.isEnabled = true
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        
        textView.text = "Say something, I'm listening!"
        
    }
    
    // MARK: Actions
    
    @IBAction func microphoneTapped(_ sender: AnyObject) {
        if sender.state == .ended && audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            microphoneButton.isEnabled = false
            microphoneButton.setTitle("Start Recording", for: .normal)
            self.sendSpeechToWatson(self.textView.text)
        } else if sender.state == .began {
            startRecording()
            self.watsonLabel.text = nil
            microphoneButton.setTitle("Stop Recording", for: .normal)
        }
    }
    
    
    // MARK: SFSpeechRecognizerDelegate

    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            microphoneButton.isEnabled = true
        } else {
            microphoneButton.isEnabled = false
        }
    }
    
    
    // MARK: IBM Watson Conversation

    fileprivate func setupWatson() {
        self.watsonLabel.text = nil
        
        let username = Credentials.username
        let password = Credentials.password
        self.conversation = Conversation(username: username, password: password, version: version)
        
        guard let conversation = self.conversation else { return }
        let failure = { (error: Error) in print(error) }
        conversation.message(withWorkspace: self.workspaceId, failure: failure) { [weak self] response in
            guard let strongSelf = self else { return }
            print(response.output.text)
            strongSelf.context = response.context
        }
    }
    
    fileprivate func sendSpeechToWatson(_ text: String) {
        let failure = { (error: Error) in
            print(error)
            self.watsonLabel.text = "Sorry, I didn't quite get that."
        }
        let request = MessageRequest(text: text, context: context)
        guard let conversation = self.conversation else { return }
        conversation.message(withWorkspace: self.workspaceId, request: request, failure: failure) { [weak self] response in
            guard let strongSelf = self else { return }
            print(response.output.text)
            strongSelf.context = response.context
            
            DispatchQueue.main.async {
                strongSelf.handleWatsonResponse(response.output.text)
            }
        }
    }
    
    fileprivate func handleWatsonResponse(_ text: [String]) {
        if !text.isEmpty, let response = text.first {
            self.watsonLabel.text = "\(response)"
        } else {
            self.watsonLabel.text = "Sorry, I didn't quite get that."
        }
    }
    
    class func instanceFromNib() -> OrderViewController {
        return UINib(nibName: "OrderViewController", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! OrderViewController
    }
}

