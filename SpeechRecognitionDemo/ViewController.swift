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

    @IBOutlet weak var speechTextLabel: UILabel!
    @IBOutlet weak var speechButton: UIButton!
    var speechRecognizerUtility: SpeechRecognitionUtility?

    override func viewDidLoad() {
        super.viewDidLoad()
        speechButton.setTitle("Start speech Recognition", for: .normal)
    }

    @IBAction func saySomethingButtonPressed(_ sender: Any) {
        if speechRecognizerUtility == nil {
            speechRecognizerUtility = SpeechRecognitionUtility(speechRecognitionAuthorizedBlock: { [weak self] in
                self?.performSpeechRecognition()
            }, stateUpdateBlock: { (currentSpeechRecognitionState) in
                self.stateChangedWithNew(state: currentSpeechRecognitionState)
            }, recordingState: .continuous)
        } else {
            self.performSpeechRecognition()
        }
    }

    private func performSpeechRecognition() {
        do {
            try self.speechRecognizerUtility?.toggleSpeechRecognitionActivity()
        } catch SpeechRecognitionOperationError.denied {
            print("Awww")
        } catch SpeechRecognitionOperationError.notDetermined {
            print("Awww")
        } catch SpeechRecognitionOperationError.restricted {
            print("Awww")
        } catch SpeechRecognitionOperationError.audioSessionUnavailable {
            print("Awww")
        } catch SpeechRecognitionOperationError.inputNodeUnavailable {
            print("Awww")
        } catch SpeechRecognitionOperationError.invalidRecognitionRequest {
            print("Awww")
        } catch SpeechRecognitionOperationError.audioEngineUnavailable {
            print("Awww")
        } catch {
            print("Unknown Error")
        }
    }

    private func stateChangedWithNew(state: SpeechRecognitionOperationState) {
        switch state {
            case .authorized:
                print("Authorized")
            case .audioEngineStart:
                self.speechTextLabel.text = "Say Something...."
                self.speechTextLabel.textColor = .green
                self.speechButton.setTitle("Stop Speech Recognition", for: .normal)
                print("Audio Engine Start")
            case .audioEngineStop:
                print("Audio Engine Stop")
            case .recognitionTaskCancelled:
                print("Recognition Task Cancelled")
            case .speechRecognised(let recognizedString):
                self.speechTextLabel.text = recognizedString
                print("Recognized String \(recognizedString)")
            case .speechNotRecognized:
                print("Speech Not Recognized")
            case .availabilityChanged(let availability):
                print("Availability \(availability)")
            case .speechRecognitionStopped:
                self.speechButton.setTitle("Start speech Recognition", for: .normal)
                self.speechTextLabel.textColor = .red
                print("Speech Recognition Stopped")
        }
    }

}

