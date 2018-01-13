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
            }, stateUpdateBlock: { [weak self] (currentSpeechRecognitionState, toSearch) in
                self?.stateChangedWithNew(state: currentSpeechRecognitionState)
                if toSearch {
                    self?.speechRecognitionDone()
                }
            }, recordingState: .continuous)
        } else {
            self.performSpeechRecognition()
        }
    }

    func speechRecognitionDone() {
        if let query = self.speechTextLabel.text, query.count > 0 {
            self.saySomethingButtonPressed(UIButton())
            self.speechTextLabel.text = "Please wait while we get translations from server"
            self.speechTextLabel.textColor = .black
            NetworkRequest.sendRequestWith(query: query, completion: { (translation) in
                OperationQueue.main.addOperation {
                    self.speechTextLabel.textColor = .green
                    self.speechTextLabel.text = translation
                }
            })
        }
//        self.currentVC.visualSearchBar?.resignFirstResponder()
//        self.dismiss(animated: true) { [weak self] in
//            if let query = self?.searchQuery, query.characters.count > 0 {
//                self?.moveToDestinationViewController(with: query)
//            }
//        }
    }

    func speechRecognitionCancelled() {
        //self.searchQuery = ""
        self.speechRecognitionDone()
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
            case .speechRecognized(let recognizedString):
                self.speechTextLabel.text = recognizedString
                print("Recognized String \(recognizedString)")
            case .speechNotRecognized:
                print("Speech Not Recognized")
            case .availabilityChanged(let availability):
                print("Availability \(availability)")
            case .speechRecognitionStopped(let finalRecognizedString):
                self.speechButton.setTitle("Start speech Recognition", for: .normal)
                self.speechTextLabel.textColor = .red
                print("Speech Recognition Stopped with final string \(finalRecognizedString)")
        }
    }

}

