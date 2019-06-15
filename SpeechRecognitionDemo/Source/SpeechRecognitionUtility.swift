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
    case denied
    case notDetermined
    case restricted
    case audioSessionUnavailable
    case invalidRecognitionRequest
    case audioEngineUnavailable
}

enum SpeechRecognitionOperationState {
    case denied
    case authorized
    case audioEngineStart
    case audioEngineStop
    case recognitionTaskCancelled
    case speechRecognized(String)
    case speechNotRecognized
    // Called when speech recognition is done and we're ready to send those strings to server for translations
    case speechRecognitionStopped(String)
}

class SpeechRecognitionUtility: NSObject {

    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine: AVAudioEngine?
    private let recognitionStateUpdateBlock: (SpeechRecognitionOperationState, Bool) -> Void
    private var speechRecognitionPermissionState: SFSpeechRecognizerAuthorizationStatus
    private let speechRecognitionAuthorizedBlock: () -> Void
    private var recognizedText: String

    init(speechRecognitionAuthorizedBlock : @escaping () -> Void, stateUpdateBlock: @escaping (SpeechRecognitionOperationState, Bool) -> Void) {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en_US"))
        recognitionStateUpdateBlock = stateUpdateBlock
        // let supportedLocales = SFSpeechRecognizer.supportedLocales()
        speechRecognitionPermissionState = .notDetermined
        self.speechRecognitionAuthorizedBlock = speechRecognitionAuthorizedBlock
        self.recognizedText = ""

        super.init()

        SFSpeechRecognizer.requestAuthorization { (status) in
            self.speechRecognitionPermissionState = status
            if status == .authorized {
                self.audioEngine = AVAudioEngine()
                // Need to return it on Main queue since this block is returned on serial queue. Assuming user wants to do UI actions once request is authorized.
                OperationQueue.main.addOperation {
                    speechRecognitionAuthorizedBlock()
                }
            } else {
                // show denial message on UI
                self.recognitionStateUpdateBlock(.denied, true)
            }
        }
    }

    func startSpeechRecognition() throws {
        switch self.speechRecognitionPermissionState {
        case .denied:
            throw SpeechRecognitionOperationError.denied
        case .notDetermined:
            throw SpeechRecognitionOperationError.notDetermined
        case .restricted:
            throw SpeechRecognitionOperationError.restricted
        case .authorized:
            print("User authorized app to access speech recognition")
        }

        if audioEngine?.isRunning ?? false {
            audioEngine?.stop()
            recognitionRequest?.endAudio()
        } else {
            try self.runSpeechRecognition()
        }
    }

    func runSpeechRecognition() throws  {

        if recognitionTask != nil {
            recognitionTask?.cancel()
            self.updateSpeechRecognitionState(with: .recognitionTaskCancelled)
            recognitionTask = nil
        }

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch let error {
            print("Error Occurred: \(error.localizedDescription)")
            throw SpeechRecognitionOperationError.audioSessionUnavailable
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        guard let audioEngine = audioEngine else {
            throw SpeechRecognitionOperationError.audioEngineUnavailable
        }

        let inputNode = audioEngine.inputNode

        guard let recognitionRequest = recognitionRequest else {
            throw SpeechRecognitionOperationError.invalidRecognitionRequest
        }

        recognitionRequest.shouldReportPartialResults = false

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { [weak self] (result, error) in
            guard let strongSelf = self else { return }
            // Hypotheses for possible transcriptions, sorted in decending order of confidence (more likely first)
            // result.transcriptions
            if let result = result {
                strongSelf.updateSpeechRecognitionState(with: .speechRecognized(result.bestTranscription.formattedString))
            } else {
                strongSelf.updateSpeechRecognitionState(with: .speechNotRecognized)
            }
        })

        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, time) in
            self.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()

        if let _ = try? audioEngine.start() {
            self.updateSpeechRecognitionState(with: .audioEngineStart)
        } else {
            throw SpeechRecognitionOperationError.audioEngineUnavailable
        }
    }

    func toggleSpeechRecognitionActivity() throws {
        if self.isSpeechRecognitionOn() == true {
            self.stopAudioRecognition()
        } else {
            try self.runSpeechRecognition()
        }
    }

    func speechFinished() {
        recognitionTask?.finish()
    }

    // A method to stop audio engine thereby stopping device to input user audio and process it. It will remove the input source from specified Bus.
    private func stopAudioRecognition() {
        guard let audioEngine = audioEngine else { return }
        if audioEngine.isRunning {
            audioEngine.stop()
            self.recognitionRequest?.endAudio()
            self.updateSpeechRecognitionState(with: .audioEngineStop)
            self.updateSpeechRecognitionState(with: .speechRecognitionStopped(recognizedText))
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        self.recognitionRequest = nil

        if self.recognitionTask != nil {
            self.recognitionTask?.cancel()
            self.updateSpeechRecognitionState(with: .recognitionTaskCancelled)
            self.recognitionTask = nil
        }
    }


    private func updateSpeechRecognitionState(with state: SpeechRecognitionOperationState, finalOutput: Bool = false) {
        OperationQueue.main.addOperation {
            self.recognitionStateUpdateBlock(state, finalOutput)
        }
    }

    private func isSpeechRecognitionOn() -> Bool {
        return self.audioEngine?.isRunning ?? false
    }
}
