import QtQuick
import "../.."
Item {
    property var context
    property int frameCount: 0
    property var dummyTexture
    readonly property string authorText: "'yamp' by Flonk"
    readonly property bool interactive: false

    Image { id: tex; source: "../assets/yamp_sdf.png"; visible: false }
    ShaderEffectSource { id: texSrc; sourceItem: tex; hideSource: true }
    Image { id: noise; source: "../assets/random.png"; visible: false }
    ShaderEffectSource { id: noiseSrc; sourceItem: noise; hideSource: true }

    LockShaderPass {
        anchors.fill: parent
        context: parent.context; frameCount: parent.frameCount; dummyTexture: parent.dummyTexture
        shaderName: "yamp"
        iChannel0: texSrc
        iChannel1: noiseSrc
    }
}
