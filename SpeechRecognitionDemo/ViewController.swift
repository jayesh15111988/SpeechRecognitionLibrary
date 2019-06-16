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
        
    }

    func requestTranslationsFromServer() {
        // Trigger the request to get translations as soon as user has done providing full speech input. Don't trigger until query length is at least one.
    }

    func resetState() {

    }

    func toggleSpeechButtonAccessState(enabled: Bool) {

    }

    private func stateChangedWith(state: SpeechRecognitionOperationState) {

    }
}
