import QtQuick
import Quickshell

Item {
    id: root
    required property var context

    // Set to a shader name (e.g. "002_blue") or "random" to pick one each lock
    property string shader: "random"

    readonly property var _allShaders: [
        "002_blue", "20221105_inercia_intended_one", "2d_clouds", "3d_fire_340",
        "8x8_pixel_character", "abacate_with_suggar", "apollonian_with_a_twist_ii",
        "ashanoha", "auroras", "breathing_rings", "cat_and_boy_12", "chilly_waves_2",
        "colorful_underwater_bubbles_ii", "crazy_spiral_thing", "dark_transit",
        "disco_sun_vortex", "discoteq_2", "fragment_plane", "gliding",
        "global_wind_circulation", "glsl_2d_tutorials", "hexagonal_grid_traversal_3d",
        "hexagonal_pattern_logic", "inside_the_torus", "isovalues_3",
        "mandelbrot_distance", "mobius_spiral", "monster", "racing_to_the_future",
        "raymarched_hexagonal_truchet", "raytraced_transformed_spheres",
        "renkli_toplar", "segmented_spiral_whirlpool", "shadertober_06b_husky",
        "sincos_3d", "starship_reentry", "superquadratic_reflections",
        "synthwave_canyon", "the_universe_within", "ui_noise_halo", "ui_test_5",
        "voxel_star_field", "wavey_spheres", "weird_truchet", "windows_95",
    ]

    property string _activeShader: ""

    function _pickShader() {
        _activeShader = (shader !== "random")
            ? shader
            : _allShaders[Math.floor(Math.random() * _allShaders.length)];
    }

    // Shared frame counter
    property int _iFrame: 0
    Timer {
        interval: 16
        running: true
        repeat: true
        onTriggered: {
            root._iFrame += 1;
            root.context.elapsedTime += 0.016;
        }
    }

    // 1x1 dummy texture for unused iChannel slots
    ShaderEffectSource {
        id: dummyTexture
        sourceItem: Rectangle { width: 1; height: 1; color: "#111" }
        hideSource: true
    }

    property string authorText: shaderLoader.item?.authorText ?? ""

    // Black base so shaders with partial alpha don't bleed through
    Rectangle {
        anchors.fill: parent
        color: "black"
    }

    onShaderChanged: _reloadShader()
    Component.onCompleted: _reloadShader()

    function _reloadShader() {
        _pickShader();
        shaderLoader.setSource("shaders/scenes/" + _activeShader + ".qml", {
            "context": Qt.binding(() => root.context),
            "frameCount": Qt.binding(() => root._iFrame),
            "dummyTexture": dummyTexture,
        });
    }

    // ---- Shader background (loaded per-shader) ----
    Loader {
        id: shaderLoader
        anchors.fill: parent
    }

    // ---- Keypress dot indicator (for shaders without built-in feedback) ----
    Rectangle {
        id: keypressDot
        visible: shaderLoader.item && !shaderLoader.item.interactive
        anchors.centerIn: parent
        width: root.height * 0.08
        height: width
        radius: width / 2
        color: "white"
        opacity: 0

        SequentialAnimation {
            id: dotFlash
            NumberAnimation { target: keypressDot; property: "opacity"; to: 0.9; duration: 30 }
            NumberAnimation { target: keypressDot; property: "opacity"; to: 0; duration: 80; easing.type: Easing.OutQuad }
        }

        Connections {
            target: root.context
            function onCurrentTextChanged() {
                if (keypressDot.visible && root.context.currentText.length > 0)
                    dotFlash.restart();
            }
        }
    }

    // ---- Bottom bar (reuses the real bar) ----
    BarContent {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        lockscreen: true
        interactive: false
        authorText: root.authorText
    }

    // ---- Hidden password input ----
    TextInput {
        id: passwordInput
        focus: true
        echoMode: TextInput.Password
        visible: false

        text: root.context.currentText
        onTextChanged: {
            if (text !== root.context.currentText) {
                root.context.currentText = text;
            }
        }

        Keys.onPressed: event => {
            root.context.recordKeypress();
        }

        Keys.onReturnPressed: {
            root.context.tryUnlock();
        }
        Keys.onEnterPressed: {
            root.context.tryUnlock();
        }
    }

    // Keep password input focused
    MouseArea {
        anchors.fill: parent
        onClicked: passwordInput.forceActiveFocus()
    }

    // ---- Failure flash overlay ----
    Rectangle {
        anchors.fill: parent
        color: "#e35532"
        opacity: root.context.showFailure ? 0.35 : 0.0
        Behavior on opacity {
            NumberAnimation { duration: 200 }
        }
    }
}
