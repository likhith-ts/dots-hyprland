import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services
import qs.modules.common

/**
 * macOS Genie-style minimize/restore animation
 * Bottom of window gets sucked into dock first (correct macOS behavior)
 * Includes minimized apps view overlay with header
 */
Scope {
    id: root
    
    Component.onCompleted: {
        console.log("[MinimizeAnimation] Component loaded");
    }
    
    property bool animating: false
    property string windowAddress: ""
    property bool isRestore: false
    property var pendingWindowData: null
    property string screenshotPath: "/tmp/qs-minimize-screenshot.png"
    property bool minimizedViewVisible: false
    property var minimizedWindows: []
    
    // Refresh minimized windows list
    function refreshMinimizedWindows() {
        getMinimizedWindows.running = true;
    }
    
    IpcHandler {
        target: "minimize"
        
        function active(): void {
            if (root.animating) return;
            root.isRestore = false;
            getActiveWindow.running = true;
        }
        
        function restore(address: string, targetX: real, targetY: real, targetW: real, targetH: real): void {
            if (root.animating) return;
            root.isRestore = true;
            root.windowAddress = address;
            root.minimizedViewVisible = false;
            
            const monitorData = HyprlandData.monitors[0];
            animationBroadcast.isRestore = true;
            animationBroadcast.windowData = {
                at: [targetX, targetY],
                size: [targetW, targetH],
                monitor: 0
            };
            animationBroadcast.dockX = monitorData ? monitorData.x + monitorData.width / 2 : 960;
            animationBroadcast.dockY = monitorData ? monitorData.y + monitorData.height - 50 : 1030;
            
            root.animating = true;
            animationBroadcast.trigger();
        }
        
        function toggleView(): void {
            if (root.minimizedViewVisible) {
                root.minimizedViewVisible = false;
            } else {
                root.refreshMinimizedWindows();
                root.minimizedViewVisible = true;
            }
        }
        
        function hideView(): void {
            root.minimizedViewVisible = false;
        }
    }
    
    // Get list of minimized windows
    Process {
        id: getMinimizedWindows
        command: ["hyprctl", "clients", "-j"]
        
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const clients = JSON.parse(text);
                    root.minimizedWindows = clients.filter(c => 
                        c.workspace && c.workspace.name === "special:minimize"
                    );
                    console.log("[MinimizeAnimation] Found", root.minimizedWindows.length, "minimized windows");
                } catch (e) {
                    console.error("MinimizeAnimation: Parse clients error:", e);
                    root.minimizedWindows = [];
                }
            }
        }
    }
    
    function getDockPosition(monitor) {
        const monitorData = HyprlandData.monitors.find(m => m.id === monitor) ?? HyprlandData.monitors[0];
        if (!monitorData) return { x: 960, y: 1080 };
        return {
            x: monitorData.x + monitorData.width / 2,
            y: monitorData.y + monitorData.height - 50
        };
    }
    
    Process {
        id: getActiveWindow
        command: ["hyprctl", "activewindow", "-j"]
        
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    if (!data || !data.address) return;
                    
                    root.windowAddress = data.address;
                    root.pendingWindowData = data;
                    
                    // Capture screenshot
                    captureScreenshot.command = [
                        "grim", "-g",
                        `${data.at[0]},${data.at[1]} ${data.size[0]}x${data.size[1]}`,
                        root.screenshotPath
                    ];
                    captureScreenshot.running = true;
                    
                } catch (e) {
                    console.error("MinimizeAnimation: Parse error:", e);
                }
            }
        }
    }
    
    Process {
        id: captureScreenshot
        
        onExited: (code, status) => {
            console.log("[MinimizeAnimation] Screenshot captured, code:", code);
            const data = root.pendingWindowData;
            if (!data) return;
            
            const dockPos = root.getDockPosition(data.monitor);
            
            root.animating = true;
            animationBroadcast.isRestore = false;
            animationBroadcast.windowData = data;
            animationBroadcast.dockX = dockPos.x;
            animationBroadcast.dockY = dockPos.y;
            animationBroadcast.screenshotReady = (code === 0);
            animationBroadcast.trigger();
        }
    }
    
    QtObject {
        id: animationBroadcast
        property var windowData: null
        property real dockX: 0
        property real dockY: 0
        property bool isRestore: false
        property bool screenshotReady: false
        signal trigger()
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: animationWindow
            required property var modelData
            screen: modelData
            
            visible: genieItem.running
            color: "transparent"
            
            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }
            
            WlrLayershell.namespace: "quickshell:minimize-animation"
            WlrLayershell.layer: WlrLayer.Overlay
            exclusiveZone: 0
            
            Item {
                id: genieItem
                anchors.fill: parent
                
                property bool running: false
                property real progress: 0.0
                property bool isRestore: false
                property bool hasScreenshot: false
                
                property real winX: 0
                property real winY: 0
                property real winW: 400
                property real winH: 300
                property real dockX: 960
                property real dockY: 1050
                
                visible: running
                
                // Screenshot for texture
                Image {
                    id: windowImage
                    source: ""
                    visible: false
                    cache: false
                    asynchronous: false
                    
                    onStatusChanged: {
                        console.log("[MinimizeAnimation] Image status:", status);
                        genieItem.hasScreenshot = (status === Image.Ready);
                        if (status === Image.Ready) {
                            genieCanvas.requestPaint();
                        }
                    }
                }
                
                Canvas {
                    id: genieCanvas
                    anchors.fill: parent
                    visible: genieItem.running
                    
                    onPaint: {
                        let ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        
                        if (!genieItem.running) return;
                        
                        // Animation progress (reversed for restore)
                        let p = genieItem.isRestore ? 1.0 - genieItem.progress : genieItem.progress;
                        
                        let winX = genieItem.winX;
                        let winY = genieItem.winY;
                        let winW = genieItem.winW;
                        let winH = genieItem.winH;
                        let dockX = genieItem.dockX;
                        let dockY = genieItem.dockY;
                        
                        let segments = 20;
                        
                        // Colors from matugen
                        let surfaceColor = Appearance?.m3colors?.m3surfaceContainerHigh?.toString() ?? "#322826";
                        let primaryColor = Appearance?.m3colors?.m3primary?.toString() ?? "#ffb4a8";
                        let secondaryColor = Appearance?.m3colors?.m3secondary?.toString() ?? "#e7bdb6";
                        let outlineColor = Appearance?.m3colors?.m3outline?.toString() ?? "#a08c89";
                        
                        // Calculate genie points - BOTTOM leads toward dock (macOS style)
                        let leftEdge = [];
                        let rightEdge = [];
                        
                        for (let i = 0; i <= segments; i++) {
                            let t = i / segments;  // 0 = top, 1 = bottom
                            
                            // macOS Genie: BOTTOM (t=1) moves first, TOP (t=0) follows
                            // Use inverted t for the "leading" calculation
                            let invertT = 1.0 - t;  // 0 = bottom, 1 = top
                            
                            // Bottom moves immediately, top delays
                            let segmentDelay = invertT * 0.6;  // Top waits longer
                            let effectiveProgress = Math.max(0, (p - segmentDelay) / (1.0 - segmentDelay));
                            effectiveProgress = Math.min(1, effectiveProgress);
                            
                            // Ease the progress
                            effectiveProgress = effectiveProgress * effectiveProgress * (3 - 2 * effectiveProgress);
                            
                            // Y position: bottom reaches dock first
                            let startY = winY + t * winH;
                            let endY = dockY;  // Everything converges to dock
                            let y = startY + (endY - startY) * effectiveProgress;
                            
                            // X position: converge toward dock center
                            // Bottom converges faster
                            let startCenterX = winX + winW / 2;
                            let xProgress = effectiveProgress;
                            let centerX = startCenterX + (dockX - startCenterX) * xProgress;
                            
                            // Width shrinks as it approaches dock
                            // Bottom shrinks faster (funnel effect)
                            let widthFactor = 1.0 - effectiveProgress * 0.92;
                            let halfW = Math.max(24, (winW * widthFactor) / 2);
                            
                            leftEdge.push({ x: centerX - halfW, y: y });
                            rightEdge.push({ x: centerX + halfW, y: y });
                        }
                        
                        // Draw the shape
                        ctx.beginPath();
                        
                        // Left edge (top to bottom)
                        ctx.moveTo(leftEdge[0].x, leftEdge[0].y);
                        for (let i = 1; i < leftEdge.length; i++) {
                            if (i < leftEdge.length - 1) {
                                let xc = (leftEdge[i].x + leftEdge[i+1].x) / 2;
                                let yc = (leftEdge[i].y + leftEdge[i+1].y) / 2;
                                ctx.quadraticCurveTo(leftEdge[i].x, leftEdge[i].y, xc, yc);
                            } else {
                                ctx.lineTo(leftEdge[i].x, leftEdge[i].y);
                            }
                        }
                        
                        // Right edge (bottom to top)
                        for (let i = rightEdge.length - 1; i >= 0; i--) {
                            if (i > 0) {
                                let xc = (rightEdge[i].x + rightEdge[i-1].x) / 2;
                                let yc = (rightEdge[i].y + rightEdge[i-1].y) / 2;
                                ctx.quadraticCurveTo(rightEdge[i].x, rightEdge[i].y, xc, yc);
                            } else {
                                ctx.lineTo(rightEdge[i].x, rightEdge[i].y);
                            }
                        }
                        
                        ctx.closePath();
                        
                        // Fill with gradient or screenshot
                        if (genieItem.hasScreenshot && windowImage.status === Image.Ready) {
                            // Create clipping path
                            ctx.save();
                            ctx.clip();
                            
                            // Draw screenshot scaled to current shape bounds
                            let minX = Math.min(...leftEdge.map(p => p.x));
                            let maxX = Math.max(...rightEdge.map(p => p.x));
                            let minY = leftEdge[0].y;
                            let maxY = leftEdge[leftEdge.length - 1].y;
                            
                            try {
                                ctx.drawImage(windowImage, minX, minY, maxX - minX, maxY - minY);
                            } catch (e) {
                                // Fallback to gradient
                                let gradient = ctx.createLinearGradient(winX, winY, winX, winY + winH);
                                gradient.addColorStop(0.0, surfaceColor);
                                gradient.addColorStop(0.5, secondaryColor);
                                gradient.addColorStop(1.0, primaryColor);
                                ctx.fillStyle = gradient;
                                ctx.fill();
                            }
                            
                            ctx.restore();
                        } else {
                            // Gradient fill
                            let gradient = ctx.createLinearGradient(winX, winY, dockX, dockY);
                            gradient.addColorStop(0.0, surfaceColor);
                            gradient.addColorStop(0.4, secondaryColor);
                            gradient.addColorStop(0.8, primaryColor);
                            gradient.addColorStop(1.0, primaryColor);
                            
                            ctx.fillStyle = gradient;
                            ctx.globalAlpha = 1.0 - p * 0.2;
                            ctx.fill();
                        }
                        
                        // Border
                        ctx.globalAlpha = 1.0;
                        ctx.strokeStyle = outlineColor;
                        ctx.lineWidth = 2;
                        ctx.stroke();
                    }
                }
                
                NumberAnimation {
                    id: genieAnim
                    target: genieItem
                    property: "progress"
                    from: 0.0
                    to: 1.0
                    duration: 350
                    easing.type: Easing.OutQuad
                    
                    onFinished: {
                        if (genieItem.isRestore) {
                            let wsId = Hyprland.focusedMonitor?.activeWorkspace?.id ?? 1;
                            Hyprland.dispatch(`movetoworkspace ${wsId},address:${root.windowAddress}`);
                            activateTimer.start();
                        }
                        
                        genieItem.running = false;
                        genieItem.progress = 0;
                        root.animating = false;
                    }
                }
                
                Timer {
                    id: activateTimer
                    interval: 30
                    onTriggered: {
                        Hyprland.dispatch(`focuswindow address:${root.windowAddress}`);
                    }
                }
                
                onProgressChanged: {
                    genieCanvas.requestPaint();
                }
                
                Connections {
                    target: animationBroadcast
                    
                    function onTrigger() {
                        const data = animationBroadcast.windowData;
                        if (!data) return;
                        
                        genieItem.isRestore = animationBroadcast.isRestore;
                        
                        if (!animationBroadcast.isRestore) {
                            // Minimize the window first
                            Hyprland.dispatch(`movetoworkspacesilent special:minimize,address:${root.windowAddress}`);
                        }
                        
                        genieItem.winX = data.at[0];
                        genieItem.winY = data.at[1];
                        genieItem.winW = data.size[0];
                        genieItem.winH = data.size[1];
                        genieItem.dockX = animationBroadcast.dockX;
                        genieItem.dockY = animationBroadcast.dockY;
                        genieItem.progress = 0;
                        
                        // Load screenshot
                        if (animationBroadcast.screenshotReady) {
                            windowImage.source = "";
                            windowImage.source = "file://" + root.screenshotPath + "?t=" + Date.now();
                        }
                        
                        genieItem.running = true;
                        genieAnim.start();
                    }
                }
            }
        }
    }
    
    // Minimized Apps View Overlay
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: minimizedViewWindow
            required property var modelData
            screen: modelData
            
            visible: root.minimizedViewVisible
            color: "transparent"
            
            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }
            
            WlrLayershell.namespace: "quickshell:minimized-view"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: root.minimizedViewVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            exclusiveZone: 0
            
            // Close on Escape
            Item {
                anchors.fill: parent
                focus: root.minimizedViewVisible
                
                Keys.onEscapePressed: {
                    root.minimizedViewVisible = false;
                }
            }
            
            // Background overlay
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.7)
                visible: root.minimizedViewVisible
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.minimizedViewVisible = false
                }
            }
            
            // Content container with header and windows
            Rectangle {
                id: viewContainer
                anchors.centerIn: parent
                width: Math.min(parent.width * 0.8, 1200)
                height: Math.min(parent.height * 0.7, 800)
                color: Appearance?.m3colors?.m3surfaceContainer?.toString() ?? "#1e1a18"
                radius: 24
                border.color: Appearance?.m3colors?.m3outlineVariant?.toString() ?? "#534340"
                border.width: 2
                
                visible: root.minimizedViewVisible
                
                // Scale animation
                scale: root.minimizedViewVisible ? 1.0 : 0.9
                opacity: root.minimizedViewVisible ? 1.0 : 0.0
                
                Behavior on scale {
                    NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
                }
                Behavior on opacity {
                    NumberAnimation { duration: 150 }
                }
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 20
                    
                    // Header
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 48
                        
                        Text {
                            text: "Minimized Apps"
                            font.pixelSize: 28
                            font.weight: Font.DemiBold
                            color: Appearance?.m3colors?.m3onSurface?.toString() ?? "#efe0dc"
                            Layout.fillWidth: true
                        }
                        
                        Text {
                            text: root.minimizedWindows.length + " window" + (root.minimizedWindows.length !== 1 ? "s" : "")
                            font.pixelSize: 16
                            color: Appearance?.m3colors?.m3onSurfaceVariant?.toString() ?? "#d8c2bc"
                            opacity: 0.7
                        }
                        
                        // Close button
                        Rectangle {
                            width: 36
                            height: 36
                            radius: 18
                            color: closeArea.containsMouse ? 
                                   (Appearance?.m3colors?.m3surfaceContainerHighest?.toString() ?? "#443e3b") : 
                                   "transparent"
                            
                            Text {
                                anchors.centerIn: parent
                                text: "✕"
                                font.pixelSize: 18
                                color: Appearance?.m3colors?.m3onSurface?.toString() ?? "#efe0dc"
                            }
                            
                            MouseArea {
                                id: closeArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: root.minimizedViewVisible = false
                            }
                        }
                    }
                    
                    // Divider
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Appearance?.m3colors?.m3outlineVariant?.toString() ?? "#534340"
                    }
                    
                    // Windows grid or empty state
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        
                        // Empty state
                        Text {
                            anchors.centerIn: parent
                            text: "No minimized windows"
                            font.pixelSize: 18
                            color: Appearance?.m3colors?.m3onSurfaceVariant?.toString() ?? "#d8c2bc"
                            opacity: 0.6
                            visible: root.minimizedWindows.length === 0
                        }
                        
                        // Windows grid
                        GridView {
                            id: windowsGrid
                            anchors.fill: parent
                            visible: root.minimizedWindows.length > 0
                            
                            cellWidth: 280
                            cellHeight: 200
                            
                            model: root.minimizedWindows
                            
                            delegate: Rectangle {
                                id: windowCard
                                required property var modelData
                                required property int index
                                
                                width: windowsGrid.cellWidth - 16
                                height: windowsGrid.cellHeight - 16
                                radius: 16
                                color: cardArea.containsMouse ? 
                                       (Appearance?.m3colors?.m3surfaceContainerHigh?.toString() ?? "#362f2c") :
                                       (Appearance?.m3colors?.m3surfaceContainerLow?.toString() ?? "#1a1614")
                                border.color: Appearance?.m3colors?.m3outline?.toString() ?? "#a08c89"
                                border.width: 1
                                
                                Behavior on color {
                                    ColorAnimation { duration: 100 }
                                }
                                
                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 8
                                    
                                    // Window preview area (scaled representation)
                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        radius: 8
                                        color: Appearance?.m3colors?.m3surfaceContainerHighest?.toString() ?? "#443e3b"
                                        
                                        // Show window class icon or placeholder
                                        Text {
                                            anchors.centerIn: parent
                                            text: windowCard.modelData?.class?.charAt(0)?.toUpperCase() ?? "?"
                                            font.pixelSize: 48
                                            font.weight: Font.Bold
                                            color: Appearance?.m3colors?.m3primary?.toString() ?? "#ffb4a8"
                                            opacity: 0.4
                                        }
                                        
                                        // "Click to restore" hint on hover
                                        Rectangle {
                                            anchors.fill: parent
                                            radius: 8
                                            color: Qt.rgba(0, 0, 0, 0.5)
                                            visible: cardArea.containsMouse
                                            
                                            Text {
                                                anchors.centerIn: parent
                                                text: "Click to restore"
                                                font.pixelSize: 14
                                                color: "#ffffff"
                                            }
                                        }
                                    }
                                    
                                    // Window info
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        
                                        Text {
                                            text: windowCard.modelData?.class ?? "Unknown"
                                            font.pixelSize: 14
                                            font.weight: Font.Medium
                                            color: Appearance?.m3colors?.m3onSurface?.toString() ?? "#efe0dc"
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                        
                                        Text {
                                            text: windowCard.modelData?.title ?? ""
                                            font.pixelSize: 12
                                            color: Appearance?.m3colors?.m3onSurfaceVariant?.toString() ?? "#d8c2bc"
                                            opacity: 0.7
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                            maximumLineCount: 1
                                        }
                                    }
                                }
                                
                                MouseArea {
                                    id: cardArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    
                                    onClicked: {
                                        const win = windowCard.modelData;
                                        if (!win) return;
                                        
                                        // Close the view
                                        root.minimizedViewVisible = false;
                                        
                                        // Calculate target position (center of screen, scaled)
                                        const monitor = HyprlandData.monitors[0];
                                        const targetW = win.size[0] * 0.8;
                                        const targetH = win.size[1] * 0.8;
                                        const targetX = monitor ? (monitor.x + (monitor.width - targetW) / 2) : 100;
                                        const targetY = monitor ? (monitor.y + (monitor.height - targetH) / 2) : 100;
                                        
                                        // Trigger restore with animation
                                        root.isRestore = true;
                                        root.windowAddress = win.address;
                                        
                                        animationBroadcast.isRestore = true;
                                        animationBroadcast.windowData = {
                                            at: [targetX, targetY],
                                            size: [targetW, targetH],
                                            monitor: 0
                                        };
                                        animationBroadcast.dockX = monitor ? monitor.x + monitor.width / 2 : 960;
                                        animationBroadcast.dockY = monitor ? monitor.y + monitor.height - 50 : 1030;
                                        animationBroadcast.screenshotReady = false;
                                        
                                        root.animating = true;
                                        animationBroadcast.trigger();
                                    }
                                }
                            }
                        }
                    }
                    
                    // Footer hint
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Press Escape or click outside to close"
                        font.pixelSize: 12
                        color: Appearance?.m3colors?.m3onSurfaceVariant?.toString() ?? "#d8c2bc"
                        opacity: 0.5
                    }
                }
            }
        }
    }
}
