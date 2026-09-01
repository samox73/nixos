import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Wayland
import Quickshell.WindowManager

ShellRoot {
    id: root

    property var health: ({ cpu: null, memory: null, temperature: null, disk: null })
    property var cpuHistory: []
    property var memoryHistory: []
    property var weather: ({ temperature: "--", feelsLike: "--", description: "Unavailable", humidity: "--", wind: "--" })
    property var forecast: []
    property string weatherText: "Vienna: --"
    property var activeNetwork: null
    property string networkIp: "--"
    property var wifiNetworks: []
    property bool wifiEnabled: false
    property bool wifiHardwareEnabled: false
    property bool wifiToggleTarget: false
    property string wifiScanError: ""
    property bool shortcutOverlayVisible: false
    property bool shortcutSearchActive: false
    property string shortcutSearch: ""
    property var shortcuts: []
    readonly property string shortcutSearchQuery: shortcutSearch.trim()
    readonly property var filteredShortcuts: shortcutSearchQuery === ""
        ? shortcuts
        : shortcuts.filter(binding => shortcutMatches(binding, shortcutSearchQuery))
    readonly property var shortcutGroups: [
        { title: "Windows & Focus", column: 0, shortcuts: filteredShortcuts.filter(binding => shortcutGroup(binding) === "windows") },
        { title: "Applications", column: 0, shortcuts: filteredShortcuts.filter(binding => shortcutGroup(binding) === "applications") },
        { title: "Workspaces", column: 1, shortcuts: filteredShortcuts.filter(binding => shortcutGroup(binding) === "workspaces") },
        { title: "Custom", column: 1, shortcuts: filteredShortcuts.filter(binding => shortcutGroup(binding) === "custom") },
        { title: "Layout & Groups", column: 2, shortcuts: filteredShortcuts.filter(binding => shortcutGroup(binding) === "layout") },
        { title: "System & Media", column: 2, shortcuts: filteredShortcuts.filter(binding => shortcutGroup(binding) === "system") }
    ]
    readonly property var audioSink: Pipewire.defaultAudioSink
    readonly property var battery: UPower.displayDevice
    readonly property var bluetoothAdapter: Bluetooth.defaultAdapter
    readonly property var spotifyPlayer: [...Mpris.players.values].find(player =>
        player.dbusName.toLowerCase().includes("spotify")
        || player.identity.toLowerCase().includes("spotify")) ?? null
    readonly property string healthText: `CPU ${health.cpu ?? "--"}%  ${health.temperature ?? "--"}°  RAM ${health.memory ?? "--"}%`
    function updateHealth(data): void {
        try {
            const sample = JSON.parse(data);
            health = sample;
            cpuHistory = [...cpuHistory, sample.cpu].slice(-120);
            memoryHistory = [...memoryHistory, sample.memory].slice(-120);
        } catch (error) {
            console.warn(`Invalid health sample: ${error}`);
        }
    }

    function updateWeather(data): void {
        try {
            const report = JSON.parse(data);
            const current = report.current_condition[0];
            weather = {
                temperature: current.temp_C,
                feelsLike: current.FeelsLikeC,
                description: current.weatherDesc[0].value,
                humidity: current.humidity,
                wind: current.windspeedKmph
            };
            forecast = report.weather.slice(0, 3).map(day => ({
                date: day.date,
                min: day.mintempC,
                max: day.maxtempC,
                description: day.hourly[4].weatherDesc[0].value
            }));
            weatherText = `Vienna: ${current.temp_C}°C`;
        } catch (error) {
            console.warn(`Invalid weather report: ${error}`);
        }
    }

    function splitNmcli(line): var {
        const fields = [""];
        let escaped = false;
        for (const character of line) {
            if (escaped) {
                fields[fields.length - 1] += character;
                escaped = false;
            } else if (character === "\\") {
                escaped = true;
            } else if (character === ":") {
                fields.push("");
            } else {
                fields[fields.length - 1] += character;
            }
        }
        if (escaped)
            fields[fields.length - 1] += "\\";
        return fields;
    }

    function updateNetworkStatus(data): void {
        const connections = data.trim().split("\n").filter(line => line !== "")
            .map(splitNmcli).filter(fields => ["802-11-wireless", "802-3-ethernet"].includes(fields[1]));
        const connection = connections.find(fields => fields[1] === "802-11-wireless") ?? connections[0];
        activeNetwork = connection === undefined ? null : {
            name: connection[0],
            wifi: connection[1] === "802-11-wireless",
            device: connection[2]
        };
        networkIp = "--";
        if (activeNetwork !== null)
            networkIpProcess.exec(["nmcli", "-g", "IP4.ADDRESS", "device", "show", activeNetwork.device]);
    }

    function updateWifiNetworks(data): void {
        const strongest = {};
        for (const line of data.trim().split("\n")) {
            const fields = splitNmcli(line);
            if (fields.length < 4 || fields[1] === "")
                continue;
            const network = {
                connected: fields[0] === "*",
                name: fields[1],
                signal: Number(fields[2]),
                security: fields[3]
            };
            const key = `$${network.name}`;
            if (strongest[key] === undefined || network.connected
                || network.signal > strongest[key].signal)
                strongest[key] = network;
        }
        wifiNetworks = Object.values(strongest).sort((a, b) =>
            Number(b.connected) - Number(a.connected) || b.signal - a.signal);
    }

    function refreshNetwork(): void {
        if (!networkStatusProcess.running)
            networkStatusProcess.running = true;
        if (!networkRadioProcess.running)
            networkRadioProcess.running = true;
    }

    function scanWifi(): void {
        wifiScanError = "";
        if (!wifiScanProcess.running)
            wifiScanProcess.running = true;
    }

    Component.onCompleted: console.assert(splitNmcli("a\\:b:c\\\\d").join("|") === "a:b|c\\d",
        "nmcli field parser is broken")

    function formatDuration(seconds): string {
        if (seconds <= 0)
            return "Calculating";
        return `${Math.floor(seconds / 3600)}h ${Math.floor(seconds % 3600 / 60)}m`;
    }

    function formatTrackTime(seconds): string {
        if (!Number.isFinite(seconds) || seconds < 0)
            return "--:--";
        const minutes = Math.floor(seconds / 60);
        const remainder = Math.floor(seconds % 60);
        return `${minutes}:${remainder < 10 ? "0" : ""}${remainder}`;
    }

    function shortcutLabel(binding): string {
        const keys = [];
        if (binding.modmask & 64) keys.push("Super");
        if (binding.modmask & 4) keys.push("Ctrl");
        if (binding.modmask & 8) keys.push("Alt");
        if (binding.modmask & 1) keys.push("Shift");

        const names = {
            Return: "Enter",
            TAB: "Tab",
            space: "Space",
            slash: "/",
            period: ".",
            comma: ",",
            "mouse:272": "LMB",
            "mouse:273": "RMB",
            XF86MonBrightnessUp: "Brightness Up",
            XF86MonBrightnessDown: "Brightness Down",
            XF86AudioRaiseVolume: "Volume Up",
            XF86AudioLowerVolume: "Volume Down",
            XF86AudioNext: "Next",
            XF86AudioPrev: "Previous"
        };
        const key = names[binding.key] ?? (binding.key.length === 1
            ? binding.key.toUpperCase() : binding.key);
        keys.push(key);
        return keys.join("+");
    }

    function shortcutMatches(binding, query): bool {
        const needle = query.toLowerCase();
        return shortcutLabel(binding).toLowerCase().replace(/\s/g, "")
            .includes(needle.replace(/\s/g, ""))
            || binding.description.toLowerCase().includes(needle);
    }

    function shortcutGroup(binding): string {
        if (["workspace", "hy3:movetoworkspace", "movecurrentworkspacetomonitor"].includes(binding.dispatcher)
            || binding.description === "Move all windows to another workspace")
            return "workspaces";
        if (binding.submap === "resize" || ["hy3:makegroup", "hy3:changefocus", "submap",
            "hy3:focustab", "hy3:changegroup", "resizeactive"].includes(binding.dispatcher))
            return "layout";
        if (["hy3:killactive", "hy3:movefocus", "focusmonitor", "movewindow", "hy3:movewindow",
            "fullscreen", "togglefloating", "mouse"].includes(binding.dispatcher))
            return "windows";
        if (["Open terminal", "Open application launcher", "Open university Firefox",
            "Open private Firefox"].includes(binding.description))
            return "applications";
        if (["Lock screen", "Increase brightness", "Decrease brightness", "Next track", "Previous track",
            "Toggle Spotify playback", "Increase volume", "Decrease volume"].includes(binding.description))
            return "system";
        return "custom";
    }

    function escapeHtml(text): string {
        return text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
    }

    function highlightMatch(text, query): string {
        const index = text.toLowerCase().indexOf(query.toLowerCase());
        if (query === "" || index < 0)
            return escapeHtml(text);
        return `${escapeHtml(text.slice(0, index))}<span style="background-color:#a7c080;color:#2d353b">${escapeHtml(text.slice(index, index + query.length))}</span>${escapeHtml(text.slice(index + query.length))}`;
    }

    function resetShortcutSearch(): void {
        shortcutSearch = "";
        shortcutSearchActive = false;
    }

    function closeShortcutOverlay(): void {
        shortcutOverlayVisible = false;
        resetShortcutSearch();
    }

    function toggleShortcutOverlay(): void {
        if (shortcutOverlayVisible) {
            closeShortcutOverlay();
        } else {
            resetShortcutSearch();
            shortcutOverlayVisible = true;
            shortcutProcess.running = true;
        }
    }

    PwObjectTracker {
        objects: [root.audioSink]
    }

    Process {
        running: true
        command: ["nu", Quickshell.shellPath("health.nu")]
        stdout: SplitParser {
            onRead: data => root.updateHealth(data)
        }
    }

    Process {
        id: weatherProcess
        command: ["curl", "-fsS", "--max-time", "10", "https://wttr.in/Vienna?m&format=j1"]
        stdout: StdioCollector {
            onStreamFinished: root.updateWeather(text)
        }
    }

    Process {
        id: shortcutProcess
        command: ["hyprctl", "binds", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.shortcuts = JSON.parse(text).filter(binding => binding.has_description);
                } catch (error) {
                    console.warn(`Invalid Hyprland shortcut list: ${error}`);
                }
            }
        }
    }

    Process {
        id: networkStatusProcess
        running: true
        command: ["nmcli", "-t", "--escape", "yes", "-f", "NAME,TYPE,DEVICE",
            "connection", "show", "--active"]
        stdout: StdioCollector {
            onStreamFinished: root.updateNetworkStatus(text)
        }
    }

    Process {
        id: networkIpProcess
        stdout: StdioCollector {
            onStreamFinished: root.networkIp = text.trim().split("\n")[0].split("/")[0] || "--"
        }
    }

    Process {
        id: networkRadioProcess
        running: true
        command: ["nmcli", "-t", "-f", "WIFI,WIFI-HW", "radio"]
        stdout: StdioCollector {
            onStreamFinished: {
                const state = text.trim().split(":");
                root.wifiEnabled = state[0] === "enabled";
                root.wifiHardwareEnabled = state[1] === "enabled";
            }
        }
    }

    Process {
        id: wifiScanProcess
        command: ["nmcli", "-t", "--escape", "yes", "-f", "IN-USE,SSID,SIGNAL,SECURITY",
            "device", "wifi", "list", "--rescan", "yes"]
        stdout: StdioCollector {
            onStreamFinished: root.updateWifiNetworks(text)
        }
        stderr: StdioCollector { id: wifiScanStderr }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                root.wifiScanError = wifiScanStderr.text.trim();
        }
    }

    Process {
        running: true
        command: ["nmcli", "monitor"]
        stdout: SplitParser {
            onRead: root.refreshNetwork()
        }
    }

    Process {
        id: wifiToggleProcess
        onExited: (exitCode, exitStatus) => {
            root.refreshNetwork();
            if (exitCode === 0 && root.wifiToggleTarget)
                root.scanWifi();
            else if (exitCode === 0)
                root.wifiNetworks = [];
        }
    }

    IpcHandler {
        target: "shortcuts"
        function toggle(): void { root.toggleShortcutOverlay(); }
    }

    Timer {
        interval: 3600000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: weatherProcess.running = true
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bar
            required property ShellScreen modelData
            readonly property var pairedBluetoothDevices: root.bluetoothAdapter === null
                ? []
                : [...root.bluetoothAdapter.devices.values]
                    .filter(device => device.paired)
                    .sort((a, b) => a.name.localeCompare(b.name))
            readonly property int connectedBluetoothDevices: pairedBluetoothDevices
                .filter(device => device.connected).length
            property var pendingWifiNetwork: null
            property var connectingWifiNetwork: null
            property string wifiPassword: ""
            property string wifiConnectPassword: ""
            property bool wifiPasswordAttempt: false
            property string networkError: ""

            screen: modelData
            color: "transparent"
            implicitHeight: 32

            anchors {
                top: true
                left: true
                right: true
            }

            margins {
                top: 10
                left: 10
                right: 10
            }

            mask: Region {
                Region { item: leftIsland }
                Region { item: workspaceIsland }
                Region { item: rightIsland }
            }

            function isPersonalWifi(network): bool {
                return !network.security.includes("802.1X")
                    && (network.security.includes("WPA") || network.security.includes("SAE"));
            }

            function connectWifi(network): void {
                networkError = "";
                connectingWifiNetwork = network;
                wifiPasswordAttempt = false;
                wifiConnectProcess.exec(["nmcli", "--wait", "20", "device", "wifi", "connect", network.name]);
            }

            function submitWifiPassword(): void {
                if (pendingWifiNetwork === null || wifiPassword === "")
                    return;
                connectingWifiNetwork = pendingWifiNetwork;
                wifiConnectPassword = wifiPassword;
                wifiPasswordAttempt = true;
                pendingWifiNetwork = null;
                networkError = "";
                wifiConnectProcess.exec(["nmcli", "--ask", "--wait", "20", "device", "wifi",
                    "connect", connectingWifiNetwork.name]);
            }

            function closePopups(): void {
                batteryPopup.visible = false;
                healthPopup.visible = false;
                networkPopup.visible = false;
                audioPopup.visible = false;
                bluetoothPopup.visible = false;
                spotifyPopup.visible = false;
                calendarPopup.visible = false;
                weatherPopup.visible = false;
            }

            function togglePopup(popup): void {
                const show = !popup.visible;
                closePopups();
                popup.visible = show;
            }

            Process {
                id: wifiConnectProcess
                stdinEnabled: true
                stdout: StdioCollector {}
                stderr: StdioCollector { id: wifiConnectStderr }
                onStarted: {
                    if (bar.wifiPasswordAttempt) {
                        write(`${bar.wifiConnectPassword}\n`);
                        bar.wifiConnectPassword = "";
                        bar.wifiPassword = "";
                    }
                }
                onExited: (exitCode, exitStatus) => {
                    if (exitCode === 0) {
                        bar.pendingWifiNetwork = null;
                        bar.networkError = "";
                        root.refreshNetwork();
                        root.scanWifi();
                    } else if (bar.connectingWifiNetwork !== null
                        && bar.isPersonalWifi(bar.connectingWifiNetwork)) {
                        bar.pendingWifiNetwork = bar.connectingWifiNetwork;
                        bar.networkError = bar.wifiPasswordAttempt
                            ? wifiConnectStderr.text.trim() || "Incorrect password."
                            : "Password required.";
                        Qt.callLater(() => wifiPasswordField.forceActiveFocus());
                    } else {
                        bar.networkError = wifiConnectStderr.text.trim() || "Could not connect.";
                    }
                    bar.connectingWifiNetwork = null;
                    bar.wifiPasswordAttempt = false;
                    bar.wifiConnectPassword = "";
                }
            }

            Connections {
                target: networkPopup
                function onVisibleChanged(): void {
                    if (!networkPopup.visible) {
                        bar.pendingWifiNetwork = null;
                        bar.wifiPassword = "";
                        bar.networkError = "";
                    }
                }
            }

            Connections {
                target: root
                function onSpotifyPlayerChanged(): void {
                    if (root.spotifyPlayer === null)
                        spotifyPopup.visible = false;
                }
            }

            Rectangle {
                id: leftIsland
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: leftContent.implicitWidth + 24
                height: 32
                radius: 10
                color: "#2d353b"
                border.color: "#a7c080"
                border.width: 1

                Row {
                    id: leftContent
                    anchors.centerIn: parent
                    spacing: 6

                    BarButton {
                        id: batteryButton
                        visible: root.battery.ready && root.battery.isLaptopBattery
                        text: `${UPower.onBattery ? "󰁹" : "󰂄"} ${Math.round(root.battery.percentage * 100)}%`
                        active: batteryPopup.visible
                        onClicked: bar.togglePopup(batteryPopup)
                    }

                    WidgetSeparator { visible: batteryButton.visible }

                    BarButton {
                        id: healthButton
                        text: root.healthText
                        active: healthPopup.visible
                        onClicked: bar.togglePopup(healthPopup)
                    }

                    WidgetSeparator {}

                    BarButton {
                        id: networkButton
                        text: root.activeNetwork === null
                            ? "󰖪 Disconnected"
                            : `${root.activeNetwork.wifi ? "󰖩" : "󰈀"} ${root.activeNetwork.name}`
                        active: networkPopup.visible
                        onClicked: bar.togglePopup(networkPopup)
                    }

                    WidgetSeparator {}

                    BarButton {
                        id: audioButton
                        text: root.audioSink === null
                            ? "󰖁 --"
                            : root.audioSink.audio.muted
                                ? "MUTE"
                                : `󰕾 ${Math.round(root.audioSink.audio.volume * 100)}%`
                        active: audioPopup.visible
                        onClicked: bar.togglePopup(audioPopup)
                        onScrolled: direction => {
                            if (root.audioSink !== null && direction !== 0)
                                root.audioSink.audio.volume = Math.max(0, Math.min(1,
                                    root.audioSink.audio.volume + direction / 100));
                        }
                    }

                    WidgetSeparator {}

                    BarButton {
                        id: bluetoothButton
                        text: root.bluetoothAdapter === null || !root.bluetoothAdapter.enabled
                            ? "󰂲"
                            : `󰂯${bar.connectedBluetoothDevices > 0 ? ` ${bar.connectedBluetoothDevices}` : ""}`
                        active: bluetoothPopup.visible
                        onClicked: bar.togglePopup(bluetoothPopup)
                    }
                }
            }

            AttachedPopup {
                id: batteryPopup
                barWindow: bar
                tabButton: batteryButton
                tabXInBar: leftIsland.x + leftContent.x + batteryButton.x
                implicitWidth: 320
                bodyHeight: 170

                Column {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 10

                    BarText {
                        text: "Battery"
                        font.bold: true
                    }

                    BarText { text: `Charge ${Math.round(root.battery.percentage * 100)}%` }
                    BarText { text: `State ${UPowerDeviceState.toString(root.battery.state).replace(/([a-z])([A-Z])/g, "$1 $2")}` }
                    BarText {
                        text: root.battery.state === UPowerDeviceState.FullyCharged
                            ? "Remaining Fully charged"
                            : `Remaining ${root.formatDuration(root.battery.state === UPowerDeviceState.Charging
                                || root.battery.state === UPowerDeviceState.PendingCharge
                                ? root.battery.timeToFull : root.battery.timeToEmpty)}`
                    }
                    BarText {
                        text: `Health ${root.battery.healthSupported ? `${Math.round(root.battery.healthPercentage * 100)}%` : "Unavailable"}`
                    }
                }
            }

            AttachedPopup {
                id: healthPopup
                barWindow: bar
                tabButton: healthButton
                tabXInBar: leftIsland.x + leftContent.x + healthButton.x
                implicitWidth: 380
                bodyHeight: 280

                Column {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    BarText {
                        text: "System Health (last 10 minutes)"
                        font.bold: true
                    }

                    UsageGraph {
                        width: parent.width
                        height: 90
                        label: "CPU"
                        value: root.health.cpu
                        values: root.cpuHistory
                        accent: "#7fbbb3"
                    }

                    UsageGraph {
                        width: parent.width
                        height: 90
                        label: "RAM"
                        value: root.health.memory
                        values: root.memoryHistory
                        accent: "#dbbc7f"
                    }

                    BarText {
                        text: `Temperature ${root.health.temperature ?? "--"}°C    Disk ${root.health.disk ?? "--"}%`
                    }
                }
            }

            AttachedPopup {
                id: networkPopup
                barWindow: bar
                tabButton: networkButton
                tabXInBar: leftIsland.x + leftContent.x + networkButton.x
                implicitWidth: 380
                bodyHeight: 430

                Column {
                    id: networkPopupLayout
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 10

                    Row {
                        width: parent.width
                        spacing: 8

                        BarText {
                            width: parent.width - wifiToggle.width - parent.spacing
                            text: root.activeNetwork === null
                                ? "Network: Disconnected"
                                : `${root.activeNetwork.name} · ${root.networkIp}`
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        ActionButton {
                            id: wifiToggle
                            width: 86
                            enabled: root.wifiHardwareEnabled && !wifiToggleProcess.running
                            text: root.wifiEnabled ? "Wi-Fi off" : "Wi-Fi on"
                            onClicked: {
                                root.wifiToggleTarget = !root.wifiEnabled;
                                wifiToggleProcess.exec(["nmcli", "radio", "wifi",
                                    root.wifiToggleTarget ? "on" : "off"]);
                            }
                        }
                    }

                    BarText {
                        visible: bar.networkError !== "" || root.wifiScanError !== ""
                        width: parent.width
                        text: bar.networkError || root.wifiScanError
                        color: "#e67e80"
                        wrapMode: Text.Wrap
                    }

                    ListView {
                        width: parent.width
                        height: bar.pendingWifiNetwork === null ? 250 : 168
                        clip: true
                        model: ScriptModel { values: root.wifiNetworks }

                        delegate: Rectangle {
                            id: wifiRow
                            required property var modelData
                            width: ListView.view.width
                            height: 40
                            radius: 8
                            color: wifiMouse.containsMouse ? "#3d484d" : "#003d484d"

                            BarText {
                                anchors.left: parent.left
                                anchors.right: wifiAction.left
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: 8
                                anchors.rightMargin: 10
                                text: `${modelData.security === "--" ? "" : "󰌾 "}${modelData.name}`
                                elide: Text.ElideRight
                            }

                            BarText {
                                id: wifiAction
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.rightMargin: 8
                                text: modelData.connected ? "Connected"
                                    : bar.connectingWifiNetwork !== null
                                        && bar.connectingWifiNetwork.name === modelData.name ? "Connecting…"
                                    : `${modelData.signal}%`
                                color: modelData.connected ? "#a7c080" : "#d3c6aa"
                            }

                            MouseArea {
                                id: wifiMouse
                                anchors.fill: parent
                                enabled: !wifiRow.modelData.connected && bar.connectingWifiNetwork === null
                                hoverEnabled: true
                                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: bar.connectWifi(wifiRow.modelData)
                            }
                        }

                        BarText {
                            anchors.centerIn: parent
                            visible: root.wifiNetworks.length === 0
                            text: !root.wifiHardwareEnabled ? "No Wi-Fi adapter"
                                : root.wifiEnabled ? "Scanning…" : "Wi-Fi is off"
                            color: "#859289"
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: 8
                        visible: bar.pendingWifiNetwork !== null

                        BarText {
                            text: `Password for ${bar.pendingWifiNetwork === null ? "" : bar.pendingWifiNetwork.name}`
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        TextField {
                            id: wifiPasswordField
                            width: parent.width
                            height: 34
                            leftPadding: 12
                            rightPadding: 12
                            echoMode: TextInput.Password
                            passwordCharacter: "●"
                            placeholderText: "Wi-Fi password"
                            text: bar.wifiPassword
                            color: "#d3c6aa"
                            placeholderTextColor: "#859289"
                            selectionColor: "#a7c080"
                            selectedTextColor: "#2d353b"
                            font.family: "JetBrainsMonoNL Nerd Font Mono"
                            font.pixelSize: 13
                            onTextEdited: bar.wifiPassword = text
                            onAccepted: bar.submitWifiPassword()

                            background: Rectangle {
                                radius: 8
                                color: "#232a2e"
                                border.color: "#a7c080"
                                border.width: 1
                            }
                        }

                        Row {
                            width: parent.width
                            spacing: 8

                            ActionButton {
                                width: (parent.width - parent.spacing) / 2
                                text: "Cancel"
                                onClicked: {
                                    bar.pendingWifiNetwork = null;
                                    bar.wifiPassword = "";
                                }
                            }

                            ActionButton {
                                width: (parent.width - parent.spacing) / 2
                                enabled: bar.wifiPassword !== ""
                                text: "Connect"
                                onClicked: bar.submitWifiPassword()
                            }
                        }
                    }

                    ActionButton {
                        width: parent.width
                        text: "Open NetworkManager settings"
                        onClicked: {
                            networkPopup.visible = false;
                            Quickshell.execDetached(["nm-connection-editor"]);
                        }
                    }
                }

                onOpened: {
                    bar.pendingWifiNetwork = null;
                    bar.wifiPassword = "";
                    bar.networkError = "";
                    root.refreshNetwork();
                    if (root.wifiEnabled)
                        root.scanWifi();
                }
            }

            AttachedPopup {
                id: audioPopup
                barWindow: bar
                tabButton: audioButton
                tabXInBar: leftIsland.x + leftContent.x + audioButton.x
                implicitWidth: 340
                bodyHeight: 160

                Column {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 10

                        BarText {
                            width: parent.width
                            text: root.audioSink === null ? "Audio: No output" : root.audioSink.description
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        BarText {
                            text: `Volume ${root.audioSink === null ? "--" : Math.round(root.audioSink.audio.volume * 100)}%`
                        }

                        BarSlider {
                            id: volumeSlider
                            width: parent.width
                            from: 0
                            to: 1
                            value: root.audioSink === null ? 0 : root.audioSink.audio.volume
                            enabled: root.audioSink !== null
                            onMoved: root.audioSink.audio.volume = value
                        }

                        ActionButton {
                            width: parent.width
                            text: root.audioSink !== null && root.audioSink.audio.muted ? "Unmute" : "Mute"
                            onClicked: {
                                if (root.audioSink !== null)
                                    root.audioSink.audio.muted = !root.audioSink.audio.muted;
                            }
                        }
                }
            }

            AttachedPopup {
                id: bluetoothPopup
                barWindow: bar
                tabButton: bluetoothButton
                tabXInBar: leftIsland.x + leftContent.x + bluetoothButton.x
                implicitWidth: 320
                bodyHeight: Math.min(320, 58 + Math.max(1, bar.pairedBluetoothDevices.length) * 40)

                BarText {
                        id: bluetoothTitle
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.margins: 14
                        text: `Bluetooth: ${root.bluetoothAdapter !== null && root.bluetoothAdapter.enabled ? "On" : "Off"}`
                        font.bold: true
                    }

                    ListView {
                        anchors.top: bluetoothTitle.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.topMargin: 8
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        anchors.bottomMargin: 10
                        clip: true
                        model: ScriptModel {
                            values: bar.pairedBluetoothDevices
                        }

                        delegate: Rectangle {
                            id: bluetoothDeviceRow
                            required property BluetoothDevice modelData
                            width: ListView.view.width
                            height: 40
                            radius: 8
                            color: bluetoothDeviceMouse.containsMouse ? "#3d484d" : "#003d484d"

                            Behavior on color {
                                ColorAnimation { duration: 100 }
                            }

                            BarText {
                                anchors.left: parent.left
                                anchors.right: bluetoothDeviceAction.left
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: 8
                                anchors.rightMargin: 10
                                text: `${modelData.connected ? "● " : ""}${modelData.name}${modelData.batteryAvailable ? ` (${Math.round(modelData.battery * 100)}%)` : ""}`
                                elide: Text.ElideRight
                            }

                            BarText {
                                id: bluetoothDeviceAction
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.rightMargin: 8
                                text: modelData.connected ? "Disconnect" : "Connect"
                                color: modelData.connected ? "#a7c080" : "#d3c6aa"
                            }

                            MouseArea {
                                id: bluetoothDeviceMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: modelData.connected ? modelData.disconnect() : modelData.connect()
                            }
                        }

                        BarText {
                            anchors.centerIn: parent
                            visible: bar.pairedBluetoothDevices.length === 0
                            text: "No paired devices"
                            color: "#859289"
                        }
                }
            }

            Rectangle {
                id: workspaceIsland
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                width: workspaceRow.implicitWidth + 8
                height: 32
                radius: 10
                color: "#2d353b"
                border.color: "#a7c080"
                border.width: 1

                Row {
                    id: workspaceRow
                    anchors.centerIn: parent
                    spacing: 4

                    Repeater {
                        model: ScriptModel {
                            values: [...WindowManager.screenProjection(bar.screen).windowsets]
                                .filter(workspace => workspace.shouldDisplay)
                                .sort((a, b) => (a.coordinates[0] ?? 0) - (b.coordinates[0] ?? 0))
                        }

                        Rectangle {
                            id: workspaceButton
                            required property Windowset modelData
                            width: 24
                            height: 24
                            radius: 8
                            color: modelData.active ? "#a7c080"
                                : workspaceMouse.containsMouse ? "#3d484d" : "#003d484d"

                            Behavior on color {
                                ColorAnimation { duration: 100 }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: modelData.name
                                color: modelData.active ? "#2d353b" : "#d3c6aa"
                                font.family: "JetBrainsMonoNL Nerd Font Mono"
                                font.pixelSize: 13
                                font.bold: modelData.active
                            }

                            MouseArea {
                                id: workspaceMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: modelData.activate()
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: rightIsland
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: rightContent.implicitWidth + 24
                height: 32
                radius: 10
                color: "#2d353b"
                border.color: "#a7c080"
                border.width: 1

                Row {
                    id: rightContent
                    anchors.centerIn: parent
                    spacing: 6

                    BarButton {
                        id: spotifyButton
                        visible: root.spotifyPlayer !== null
                        text: {
                            if (root.spotifyPlayer === null)
                                return "";
                            const title = root.spotifyPlayer.trackTitle || "Spotify";
                            const shortTitle = title.length > 28 ? `${title.slice(0, 27)}…` : title;
                            const state = root.spotifyPlayer.playbackState === MprisPlaybackState.Playing
                                ? "󰐊" : root.spotifyPlayer.playbackState === MprisPlaybackState.Paused ? "󰏤" : "󰓛";
                            const volume = root.spotifyPlayer.volumeSupported
                                ? `${Math.round(root.spotifyPlayer.volume * 100)}%` : "--";
                            return `${state} ${shortTitle}  󰕾 ${volume}`;
                        }
                        active: spotifyPopup.visible
                        onClicked: bar.togglePopup(spotifyPopup)
                        onScrolled: direction => {
                            if (root.spotifyPlayer !== null && root.spotifyPlayer.volumeSupported && direction !== 0)
                                root.spotifyPlayer.volume = Math.max(0, Math.min(1,
                                    root.spotifyPlayer.volume + direction / 100));
                        }
                    }

                    WidgetSeparator { visible: spotifyButton.visible }

                    BarButton {
                        id: clockButton
                        text: Qt.formatDateTime(clock.date, "ddd dd MMM HH:mm:ss")
                        active: calendarPopup.visible
                        onClicked: bar.togglePopup(calendarPopup)
                    }

                    WidgetSeparator {}

                    BarButton {
                        id: weatherButton
                        text: root.weatherText
                        active: weatherPopup.visible
                        onClicked: bar.togglePopup(weatherPopup)
                    }
                }
            }

            AttachedPopup {
                id: spotifyPopup
                barWindow: bar
                tabButton: spotifyButton
                tabXInBar: rightIsland.x + rightContent.x + spotifyButton.x
                implicitWidth: 440
                bodyHeight: spotifyPopupLayout.implicitHeight + 34

                Timer {
                    interval: 1000
                    running: spotifyPopup.visible && root.spotifyPlayer !== null && root.spotifyPlayer.isPlaying
                    repeat: true
                    triggeredOnStart: true
                    onTriggered: root.spotifyPlayer.positionChanged()
                }

                Column {
                    id: spotifyPopupLayout
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                        Row {
                            width: parent.width
                            height: 144
                            spacing: 14

                            Rectangle {
                                width: 144
                                height: 144
                                radius: 8
                                color: "#232a2e"
                                clip: true

                                Image {
                                    id: spotifyCover
                                    anchors.fill: parent
                                    source: root.spotifyPlayer === null ? "" : root.spotifyPlayer.trackArtUrl
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                }

                                BarText {
                                    anchors.centerIn: parent
                                    visible: spotifyCover.status !== Image.Ready
                                    text: "󰝚"
                                    color: "#859289"
                                    font.pixelSize: 42
                                }
                            }

                            Column {
                                width: parent.width - 158
                                spacing: 8

                                BarText {
                                    width: parent.width
                                    text: root.spotifyPlayer === null ? "Nothing playing"
                                        : root.spotifyPlayer.trackTitle || "Unknown song"
                                    font.bold: true
                                    font.pixelSize: 16
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 2
                                    elide: Text.ElideRight
                                }

                                BarText {
                                    width: parent.width
                                    text: root.spotifyPlayer === null ? ""
                                        : root.spotifyPlayer.trackArtist || "Unknown artist"
                                    color: "#a7c080"
                                    elide: Text.ElideRight
                                }

                                BarText {
                                    width: parent.width
                                    visible: root.spotifyPlayer !== null && root.spotifyPlayer.trackAlbum !== ""
                                    text: root.spotifyPlayer === null ? "" : `Album  ${root.spotifyPlayer.trackAlbum}`
                                    color: "#859289"
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 3
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        Column {
                            width: parent.width
                            spacing: 3

                            Item {
                                width: parent.width
                                height: 18

                                BarText {
                                    anchors.left: parent.left
                                    text: root.formatTrackTime(root.spotifyPlayer === null ? 0 : root.spotifyPlayer.position)
                                    color: "#859289"
                                }

                                BarText {
                                    anchors.right: parent.right
                                    text: root.formatTrackTime(root.spotifyPlayer === null ? 0 : root.spotifyPlayer.length)
                                    color: "#859289"
                                }
                            }

                            BarSlider {
                                id: spotifyProgress
                                width: parent.width
                                from: 0
                                to: root.spotifyPlayer === null ? 1 : Math.max(1, root.spotifyPlayer.length)
                                value: root.spotifyPlayer === null ? 0
                                    : Math.min(root.spotifyPlayer.position, root.spotifyPlayer.length)
                                enabled: root.spotifyPlayer !== null && root.spotifyPlayer.canSeek
                                    && root.spotifyPlayer.positionSupported && root.spotifyPlayer.lengthSupported
                                onPressedChanged: {
                                    if (!pressed && root.spotifyPlayer !== null)
                                        root.spotifyPlayer.position = value;
                                }
                            }
                        }

                        Item {
                            width: parent.width
                            height: 42

                            Row {
                                anchors.centerIn: parent
                                spacing: 12

                                MediaControlButton {
                                    text: "󰒟"
                                    accessibleName: root.spotifyPlayer !== null && root.spotifyPlayer.shuffle
                                        ? "Disable shuffle" : "Enable shuffle"
                                    active: root.spotifyPlayer !== null && root.spotifyPlayer.shuffle
                                    enabled: root.spotifyPlayer !== null && root.spotifyPlayer.canControl
                                        && root.spotifyPlayer.shuffleSupported
                                    onClicked: root.spotifyPlayer.shuffle = !root.spotifyPlayer.shuffle
                                }

                                MediaControlButton {
                                    text: "󰒮"
                                    accessibleName: "Previous track"
                                    enabled: root.spotifyPlayer !== null && root.spotifyPlayer.canGoPrevious
                                    onClicked: root.spotifyPlayer.previous()
                                }

                                MediaControlButton {
                                    width: 48
                                    text: root.spotifyPlayer !== null && root.spotifyPlayer.isPlaying ? "󰏤" : "󰐊"
                                    accessibleName: root.spotifyPlayer !== null && root.spotifyPlayer.isPlaying ? "Pause" : "Play"
                                    enabled: root.spotifyPlayer !== null && root.spotifyPlayer.canTogglePlaying
                                    onClicked: root.spotifyPlayer.togglePlaying()
                                }

                                MediaControlButton {
                                    text: "󰒭"
                                    accessibleName: "Next track"
                                    enabled: root.spotifyPlayer !== null && root.spotifyPlayer.canGoNext
                                    onClicked: root.spotifyPlayer.next()
                                }

                                MediaControlButton {
                                    text: root.spotifyPlayer !== null && root.spotifyPlayer.loopState === MprisLoopState.Track
                                        ? "󰑘" : "󰑖"
                                    accessibleName: root.spotifyPlayer === null ? "Repeat"
                                        : `Repeat ${MprisLoopState.toString(root.spotifyPlayer.loopState)}`
                                    active: root.spotifyPlayer !== null && root.spotifyPlayer.loopState !== MprisLoopState.None
                                    enabled: root.spotifyPlayer !== null && root.spotifyPlayer.canControl
                                        && root.spotifyPlayer.loopSupported
                                    onClicked: root.spotifyPlayer.loopState = root.spotifyPlayer.loopState === MprisLoopState.None
                                        ? MprisLoopState.Playlist
                                        : root.spotifyPlayer.loopState === MprisLoopState.Playlist
                                            ? MprisLoopState.Track : MprisLoopState.None
                                }
                            }
                        }

                        Column {
                            width: parent.width
                            spacing: 3

                            BarText {
                                text: root.spotifyPlayer !== null && root.spotifyPlayer.volumeSupported
                                    ? `󰕾  Volume ${Math.round(root.spotifyPlayer.volume * 100)}%`
                                    : "󰕾  Volume --"
                            }

                            BarSlider {
                                width: parent.width
                                from: 0
                                to: 1
                                value: root.spotifyPlayer === null ? 0 : root.spotifyPlayer.volume
                                enabled: root.spotifyPlayer !== null && root.spotifyPlayer.canControl
                                    && root.spotifyPlayer.volumeSupported
                                onMoved: root.spotifyPlayer.volume = value
                            }
                        }
                }

                onOpened: if (root.spotifyPlayer !== null) root.spotifyPlayer.positionChanged()
            }

            AttachedPopup {
                id: calendarPopup
                property date displayedMonth: clock.date

                function changeMonth(offset): void {
                    displayedMonth = new Date(displayedMonth.getFullYear(), displayedMonth.getMonth() + offset, 1);
                }

                barWindow: bar
                tabButton: clockButton
                tabXInBar: rightIsland.x + rightContent.x + clockButton.x
                implicitWidth: 340
                bodyHeight: 320

                Column {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 6

                        Item {
                            width: parent.width
                            height: 24

                            BarText {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                text: Qt.formatDate(calendarPopup.displayedMonth, "MMMM yyyy")
                                font.bold: true
                            }

                            MediaControlButton {
                                id: nextMonthButton
                                anchors.right: parent.right
                                width: 24
                                height: 24
                                text: "↓"
                                accessibleName: "Next month"
                                onClicked: calendarPopup.changeMonth(1)
                            }

                            MediaControlButton {
                                anchors.right: nextMonthButton.left
                                anchors.rightMargin: 4
                                width: 24
                                height: 24
                                text: "↑"
                                accessibleName: "Previous month"
                                onClicked: calendarPopup.changeMonth(-1)
                            }
                        }

                        DayOfWeekRow {
                            width: parent.width
                            height: 24
                            locale: Qt.locale()
                            delegate: BarText {
                                required property string shortName
                                text: shortName
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        MonthGrid {
                            id: monthGrid
                            width: parent.width
                            height: 228
                            month: calendarPopup.displayedMonth.getMonth()
                            year: calendarPopup.displayedMonth.getFullYear()
                            locale: Qt.locale()
                            delegate: Rectangle {
                                required property var model
                                radius: 8
                                color: model.today ? "#a7c080" : "transparent"

                                BarText {
                                    anchors.centerIn: parent
                                    text: model.day
                                    color: model.today ? "#2d353b"
                                        : model.month === monthGrid.month ? "#d3c6aa" : "#859289"
                                    font.bold: model.today
                                }
                            }
                        }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    onWheel: wheel => calendarPopup.changeMonth(-Math.sign(wheel.angleDelta.y))
                }

                onOpened: displayedMonth = clock.date
            }

            AttachedPopup {
                id: weatherPopup
                barWindow: bar
                tabButton: weatherButton
                tabXInBar: rightIsland.x + rightContent.x + weatherButton.x
                implicitWidth: 390
                bodyHeight: weatherPopupLayout.implicitHeight + 34

                Column {
                    id: weatherPopupLayout
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 9

                        BarText {
                            width: parent.width
                            text: `Vienna  ${root.weather.temperature}°C  ${root.weather.description}`
                            font.bold: true
                            elide: Text.ElideRight
                        }
                        BarText {
                            text: `Feels ${root.weather.feelsLike}°C  Humidity ${root.weather.humidity}%  Wind ${root.weather.wind} km/h`
                        }
                        BarText {
                            text: "Short forecast"
                            font.bold: true
                        }

                        Repeater {
                            model: ScriptModel { values: root.forecast }

                            Row {
                                required property var modelData
                                width: parent.width
                                spacing: 10

                                BarText {
                                    width: 90
                                    text: Qt.formatDate(new Date(`${modelData.date}T12:00:00`), "ddd dd MMM")
                                }
                                BarText {
                                    width: 75
                                    text: `${modelData.min}° / ${modelData.max}°`
                                }
                                BarText {
                                    width: parent.width - 185
                                    text: modelData.description
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        BarText {
                            visible: root.forecast.length === 0
                            text: "Forecast unavailable"
                            color: "#859289"
                        }
                }
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: shortcutOverlay
            required property ShellScreen modelData

            screen: modelData
            visible: root.shortcutOverlayVisible
            color: "#e61e2326"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            FocusScope {
                id: shortcutFocus
                anchors.fill: parent
                focus: true

                Item {
                    id: shortcutKeyHandler
                    anchors.fill: parent
                    focus: true
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Slash && event.modifiers === Qt.NoModifier) {
                            root.shortcutSearchActive = true;
                            shortcutSearchField.forceActiveFocus();
                        } else {
                            root.closeShortcutOverlay();
                        }
                        event.accepted = true;
                    }
                }

                Rectangle {
                    id: shortcutCard

                    anchors.centerIn: parent
                    width: Math.min(parent.width - 80, 1800)
                    height: Math.min(parent.height - 80, 980)
                    radius: 18
                    color: "#2d353b"
                    border.color: "#a7c080"
                    border.width: 1

                    BarText {
                        id: shortcutTitle
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.topMargin: 22
                        anchors.leftMargin: 24
                        text: "Keyboard shortcuts"
                        font.pixelSize: 20
                        font.bold: true
                    }

                    BarText {
                        anchors.right: parent.right
                        anchors.verticalCenter: shortcutTitle.verticalCenter
                        anchors.rightMargin: 24
                        visible: !root.shortcutSearchActive
                        text: "Press / to search · any other key or click to close"
                        color: "#859289"
                    }

                    TextField {
                        id: shortcutSearchField
                        anchors.right: parent.right
                        anchors.verticalCenter: shortcutTitle.verticalCenter
                        anchors.rightMargin: 24
                        visible: root.shortcutSearchActive
                        width: 420
                        height: 34
                        leftPadding: 12
                        rightPadding: 12
                        placeholderText: "Search keys or effects…"
                        text: root.shortcutSearch
                        color: "#d3c6aa"
                        placeholderTextColor: "#859289"
                        selectionColor: "#a7c080"
                        selectedTextColor: "#2d353b"
                        font.family: "JetBrainsMonoNL Nerd Font Mono"
                        font.pixelSize: 13
                        onTextEdited: root.shortcutSearch = text
                        Keys.onEscapePressed: event => {
                            root.resetShortcutSearch();
                            shortcutKeyHandler.forceActiveFocus();
                            event.accepted = true;
                        }

                        background: Rectangle {
                            radius: 8
                            color: "#232a2e"
                            border.color: "#a7c080"
                            border.width: 1
                        }
                    }

                    Row {
                        id: shortcutColumns
                        anchors.top: shortcutTitle.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.topMargin: 18
                        anchors.leftMargin: 24
                        anchors.rightMargin: 24
                        anchors.bottomMargin: 18
                        spacing: 32

                        Repeater {
                            model: ScriptModel { values: [0, 1, 2] }

                            Column {
                                id: shortcutColumn
                                required property int modelData
                                width: (shortcutColumns.width - shortcutColumns.spacing * 2) / 3
                                spacing: 14

                                Repeater {
                                    model: ScriptModel {
                                        values: root.shortcutGroups.filter(group =>
                                            group.column === shortcutColumn.modelData && group.shortcuts.length > 0)
                                    }

                                    Column {
                                        id: shortcutGroupColumn
                                        required property var modelData
                                        width: shortcutColumn.width
                                        spacing: 2

                                        BarText {
                                            width: parent.width
                                            height: 24
                                            text: shortcutGroupColumn.modelData.title
                                            color: "#7fbbb3"
                                            font.bold: true
                                            font.pixelSize: 14
                                        }

                                        Repeater {
                                            model: ScriptModel { values: shortcutGroupColumn.modelData.shortcuts }

                                            Item {
                                                id: shortcutRow
                                                required property var modelData
                                                width: shortcutGroupColumn.width
                                                height: 26

                                                BarText {
                                                    anchors.left: parent.left
                                                    width: 180
                                                    text: root.highlightMatch(root.shortcutLabel(shortcutRow.modelData),
                                                        root.shortcutSearchQuery.replace(/\s/g, ""))
                                                    textFormat: Text.RichText
                                                    color: "#a7c080"
                                                    font.bold: true
                                                }

                                                BarText {
                                                    anchors.left: parent.left
                                                    anchors.right: parent.right
                                                    anchors.leftMargin: 190
                                                    text: `${root.highlightMatch(shortcutRow.modelData.description, root.shortcutSearchQuery)}`
                                                        + (shortcutRow.modelData.submap === "" ? "" : `  [${shortcutRow.modelData.submap}]`)
                                                    textFormat: Text.RichText
                                                    elide: Text.ElideRight
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    BarText {
                        anchors.centerIn: parent
                        visible: root.filteredShortcuts.length === 0
                        text: "No matching shortcuts"
                        color: "#859289"
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onPressed: root.closeShortcutOverlay()
                }
            }

            onVisibleChanged: {
                if (visible)
                    shortcutKeyHandler.forceActiveFocus();
            }
        }
    }

    component AttachedPopup: PopupWindow {
        id: popup
        required property var barWindow
        required property Item tabButton
        required property real tabXInBar
        required property real bodyHeight
        default property alias bodyData: body.data
        readonly property real popupX: Math.max(0, Math.min(barWindow.width - width,
            tabXInBar + tabButton.width / 2 - width / 2))
        readonly property real tabX: tabXInBar - popupX
        readonly property real tabWidth: tabButton.width
        readonly property real bodyTop: barWindow.height - 1
        readonly property real shoulder: width > tabWidth ? tabButton.radius : 0
        signal opened()

        anchor.window: barWindow
        anchor.rect.x: popupX
        anchor.rect.y: 0
        implicitHeight: bodyTop + bodyHeight
        color: "transparent"
        grabFocus: true

        mask: Region {
            Region {
                x: popup.tabX
                width: popup.tabWidth
                height: popup.bodyTop
            }
            Region {
                y: popup.bodyTop
                width: popup.width
                height: popup.height - y
            }
        }

        Item {
            id: popupFocus
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: popup.visible = false

            Canvas {
                id: popupShape
                anchors.fill: parent

                onPaint: {
                    const ctx = getContext("2d");
                    const half = 0.5;
                    const left = half;
                    const right = width - half;
                    const top = popup.bodyTop + half;
                    const bottom = height - half;
                    const tabLeft = popup.tabX + half;
                    const tabRight = popup.tabX + popup.tabWidth - half;
                    const tabTop = half;
                    const tabRadius = popup.tabButton.radius;
                    const bodyRadius = 10;
                    const leftShoulder = Math.min(popup.shoulder,
                        Math.max(0, tabLeft - left - bodyRadius));
                    const rightShoulder = Math.min(popup.shoulder,
                        Math.max(0, right - bodyRadius - tabRight));

                    ctx.clearRect(0, 0, width, height);
                    ctx.fillStyle = "#2d353b";
                    ctx.strokeStyle = "#a7c080";
                    ctx.beginPath();
                    ctx.moveTo(left, top + bodyRadius);
                    ctx.quadraticCurveTo(left, top, left + bodyRadius, top);
                    ctx.lineTo(tabLeft - leftShoulder, top);
                    ctx.quadraticCurveTo(tabLeft, top, tabLeft, top - leftShoulder);
                    ctx.lineTo(tabLeft, tabTop + tabRadius);
                    ctx.quadraticCurveTo(tabLeft, tabTop, tabLeft + tabRadius, tabTop);
                    ctx.lineTo(tabRight - tabRadius, tabTop);
                    ctx.quadraticCurveTo(tabRight, tabTop, tabRight, tabTop + tabRadius);
                    ctx.lineTo(tabRight, top - rightShoulder);
                    ctx.quadraticCurveTo(tabRight, top, tabRight + rightShoulder, top);
                    ctx.lineTo(right - bodyRadius, top);
                    ctx.quadraticCurveTo(right, top, right, top + bodyRadius);
                    ctx.lineTo(right, bottom - bodyRadius);
                    ctx.quadraticCurveTo(right, bottom, right - bodyRadius, bottom);
                    ctx.lineTo(left + bodyRadius, bottom);
                    ctx.quadraticCurveTo(left, bottom, left, bottom - bodyRadius);
                    ctx.closePath();
                    ctx.fill();
                    ctx.save();
                    ctx.clip();
                    ctx.lineWidth = 2;
                    ctx.stroke();
                    ctx.restore();
                }

                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                onVisibleChanged: if (visible) requestPaint()
            }

            BarText {
                x: popup.tabX
                y: Math.round((popup.bodyTop - popup.tabButton.height) / 2)
                width: popup.tabWidth
                height: popup.tabButton.height
                text: popup.tabButton.text
                horizontalAlignment: Text.AlignHCenter
            }

            MouseArea {
                x: popup.tabX
                width: popup.tabWidth
                height: popup.bodyTop
                cursorShape: Qt.PointingHandCursor
                onClicked: popup.visible = false
                onWheel: wheel => popup.tabButton.scrolled(Math.sign(wheel.angleDelta.y))
            }

            Item {
                id: body
                x: 1
                y: popup.bodyTop + 1
                width: parent.width - 2
                height: popup.bodyHeight - 2
            }
        }

        onVisibleChanged: {
            if (visible) {
                popupShape.requestPaint();
                popupFocus.forceActiveFocus();
                opened();
            }
        }
        onTabXChanged: popupShape.requestPaint()
        onTabWidthChanged: popupShape.requestPaint()
    }

    component BarText: Text {
        color: "#d3c6aa"
        font.family: "JetBrainsMonoNL Nerd Font Mono"
        font.pixelSize: 13
        verticalAlignment: Text.AlignVCenter
    }

    component WidgetSeparator: BarText {
        y: Math.round((parent.height - height) / 2)
        text: "·"
        color: "#859289"
    }

    component BarButton: Rectangle {
        id: button
        property alias text: buttonLabel.text
        property bool active: false
        signal clicked()
        signal scrolled(int direction)

        width: buttonLabel.implicitWidth + 12
        height: 24
        radius: 8
        color: buttonMouse.containsMouse || active ? "#3d484d" : "#003d484d"

        Behavior on color {
            ColorAnimation { duration: 100 }
        }

        BarText {
            id: buttonLabel
            anchors.centerIn: parent
        }

        MouseArea {
            id: buttonMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.clicked()
            onWheel: wheel => button.scrolled(Math.sign(wheel.angleDelta.y))
        }
    }

    component BarSlider: Slider {
        id: slider
        height: 24

        background: Rectangle {
            x: slider.leftPadding
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            width: slider.availableWidth
            height: 4
            radius: 2
            color: "#475258"

            Rectangle {
                width: slider.visualPosition * parent.width
                height: parent.height
                radius: parent.radius
                color: "#a7c080"
            }
        }

        handle: Rectangle {
            x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            width: 14
            height: 14
            radius: 7
            color: slider.pressed ? "#d3c6aa" : "#a7c080"
        }
    }

    component MediaControlButton: Rectangle {
        id: mediaAction
        property alias text: mediaActionLabel.text
        property string accessibleName: "Media control"
        property bool active: false
        signal clicked()

        width: 40
        height: 40
        radius: 12
        color: mediaActionMouse.containsMouse ? "#475258" : "#00475258"
        opacity: enabled ? 1 : 0.35
        activeFocusOnTab: enabled
        Accessible.role: Accessible.Button
        Accessible.name: accessibleName

        Behavior on color {
            ColorAnimation { duration: 100 }
        }

        BarText {
            id: mediaActionLabel
            anchors.centerIn: parent
            color: mediaAction.active ? "#a7c080" : "#d3c6aa"
            font.pixelSize: 20
        }

        MouseArea {
            id: mediaActionMouse
            anchors.fill: parent
            enabled: mediaAction.enabled
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: mediaAction.clicked()
        }

        Keys.onSpacePressed: clicked()
        Keys.onReturnPressed: clicked()
    }

    component ActionButton: Rectangle {
        id: action
        property alias text: actionLabel.text
        signal clicked()

        height: 32
        radius: 8
        color: actionMouse.containsMouse ? "#475258" : "#3d484d"

        Behavior on color {
            ColorAnimation { duration: 100 }
        }

        BarText {
            id: actionLabel
            anchors.centerIn: parent
            color: "#a7c080"
        }

        MouseArea {
            id: actionMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: action.clicked()
        }
    }

    component UsageGraph: Item {
        id: graphRoot
        required property string label
        required property var value
        required property var values
        required property color accent

        BarText {
            text: `${graphRoot.label} ${graphRoot.value ?? "--"}%`
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 66
            radius: 6
            color: "#232a2e"

            Canvas {
                id: graph
                anchors.fill: parent
                anchors.margins: 4

                onPaint: {
                    const ctx = getContext("2d");
                    const samples = graphRoot.values;
                    ctx.clearRect(0, 0, width, height);
                    ctx.lineWidth = 1;
                    ctx.strokeStyle = "#475258";

                    for (let percent = 25; percent < 100; percent += 25) {
                        const y = height * (1 - percent / 100);
                        ctx.beginPath();
                        ctx.moveTo(0, y);
                        ctx.lineTo(width, y);
                        ctx.stroke();
                    }

                    if (samples.length < 2)
                        return;

                    ctx.lineWidth = 2;
                    ctx.strokeStyle = graphRoot.accent;
                    ctx.beginPath();

                    for (let i = 0; i < samples.length; i++) {
                        const x = width - (samples.length - 1 - i) * width / 119;
                        const y = height * (1 - Math.max(0, Math.min(100, samples[i])) / 100);
                        if (i === 0)
                            ctx.moveTo(x, y);
                        else
                            ctx.lineTo(x, y);
                    }

                    ctx.stroke();
                }

                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
            }
        }

        onValuesChanged: graph.requestPaint()
    }
}
