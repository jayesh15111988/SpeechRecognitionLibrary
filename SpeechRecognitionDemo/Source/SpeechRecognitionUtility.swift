//
//  SpeechRecognitionUtility.swift
//  SpeechRecognitionDemo
//
//  Created by Jayesh Kawli on 3/17/17.
//  Copyright © 2017 Jayesh Kawli. All rights reserved.
//

import Foundation
import Speech

enum SpeechRecognitionOperationError: Error {

}

enum SpeechRecognitionOperationState {

}

class SpeechRecognitionUtility: NSObject {

    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine: AVAudioEngine?
    private var recognitionStateUpdateBlock: ((SpeechRecognitionOperationState, Bool) -> Void)?
    private var speechRecognitionPermissionState: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    private var speechRecognitionAuthorizedBlock: (() -> Void)?
    private var recognizedText: String = ""

    init(speechRecognitionAuthorizedBlock : @escaping () -> Void, stateUpdateBlock: @escaping (SpeechRecognitionOperationState, Bool) -> Void) {

    }

    func startSpeechRecognition() throws {

    }

    func runSpeechRecognition() throws  {

    }

    func speechFinished() {
        recognitionTask?.finish()
    }

    // A method to stop audio engine thereby stopping device to input user audio and process it. It will remove the input source from specified Bus.
    private func stopAudioRecognition() {

    }

    private func isSpeechRecognitionOn() -> Bool {
        //return self.audioEngine?.isRunning ?? false
        return false
    }
}
