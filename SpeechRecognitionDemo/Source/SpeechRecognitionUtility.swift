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

    func toggleSpeechRecognitionActivity() throws {
        if isSpeechRecognitionOn() {
            stopAudioRecognition()
        } else {
            try runSpeechRecognition()
        }
    }

    func runSpeechRecognition() throws  {
        if recognitionTask != nil {
            recognitionTask?.cancel()
            updateSpeechRecognitionState(with: .recognitionTaskCancelled)
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

        // For utilizing direct input from mic
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        guard let audioEngine = audioEngine else {
            throw SpeechRecognitionOperationError.audioEngineUnavailable
        }

        let inputNode = audioEngine.inputNode

        guard let recognitionRequest = recognitionRequest else {
            throw SpeechRecognitionOperationError.invalidRecognitionRequest
        }

        recognitionRequest.shouldReportPartialResults = true

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { [weak self] (result, error) in
            guard let strongSelf = self else { return }
            // Hypotheses for possible transcriptions, sorted in decending order of confidence (more likely first)
            if let result = result {

                for transcription in result.transcriptions {
                    for segment in transcription.segments {
                        let bestString = transcription.formattedString
                        let indexTo = bestString.index(bestString.startIndex, offsetBy: segment.substringRange.location)
                        print("Segment is \(bestString[indexTo...]) with probability value of \(segment.confidence)\n\n")
                    }
                }

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

    private func updateSpeechRecognitionState(with state: SpeechRecognitionOperationState, finalOutput: Bool = false) {
        OperationQueue.main.addOperation {
            self.recognitionStateUpdateBlock(state, finalOutput)
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
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        self.recognitionRequest = nil

        if self.recognitionTask != nil {
            self.recognitionTask?.cancel()
            self.updateSpeechRecognitionState(with: .recognitionTaskCancelled)
            self.recognitionTask = nil
        }
    }

    private func isSpeechRecognitionOn() -> Bool {
        return self.audioEngine?.isRunning ?? false
    }
}
