import QtQuick
import QtQuick.Shapes

// Gothic glass card, Skeletor-theme: chamfered (notched) corners, near-black frosted
// glass, thin metallic silver edge on a dark buffer (the buffer kills the green fringe).
Item {
    id: root
    default property alias content: inner.data
    property real ch: 13          // chamfer (corner cut) size

    // outer dark buffer (chamfer) — fringe guard behind the silver edge, no stroke
    Shape {
        id: outer
        anchors.fill: parent
        ShapePath {
            strokeWidth: -1               // no stroke
            fillColor: "#05060acc"
            startX: root.ch; startY: 0
            PathLine { x: outer.width - root.ch; y: 0 }
            PathLine { x: outer.width;           y: root.ch }
            PathLine { x: outer.width;           y: outer.height - root.ch }
            PathLine { x: outer.width - root.ch; y: outer.height }
            PathLine { x: root.ch;               y: outer.height }
            PathLine { x: 0;                     y: outer.height - root.ch }
            PathLine { x: 0;                     y: root.ch }
            PathLine { x: root.ch;               y: 0 }
        }
    }

    // near-black frosted glass + metallic silver edge, inset so the silver is on dark
    Shape {
        id: glass
        anchors.fill: parent
        anchors.margins: 1.5
        property real c: root.ch - 1.5
        ShapePath {
            strokeColor: "#9aa0ac"            // metallic silver edge
            strokeWidth: 1.4
            joinStyle: ShapePath.MiterJoin
            fillGradient: LinearGradient {
                x1: 0; y1: 0; x2: 0; y2: glass.height
                // very dark, low alpha so the compositor blur frosts behind it
                GradientStop { position: 0.0; color: "#181a2082" }
                GradientStop { position: 0.5; color: "#0d0e1278" }
                GradientStop { position: 1.0; color: "#06070990" }
            }
            startX: glass.c; startY: 0
            PathLine { x: glass.width - glass.c; y: 0 }
            PathLine { x: glass.width;           y: glass.c }
            PathLine { x: glass.width;           y: glass.height - glass.c }
            PathLine { x: glass.width - glass.c; y: glass.height }
            PathLine { x: glass.c;               y: glass.height }
            PathLine { x: 0;                     y: glass.height - glass.c }
            PathLine { x: 0;                     y: glass.c }
            PathLine { x: glass.c;               y: 0 }
        }
    }

    Item {
        id: inner
        anchors.fill: parent
    }
}
