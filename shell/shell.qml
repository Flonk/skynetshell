// shell.qml
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

ShellRoot {
    Bar {}
    Shortcuts {}

    LockContext {
        id: lockContext

        onUnlocked: {
            Qt.callLater(() => { lock.locked = false; });
        }
    }

    WlSessionLock {
        id: lock
        locked: false

        WlSessionLockSurface {
            LockSurface {
                anchors.fill: parent
                context: lockContext
            }
        }
    }

    Connections {
        target: LockWidget
        function onLockRequested() { lockScreen(); }
    }

    IpcHandler {
        target: "lock"
        function lock(): void { lockScreen(); }
    }

    function lockScreen() {
        lockContext.elapsedTime = 0;
        lockContext.lastKeyTime = -1000.0;
        lockContext.lastFailedUnlockTime = -1000.0;
        lockContext.authStartedTime = -1000.0;
        lockContext.keypulseBase = 0.0;
        lockContext.keyBase = 0.0;
        lockContext.currentText = "";
        lockContext.showFailure = false;
        lock.locked = true;
    }
}
