 # SpeechRecognitionLibrary

This repository represents the pluggable library to use iOS speech recognition service in any arbitrary iOS application. <br/>
Text below describes the feature of library and how to use it with example. Library also has a demo project if 
you're curious about how it works with any arbitrary client app.

**Step 1:**

Add required keys to `plist` file. In order to use speech recognition, you will need to add two keys to `plist` file.
One key is used for microphone access and other for taking user speech or words as an input into the app. You will need to add these keys at the top level of `plist` inside main `<dict>` tag

1. `<key>NSSpeechRecognitionUsageDescription</key>`<br/>
	 `<string>Speech recognition will be used to take input and search for keywords</string>`
  
2. `<key>NSMicrophoneUsageDescription</key>`<br/>
	 `<string>SpeechRecognitionDemo app wants to use microphone for demo purpose</string>`

**Step 2:**

Initializing `SpeechRecognitionUtility`

In order to use library, you will first have to initialize an object of type `SpeechRecognitionUtility`. 

Example:


```swift
var speechRecognizerUtility: SpeechRecognitionUtility?
speechRecognizerUtility = SpeechRecognitionUtility(speechRecognitionAuthorizedBlock: { [weak self] in
                // Perform speech recognition
            }, stateUpdateBlock: { (currentSpeechRecognitionState) in
                // Speech recognition state changed
            }, recordingState: .Continuous)
```

Initializer will take following parameters as input

1. `speechRecognitionAuthorizedBlock` - This will be called when user authorizes app to use device microphone and allows an access to speech recognizer utility. This way app can capture what user has said and use it for further processing

2. `stateUpdateBlock` - This will be called every time `SpeechRecognitionUtility` changes state. Possible states included are, but not limited to `speechRecognised(String)`, `speechNotRecognized`, `authorized`, `audioEngineStart`. Please refer to library for list of all possible states. Client app can take respective actions based on the current state of `SpeechRecognitionUtility` object

3. `recordingState` - There are two possible states of recording in the app. First mode is called `oneWordAtTime` which is on by default. In this mode, as soon as speech recognizer detects single word said by user, it stops listening for further input.

     Other mode is named `continuous`. In this case app will keep listening for user input unless client app explicitly makes call to `toggleSpeechRecognitionActivity` which toggles the live status whether app is currently listening for user input or not. 

      When `continuous` mode is on, it is client app's responsibility to turn off ongoing speech recognition activity by making call to `toggleSpeechRecognitionActivity`. (As per Apple docs, iOS will automatically stop recording after 60 seconds of interaction).

**Step 3:**

User can always check whether system is currently listening to user input by calling `isSpeechRecognitionOn` on 
`SpeechRecognitionUtility` object. When in continuous mode, user can stop speech recognition activity by calling
Utility method `toggleSpeechRecognitionActivity()` which will toggle the speech recognition state.

Please note that `toggleSpeechRecognitionActivity` throws an exception which necessitates it to wrap it with `try-catch` blocks as follows

```swift
do {
    try self.speechRecognizerUtility?.toggleSpeechRecognitionActivity()
} catch {
    print("Error")
}
```

List of possible throwable errors could be, but are not limited to `denied`, `notDetermined` and `restricted`.
Please refer to library for list of all possible errors that can be thrown from the function.

Also note the significance of `stateUpdateBlock` as a part of initializer requirement. Every time speech recognizer utility changes state, this block is a way to notify client about current status. User can then take suitable actions based on the ongoing state. For example, we can detect speech detect event with following state check
 
 ```swift
 speechRecognizerUtility = SpeechRecognitionUtility(speechRecognitionAuthorizedBlock: { [weak self] in
                // blah
            }, stateUpdateBlock: { (currentSpeechRecognitionState) in
                // Speech recognized state
                switch state {
                  case .speechRecognised(let recognizedString):                      
                      print("Recognized String \(recognizedString)")
                }
            }, recordingState: .Continuous)
 ```
 
Possible states could be, but are not limited to `speechRecognised(String)`, `speechNotRecognized`, `authorized`, `audioEngineStart`.


> Library also includes a sample project which demonstrates the usage of library with applicable error conditions
 and system state capture.
 
 **I hope this library will be useful to you while implementing speech recognition into the app. It has only one file
 Written in Swift 3.0 so adding it in the project should be as simple as just dragging and dropping the file which
 houses the code for speech recognition utility. Please let me know if you have further questions on usage or utility
 of this library.**
 
 **Few things to note:**
 
 * Speech recognition utility is only available in iOS 10. It makes this library unusable for apps targetting iOS versions lower than 10.0
 * As current situation necessitates, this library is written in Swift 3.0. If you are planning to integrate in your project, make sure that project uses Swift 3.0 syntax or change the library to use Swift 2.x syntax.
 


> Ref: [AppCoda tutorial](http://www.appcoda.com/siri-speech-framework/)
