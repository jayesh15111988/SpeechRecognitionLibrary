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

    // A button to begin/terminate or toggle the speech recognition.
    @IBOutlet weak var speechButton: UIButton!

    // A view to indicate the current limit reached of user speech input in terms of number of seconds
    @IBOutlet weak var timeLimiterIndicatorLabel: UILabel!

    @IBOutlet weak var speechFinishedButton: UIButton!

    @IBOutlet weak var requestTranslationsButton: UIButton!

    var speechRecognizerUtility: SpeechRecognitionUtility?

    private var timer: Timer?
    private var totalTime: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Translations app"
        speechButton.setTitle("Begin Translations...", for: .normal)
        speechTextLabel.text = "Tap Begin translations to initiate speech recognition process"
        translatedTextLabel.text = ""

        reachability.whenReachable = { [weak self] reachable in
            print("Network service reachable")
            self?.toggleSpeechButtonAccessState(enabled: true)
            self?.speechButton.setTitle("Begin New Session", for: .normal)
        }

        reachability.whenUnreachable = { [weak self] _ in
            print("Network service unreachable")
            self?.speechButton.setTitle("No network connectivity", for: .normal)
            self?.toggleSpeechButtonAccessState(enabled: false)
            self?.speechFinishedButton.isHidden = true
        }

        do {
            try reachability.startNotifier()
        } catch {
            print("Unable to start notifier")
        }
    }

    @IBAction func speechFinished() {
        speechRecognizerUtility?.speechFinished()
        speechFinishedButton.isHidden = true
        speechButton.setTitle(nil, for: .normal)
        stopTimeCounter()
    }

    @IBAction func requestTranslations() {
        print("requesting translations....")
        toggleSpeechRecognitionState()
        stopTimeCounter()
        requestTranslationsFromServer()
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
        }
    }

    private func resetState() {
        self.statusLabel.text = ""
        self.speechButton.setTitle("Begin New Session", for: .normal)
        self.speechButton.setTitleColor(.green, for: .normal)
        // Re-enable the toggle speech button once translations are ready.
        self.requestTranslationsButton.setTitle(nil, for: .normal)
        self.toggleSpeechButtonAccessState(enabled: true)
    }

    @IBAction func saySomethingButtonPressed(_ sender: Any) {
        if speechRecognizerUtility == nil {
            speechRecognizerUtility = SpeechRecognitionUtility(speechRecognitionAuthorizedBlock: { [weak self] in
                self?.toggleSpeechRecognitionState()
            }, stateUpdateBlock: { [weak self] (currentSpeechRecognitionState, finished) in
                self?.stateChangedWith(state: currentSpeechRecognitionState)
                if finished {
                    self?.toggleSpeechRecognitionState()
                }
            })
        } else {
            toggleSpeechRecognitionState()
        }
    }

    private func toggleSpeechRecognitionState() {
        do {
            try speechRecognizerUtility?.toggleSpeechRecognitionActivity()
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
        } catch SpeechRecognitionOperationError.speechRecognizerAvailable {
            print("Specified speech recognizer object is unavailable.")
        } catch {
            print("Unknown error occurred")
        }
    }

    func toggleSpeechButtonAccessState(enabled: Bool) {
        self.speechButton.isUserInteractionEnabled = enabled
        if enabled {
            self.speechButton.alpha = 1.0
            speechFinishedButton.isHidden = true
        } else {
            self.speechButton.alpha = 0.6
        }
    }

    private func stateChangedWith(state: SpeechRecognitionOperationState) {
        switch state {
        case .denied:
            print("Access to Speech Recognizer denied")
        case .authorized:
            print("State: Speech recognition authorized")
        case .audioEngineStart:
            self.speechTextLabel.text = "Please say something to translate"
            self.speechButton.setTitle("Listening....", for: .normal)
            toggleSpeechButtonAccessState(enabled: false)
            startTimeCounterAndUpdateUI()
            speechButton.setTitleColor(.red, for: .normal)
            translatedTextLabel.text = ""
            speechFinishedButton.isHidden = false
            print("State: Audio Engine Started")
        case .audioEngineStop:
            print("State: Audio Engine Stopped")
        case .recognitionTaskCancelled:
            print("State: Recognition Task Cancelled")
        case .speechRecognized(let recognizedString):
            self.speechTextLabel.text = recognizedString
            self.requestTranslationsButton.setTitle("Translate", for: .normal)
            speechButton.setTitleColor(.green, for: .normal)
            print("State: Recognized String \(recognizedString)")
        case .speechNotRecognized:
            print("State: Speech Not Recognized")
        }
    }

    private func startTimeCounterAndUpdateUI() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] (timer) in
            guard let weakSelf = self else { return }

            guard weakSelf.totalTime < maximumAllowedTimeDuration else {
                weakSelf.speechTextLabel.text = "Maximum time out reached. Please start over"
                weakSelf.toggleSpeechRecognitionState()
                weakSelf.resetState()
                weakSelf.stopTimeCounter()
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
