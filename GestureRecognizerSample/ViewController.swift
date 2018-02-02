//
//  ViewController.swift
//  GestureRecognizerSample
//
//  Created by Amr Omran on 02.02.18.
//  Copyright © 2018 Amr Omran. All rights reserved.
//

import UIKit
import AVFoundation
import Speech

class ViewController: UIViewController, SFSpeechRecognizerDelegate {
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var inputTextField: UITextField!
    @IBOutlet weak var talkBtnOutlet: UIButton!
    
    let talk = AVSpeechSynthesizer()
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))  //1
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        talkBtnOutlet.isEnabled = false
        talkBtnOutlet.setImage(UIImage(named: "if_ic_mic_48px_352543.png"), for: .normal)
        speechRecognizer?.delegate = self
        
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
        
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
                self.talkBtnOutlet.isEnabled = isButtonEnabled
            }
        
        }
    }
    
    func startRecording() {
        
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
        let inputNode = audioEngine.inputNode
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
                self.talkBtnOutlet.isEnabled = true
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
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            talkBtnOutlet.isEnabled = true
        } else {
            talkBtnOutlet.isEnabled = false
        }
    }
    

    @IBAction func talkBtn(_ sender: Any) {
        if (audioEngine.isRunning) {
            audioEngine.stop()
            recognitionRequest!.endAudio()
            talkBtnOutlet.isEnabled = true
            talkBtnOutlet.setImage(UIImage(named: "if_ic_mic_48px_352543.png"), for: .normal)
            textView.text = ""

        } else {
            startRecording()
            talkBtnOutlet.setImage(UIImage(named: "if_media-stop_216325.png"), for: .normal)
        }
    }



    @IBAction func sayBtn(_ sender: Any) {
        var input = inputTextField.text
        synthesizeSpeech(inputText: input!)
    }
    

    func synthesizeSpeech(inputText: String){
        let speakText = AVSpeechUtterance(string: inputText)
        speakText.rate = 0.5
        speakText.pitchMultiplier = 1.7
        talk.speak(speakText)
    }

}


