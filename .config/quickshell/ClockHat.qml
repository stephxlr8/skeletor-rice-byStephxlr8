import QtQuick
import Quickshell

// Analog clock framed by the pink cat-hat PNG. The generated geometry and baked
// glass image both come from tools/generate-clock-hole.py, so the face cannot drift.
Item {
    id: root
    property real artW: 320
    ClockHatGeometry { id: hole }

    readonly property real scale: artW / hole.sourceWidth
    implicitWidth: artW
    implicitHeight: hole.sourceHeight * scale

    readonly property real cx: hole.holeCx * scale
    readonly property real cy: hole.holeCy * scale
    readonly property real faceR: hole.faceRadius * scale

    SystemClock { id: sysclk; precision: SystemClock.Seconds }
    readonly property var now: sysclk.date
    readonly property int hrs: now.getHours()
    readonly property int mins: now.getMinutes()
    readonly property int secs: now.getSeconds()

    // hat with dark hole already baked in
    Image {
        anchors.fill: parent
        source: Qt.resolvedUrl("assets/cat-hat-clock.png?v=white-r333")
        fillMode: Image.PreserveAspectFit
        cache: false
        smooth: true
        mipmap: true
    }

    // ---- clock graphics on top of the dark hole ----
    Item {
        id: face
        width: root.faceR * 2
        height: root.faceR * 2
        x: root.cx - root.faceR
        y: root.cy - root.faceR

        // violet rim
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: "transparent"
            border.color: "#8a5cff"
            border.width: 2
        }

        // hour ticks
        Repeater {
            model: 12
            delegate: Item {
                width: face.width
                height: face.height
                rotation: index * 30
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: face.height * 0.07
                    width: index % 3 === 0 ? 4 : 2
                    height: index % 3 === 0 ? 14 : 8
                    radius: 1.5
                    color: index % 3 === 0 ? "#3a164f" : "#6f4f83"
                }
            }
        }

        // hour hand
        Rectangle {
            x: face.width / 2 - width / 2
            y: face.height / 2 - height
            width: 6
            height: face.height * 0.27
            radius: 3
            color: "#241033"
            transformOrigin: Item.Bottom
            rotation: (root.hrs % 12) * 30 + root.mins * 0.5
        }
        // minute hand
        Rectangle {
            x: face.width / 2 - width / 2
            y: face.height / 2 - height
            width: 4
            height: face.height * 0.38
            radius: 2
            color: "#3b1853"
            transformOrigin: Item.Bottom
            rotation: root.mins * 6 + root.secs * 0.1
        }
        // second hand
        Rectangle {
            x: face.width / 2 - width / 2
            y: face.height / 2 - height
            width: 2
            height: face.height * 0.42
            color: "#d0189a"
            transformOrigin: Item.Bottom
            rotation: root.secs * 6
        }
        // center cap
        Rectangle {
            anchors.centerIn: parent
            width: 12; height: 12; radius: 6
            color: "#d0189a"
            border.color: "#ffffff"; border.width: 2
        }
    }
}
