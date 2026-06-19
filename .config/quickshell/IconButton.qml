import QtQuick
Rectangle {
    id: button

    signal clicked()
    property string label: "?"
    property bool glyph: false   // true = render label as a Symbols Nerd Font icon

    width: 40
    height: 32
    radius: 8
    gradient: Gradient {
        GradientStop { position: 0.0; color: hover.hovered ? "#3a3c4290" : "#1a1b1f50" }
        GradientStop { position: 1.0; color: hover.hovered ? "#2a2c3290" : "#0d0e1048" }
    }
    border.color: hover.hovered ? "#c4c8d2" : "#4a4c52aa"
    border.width: 2

    Behavior on border.color { ColorAnimation { duration: 120 } }

    // top gloss — soft glassy reflection (soft fill, no hard 1px line = no fringe)
    Rectangle {
        anchors { left: parent.left; right: parent.right; top: parent.top }
        anchors.margins: 2
        height: parent.height * 0.5
        radius: parent.radius
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#28ffffff" }
            GradientStop { position: 0.6; color: "#08ffffff" }
            GradientStop { position: 1.0; color: "#00ffffff" }
        }
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: button.clicked()
    }

    Text {
        anchors.centerIn: parent
        text: button.label
        color: hover.hovered ? "#eef0f2" : "#c0c2c8"
        font.family: button.glyph ? "Symbols Nerd Font Mono" : "Noto Sans Mono"
        font.pixelSize: button.glyph ? 15 : (button.label.length > 2 ? 10 : 13)
        font.bold: !button.glyph
    }
}
