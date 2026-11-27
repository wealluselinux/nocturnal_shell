import QtQuick

Item {
    id: root
    property color logoColor: Theme.accent
    property bool sunMode: Theme.lightMode
    implicitWidth: 64
    implicitHeight: 64

    onLogoColorChanged: canvas.requestPaint()
    onSunModeChanged: canvas.requestPaint()
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
            ctx.fillStyle = root.logoColor
            ctx.strokeStyle = root.logoColor

            if (root.sunMode) {
                var cx = w * 0.5, cy = h * 0.5, r = w * 0.24
                ctx.beginPath()
                ctx.arc(cx, cy, r, 0, Math.PI * 2)
                ctx.fill()

                ctx.lineWidth = Math.max(2, w * 0.06)
                ctx.lineCap = "round"
                for (var i = 0; i < 8; i++) {
                    var a = (Math.PI * 2 * i) / 8
                    ctx.beginPath()
                    ctx.moveTo(cx + Math.cos(a) * (r * 1.35), cy + Math.sin(a) * (r * 1.35))
                    ctx.lineTo(cx + Math.cos(a) * (r * 1.78), cy + Math.sin(a) * (r * 1.78))
                    ctx.stroke()
                }
            } else {
                ctx.beginPath()
                ctx.arc(w * 0.48, h * 0.52, w * 0.36, 0, Math.PI * 2)
                ctx.fill()

                ctx.globalCompositeOperation = "destination-out"
                ctx.beginPath()
                ctx.arc(w * 0.62, h * 0.40, w * 0.30, 0, Math.PI * 2)
                ctx.fill()

                ctx.globalCompositeOperation = "source-over"
                ctx.fillStyle = root.logoColor
                var sx = w * 0.72, sy = h * 0.28, sr = w * 0.07
                ctx.beginPath()
                ctx.moveTo(sx, sy - sr * 1.4)
                ctx.quadraticCurveTo(sx, sy, sx + sr * 1.4, sy)
                ctx.quadraticCurveTo(sx, sy, sx, sy + sr * 1.4)
                ctx.quadraticCurveTo(sx, sy, sx - sr * 1.4, sy)
                ctx.quadraticCurveTo(sx, sy, sx, sy - sr * 1.4)
                ctx.fill()
            }
        }
    }
}
