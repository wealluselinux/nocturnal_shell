import QtQuick

Item {
    id: root
    property color logoColor: Theme.accent
    implicitWidth: 64
    implicitHeight: 64

    onLogoColorChanged: canvas.requestPaint()
    onWidthChanged: canvas.requestPaint()
    onHeightChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d")
            var w = width
            var h = height
            ctx.reset()

            // Outer moon circle
            ctx.fillStyle = root.logoColor
            ctx.beginPath()
            ctx.arc(w * 0.48, h * 0.52, w * 0.36, 0, Math.PI * 2)
            ctx.fill()

            // Transparent crescent cutout
            ctx.globalCompositeOperation = "destination-out"
            ctx.beginPath()
            ctx.arc(w * 0.62, h * 0.40, w * 0.30, 0, Math.PI * 2)
            ctx.fill()

            // Small twinkling star
            ctx.globalCompositeOperation = "source-over"
            ctx.fillStyle = root.logoColor
            var sx = w * 0.72
            var sy = h * 0.28
            var r = w * 0.07
            ctx.beginPath()
            ctx.moveTo(sx, sy - r * 1.4)
            ctx.quadraticCurveTo(sx, sy, sx + r * 1.4, sy)
            ctx.quadraticCurveTo(sx, sy, sx, sy + r * 1.4)
            ctx.quadraticCurveTo(sx, sy, sx - r * 1.4, sy)
            ctx.quadraticCurveTo(sx, sy, sx, sy - r * 1.4)
            ctx.fill()
        }
    }
}
