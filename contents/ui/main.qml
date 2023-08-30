// TODO: check https://github.com/maniacx/Battery-Health-Charging for compatibility and different models, specially models with dual battery

import QtQuick 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 2.0
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.plasmoid 2.0


Item {
    id: root

    property string pkexecPath: "/usr/bin/pkexec"

    property string batteryChargeLimitConfigPath
    property string batteryCalibrationConfigPath


    readonly property var const_COMMANDS: ({
        "queryLimitStatus": "cat " + root.batteryChargeLimitConfigPath,
        "queryCalibrationStatus": "cat " + root.batteryCalibrationConfigPath,
        "onLimit": "echo 1 | " + root.pkexecPath + " tee " + root.batteryChargeLimitConfigPath + " 1>/dev/null",
        "offLimit": "echo 0 | " + root.pkexecPath + " tee " + root.batteryChargeLimitConfigPath + " 1>/dev/null",
        "onCalibration": "echo 1 | " + root.pkexecPath + " tee " + root.batteryCalibrationConfigPath + " 1>/dev/null",
        "offCalibration": "echo 0 | " + root.pkexecPath + " tee " + root.batteryCalibrationConfigPath + " 1>/dev/null",
        "findChargeLimitConfigPath":"find /sys -name \"health_mode\" -path \"*/acer-wmi-battery/*\"",
        "findCalibrationConfigPath":"find /sys -name \"calibration_mode\" -path \"*/acer-wmi-battery/*\"",
        "findNotificationToolPath": "find /usr -type f -executable \\( -name \"notify-send\" -o -name \"zenity\" \\)",
        // defined in findNotificationToolPath Connection
        "sendNotification": () => ""
    })

    property var icons: ({
        "on": Qt.resolvedUrl("./image/on.png"),
        "off": Qt.resolvedUrl("./image/off.png"),
        "calibration": Qt.resolvedUrl("./image/calibration.png"),
        "error": Qt.resolvedUrl("./image/error.png")
    })

    // This values can change after the execution of onCompleted().
    property string currentLimitStatus: "off"
    property bool isCompatibleChargeLimit: false
    property string currentCalibrationStatus: "off"
    property bool isCompatibleCalibration: false

    property string desiredLimitStatus: "off"
    property string desiredCalibrationStatus: "off"

    property bool loading: false

    property string icon: root.currentCalibrationStatus === "on" ? root.icons.calibration : root.icons[root.currentLimitStatus]

    Plasmoid.icon: root.icon

    Connections {
        target: Plasmoid.configuration
    }

    Component.onCompleted: {
        findNotificationToolPath()
        findChargeLimitConfigPath()
        findCalibrationConfigPath()
    }

    PlasmaCore.DataSource {
        id: queryChargeLimitStatusDataSource
        engine: "executable"
        connectedSources: []

        onNewData: {
            var exitCode = data["exit code"]
            var exitStatus = data["exit status"]
            var stdout = data["stdout"]
            var stderr = data["stderr"]

            exited(exitCode, exitStatus, stdout, stderr)
            disconnectSource(sourceName)
        }

        function exec(cmd) {
            connectSource(cmd)
        }

        signal exited(int exitCode, int exitStatus, string stdout, string stderr)
    }


    PlasmaCore.DataSource {
        id: queryCalibrationStatusDataSource
        engine: "executable"
        connectedSources: []

        onNewData: {
            var exitCode = data["exit code"]
            var exitStatus = data["exit status"]
            var stdout = data["stdout"]
            var stderr = data["stderr"]

            exited(exitCode, exitStatus, stdout, stderr)
            disconnectSource(sourceName)
        }

        function exec(cmd) {
            connectSource(cmd)
        }

        signal exited(int exitCode, int exitStatus, string stdout, string stderr)
    }


    PlasmaCore.DataSource {
        id: setChargeLimitStatusDataSource
        engine: "executable"
        connectedSources: []

        onNewData: {
            var exitCode = data["exit code"]
            var exitStatus = data["exit status"]
            var stdout = data["stdout"]
            var stderr = data["stderr"]

            exited(exitCode, exitStatus, stdout, stderr)
            disconnectSource(sourceName)
        }

        function exec(cmd) {
            connectSource(cmd)
        }

        signal exited(int exitCode, int exitStatus, string stdout, string stderr)
    }


    PlasmaCore.DataSource {
        id: setCalibrationStatusDataSource
        engine: "executable"
        connectedSources: []

        onNewData: {
            var exitCode = data["exit code"]
            var exitStatus = data["exit status"]
            var stdout = data["stdout"]
            var stderr = data["stderr"]

            exited(exitCode, exitStatus, stdout, stderr)
            disconnectSource(sourceName)
        }

        function exec(cmd) {
            connectSource(cmd)
        }

        signal exited(int exitCode, int exitStatus, string stdout, string stderr)
    }


    PlasmaCore.DataSource {
        id: findNotificationToolPathDataSource
        engine: "executable"
        connectedSources: []

        onNewData: {
            var exitCode = data["exit code"]
            var exitStatus = data["exit status"]
            var stdout = data["stdout"]
            // stderr output can contain "permission denied" errors
            var stderr = data["stderr"]

            exited(exitCode, exitStatus, stdout, stderr)
            disconnectSource(sourceName)
        }

        function exec(cmd) {
            connectSource(cmd)
        }

        signal exited(int exitCode, int exitStatus, string stdout, string stderr)
    }


    PlasmaCore.DataSource {
        id: findChargeLimitConfigPathDataSource
        engine: "executable"
        connectedSources: []

        onNewData: {
            var exitCode = data["exit code"]
            var exitStatus = data["exit status"]
            var stdout = data["stdout"]
            // stderr output can contain "permission denied" errors
            var stderr = data["stderr"]

            exited(exitCode, exitStatus, stdout, stderr)
            disconnectSource(sourceName)
        }

        function exec(cmd) {
            connectSource(cmd)
        }

        signal exited(int exitCode, int exitStatus, string stdout, string stderr)
    }


    PlasmaCore.DataSource {
        id: findCalibrationConfigPathDataSource
        engine: "executable"
        connectedSources: []

        onNewData: {
            var exitCode = data["exit code"]
            var exitStatus = data["exit status"]
            var stdout = data["stdout"]
            // stderr output can contain "permission denied" errors
            var stderr = data["stderr"]

            exited(exitCode, exitStatus, stdout, stderr)
            disconnectSource(sourceName)
        }

        function exec(cmd) {
            connectSource(cmd)
        }

        signal exited(int exitCode, int exitStatus, string stdout, string stderr)
    }


    PlasmaCore.DataSource {
        id: sendNotification
        engine: "executable"
        connectedSources: []

        onNewData: {
            disconnectSource(sourceName)
        }

        function exec(cmd) {
            connectSource(cmd)
        }
    }


    Connections {
        target: queryChargeLimitStatusDataSource
        function onExited(exitCode, exitStatus, stdout, stderr){
            root.loading = false

            if (stderr) {
                root.icon = root.icons.error
                showNotification(root.icons.error, stderr, stderr)
            } else {
                var status = stdout.trim()
                root.currentLimitStatus = root.desiredLimitStatus = status === "1"? "on" : "off"
            }
        }
    }


    Connections {
        target: queryCalibrationStatusDataSource
        function onExited(exitCode, exitStatus, stdout, stderr){
            root.loading = false

            if (stderr) {
                root.icon = root.icons.error
                showNotification(root.icons.error, stderr, stderr)
            } else {
                var status = stdout.trim()
                root.currentCalibrationStatus = root.desiredCalibrationStatus = status === "1"? "on" : "off"
            }
        }
    }


    Connections {
        target: setChargeLimitStatusDataSource
        function onExited(exitCode, exitStatus, stdout, stderr){
            root.loading = false

            if(exitCode === 127){
                showNotification(root.icons.error, i18n("Root privileges are required."))
                root.desiredLimitStatus = root.currentLimitStatus
                return
            }

            if (stderr) {
                showNotification(root.icons.error, stderr, stdout)
            } else {
                root.currentLimitStatus = root.desiredLimitStatus
                showNotification(root.icons[root.currentLimitStatus], i18n("Charge Limit status switched to %1.", root.currentLimitStatus.toUpperCase()))
            }
        }
    }


    Connections {
        target: setCalibrationStatusDataSource
        function onExited(exitCode, exitStatus, stdout, stderr){
            root.loading = false

            if(exitCode === 127){
                showNotification(root.icons.error, i18n("Root privileges are required."))
                root.desiredCalibrationStatus = root.currentCalibrationStatus
                return
            }

            if (stderr) {
                showNotification(root.icons.error, stderr, stdout)
            } else {
                root.currentCalibrationStatus = root.desiredCalibrationStatus
                showNotification(root.icons.calibration, i18n("Calibration status switched to %1.", root.currentCalibrationStatus.toUpperCase()))
            }
        }
    }


    Connections {
        target: findNotificationToolPathDataSource
        function onExited(exitCode, exitStatus, stdout, stderr){

            if (stdout) {
                // Many Linux distros have two notification tools
                var paths = stdout.trim().split("\n")
                var path1 = paths[0]
                var path2 = paths[1]

                // prefer notify-send because it allows to use icon, zenity v3.44.0 does not accept icon option
                if (path1 && path1.trim().endsWith("notify-send")) {
                    const_COMMANDS.sendNotification = (title, message, iconURL, options) => path1.trim() + " -i " + iconURL + " '" + title + "' '" + message + "'" + options
                }if (path2 && path2.trim().endsWith("notify-send")) {
                    const_COMMANDS.sendNotification = (title, message, iconURL, options) => path2.trim() + " -i " + iconURL + " '" + title + "' '" + message + "'" + options
                }else if (path1 && path1.trim().endsWith("zenity")) {
                    const_COMMANDS.sendNotification = (title, message, iconURL, options) => path1.trim() + " --notification --text='" + title + "\\n" + message + "'"
                }
            }
        }
    }


    Connections {
        target: findChargeLimitConfigPathDataSource
        function onExited(exitCode, exitStatus, stdout, stderr){
            if (stdout.trim()) {
                root.batteryChargeLimitConfigPath = stdout.trim()
                root.isCompatibleChargeLimit = true
                queryChargeLimitStatus()
            }else {
                root.icon = root.icons.error
            }
        }
    }


    Connections {
        target: findCalibrationConfigPathDataSource
        function onExited(exitCode, exitStatus, stdout, stderr){
            if (stdout.trim()) {
                root.batteryCalibrationConfigPath = stdout.trim()
                root.isCompatibleCalibration = true
                queryCalibrationStatus()
            }
        }
    }


    function queryChargeLimitStatus() {
        root.loading = true
        queryChargeLimitStatusDataSource.exec(const_COMMANDS.queryLimitStatus)
    }


    function queryCalibrationStatus() {
        root.loading = true
        queryCalibrationStatusDataSource.exec(const_COMMANDS.queryCalibrationStatus)
    }


    function switchChargeLimitStatus() {
        root.loading = true

        showNotification(root.icons[root.desiredLimitStatus], i18n("Switching Charge Limit status to %1.", root.desiredLimitStatus.toUpperCase()))

        setChargeLimitStatusDataSource.exec(const_COMMANDS[root.desiredLimitStatus + "Limit"])
    }


    function switchCalibrationStatus() {
        root.loading = true

        showNotification(root.icons.calibration, i18n("Switching Calibration status to %1.", root.desiredCalibrationStatus.toUpperCase()))

        setCalibrationStatusDataSource.exec(const_COMMANDS[root.desiredCalibrationStatus + "Calibration"])
    }


    function showNotification(iconURL: string, message: string, title = i18n("Battery Limit Switcher"), options = ""){
        sendNotification.exec(const_COMMANDS.sendNotification(title, message, iconURL, options))
    }

    function findNotificationToolPath() {
        findNotificationToolPathDataSource.exec(const_COMMANDS.findNotificationToolPath)
    }

    function findChargeLimitConfigPath() {
        // Check if the user defined the file path manually and use it if he did.
        if(Plasmoid.configuration.batteryChargeLimitConfigPath){
            root.batteryChargeLimitConfigPath = Plasmoid.configuration.batteryChargeLimitConfigPath
        }else{
            findChargeLimitConfigPathDataSource.exec(const_COMMANDS.findChargeLimitConfigPath)
        }

    }


    function findCalibrationConfigPath() {
        // Check if the user defined the file path manually and use it if he did.
        if(Plasmoid.configuration.batteryCalibrationConfigPath){
            root.batteryCalibrationConfigPath = Plasmoid.configuration.batteryCalibrationConfigPath
        }else{
            findCalibrationConfigPathDataSource.exec(const_COMMANDS.findCalibrationConfigPath)
        }

    }

    Plasmoid.preferredRepresentation: Plasmoid.compactRepresentation

    Plasmoid.compactRepresentation: Item {
        PlasmaCore.IconItem {
            height: Plasmoid.configuration.iconSize
            width: Plasmoid.configuration.iconSize
            anchors.centerIn: parent

            source: root.icon
            active: compactMouse.containsMouse

            MouseArea {
                id: compactMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    plasmoid.expanded = !plasmoid.expanded
                }
            }
        }
    }

    Plasmoid.fullRepresentation: Item {
        Layout.preferredWidth: 400 * PlasmaCore.Units.devicePixelRatio
        Layout.preferredHeight: 300 * PlasmaCore.Units.devicePixelRatio

        ColumnLayout {
            anchors.centerIn: parent

            Image {
                id: mode_image
                source: root.icon
                Layout.alignment: Qt.AlignCenter
                Layout.preferredHeight: 64
                fillMode: Image.PreserveAspectFit
            }


            PlasmaComponents3.Label {
                Layout.alignment: Qt.AlignCenter
                text: root.isCompatibleChargeLimit ? i18n("Battery Charge Limit is %1.", root.currentLimitStatus.toUpperCase()) : i18n("The Battery Charge Limit feature is not available.")
            }
            ColumnLayout {
                Layout.alignment: Qt.AlignCenter
                visible: root.isCompatibleChargeLimit

                PlasmaComponents3.Label {
                    Layout.alignment: Qt.AlignCenter
                    text: i18n("(To turn on Charge Limit you must turn off Calibration)")
                    visible: root.currentCalibrationStatus === "on"
                }
                PlasmaComponents3.Switch {
                    Layout.alignment: Qt.AlignCenter
                    enabled: !root.loading && root.currentCalibrationStatus === "off"
                    checked: root.desiredLimitStatus === "on"
                    onCheckedChanged: {
                        root.desiredLimitStatus = checked ? "on" : "off"
                        if(root.desiredLimitStatus !== root.currentLimitStatus){
                            switchChargeLimitStatus()
                        }
                    }
                }
            }



            ColumnLayout {
                Layout.alignment: Qt.AlignCenter
                visible: root.isCompatibleCalibration

                PlasmaComponents3.Label {
                    Layout.alignment: Qt.AlignCenter
                    text: i18n("Battery Calibration is %1.", root.currentCalibrationStatus.toUpperCase())
                }

                PlasmaComponents3.Label {
                    Layout.alignment: Qt.AlignCenter
                    text: i18n("(Be sure you know how it works)")
                    color: "#FF0000"
                    visible: root.currentLimitStatus === "off" && root.currentCalibrationStatus === "off"
                }
                PlasmaComponents3.Label {
                    Layout.alignment: Qt.AlignCenter
                    text: i18n("(To turn on Calibration you must turn off Charge Limit)")
                    visible: root.currentLimitStatus === "on" && root.currentCalibrationStatus === "off"
                }
                PlasmaComponents3.Label {
                    Layout.alignment: Qt.AlignCenter
                    color: "#FF0000"
                    text: i18n("(You must turn this off manually)")
                    visible: root.currentCalibrationStatus === "on"
                }
                PlasmaComponents3.Switch {
                    Layout.alignment: Qt.AlignCenter
                    enabled: !root.loading && root.currentLimitStatus === "off"
                    checked: root.desiredCalibrationStatus === "on"
                    onCheckedChanged: {
                        root.desiredCalibrationStatus = checked ? "on" : "off"
                        if(root.desiredCalibrationStatus !== root.currentCalibrationStatus){
                            switchCalibrationStatus()
                        }
                    }
                }
            }


            BusyIndicator {
                id: loadingIndicator
                Layout.alignment: Qt.AlignCenter
                running: root.loading
            }

        }
    }

    property bool tst: false

    Plasmoid.toolTipMainText: i18n("Switch Battery Charge Limit.")
    Plasmoid.toolTipSubText: root.isCompatibleChargeLimit ? i18n("Battery Charge Limit is %1.", root.currentLimitStatus.toUpperCase()) : i18n("The Battery Charge Limit feature is not available.")
}
