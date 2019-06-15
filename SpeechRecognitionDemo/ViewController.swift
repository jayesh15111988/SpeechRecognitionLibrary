//
//  ViewController.swift
//  SpeechRecognitionDemo
//
//  Created by Jayesh Kawli on 3/14/17.
//  Copyright © 2017 Jayesh Kawli. All rights reserved.
//

import UIKit
import Speech

let maximumAllowedTimeDuration = 30

class ViewController: UIViewController, SFSpeechRecognizerDelegate {

    let reachability = Reachability()!

    // A label for showing instructions while speech recognition is in progress plus the original text to translate.
    @IBOutlet weak var speechTextLabel: UILabel!

    // A label to indicate the status of current translated speech recognition state
    @IBOutlet weak var statusLabel: UILabel!

    // A label for showing the translated text in the app
    @IBOutlet weak var translatedTextLabel: UILabel!

    // An image to indicate the recording status of current session
    @IBOutlet weak var recordingIndicator: UIImageView!

    // A button to begin/terminate or toggle the speech recognition.
    @IBOutlet weak var speechButton: UIButton!

    // A view to indicate the current limit reached of user speech input in terms of number of seconds
    @IBOutlet weak var timeLimiterIndicatorLabel: UILabel!

    @IBOutlet weak var speechFinishedButton: UIButton!

    @IBOutlet weak var requestTranslationsButton: UIButton!

    // A utility to easily use the speech recognition facility.
    var speechRecognizerUtility: SpeechRecognitionUtility?

    private var timer: Timer?
    private var totalTime: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        reachability.whenReachable = { [weak self] reachable in
            self?.toggleSpeechButtonAccessState(enabled: true)
            self?.speechButton.setTitle("Begin New Translation", for: .normal)
        }

        reachability.whenUnreachable = {[weak self] _ in
            self?.speechButton.setTitle("No network connectivity", for: .normal)
            self?.toggleSpeechButtonAccessState(enabled: false)
            self?.speechFinishedButton.isHidden = true
        }

        do {
            try reachability.startNotifier()
        } catch {
            print("Unable to start notifier")
        }

        self.title = "Translations App"
        speechButton.setTitle("Begin Translation...", for: .normal)
        speechTextLabel.text = "Press Begin Translation button to start translation"
        translatedTextLabel.text = ""
        timeLimiterIndicatorLabel.backgroundColor = .green
        timeLimiterIndicatorLabel.textAlignment = .center
        timeLimiterIndicatorLabel.font = UIFont.systemFont(ofSize: 12)
        timeLimiterIndicatorLabel.text = "0"
        statusLabel.text = ""
        speechFinishedButton.addTarget(self, action: #selector(speechFinished), for: .touchUpInside)
        requestTranslationsButton.addTarget(self, action: #selector(requestTranslations), for: .touchUpInside)
    }

    @objc func speechFinished() {
        speechRecognizerUtility?.speechFinished()
        speechFinishedButton.isHidden = true
        speechButton.setTitle(nil, for: .normal)
    }

    @objc func requestTranslations() {
        toggleSpeechRecognitionState()
        stopTimeCounter()
        requestTranslationsFromServer()
    }

    @IBAction func saySomethingButtonPressed(_ sender: Any) {
        if speechRecognizerUtility == nil {
            // Initialize the speech recognition utility here
            speechRecognizerUtility = SpeechRecognitionUtility(speechRecognitionAuthorizedBlock: { [weak self] in
                self?.toggleSpeechRecognitionState()
            }, stateUpdateBlock: { [weak self] (currentSpeechRecognitionState, finalOutput) in
                // A block to update the status of speech recognition. This block will get called every time Speech framework recognizes the speech input
                self?.stateChangedWithNew(state: currentSpeechRecognitionState)
                // We won't perform translation until final input is ready. We will usually wait for users to finish speaking their input until translation request is sent
                if finalOutput {
                    self?.toggleSpeechRecognitionState()
                }
            })
        } else {
            // We will call this method to toggle the state on/off of speech recognition operation.
            self.toggleSpeechRecognitionState()
        }
    }

    func requestTranslationsFromServer() {
        // Trigger the request to get translations as soon as user has done providing full speech input. Don't trigger until query length is at least one.
        self.speechButton.setTitle("Getting translations.....", for: .normal)
        if let query = self.speechTextLabel.text, query.count > 0 {
            self.statusLabel.text = "Please wait while we get translations from server"
            // Disable the toggle speech button while we're getting translations from server.
            toggleSpeechButtonAccessState(enabled: false)
            NetworkRequest.sendRequestWith(query: query, completion: { (translation) in
                OperationQueue.main.addOperation {
                    // Explicitly execute the code on main thread since the request we get back need not be on the main thread.
                    self.translatedTextLabel.text = translation
                    self.resetState()
                }
            })
        } else {
            resetState()
        }
    }

    func resetState() {
        self.statusLabel.text = ""
        self.speechButton.setTitle("Begin New Translation", for: .normal)
        // Re-enable the toggle speech button once translations are ready.
        self.requestTranslationsButton.setTitle(nil, for: .normal)
        self.toggleSpeechButtonAccessState(enabled: true)
    }

    // A method to toggle the userInteractionState of toggle speech state button
    func toggleSpeechButtonAccessState(enabled: Bool) {
        self.speechButton.isUserInteractionEnabled = enabled
        if enabled {
            self.speechButton.alpha = 1.0
            speechFinishedButton.isHidden = true
        } else {
            self.speechButton.alpha = 0.6
        }
    }

    // A method to toggle the speech recognition state between on/off
    private func toggleSpeechRecognitionState() {
        do {
            try self.speechRecognizerUtility?.toggleSpeechRecognitionActivity()
        } catch SpeechRecognitionOperationError.denied {
            print("Speech Recognition access denied")
        } catch SpeechRecognitionOperationError.notDetermined {
            print("Unrecognized Error occurred")
        } catch SpeechRecognitionOperationError.restricted {
            print("Speech recognition access restricted")
        } catch SpeechRecognitionOperationError.audioSessionUnavailable {
            print("Audio session unavailable")
        } catch SpeechRecognitionOperationError.invalidRecognitionRequest {
            print("Recognition request is null. Expected non-null value")
        } catch SpeechRecognitionOperationError.audioEngineUnavailable {
            print("Audio engine is unavailable. Cannot perform speech recognition")
        } catch {
            print("Unknown error occurred")
        }
    }

    private func stateChangedWithNew(state: SpeechRecognitionOperationState) {
        switch state {
            case .denied:
                print("Access to Speech Recognizer denied")
            case .authorized:
                print("State: Speech recognition authorized")
            case .audioEngineStart:
                self.speechTextLabel.text = "Please say something to translate"
                self.speechButton.setTitle("Listening....", for: .normal)
                self.speechFinishedButton.isHidden = false
                toggleSpeechButtonAccessState(enabled: false)
                self.startTimeCounterAndUpdateUI()
                speechButton.setTitleColor(.red, for: .normal)
                translatedTextLabel.text = ""
                self.speechFinishedButton.isHidden = false
                self.recordingIndicator.isHidden = false
                print("State: Audio Engine Started")
            case .audioEngineStop:
                print("State: Audio Engine Stopped")
            self.recordingIndicator.isHidden = true
            case .recognitionTaskCancelled:
                print("State: Recognition Task Cancelled")
            case .speechRecognized(let recognizedString):
                self.speechTextLabel.text = recognizedString
                self.requestTranslationsButton.setTitle("Translate", for: .normal)
                speechButton.setTitleColor(.green, for: .normal)
                print("State: Recognized String \(recognizedString)")
            case .speechNotRecognized:
                print("State: Speech Not Recognized")
            // Called when speech recognition is done, audio engine is stopped and strings are finally sent for translation on the server.
            case .speechRecognitionStopped(let finalRecognizedString):
                self.stopTimeCounter()
                speechButton.setTitleColor(.green, for: .normal)
                print("State: Speech Recognition Stopped with final string \(finalRecognizedString)")
        }
    }

    private func startTimeCounterAndUpdateUI() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] (timer) in
            guard let weakSelf = self else { return }

            guard weakSelf.totalTime < maximumAllowedTimeDuration else {
                weakSelf.speechTextLabel.text = "Maximum time out reached. Please start over"
                weakSelf.toggleSpeechRecognitionState()
                weakSelf.resetState()
                return
            }

            weakSelf.totalTime = weakSelf.totalTime + 1

            if weakSelf.totalTime >= 2 * (maximumAllowedTimeDuration / 3) {
                weakSelf.timeLimiterIndicatorLabel.backgroundColor = .red
            } else if weakSelf.totalTime >= maximumAllowedTimeDuration / 3 {
                weakSelf.timeLimiterIndicatorLabel.backgroundColor = .orange
            } else {
                weakSelf.timeLimiterIndicatorLabel.backgroundColor = .green
            }
            weakSelf.timeLimiterIndicatorLabel.text = "\(weakSelf.totalTime)"
        })
    }

    private func stopTimeCounter() {
        self.timer?.invalidate()
        self.timer = nil
        self.totalTime = 0
        self.timeLimiterIndicatorLabel.backgroundColor = .green
        self.timeLimiterIndicatorLabel.text = "0"
    }
}

