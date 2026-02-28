import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services
import qs.modules.common

/**
 * Genie-style minimize animation overlay
 * Creates a warping/shrinking effect as the window animates to the dock
 */
Scope {
    id: root
    
    Component.onCompleted: {
        console.log("[MinimizeAnimation] Component loaded and ready");
    }
    
    // Animation state
    property bool animating: false
    property string windowAddress: ""
    
    // IPC handler for minimize commands
    IpcHandler {
        target: "minimize"
        
        function active(): void {
            console.log("[MinimizeAnimation] active() called");
            if (root.animating) {
                console.log("[MinimizeAnimation] Already animating, skipping");
                return;
            }
            console.log("[MinimizeAnimation] Starting getActiveWindow process");
            getActiveWindow.running = true;
        }
    }
    
    // Get dock position (bottom center of monitor)
    function getDockPosition(monitor) {
        const monitorData = HyprlandData.monitors.find(m => m.id === monitor) ?? HyprlandData.monitors[0];
        if (!monitorData) return { x: 960, y: 1080 };
        return {
            x: monitorData.x + monitorData.width / 2,
            y: monitorData.y + monitorData.height - 35
        };
    }
    
    // Get active window data
    Process {
        id: getActiveWindow
        command: ["hyprctl", "activewindow", "-j"]
        
        stdout: StdioCollector {
            onStreamFinished: {
                console.log("[MinimizeAnimation] stdout received:", text);
                try {
                    const data = JSON.parse(text);
                    console.log("[MinimizeAnimation] Parsed data:", JSON.stringify(data));
                    if (!data || !data.address) {
                        console.log("[MinimizeAnimation] No valid address in data");
                        return;
                    }
                    
                    root.windowAddress = data.address;
                    const dockPos = root.getDockPosition(data.monitor);
                    
                    // Trigger animation
                    root.animating = true;
                    animationBroadcast.windowData = data;
                    animationBroadcast.dockX = dockPos.x;
                    animationBroadcast.dockY = dockPos.y;
                    animationBroadcast.trigger();
                    
                } catch (e) {
                    console.error("MinimizeAnimation: Failed to parse window data:", e);
                    root.animating = false;
                }
            }
        }
    }
    
    // Broadcast object to communicate with panel windows
    QtObject {
        id: animationBroadcast
        property var windowData: null
        property real dockX: 0
        property real dockY: 0
        signal trigger()
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: animationWindow
            required property var modelData
            screen: modelData
            
            visible: animRect.running
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
            
            // Simple animated rectangle (genie simulation)
            Rectangle {
                id: animRect
                property bool running: false
                property real targetX: 0
                property real targetY: 0
                
                visible: running
                color: Appearance?.colors?.colLayer1 ?? "#2d2d2d"
                radius: 12
                border.width: 2
                border.color: Appearance?.colors?.colLayer1Border ?? "#444444"
                
                // Scale transform for genie effect
                transform: [
                    Scale {
                        id: scaleTransform
                        origin.x: animRect.width / 2
                        origin.y: animRect.height
                        xScale: 1.0
                        yScale: 1.0
                    }
                ]
                
                // Minimize animation
                ParallelAnimation {
                    id: minimizeAnim
                    
                    NumberAnimation {
                        target: animRect
                        property: "x"
                        duration: 250
                        easing.type: Easing.InOutQuad
                    }
                    NumberAnimation {
                        target: animRect
                        property: "y"
                        duration: 250
                        easing.type: Easing.InOutQuad
                    }
                    NumberAnimation {
                        target: animRect
                        property: "width"
                        to: 50
                        duration: 250
                        easing.type: Easing.InOutQuad
                    }
                    NumberAnimation {
                        target: animRect
                        property: "height"
                        to: 30
                        duration: 250
                        easing.type: Easing.InOutQuad
                    }
                    NumberAnimation {
                        target: animRect
                        property: "opacity"
                        from: 0.85
                        to: 0.0
                        duration: 250
                        easing.type: Easing.InQuad
                    }
                    NumberAnimation {
                        target: scaleTransform
                        property: "xScale"
                        from: 1.0
                        to: 0.3
                        duration: 250
                        easing.type: Easing.InOutQuad
                    }
                    NumberAnimation {
                        target: animRect
                        property: "radius"
                        to: 25
                        duration: 250
                        easing.type: Easing.InOutQuad
                    }
                    
                    onFinished: {
                        animRect.running = false;
                        root.animating = false;
                        // Window already minimized at start of animation
                    }
                }
                
                Connections {
                    target: animationBroadcast
                    
                    function onTrigger() {
                        console.log("[MinimizeAnimation] onTrigger called");
                        const data = animationBroadcast.windowData;
                        if (!data) {
                            console.log("[MinimizeAnimation] No data in broadcast");
                            return;
                        }
                        console.log("[MinimizeAnimation] Starting animation for window at", data.at, "size", data.size);
                        
                        // Minimize the window FIRST so it's gone
                        Hyprland.dispatch(`movetoworkspacesilent special:minimize,address:${root.windowAddress}`);
                        
                        // Setup initial position/size for animation overlay
                        animRect.x = data.at[0];
                        animRect.y = data.at[1];
                        animRect.width = data.size[0];
                        animRect.height = data.size[1];
                        animRect.opacity = 0.85;
                        animRect.radius = 12;
                        scaleTransform.xScale = 1.0;
                        scaleTransform.yScale = 1.0;
                        
                        // Target position (dock)
                        animRect.targetX = animationBroadcast.dockX - 25;
                        animRect.targetY = animationBroadcast.dockY - 15;
                        
                        // Update animation targets
                        minimizeAnim.animations[0].to = animRect.targetX;
                        minimizeAnim.animations[1].to = animRect.targetY;
                        
                        animRect.running = true;
                        minimizeAnim.start();
                    }
                }
            }
        }
    }
}
