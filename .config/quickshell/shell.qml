import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Qt.labs.folderlistmodel

ShellRoot {
    id: root

    // Skeletor gothic-glass palette — neutral dark gray (no blue tint)
    property color text: "#d3d4d8"
    property color textDim: "#8a8c92"
    property color accent: "#6a6c72"
    property color cyan: "#bdbfc4"
    property color hairline: "#4a4c52aa"   // dark gray — only LIGHT thin edges fringe green, dark ones are safe

    // glyph = Symbols Nerd Font fallback; icon = glossy Vista (frutiger aero) PNG
    property var folders: [
        { "name": "Home", "glyph": "\uf015", "icon": "assets/icons/home.png", "path": "/home/stephxlr8" },
        { "name": "Downloads", "glyph": "\uf019", "icon": "assets/icons/downloads.png", "path": "/home/stephxlr8/Downloads" },
        { "name": "Documents", "glyph": "\uf15b", "icon": "assets/icons/documents.png", "path": "/home/stephxlr8/Documents" },
        { "name": "Pictures", "glyph": "\uf03e", "icon": "assets/icons/pictures.png", "path": "/home/stephxlr8/Pictures" },
        { "name": "Github", "glyph": "\uf09b", "icon": "assets/icons/github.png", "path": "/home/stephxlr8/Documents/Github" },
        { "name": "Projects", "glyph": "\uf121", "icon": "assets/icons/projects.png", "path": "/home/stephxlr8/Projects" }
    ]

    Process { id: launcher }
    SystemClock { id: clock; precision: SystemClock.Seconds }

    // Live audio levels from cava (40 bars, 0..100)
    property var levels: []

    Process {
        id: cavaProc
        command: ["cava", "-p", "/home/stephxlr8/.config/cava/quickshell.conf"]
        running: true
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function(line) {
                var parts = line.split(";");
                var out = [];
                for (var i = 0; i < parts.length; i++) {
                    if (parts[i].length === 0) continue;
                    out.push(parseInt(parts[i]) || 0);
                }
                if (out.length > 0) root.levels = out;
            }
        }
    }

    // Player state (title @@ status @@ position_us @@ length_us), polled every 1s
    property string trackTitle: ""
    property string playStatus: ""
    property real trackPos: 0
    property real trackLen: 0
    Process {
        id: playerProc
        command: ["bash", "-c", "while true; do playerctl -p playerctld,%any metadata --format '{{title}}@@{{status}}@@{{position}}@@{{mpris:length}}' 2>/dev/null || echo '@@@@@@'; sleep 1; done"]
        running: true
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function(line) {
                var p = line.split("@@");
                root.trackTitle = p[0] || "";
                root.playStatus = p[1] || "";
                root.trackPos = parseFloat(p[2]) || 0;
                root.trackLen = parseFloat(p[3]) || 0;
            }
        }
    }
    function fmtTime(us) {
        if (!us || us <= 0) return "0:00";
        var s = Math.floor(us / 1000000);
        var m = Math.floor(s / 60);
        s = s % 60;
        return m + ":" + (s < 10 ? "0" : "") + s;
    }

    // Waybar owns the bottom bar. Quickshell = floating gothic widgets, ws 1 only.

    // ---------- Folders ----------
    PanelWindow {
        id: folderPanel
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "skeletor-widgets"
        visible: Hyprland.focusedWorkspace?.id === 1
        anchors { right: true; bottom: true }
        margins { right: 30; bottom: 60 }
        implicitWidth: 360
        implicitHeight: 360
        exclusiveZone: 0
        color: "transparent"

        GlassPanel {
            anchors.fill: parent

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 11

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Folders"
                        color: root.text
                        font.family: "Noto Sans Mono"
                        font.pixelSize: 14
                        font.bold: true
                        font.letterSpacing: 1.5
                        Layout.fillWidth: true
                    }
                    Text {
                        text: "\uf07b"
                        color: root.cyan
                        font.family: "Symbols Nerd Font Mono"
                        font.pixelSize: 14
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "#00505258" }
                        GradientStop { position: 0.5; color: "#50525299" }
                        GradientStop { position: 1.0; color: "#00505258" }
                    }
                }

                GridLayout {
                    columns: 2
                    rowSpacing: 10
                    columnSpacing: 10
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Repeater {
                        model: root.folders
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 60
                            radius: 9
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: hover.hovered ? "#34363c90" : "#1c1d2148" }
                                GradientStop { position: 1.0; color: hover.hovered ? "#1e1f2390" : "#0c0d0f50" }
                            }
                            border.color: hover.hovered ? "#c4c8d2" : root.hairline
                            border.width: 2

                            Behavior on border.color { ColorAnimation { duration: 130 } }

                            // top gloss — inset, soft fill (no edge line)
                            Rectangle {
                                anchors { left: parent.left; right: parent.right; top: parent.top }
                                anchors.margins: 3
                                height: parent.height * 0.5
                                radius: parent.radius
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: "#1cffffff" }
                                    GradientStop { position: 1.0; color: "#00ffffff" }
                                }
                            }

                            MouseArea {
                                id: hover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: launcher.exec(["xdg-open", modelData.path])
                            }

                            Column {
                                anchors.centerIn: parent
                                spacing: 5
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modelData.glyph
                                    color: hover.hovered ? "#eef0f2" : root.text
                                    font.family: "Symbols Nerd Font Mono"
                                    font.pixelSize: 26
                                }
                                Text {
                                    width: 116
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                    text: modelData.name
                                    color: hover.hovered ? root.text : root.textDim
                                    font.family: "Noto Sans Mono"
                                    font.pixelSize: 11
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ---------- Clock (cat-hat) + calendar, top-right ----------
    PanelWindow {
        id: clockPanel
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "skeletor-widgets"
        visible: Hyprland.focusedWorkspace?.id === 1
        anchors { right: true; top: true }
        margins { right: 30; top: 90 }
        implicitWidth: 248
        implicitHeight: 432
        exclusiveZone: 0
        color: "transparent"

        // calendar cells for current month, recomputed when the day changes
        property var calCells: {
            var d = clock.date;
            var y = d.getFullYear(), m = d.getMonth();
            var first = new Date(y, m, 1).getDay();
            var dim = new Date(y, m + 1, 0).getDate();
            var arr = [];
            for (var i = 0; i < first; i++) arr.push(0);
            for (var n = 1; n <= dim; n++) arr.push(n);
            return arr;
        }
        property int today: clock.date.getDate()
        readonly property var monthNames: ["January","February","March","April","May","June","July","August","September","October","November","December"]

        GlassPanel {
            anchors.fill: parent

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 5

                ClockHat {
                    artW: 185
                    Layout.alignment: Qt.AlignHCenter
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "#00505258" }
                        GradientStop { position: 0.5; color: "#50525299" }
                        GradientStop { position: 1.0; color: "#00505258" }
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: clockPanel.monthNames[clock.date.getMonth()] + " " + clock.date.getFullYear()
                    color: root.text
                    font.family: "Noto Sans Mono"
                    font.pixelSize: 13
                    font.bold: true
                    font.letterSpacing: 0.8
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 7
                    rowSpacing: 1
                    columnSpacing: 2

                    Repeater {
                        model: ["S","M","T","W","T","F","S"]
                        delegate: Text {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: modelData
                            color: root.cyan
                            font.family: "Noto Sans Mono"
                            font.pixelSize: 11
                            font.bold: true
                        }
                    }

                    Repeater {
                        model: clockPanel.calCells
                        delegate: Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 20
                            property bool isToday: modelData === clockPanel.today
                            Rectangle {
                                anchors.centerIn: parent
                                width: 26; height: 20
                                radius: 4
                                visible: parent.isToday
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: "#6a6c72cc" }
                                    GradientStop { position: 1.0; color: "#3a3c42cc" }
                                }
                                border.color: "#9aa0b0"
                                border.width: 1
                            }
                            Text {
                                anchors.centerIn: parent
                                visible: modelData !== 0
                                text: modelData
                                color: parent.isToday ? "#eef0f2" : root.textDim
                                font.family: "Noto Sans Mono"
                                font.pixelSize: 12
                                font.bold: parent.isToday
                            }
                        }
                    }
                }
            }
        }
    }

    // ---------- Media player (center-bottom, like reference) ----------
    PanelWindow {
        id: musicPanel
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "skeletor-widgets"
        visible: Hyprland.focusedWorkspace?.id === 1
        anchors { bottom: true }
        margins { bottom: 78 }
        implicitWidth: 660
        implicitHeight: 198
        exclusiveZone: 0
        color: "transparent"

        GlassPanel {
            anchors.fill: parent

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 8

                // header: track title + control glyphs
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Text {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        text: root.trackTitle && root.trackTitle.length ? root.trackTitle : "No media"
                        color: root.text
                        font.family: "Noto Sans Mono"
                        font.pixelSize: 12
                        font.bold: true
                        font.letterSpacing: 1.0
                    }
                    Text { text: ""; color: root.cyan; font.family: "Symbols Nerd Font Mono"; font.pixelSize: 13 }
                    Text { text: ""; color: root.cyan; font.family: "Symbols Nerd Font Mono"; font.pixelSize: 13 }
                }

                // emblem + spectrum
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 10

                    Rectangle {
                        Layout.preferredWidth: 66
                        Layout.fillHeight: true
                        radius: 7
                        color: "#06070b88"
                        border.color: root.hairline
                        border.width: 1
                        Image {
                            anchors.centerIn: parent
                            source: Qt.resolvedUrl("assets/icons/media-emblem.png")
                            sourceSize.width: 52
                            sourceSize.height: 52
                            width: 48
                            height: 48
                            smooth: true
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 7
                        color: "#06070b88"
                        border.color: root.hairline
                        border.width: 1
                        clip: true

                        Item {
                            id: specArea
                            anchors.fill: parent
                            anchors.margins: 8

                            Row {
                                anchors.fill: parent
                                spacing: 2
                                Repeater {
                                    model: 44
                                    delegate: Item {
                                        property real lvl: index < root.levels.length ? root.levels[index] : 0
                                        width: (specArea.width - 43 * 2) / 44
                                        height: specArea.height
                                        Rectangle {
                                            anchors.bottom: parent.bottom
                                            width: parent.width
                                            height: Math.max(2, lvl / 100 * (parent.height - 2))
                                            radius: 1
                                            gradient: Gradient {
                                                GradientStop { position: 0.0; color: "#7d6cb0" }
                                                GradientStop { position: 1.0; color: "#3a3550" }
                                            }
                                            opacity: 0.5 + (lvl / 100) * 0.5
                                            Behavior on height { NumberAnimation { duration: 60 } }
                                        }
                                    }
                                }
                            }

                            Canvas {
                                id: spec
                                anchors.fill: parent
                                onPaint: {
                                    var ctx = getContext("2d");
                                    ctx.reset();
                                    var n = 44, w = width, h = height;
                                    function lv(i) { return i < root.levels.length ? root.levels[i] : 0; }
                                    ctx.beginPath();
                                    ctx.moveTo(0, h);
                                    for (var i = 0; i < n; i++) {
                                        var x = (i + 0.5) / n * w;
                                        var y = h - (lv(i) / 100) * (h - 2) - 1;
                                        ctx.lineTo(x, y);
                                    }
                                    ctx.lineTo(w, h);
                                    ctx.closePath();
                                    var g = ctx.createLinearGradient(0, 0, 0, h);
                                    g.addColorStop(0, "rgba(155,134,216,0.33)");
                                    g.addColorStop(1, "rgba(155,134,216,0.0)");
                                    ctx.fillStyle = g;
                                    ctx.fill();
                                    ctx.beginPath();
                                    for (var j = 0; j < n; j++) {
                                        var xx = (j + 0.5) / n * w;
                                        var yy = h - (lv(j) / 100) * (h - 2) - 1;
                                        if (j === 0) ctx.moveTo(xx, yy); else ctx.lineTo(xx, yy);
                                    }
                                    ctx.strokeStyle = "#c4b3ff";
                                    ctx.lineWidth = 1.4;
                                    ctx.stroke();
                                }
                                Connections {
                                    target: root
                                    function onLevelsChanged() { spec.requestPaint(); }
                                }
                            }
                        }
                    }
                }

                // progress bar
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Text { text: root.fmtTime(root.trackPos); color: root.textDim; font.family: "Noto Sans Mono"; font.pixelSize: 9 }
                    Rectangle {
                        id: seek
                        Layout.fillWidth: true
                        implicitHeight: 4
                        radius: 2
                        color: "#1a1b2099"
                        property real ratio: root.trackLen > 0 ? Math.min(1, root.trackPos / root.trackLen) : 0
                        Rectangle {
                            height: parent.height
                            radius: 2
                            width: parent.width * seek.ratio
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: "#6a5fb0" }
                                GradientStop { position: 1.0; color: "#c4b3ff" }
                            }
                        }
                        Rectangle {
                            width: 8; height: 8; radius: 4
                            color: "#e6e0ff"
                            y: (parent.height - height) / 2
                            x: parent.width * seek.ratio - width / 2
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: function(m) {
                                if (root.trackLen > 0) {
                                    var sec = (m.x / width) * (root.trackLen / 1000000);
                                    launcher.exec(["playerctl", "-p", "playerctld,%any", "position", sec.toFixed(1)]);
                                }
                            }
                        }
                    }
                    Text { text: root.fmtTime(root.trackLen); color: root.textDim; font.family: "Noto Sans Mono"; font.pixelSize: 9 }
                }

                // transport pill: prev, rewind, BIG play, fwd, next
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: pillRow.implicitWidth + 36
                    Layout.preferredHeight: 46
                    radius: 23
                    color: "#08090e88"
                    border.color: root.hairline
                    border.width: 1

                    RowLayout {
                        id: pillRow
                        anchors.centerIn: parent
                        spacing: 14

                        IconButton { label: ""; glyph: true; implicitWidth: 30; implicitHeight: 30; radius: 15; onClicked: launcher.exec(["playerctl", "-p", "playerctld,%any", "previous"]) }
                        IconButton { label: ""; glyph: true; implicitWidth: 30; implicitHeight: 30; radius: 15; onClicked: launcher.exec(["playerctl", "-p", "playerctld,%any", "position", "5-"]) }

                        Rectangle {
                            implicitWidth: 42; implicitHeight: 42; radius: 21
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: playHover.hovered ? "#3a3550" : "#23202f" }
                                GradientStop { position: 1.0; color: playHover.hovered ? "#23202f" : "#121019" }
                            }
                            border.color: "#9b86d8"
                            border.width: 2
                            Text {
                                anchors.centerIn: parent
                                text: root.playStatus === "Playing" ? "" : ""
                                color: "#e6e0ff"
                                font.family: "Symbols Nerd Font Mono"
                                font.pixelSize: 17
                            }
                            MouseArea {
                                id: playHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: launcher.exec(["playerctl", "-p", "playerctld,%any", "play-pause"])
                            }
                        }

                        IconButton { label: ""; glyph: true; implicitWidth: 30; implicitHeight: 30; radius: 15; onClicked: launcher.exec(["playerctl", "-p", "playerctld,%any", "position", "5+"]) }
                        IconButton { label: ""; glyph: true; implicitWidth: 30; implicitHeight: 30; radius: 15; onClicked: launcher.exec(["playerctl", "-p", "playerctld,%any", "next"]) }
                    }
                }
            }
        }
    }

    // ---------- EQ / spectrum (top-left, like reference) ----------
    PanelWindow {
        id: eqPanel
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "skeletor-widgets"
        visible: Hyprland.focusedWorkspace?.id === 1
        anchors { left: true; top: true }
        margins { left: 30; top: 90 }
        implicitWidth: 240
        implicitHeight: 150
        exclusiveZone: 0
        color: "transparent"

        GlassPanel {
            anchors.fill: parent

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 9

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Spectrum"
                        color: root.text
                        font.family: "Noto Sans Mono"
                        font.pixelSize: 13
                        font.bold: true
                        font.letterSpacing: 1.5
                        Layout.fillWidth: true
                    }
                    Text {
                        text: "\uf080"
                        color: root.cyan
                        font.family: "Symbols Nerd Font Mono"
                        font.pixelSize: 13
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 7
                    color: "#070a1399"
                    border.color: root.hairline
                    border.width: 1
                    clip: true

                    Row {
                        id: eqRow
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 3
                        Repeater {
                            model: 22
                            delegate: Item {
                                // sample every other cava bar (40 -> 22ish)
                                property real lvl: {
                                    var i = Math.floor(index * root.levels.length / 22);
                                    return i < root.levels.length ? root.levels[i] : 0;
                                }
                                width: (eqRow.width - 21 * 3) / 22
                                height: eqRow.height
                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    width: parent.width
                                    height: Math.max(2, lvl / 100 * (parent.height - 2))
                                    radius: 1.5
                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: "#b4b6bc" }
                                        GradientStop { position: 1.0; color: "#45474d" }
                                    }
                                    opacity: 0.55 + (lvl / 100) * 0.45
                                    Behavior on height { NumberAnimation { duration: 60 } }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ---------- Shortcuts (left, below EQ) ----------
    PanelWindow {
        id: shortcutPanel
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "skeletor-widgets"
        visible: Hyprland.focusedWorkspace?.id === 1
        anchors { left: true; top: true }
        margins { left: 30; top: 256 }
        implicitWidth: 240
        implicitHeight: 132
        exclusiveZone: 0
        color: "transparent"

        // mark = Symbols Nerd Font glyph (\uXXXX)
        property var shortcuts: [
            { "mark": "", "cmd": ["kitty"] },
            { "mark": "", "cmd": ["firefox"] },
            { "mark": "", "cmd": ["dolphin"] },
            { "mark": "", "cmd": ["kitty", "-e", "htop"] }
        ]

        GlassPanel {
            anchors.fill: parent

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 9

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Shortcuts"
                        color: root.text
                        font.family: "Noto Sans Mono"
                        font.pixelSize: 13
                        font.bold: true
                        font.letterSpacing: 1.5
                        Layout.fillWidth: true
                    }
                    Text {
                        text: "\uf654"
                        color: root.cyan
                        font.family: "Symbols Nerd Font Mono"
                        font.pixelSize: 13
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    columns: 4
                    columnSpacing: 8
                    Repeater {
                        model: shortcutPanel.shortcuts
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 8
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: sc.hovered ? "#34363cb0" : "#161d3399" }
                                GradientStop { position: 1.0; color: sc.hovered ? "#222428c0" : "#0a0e1aaa" }
                            }
                            border.color: sc.hovered ? "#c4c8d2" : "#4a4c52aa"
                            border.width: 2
                            Behavior on border.color { ColorAnimation { duration: 120 } }

                            Rectangle {
                                anchors { left: parent.left; right: parent.right; top: parent.top }
                                anchors.margins: 3
                                height: parent.height * 0.5
                                radius: parent.radius
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: "#1cffffff" }
                                    GradientStop { position: 1.0; color: "#00ffffff" }
                                }
                            }

                            MouseArea {
                                id: sc
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: launcher.exec(modelData.cmd)
                            }

                            Text {
                                anchors.centerIn: parent
                                text: modelData.mark
                                color: sc.hovered ? "#eef0f2" : "#c0c2c8"
                                font.family: "Symbols Nerd Font Mono"
                                font.pixelSize: 18
                            }
                        }
                    }
                }
            }
        }
    }

    // ---------- Photo frame / gallery (bottom-left) ----------
    PanelWindow {
        id: photoPanel
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "skeletor-widgets"
        visible: Hyprland.focusedWorkspace?.id === 1
        anchors { left: true; bottom: true }
        margins { left: 30; bottom: 140 }
        implicitWidth: 360
        implicitHeight: 300
        exclusiveZone: 0
        color: "transparent"

        property int idx: 0

        FolderListModel {
            id: photoModel
            folder: "file:///home/stephxlr8/Pictures/widget"
            nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.gif", "*.bmp"]
            showDirs: false
            sortField: FolderListModel.Name
            onCountChanged: if (photoPanel.idx >= count) photoPanel.idx = 0
        }

        GlassPanel {
            anchors.fill: parent

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 8
                    color: "#06070b99"
                    border.color: root.hairline
                    border.width: 1
                    clip: true
                    Image {
                        anchors.fill: parent
                        anchors.margins: 3
                        source: photoModel.count > 0 ? "file://" + photoModel.get(photoPanel.idx, "filePath") : ""
                        fillMode: Image.PreserveAspectCrop
                        smooth: true
                        asynchronous: true
                        cache: false
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: photoModel.count === 0
                        text: "Sin fotos\n~/Pictures/widget"
                        horizontalAlignment: Text.AlignHCenter
                        color: root.textDim
                        font.family: "Noto Sans Mono"
                        font.pixelSize: 11
                    }
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 16
                    IconButton { label: ""; glyph: true; onClicked: if (photoModel.count > 0) photoPanel.idx = (photoPanel.idx - 1 + photoModel.count) % photoModel.count }
                    IconButton { label: ""; glyph: true; onClicked: if (photoModel.count > 0) photoPanel.idx = (photoPanel.idx + 1) % photoModel.count }
                }
            }
        }
    }

}
