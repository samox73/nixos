import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.WindowManager

ShellRoot {
    id: root

    property var health: ({ cpu: null, memory: null, temperature: null, disk: null })
    property var cpuHistory: []
    property var memoryHistory: []
    property var weather: ({ temperature: "--", feelsLike: "--", description: "Unavailable", humidity: "--", wind: "--" })
    property var forecast: []
    property string weatherText: "Vienna: --"
    readonly property var audioSink: Pipewire.defaultAudioSink
    readonly property var battery: UPower.displayDevice
    readonly property var bluetoothAdapter: Bluetooth.defaultAdapter
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

    function formatDuration(seconds): string {
        if (seconds <= 0)
            return "Calculating";
        return `${Math.floor(seconds / 3600)}h ${Math.floor(seconds % 3600 / 60)}m`;
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
            readonly property var activeNetwork: connectedNetwork()
            property string networkIp: "--"

            onActiveNetworkChanged: {
                networkIp = "--";
                if (networkPopup.visible && activeNetwork !== null)
                    networkIpProcess.running = true;
            }

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

            function connectedNetwork(): var {
                for (const device of Networking.devices.values) {
                    for (const network of device.networks.values) {
                        if (network.connected)
                            return network;
                    }
                }
                return null;
            }

            function closePopups(): void {
                batteryPopup.visible = false;
                healthPopup.visible = false;
                networkPopup.visible = false;
                audioPopup.visible = false;
                bluetoothPopup.visible = false;
                calendarPopup.visible = false;
                weatherPopup.visible = false;
            }

            function togglePopup(popup): void {
                const show = !popup.visible;
                closePopups();
                popup.visible = show;
            }

            Process {
                id: networkIpProcess
                command: bar.activeNetwork === null
                    ? ["true"]
                    : ["nmcli", "-g", "IP4.ADDRESS", "device", "show", bar.activeNetwork.device.name]
                stdout: StdioCollector {
                    onStreamFinished: bar.networkIp = text.trim().split("\n")[0].split("/")[0] || "--"
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
                        text: bar.activeNetwork === null
                            ? "󰖪 Disconnected"
                            : `${bar.activeNetwork.device.type === DeviceType.Wifi ? "󰖩" : "󰈀"} ${bar.activeNetwork.name}`
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

            PopupWindow {
                id: batteryPopup
                anchor.window: bar
                anchor.rect.x: Math.max(0, Math.min(bar.width - width,
                    leftIsland.x + leftContent.x + batteryButton.x + batteryButton.width / 2 - width / 2))
                anchor.rect.y: bar.height + 8
                implicitWidth: 320
                implicitHeight: 170
                color: "transparent"
                grabFocus: true

                PopupSurface {
                    id: batteryPopupContent
                    focus: true
                    Keys.onEscapePressed: batteryPopup.visible = false

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

                onVisibleChanged: {
                    if (visible)
                        batteryPopupContent.forceActiveFocus();
                }
            }

            PopupWindow {
                id: healthPopup
                anchor.window: bar
                anchor.rect.x: Math.max(0, Math.min(bar.width - width,
                    leftIsland.x + leftContent.x + healthButton.x + healthButton.width / 2 - width / 2))
                anchor.rect.y: bar.height + 8
                implicitWidth: 380
                implicitHeight: 280
                color: "transparent"
                grabFocus: true

                PopupSurface {
                    id: healthPopupContent
                    focus: true
                    Keys.onEscapePressed: healthPopup.visible = false

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

                onVisibleChanged: {
                    if (visible)
                        healthPopupContent.forceActiveFocus();
                }
            }

            PopupWindow {
                id: networkPopup
                anchor.window: bar
                anchor.rect.x: Math.max(0, Math.min(bar.width - width,
                    leftIsland.x + leftContent.x + networkButton.x + networkButton.width / 2 - width / 2))
                anchor.rect.y: bar.height + 8
                implicitWidth: 340
                implicitHeight: 210
                color: "transparent"
                grabFocus: true

                PopupSurface {
                    id: networkPopupContent
                    focus: true
                    Keys.onEscapePressed: networkPopup.visible = false

                    Column {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 10

                        BarText {
                            text: bar.activeNetwork === null ? "Network: Disconnected" : bar.activeNetwork.name
                            font.bold: true
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        BarText {
                            text: `Type ${bar.activeNetwork === null ? "--"
                                : bar.activeNetwork.device.type === DeviceType.Wifi ? "Wi-Fi" : "Ethernet"}`
                        }
                        BarText {
                            text: `Signal ${bar.activeNetwork === null || bar.activeNetwork.device.type !== DeviceType.Wifi
                                ? "--" : `${Math.round(bar.activeNetwork.signalStrength * 100)}%`}`
                        }
                        BarText { text: `IP ${bar.networkIp}` }

                        ActionButton {
                            width: parent.width
                            text: "Open NetworkManager settings"
                            onClicked: {
                                networkPopup.visible = false;
                                Quickshell.execDetached(["nm-connection-editor"]);
                            }
                        }
                    }
                }

                onVisibleChanged: {
                    if (visible) {
                        networkPopupContent.forceActiveFocus();
                        if (bar.activeNetwork !== null)
                            networkIpProcess.running = true;
                    }
                }
            }

            PopupWindow {
                id: audioPopup
                anchor.window: bar
                anchor.rect.x: Math.max(0, Math.min(bar.width - width,
                    leftIsland.x + leftContent.x + audioButton.x + audioButton.width / 2 - width / 2))
                anchor.rect.y: bar.height + 8
                implicitWidth: 340
                implicitHeight: 160
                color: "transparent"
                grabFocus: true

                PopupSurface {
                    id: audioPopupContent
                    focus: true
                    Keys.onEscapePressed: audioPopup.visible = false

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

                        Slider {
                            id: volumeSlider
                            width: parent.width
                            height: 24
                            from: 0
                            to: 1
                            value: root.audioSink === null ? 0 : root.audioSink.audio.volume
                            enabled: root.audioSink !== null
                            onMoved: root.audioSink.audio.volume = value

                            background: Rectangle {
                                x: volumeSlider.leftPadding
                                y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                                width: volumeSlider.availableWidth
                                height: 4
                                radius: 2
                                color: "#475258"

                                Rectangle {
                                    width: volumeSlider.visualPosition * parent.width
                                    height: parent.height
                                    radius: parent.radius
                                    color: "#a7c080"
                                }
                            }

                            handle: Rectangle {
                                x: volumeSlider.leftPadding + volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
                                y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                                width: 14
                                height: 14
                                radius: 7
                                color: volumeSlider.pressed ? "#d3c6aa" : "#a7c080"
                            }
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

                onVisibleChanged: {
                    if (visible)
                        audioPopupContent.forceActiveFocus();
                }
            }

            PopupWindow {
                id: bluetoothPopup
                anchor.window: bar
                anchor.rect.x: Math.max(0, Math.min(bar.width - width,
                    leftIsland.x + leftContent.x + bluetoothButton.x + bluetoothButton.width / 2 - width / 2))
                anchor.rect.y: bar.height + 8
                implicitWidth: 320
                implicitHeight: Math.min(320, 58 + Math.max(1, bar.pairedBluetoothDevices.length) * 40)
                color: "transparent"
                grabFocus: true

                PopupSurface {
                    id: bluetoothPopupContent
                    focus: true
                    Keys.onEscapePressed: bluetoothPopup.visible = false

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
                            color: bluetoothDeviceMouse.containsMouse ? "#3d484d" : "transparent"

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

                onVisibleChanged: {
                    if (visible)
                        bluetoothPopupContent.forceActiveFocus();
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
                                : workspaceMouse.containsMouse ? "#3d484d" : "transparent"

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

            PopupWindow {
                id: calendarPopup
                anchor.window: bar
                anchor.rect.x: Math.max(0, Math.min(bar.width - width,
                    rightIsland.x + rightContent.x + clockButton.x + clockButton.width / 2 - width / 2))
                anchor.rect.y: bar.height + 8
                implicitWidth: 340
                implicitHeight: 320
                color: "transparent"
                grabFocus: true

                PopupSurface {
                    id: calendarPopupContent
                    focus: true
                    Keys.onEscapePressed: calendarPopup.visible = false

                    Column {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 6

                        BarText {
                            text: Qt.formatDate(clock.date, "MMMM yyyy")
                            font.bold: true
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
                            height: 236
                            month: clock.date.getMonth()
                            year: clock.date.getFullYear()
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
                }

                onVisibleChanged: {
                    if (visible)
                        calendarPopupContent.forceActiveFocus();
                }
            }

            PopupWindow {
                id: weatherPopup
                anchor.window: bar
                anchor.rect.x: Math.max(0, Math.min(bar.width - width,
                    rightIsland.x + rightContent.x + weatherButton.x + weatherButton.width / 2 - width / 2))
                anchor.rect.y: bar.height + 8
                implicitWidth: 390
                implicitHeight: 235
                color: "transparent"
                grabFocus: true

                PopupSurface {
                    id: weatherPopupContent
                    focus: true
                    Keys.onEscapePressed: weatherPopup.visible = false

                    Column {
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

                onVisibleChanged: {
                    if (visible)
                        weatherPopupContent.forceActiveFocus();
                }
            }
        }
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
        color: buttonMouse.containsMouse || active ? "#3d484d" : "transparent"

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

    component PopupSurface: Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: 10
        color: "#2d353b"
        border.color: "#a7c080"
        border.width: 1
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
