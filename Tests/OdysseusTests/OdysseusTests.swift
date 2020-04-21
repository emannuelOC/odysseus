import XCTest
import Speech
@testable import Odysseus

class MockTask: SFSpeechRecognitionTask {
    
    var finishCalled = false
    
    override func finish() {
        finishCalled = true
    }
    
}

class MockRecognizer: SFSpeechRecognizer {
    
    var recognitionTaskCalled = false
    var passedRequest: SFSpeechRecognitionRequest?
    
    var returnedTask = MockTask()
    
    override func recognitionTask(with request: SFSpeechRecognitionRequest, resultHandler: @escaping (SFSpeechRecognitionResult?, Error?) -> Void) -> SFSpeechRecognitionTask {
        recognitionTaskCalled = true
        passedRequest = request
        
        return returnedTask
    }
    
}

class MockAudioEngine: AVAudioEngine {
    
    var prepareCalled = false
    var startCalled = false
    var stopCalled = false
    
    override func prepare() {
        prepareCalled = true
    }
    
    override func start() throws {
        startCalled = true
    }
    
    override func stop() {
        stopCalled = true
    }
}

class MockRequest: SFSpeechAudioBufferRecognitionRequest {
    
    var endAudioCalled = false
    
    override func endAudio() {
        endAudioCalled = true
    }
    
}

final class OdysseusTests: XCTestCase {
    
    var sut: SpeechRecognizer!

    
    func testInitialization() {
        sut = SpeechRecognizer()
        
        XCTAssert(sut.speechRecognizer?.locale.identifier == "pt-BR")
    }
    
    func testInitializationWithLocale() {
        sut = SpeechRecognizer(locale: Locale(identifier: "en-US"))
        
        XCTAssert(sut.speechRecognizer?.locale.identifier == "en-US")
    }
    
    func testStartRecognizing() {
        sut = SpeechRecognizer()
        let mockRecognizer = MockRecognizer()
        sut.speechRecognizer = mockRecognizer
        
        let mockEngine = MockAudioEngine()
        sut.audioEngine = mockEngine

        
        sut.startRecognizing()
        
        XCTAssert(mockRecognizer?.recognitionTaskCalled ?? false)
        XCTAssert(mockRecognizer?.passedRequest?.shouldReportPartialResults ?? false)
        
        XCTAssert(mockEngine.prepareCalled)
        XCTAssert(mockEngine.startCalled)
    }
    
    func testStopRecognizing() {
        sut = SpeechRecognizer()
        let mockRecognizer = MockRecognizer()
        sut.speechRecognizer = mockRecognizer
        let mockEngine = MockAudioEngine()
        sut.audioEngine = mockEngine
        sut.startRecognizing()
        
        sut.stopRecognizing()
        
        XCTAssert(mockEngine.stopCalled)
        XCTAssert(mockRecognizer?.returnedTask.finishCalled ?? false)
    }
    
    func testRecognizerDelegate() {
        sut = SpeechRecognizer()
        let mockRecognizer = MockRecognizer()!
        
        sut.speechRecognizer(mockRecognizer, availabilityDidChange: true)
        
        XCTAssert(sut.isAvailable)
        
        sut.speechRecognizer(mockRecognizer, availabilityDidChange: false)
        
        XCTAssertFalse(sut.isAvailable)
        
    }
    

    static var allTests = [
        ("testInitialization", testInitialization),
        ("testInitializationWithLocale", testInitializationWithLocale),
        ("testStartRecognizing", testStartRecognizing),
        ("testStopRecognizing", testStopRecognizing),
        ("testRecognizerDelegate", testRecognizerDelegate)
    ]
}
