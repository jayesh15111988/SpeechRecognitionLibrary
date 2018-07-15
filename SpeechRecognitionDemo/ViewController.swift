//
//  ViewController.swift
//  SpeechRecognitionDemo
//
//  Created by Jayesh Kawli on 3/14/17.
//  Copyright © 2017 Jayesh Kawli. All rights reserved.
//

import UIKit
import Speech

let speechRecognitionTimeout: Double = 1.5
let maximumAllowedTimeDuration = 10

class ViewController: UIViewController, SFSpeechRecognizerDelegate {

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
    let timeLimiterIndicatorLabel = UILabel()

    // A utility to easily use the speech recognition facility.
    var speechRecognizerUtility: SpeechRecognitionUtility?

    private var timer: Timer?
    private var totalTime: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Spanish Translation Request"
        speechButton.setTitleColor(.green, for: .normal)
        speechButton.setTitle("Begin Translation...", for: .normal)
        speechTextLabel.text = "Press Begin Translation button to start translation"
        translatedTextLabel.text = ""
        timeLimiterIndicatorLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLimiterIndicatorLabel.backgroundColor = .green
        timeLimiterIndicatorLabel.textAlignment = .center
        timeLimiterIndicatorLabel.font = UIFont.systemFont(ofSize: 12)
        timeLimiterIndicatorLabel.text = "0"
        statusLabel.text = ""
        self.view.addSubview(timeLimiterIndicatorLabel)
        let viewDictionary: [String: Any] = ["timeLimiterIndicatorLabel": timeLimiterIndicatorLabel, "topLayoutGuide": self.topLayoutGuide]
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[topLayoutGuide]-[timeLimiterIndicatorLabel(25)]", options: [], metrics: nil, views: viewDictionary))
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[timeLimiterIndicatorLabel(25)]-|", options: [], metrics: nil, views: viewDictionary))
        self.view.backgroundColor = .purple
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
                    //self?.stopTimeCounter()
                    self?.toggleSpeechRecognitionState()
                    self?.speechRecognitionDone()
                }
            }, timeoutPeriod: speechRecognitionTimeout) // We will set the Speech recognition Timeout to make sure we get the full string output once user has stopped talking. For example, if we specify timeout as 2 seconds. User initiates speech recognition, speaks continuously (Hopegully way less than full one minute), and if pauses for more than 2 seconds, value of finalOutput in above block will be true. Before that you will keep getting output, but that won't be the final one.
        } else {
            // We will call this method to toggle the state on/off of speech recognition operation.
            self.toggleSpeechRecognitionState()
        }
    }

    func speechRecognitionDone() {
        // Trigger the request to get translations as soon as user has done providing full speech input. Don't trigger until query length is at least one.
        if let query = self.speechTextLabel.text, query.count > 0, query != "Please say something to translate" {
            self.statusLabel.text = "Please wait while we get translations from server"
            self.statusLabel.textColor = .black
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
        self.speechTextLabel.textColor = .green
        self.statusLabel.text = ""
        self.speechButton.setTitle("Begin New Translation", for: .normal)
        // Re-enable the toggle speech button once translations are ready.
        self.toggleSpeechButtonAccessState(enabled: true)
    }

    // A method to toggle the userInteractionState of toggle speech state button
    func toggleSpeechButtonAccessState(enabled: Bool) {
        self.speechButton.isUserInteractionEnabled = enabled
        if enabled {
            self.speechButton.alpha = 1.0
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
            case .authorized:
                print("State: Speech recognition authorized")
            case .audioEngineStart:
                self.speechTextLabel.text = "Please say something to translate"
                self.speechTextLabel.textColor = .black
                self.speechButton.setTitle("Listening....", for: .normal)
                toggleSpeechButtonAccessState(enabled: false)
                self.startTimeCounterAndUpdateUI()
                self.view.backgroundColor = .yellow
                speechButton.setTitleColor(.red, for: .normal)
                translatedTextLabel.text = ""
                self.recordingIndicator.isHidden = false
                print("State: Audio Engine Started")
            case .audioEngineStop:
                print("State: Audio Engine Stopped")
            self.recordingIndicator.isHidden = true
            case .recognitionTaskCancelled:
                print("State: Recognition Task Cancelled")
            case .speechRecognized(let recognizedString):
                self.speechTextLabel.text = recognizedString
                self.speechTextLabel.textColor = .green
                self.view.backgroundColor = .orange
                speechButton.setTitleColor(.green, for: .normal)
                print("State: Recognized String \(recognizedString)")
            case .speechNotRecognized:
                print("State: Speech Not Recognized")
            case .availabilityChanged(let availability):
                toggleSpeechButtonAccessState(enabled: availability)
                print("State: Availability changed. New availability \(availability)")
            case .speechRecognitionStopped(let finalRecognizedString):
                self.stopTimeCounter()
                self.speechButton.setTitle("Getting translations.....", for: .normal)
                self.speechTextLabel.textColor = .black
                self.view.backgroundColor = .purple
                speechButton.setTitleColor(.green, for: .normal)
                print("State: Speech Recognition Stopped with final string \(finalRecognizedString)")
        }
    }

    private func startTimeCounterAndUpdateUI() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] (timer) in
            guard let weakSelf = self else { return }

            guard weakSelf.totalTime < maximumAllowedTimeDuration else {
                weakSelf.toggleSpeechRecognitionState()
                weakSelf.speechRecognitionDone()
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

