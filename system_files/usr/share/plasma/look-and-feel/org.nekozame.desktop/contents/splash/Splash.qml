// nekozame os: the bubble on plum while plasma starts
import QtQuick

Rectangle {
    id: root
    color: "#433a55"
    property int stage

    Image {
        anchors.centerIn: parent
        source: "images/logo.png"
        width: Math.min(parent.width, parent.height) / 4
        height: width
        fillMode: Image.PreserveAspectFit
        smooth: true
        opacity: root.stage > 1 ? 1 : 0.6
        Behavior on opacity { NumberAnimation { duration: 600 } }
    }
}
