import QtQuick
import "../.."
Item {
    property var context
    property int frameCount: 0
    property var dummyTexture
    readonly property string authorText: "'2D Clouds' by drift"
    readonly property bool interactive: true

    Image { id: noise; source: "../assets/fractalnoise.png"; visible: false }

    LockShaderPass {
        anchors.fill: parent
        context: parent.context; frameCount: parent.frameCount; dummyTexture: parent.dummyTexture
        shaderName: "2d_clouds"
        iChannel0: noise
    }
}
