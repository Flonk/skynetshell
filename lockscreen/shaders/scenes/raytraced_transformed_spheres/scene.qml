import QtQuick
import "../.."
Item {
    property var context
    property int frameCount: 0
    property var dummyTexture
    readonly property string authorText: "'Raytraced Transformed Spheres' by Shane"
    readonly property bool interactive: false

    Image { id: tex; source: "../assets/cityscape.jpg"; visible: false }

    LockShaderPass {
        anchors.fill: parent
        context: parent.context; frameCount: parent.frameCount; dummyTexture: parent.dummyTexture
        shaderName: "raytraced_transformed_spheres"
        iChannel0: tex
    }
}
