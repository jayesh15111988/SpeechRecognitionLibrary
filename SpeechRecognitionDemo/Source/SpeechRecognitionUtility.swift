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
    case denied
}

class SpeechRecognitionUtility: NSObject {

    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine: AVAudioEngine?
    private var recognitionStateUpdateBlock: (SpeechRecognitionOperationState, Bool) -> Void
    private var speechRecognitionPermissionState: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    private var speechRecognitionAuthorizedBlock: (() -> Void)?

    init(speechRecognitionAuthorizedBlock : @escaping () -> Void, stateUpdateBlock: @escaping (SpeechRecognitionOperationState, Bool) -> Void) {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en_US"))
        let supportedLocales = SFSpeechRecognizer.supportedLocales()
        recognitionStateUpdateBlock = stateUpdateBlock
        super.init()

        SFSpeechRecognizer.requestAuthorization { (status) in
            self.speechRecognitionPermissionState = status
            if status == .authorized {
                print("Authorized")
                self.audioEngine = AVAudioEngine()
                OperationQueue.main.addOperation {
                    speechRecognitionAuthorizedBlock()
                }
            } else {
                print("Denied")
                // Show permission denial message on UI
                self.recognitionStateUpdateBlock(.denied, true)
            }
        }

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
