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
import Combine

public protocol SpeechRecognizerDelegate: class {
    func speechRecognizer(_ speechRecognizer: SpeechRecognizer, didChange status: SpeechRecognizer.Status)
}

public typealias SpeechRecognizerErrorHandler = (Error) -> Void

public class SpeechRecognizer: NSObject, ObservableObject {
        
    @Published public var results = ""
    
    var speechRecognizer: SFSpeechRecognizer?
    
    var audioEngine = AVAudioEngine()
    
    public var audioLevel = 0.0
    
    public var isAvailable = true
    
    public weak var delegate: SpeechRecognizerDelegate?
    
    public var authorizationStatus = Status.waiting {
        didSet {
            delegate?.speechRecognizer(self, didChange: authorizationStatus)
        }
    }
    
    private var task: SFSpeechRecognitionTask?
    
    private var request: SFSpeechAudioBufferRecognitionRequest?
    
    private var audioMeasurer = AudioMeasurer()
    
    private var node: AVAudioInputNode?
    
    public enum Status {
        case waiting, authorized, denied
    }
    
    public init(locale: Locale = Locale(identifier: "pt-BR")) {
        self.speechRecognizer = SFSpeechRecognizer(locale: locale)
        super.init()
        setupRecognizer()
        requestAuthorization()
        request = SFSpeechAudioBufferRecognitionRequest()
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

extension SpeechRecognizer {
    
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


extension SpeechRecognizer: SFSpeechRecognizerDelegate {
    
    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer,
                          availabilityDidChange available: Bool) {
        isAvailable = available
    }
    
}
