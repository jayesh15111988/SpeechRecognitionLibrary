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
    private let speechrecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    override func viewDidLoad() {
        super.viewDidLoad()

        speechrecognizer?.delegate = self

        SFSpeechRecognizer.requestAuthorization { (status) in
            switch status {
            case .authorized:
                print("Authorized")
            case .denied:
                print("Denied")
            case .notDetermined:
                print("Failed with an unknown error")
            case .restricted:
                print("Restricted the usage of ")
            }
        }

        OperationQueue.main.addOperation {
            self.speechTextLabel.text = "Mic is enabled now"
        }
    }

    @IBAction func saySomethingButtonPressed(_ sender: Any) {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
        } else {
            self.runSpeechRecognition()

        }
    }

    func runSpeechRecognition() {
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("Audio Session setup was failed with an error")
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        guard let inputNode = audioEngine.inputNode else {
            return
        }

        guard let recognitionRequest = recognitionRequest else {
            return
        }

        recognitionRequest.shouldReportPartialResults = true

        recognitionTask = speechrecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in

            var isFinal = false

            if result != nil {
                self.speechTextLabel.text = result?.bestTranscription.formattedString
                isFinal = true
            }

            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask?.cancel()
                self.recognitionTask = nil
            }
        })

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, time) in
            self.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()
        } catch {
            print("Failed to start the audio engine")
        }
    }

    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        print("Speech recognition availability changed. Now is availabke \(available)")
    }


}

