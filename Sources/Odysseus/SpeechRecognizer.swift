//
//  SpeechRecognizer.swift
//  Lana
//
//  Created by Emannuel Carvalho on 19/11/19.
//  Copyright © 2019 Emannuel Carvalho. All rights reserved.
//

import Foundation
import Accelerate
import Speech

enum SpeechRecognizerStatus {
    case waiting, authorized, denied
}

public typealias SpeechRecognizerErrorHandler = (Error) -> Void

protocol SpeechRecognizer {
    func requestAuthorization()
    func startRecognizing(errorHandler: SpeechRecognizerErrorHandler?)
    func stopRecognizing()
    
    var audioLevel: Double { get }
    var isAvailable: Bool { get }
    var results: String { get }
    var authorizationStatus: SpeechRecognizerStatus { get }
}

extension SpeechRecognizer {
    func startRecognizing(errorHandler: SpeechRecognizerErrorHandler? = nil) {
        self.startRecognizing(errorHandler: errorHandler)
    }
}

@available(iOS 13.0, *)
public class Recognizer: NSObject, SpeechRecognizer, ObservableObject {
        
    @Published var results = "" {
        willSet {
            objectWillChange.send()
        }
    }
    
    var audioLevel = 0.0
    
    var isAvailable = true
    
    var authorizationStatus = SpeechRecognizerStatus.waiting
    
    private var speechRecognizer: SFSpeechRecognizer?
    
    private var task: SFSpeechRecognitionTask?
    
    private let audioEngine = AVAudioEngine()
    
    private var request: SFSpeechAudioBufferRecognitionRequest?
    
    private var audioMeasurer = AudioMeasurer()
    
    private var node: AVAudioInputNode?
    
    public init(locale: Locale = Locale(identifier: "pt-BR")) {
        self.speechRecognizer = SFSpeechRecognizer(locale: locale)
        super.init()
        setupRecognizer()
        requestAuthorization()
    }
    
    public func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] (status) in
            OperationQueue.main.addOperation {
                self?.updateStatus(status)
            }
        }
    }
        
    public func startRecognizing(errorHandler: SpeechRecognizerErrorHandler? = nil) {
        request = SFSpeechAudioBufferRecognitionRequest()
        node = audioEngine.inputNode
        guard let request = self.request,
            let node = self.node else {
                return
        }
        let recordingFormat = node.outputFormat(forBus: 0)
        node.installTap(onBus: 0,
                        bufferSize: 1024,
                        format: recordingFormat) { [weak self] (buffer, _) in
                            self?.request?.append(buffer)
                            self?.measureAudio(buffer: buffer)
        }
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            errorHandler?(error)
        }
        request.shouldReportPartialResults = true
        task = speechRecognizer?.recognitionTask(with: request) { [weak self] (result, error) in
          var isFinal = false
          
            if let result = result {
                self?.results = result.bestTranscription.formattedString
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                self?.audioEngine.stop()
                self?.node?.removeTap(onBus: 0)
                
                self?.request = nil
                self?.task = nil
            }
        }
    }
    
    public func stopRecognizing() {
        request?.endAudio()
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        task?.finish()
    }
    
}

@available(iOS 13.0, *)
extension Recognizer {
    
    fileprivate func measureAudio(buffer: AVAudioPCMBuffer) {
        audioLevel = 7000.0 / audioMeasurer.level(for: buffer)
    }
    
    fileprivate func setupRecognizer() {
        speechRecognizer?.delegate = self
    }
    
    fileprivate func updateStatus(_ status: SFSpeechRecognizerAuthorizationStatus) {
        switch status {
        case .denied, .restricted:
            authorizationStatus = .denied
        case .authorized:
            authorizationStatus = .authorized
        default:
            authorizationStatus = .waiting
        }
    }
    
}


@available(iOS 13.0, *)
extension Recognizer: SFSpeechRecognizerDelegate {
    
    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer,
                          availabilityDidChange available: Bool) {
        isAvailable = available
    }
    
}
