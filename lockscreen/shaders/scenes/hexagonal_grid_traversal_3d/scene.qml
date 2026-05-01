import QtQuick
import "../.."
Item {
    property var context
    property int frameCount: 0
    property var dummyTexture
    readonly property string authorText: "'Hexagonal Grid Traversal - 3D' by iq"
    readonly property bool interactive: true

    Image { id: tex0; source: "../assets/hexagonal_grid_traversal_3d_iChannel0.jpg"; visible: false }
    Image { id: tex1; source: "../assets/random.png"; visible: false }

    LockShaderPass {
        anchors.fill: parent
        context: parent.context; frameCount: parent.frameCount; dummyTexture: parent.dummyTexture
        shaderName: "hexagonal_grid_traversal_3d"
        iChannel0: tex0
        iChannel1: tex1
    }
}
