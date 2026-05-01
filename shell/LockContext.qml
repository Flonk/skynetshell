import QtQuick
import Quickshell
import Quickshell.Services.Pam

Scope {
    id: root
    signal unlocked()

    property string currentText: ""
    property bool unlockInProgress: false
    property bool showFailure: false

    // Envelope timing state (seconds since lock start)
    property real elapsedTime: 0
    property real lastKeyTime: -1000.0
    property real lastFailedUnlockTime: -1000.0
    property real authStartedTime: -1000.0

    // Envelope base values for seamless mid-animation keypresses
    property real keypulseBase: 0.0
    property real keyBase: 0.0

    onCurrentTextChanged: showFailure = false

    function recordKeypress() {
        // Sample current envelope values as bases for the next animation
        let age = elapsedTime - lastKeyTime;
        if (age < 0.11) {
            let ramp = Math.min(age / 0.03, 1.0);
            let p = keypulseBase * (1.0 - ramp) + ramp;
            let decay = Math.max((age - 0.03) / 0.08, 0.0);
            keypulseBase = p * (1.0 - decay * decay);
        } else {
            keypulseBase = 0.0;
        }
        if (age < 3.06) {
            let ramp = Math.min(age / 0.06, 1.0);
            let p = keyBase * (1.0 - ramp) + ramp;
            let decay = Math.max((age - 1.06) / 2.0, 0.0);
            keyBase = Math.max(0.0, p * (1.0 - decay));
        } else {
            keyBase = 0.0;
        }
        lastKeyTime = elapsedTime;
    }

    function tryUnlock() {
        if (currentText === "") return;
        unlockInProgress = true;
        authStartedTime = elapsedTime;
        pam.start();
    }

    PamContext {
        id: pam
        configDirectory: "pam"
        config: "password.conf"

        onPamMessage: {
            if (this.responseRequired) {
                this.respond(root.currentText);
            }
        }

        onCompleted: result => {
            if (result === PamResult.Success) {
                Qt.callLater(() => root.unlocked());
            } else {
                root.lastFailedUnlockTime = root.elapsedTime;
                root.currentText = "";
                root.showFailure = true;
            }
            root.authStartedTime = -1000.0;
            root.unlockInProgress = false;
        }
    }
}
