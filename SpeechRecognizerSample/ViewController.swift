//
//  ViewController.swift
//  SpeechRecognizerSample
//
//  Created by Antonín Charvát on 25/09/2020.
//  Copyright © 2020 AntoninCharvat. All rights reserved.
//

import UIKit
import Speech

/**
 Simple controller using the Speech framework to recognize spoken orders based on defined vocabulary.
 */

final class ViewController: UIViewController {

    private lazy var speechRecognizer: SFSpeechRecognizer = {
        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en_US"))
        recognizer?.delegate = self
        recognizer?.supportsOnDeviceRecognition = true
        return recognizer!
    }()
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    private var audioEngine: AVAudioEngine!
    private var inputNode: AVAudioInputNode!
    
    private var listening = false
    private var waitingForCommands = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAudioSession()
        setupAudioEngine()
        startEngine()
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.record, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Error setting up audio session")
        }
    }
    
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        inputNode = audioEngine.inputNode
    }
    
    private func startEngine() {
        guard !audioEngine.isRunning else {
            print("Already started")
            return
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("Error starting audio engine")
        }
    }
    
    private func startListening() {
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest?.shouldReportPartialResults = true
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        DispatchQueue.main.async {
            self.inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat, block: { (buffer, _) in
                self.recognitionRequest?.append(buffer)
            })
        }

        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest!, delegate: self)
        listening = true
    }
    
    private func resetRecognitionRequest() {
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        inputNode.removeTap(onBus: 0)
        listening = false
        waitingForCommands = false
    }
    
    @IBAction func startButtonTapped() {
        guard !listening else { return }
        
        SFSpeechRecognizer.requestAuthorization { (status) in
            OperationQueue.main.addOperation {
                switch status {
                case .authorized:
                    self.startListening()
                default:
                    print("Speech recognizer permission not granted")
                }
            }
        }
    }
}

// MARK: - SFSpeechRecognizerDelegate

extension ViewController: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        print(available)
    }
}

// MARK: - SFSpeechRecognitionTaskDelegate

extension ViewController: SFSpeechRecognitionTaskDelegate {
    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didHypothesizeTranscription transcription: SFTranscription) {
        let phrase = transcription.formattedString.lowercased()
        
        if Vocabulary.stop.phrases.contains(where: phrase.contains) {
            print("Okay, stopping recognition")
            resetRecognitionRequest()
            return
        }
        
        if Vocabulary.nevermind.phrases.contains(where: phrase.contains), self.waitingForCommands {
            print("Okay, nevermind...")
            resetRecognitionRequest()
            startListening()
            return
        }
        
        if Vocabulary.attention.phrases.contains(where: phrase.contains), !self.waitingForCommands {
            self.waitingForCommands = true
            print("Listening to commands...")
            return
        }
        
        guard self.waitingForCommands else { return }
        
        if Vocabulary.slowDown.phrases.contains(where: phrase.contains) {
            print("Okay, slowing down...")
            resetRecognitionRequest()
            startListening()
        } else if Vocabulary.speedUp.phrases.contains(where: phrase.contains) {
            print("Okay, speeding up...")
            resetRecognitionRequest()
            startListening()
        }
    }
    
    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishRecognition recognitionResult: SFSpeechRecognitionResult) {
        print("Restarting recognition...")
        resetRecognitionRequest()
        startListening()
    }
    
    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishSuccessfully successfully: Bool) {
        print("Did finish successfully: \(successfully)")
        resetRecognitionRequest()
        startListening()
    }
}
