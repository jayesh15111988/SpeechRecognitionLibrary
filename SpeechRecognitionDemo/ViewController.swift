//
//  ViewController.swift
//  SpeechRecognitionDemo
//
//  Created by Jayesh Kawli on 3/14/17.
//  Copyright © 2017 Jayesh Kawli. All rights reserved.
//

import UIKit
import Speech

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

    var speechRecognizerUtility: SpeechRecognitionUtility?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Translations app"
        speechButton.setTitle("Begin Translations...", for: .normal)
        speechTextLabel.text = "Tap Begin translations to initiate speech recognition process"
        translatedTextLabel.text = ""

        reachability.whenReachable = { reachable in
            print("Network service reachable")
        }

        reachability.whenUnreachable = { _ in
            print("Network service unreachable")
        }

        do {
            try reachability.startNotifier()
        } catch {
            print("Unable to start notifier")
        }
    }

    @IBAction func speechFinished() {

    }

    @IBAction func requestTranslations() {
        print("requesting translations....")
        toggleSpeechRecognitionState()
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
        self.speechButton.setTitle("Begin New Translation", for: .normal)
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
        } catch {
            print("Unknown error occurred")
        }
    }

    func toggleSpeechButtonAccessState(enabled: Bool) {
        self.speechButton.isUserInteractionEnabled = enabled
        if enabled {
            self.speechButton.alpha = 1.0
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
            speechButton.setTitleColor(.red, for: .normal)
            translatedTextLabel.text = ""
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
        // Called when speech recognition is done, audio engine is stopped and strings are finally sent for translation on the server.
        case .speechRecognitionStopped(let finalRecognizedString):
            speechButton.setTitleColor(.green, for: .normal)
            print("State: Speech Recognition Stopped with final string \(finalRecognizedString)")
        }
    }
}
