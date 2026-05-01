import QtQuick

ShaderEffect {
    id: pass

    property var context
    property int frameCount: 0
    property var dummyTexture
    property bool interactive: false
    property string shaderName: ""
    property string authorText: ""

    // Paths resolve relative to the instantiating file (shell/shaders/scenes/),
    // not this component file, so we go up one level to shell/shaders/
    vertexShader: "../default.vert.qsb"
    fragmentShader: shaderName ? "../" + shaderName + ".frag.qsb" : ""

    property vector3d iResolution: Qt.vector3d(width, height, 1.0)
    property real iTime: context ? context.elapsedTime : 0
    property int iFrame: frameCount
    property vector4d iMouse: Qt.vector4d(0, 0, 0, 0)
    property vector4d iClock: {
        let d = new Date();
        let h = d.getHours();
        let m = d.getMinutes();
        return Qt.vector4d(Math.floor(h / 10), h % 10,
                           Math.floor(m / 10), m % 10);
    }

    property var iChannel0: dummyTexture
    property var iChannel1: dummyTexture
    property var iChannel2: dummyTexture
    property var iChannel3: dummyTexture

    property int u_indicator_type: 0
    property vector3d u_indicator_color: Qt.vector3d(1, 1, 1)
    property real u_last_key_time: context ? context.lastKeyTime : 0
    property real u_last_failed_unlock_time: context ? context.lastFailedUnlockTime : 0
    property real u_auth_started_time: context ? context.authStartedTime : 0
    property vector2d u_key_bases: context ? Qt.vector2d(context.keypulseBase, context.keyBase) : Qt.vector2d(0, 0)
}
