    pragma Singleton
    import QtQuick

    QtObject {
        // Bar Settings
        readonly property int barSize: 50

        // Colors
        readonly property color app100: "#0b0e14"
    readonly property color app150: "#131721"
    readonly property color app200: "#202229"
    readonly property color app600: "#e6e1cf"
    readonly property color app700: "#3e4b59"
    readonly property color app800: "#ece8db"
    readonly property color app900: "#f2f0e7"
    readonly property color error400: "#f07178"
    readonly property color error600: "#ff8f40"
    readonly property color success600: "#aad94c"
    readonly property color wm800: "#ff9624"

        // Font Sizes
        readonly property int fontSizeBig: 10
    readonly property int fontSizeBigger: 12
    readonly property int fontSizeHuge: 14
    readonly property int fontSizeHumongous: 20
    readonly property int fontSizeNormal: 9
    readonly property int fontSizeSmall: 8
    readonly property int fontSizeTiny: 7

        // Font Families
        readonly property string fontFamilyMono: "DejaVuSansM Nerd Font"
    readonly property string fontFamilyMonoNf: "DejaVuSansM Nerd Font"
    readonly property string fontFamilyUi: "DejaVuSansM Nerd Font"
    readonly property string fontFamilyUiNf: "DejaVuSansM Nerd Font"

// Asset URLs
readonly property url logoAndampAmpBlue: Qt.resolvedUrl("assets/logos/andamp-amp-blue.png")
        readonly property url logoTileGrey: Qt.resolvedUrl("assets/logos/tile-grey.png")

    }

