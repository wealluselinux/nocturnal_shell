import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

Scope {
    id: root
    property string condition: ""
    property string effectType: "none" // "none" | "rain" | "storm" | "snow" | "cloudy"

    function classify(cond) {
        var c = (cond || "").toLowerCase()
        if (c === "") return "none"
        if (c.indexOf("thunder") >= 0 || c.indexOf("storm") >= 0) return "storm"
        if (c.indexOf("rain") >= 0 || c.indexOf("drizzle") >= 0 || c.indexOf("shower") >= 0) return "rain"
        if (c.indexOf("snow") >= 0 || c.indexOf("sleet") >= 0 || c.indexOf("blizzard") >= 0 || c.indexOf("flurr") >= 0 || c.indexOf("ice") >= 0) return "snow"
        if (c.indexOf("cloud") >= 0 || c.indexOf("overcast") >= 0 || c.indexOf("mist") >= 0 || c.indexOf("fog") >= 0 || c.indexOf("haze") >= 0) return "cloudy"
        return "none"
    }

    Process {
        id: weatherProc
        command: ["curl", "-s", "-m", "6", "wttr.in/?format=%C"]
        stdout: StdioCollector {
            id: wCol
            onStreamFinished: {
                var c = wCol.text.trim()
                if (c.length > 0) {
                    root.condition = c
                    root.effectType = root.classify(c)
                }
            }
        }
    }

    Timer {
        interval: 900000
        running: Theme.weatherEffects
        repeat: true
        triggeredOnStart: true
        onTriggered: weatherProc.running = true
    }

    Connections {
        target: Theme
        function onWeatherEffectsChanged() {
            if (Theme.weatherEffects) weatherProc.running = true
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            visible: Theme.weatherEffects && root.effectType !== "none"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            mask: Region {}

            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"

            Canvas {
                id: fxCanvas
                anchors.fill: parent
                property var particles: []
                property int flashTicks: 0

                function initParticles() {
                    var count = root.effectType === "cloudy" ? 18 : (root.effectType === "storm" ? 42 : 30)
                    var arr = []
                    var w = width > 0 ? width : 1920
                    var h = height > 0 ? height : 1080
                    for (var i = 0; i < count; i++) {
                        arr.push({
                            x: Math.random() * w,
                            y: Math.random() * h,
                            speed: root.effectType === "snow" ? (1.0 + Math.random() * 1.5) : (root.effectType === "cloudy" ? (0.4 + Math.random() * 0.6) : (9.0 + Math.random() * 7.0)),
                            size: root.effectType === "snow" ? (2.0 + Math.random() * 2.5) : (root.effectType === "cloudy" ? (40 + Math.random() * 70) : (10 + Math.random() * 10)),
                            drift: (Math.random() - 0.5) * 1.2
                        })
                    }
                    particles = arr
                }

                Component.onCompleted: initParticles()
                onWidthChanged: initParticles()

                Timer {
                    interval: 33
                    running: Theme.weatherEffects && root.effectType !== "none"
                    repeat: true
                    onTriggered: {
                        if (fxCanvas.particles.length === 0) fxCanvas.initParticles()
                        var w = fxCanvas.width, h = fxCanvas.height
                        if (w <= 0 || h <= 0) return
                        for (var i = 0; i < fxCanvas.particles.length; i++) {
                            var p = fxCanvas.particles[i]
                            if (root.effectType === "cloudy") {
                                p.x += p.speed
                                if (p.x - p.size > w) p.x = -p.size
                            } else if (root.effectType === "snow") {
                                p.y += p.speed
                                p.x += p.drift
                                if (p.y > h) { p.y = -6; p.x = Math.random() * w }
                                if (p.x < 0) p.x = w
                                if (p.x > w) p.x = 0
                            } else {
                                p.y += p.speed
                                p.x -= 1.2
                                if (p.y > h) { p.y = -20; p.x = Math.random() * (w + 100) }
                            }
                        }
                        if (root.effectType === "storm") {
                            if (fxCanvas.flashTicks > 0) fxCanvas.flashTicks--
                            else if (Math.random() < 0.004) fxCanvas.flashTicks = 3
                        } else {
                            fxCanvas.flashTicks = 0
                        }
                        fxCanvas.requestPaint()
                    }
                }

                onPaint: {
                    var ctx = getContext("2d")
                    ctx.reset()
                    if (flashTicks > 0) {
                        ctx.fillStyle = "rgba(220, 230, 255, 0.08)"
                        ctx.fillRect(0, 0, width, height)
                    }
                    if (root.effectType === "rain" || root.effectType === "storm") {
                        ctx.strokeStyle = Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.28)
                        ctx.lineWidth = 1.4
                        ctx.beginPath()
                        for (var i = 0; i < particles.length; i++) {
                            var r = particles[i]
                            ctx.moveTo(r.x, r.y)
                            ctx.lineTo(r.x - 2.5, r.y + r.size)
                        }
                        ctx.stroke()
                    } else if (root.effectType === "snow") {
                        ctx.fillStyle = "rgba(235, 240, 255, 0.55)"
                        for (var j = 0; j < particles.length; j++) {
                            var s = particles[j]
                            ctx.beginPath()
                            ctx.arc(s.x, s.y, s.size, 0, Math.PI * 2)
                            ctx.fill()
                        }
                    } else if (root.effectType === "cloudy") {
                        ctx.fillStyle = "rgba(200, 205, 230, 0.045)"
                        for (var k = 0; k < particles.length; k++) {
                            var c = particles[k]
                            ctx.beginPath()
                            ctx.arc(c.x, (k % 3) * 42 + 28, c.size, 0, Math.PI * 2)
                            ctx.fill()
                        }
                    }
                }
            }
        }
    }
}
