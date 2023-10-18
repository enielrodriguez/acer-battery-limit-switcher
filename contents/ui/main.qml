// TODO: check https://github.com/maniacx/Battery-Health-Charging for compatibility and different models, specially models with dual battery

import QtQuick 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 2.0
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.plasmoid 2.0


Item {
    id: root

    // Path to the pkexec binary
    property string pkexecPath: "/usr/bin/pkexec"

    // Path to the battery charge limit configuration file
    property string batteryChargeLimitConfigPath

    // Path to the battery calibration configuration file
    property string batteryCalibrationConfigPath

    // Icons for different status and error
    property var icons: ({
        "on": Qt.resolvedUrl("./image/on.png"),
        "off": Qt.resolvedUrl("./image/off.png"),
        "calibration": Qt.resolvedUrl("./image/calibration.png"),
        "error": Qt.resolvedUrl("./image/error.png")
    })

    // The current status of the conservation mode ("on" or "off"). This values can change after the execution of onCompleted().
    property string currentLimitStatus: "off"

    // A flag indicating whether the system is compatible for charge limit. This values can change after the execution of onCompleted().
    property bool isCompatibleChargeLimit: false

    // The current status of the calibration mode ("on" or "off"). This values can change after the execution of onCompleted().
    property string currentCalibrationStatus: "off"

    // A flag indicating whether the system is compatible for calibration. This values can change after the execution of onCompleted().
    property bool isCompatibleCalibration: false

    // The desired status for the charge limit feature ("on" or "off")
    property string desiredLimitStatus: "off"

    // The desired status for the calibration mode feature ("on" or "off")
    property string desiredCalibrationStatus: "off"

    // The notification tool to use (e.g., "zenity" or "notify-send")
    property string notificationTool: ""

    // A flag indicating if an operation is in progress
    property bool loading: false

    // Determine the icon based on calibration status and charge limit status
    property string icon: root.currentCalibrationStatus === "on" ? root.icons.calibration : root.icons[root.currentLimitStatus]

    // Set the icon for the Plasmoid
    Plasmoid.icon: root.icon

    // Connect to Plasmoid configuration
    Connections {
        target: Plasmoid.configuration
    }

    // Executed when the component is fully initialized
    Component.onCompleted: {
        findNotificationToolPath()
        findChargeLimitConfigPath()
        findCalibrationConfigPath()
    }

    // CustomDataSource for querying the current charge limit status
    CustomDataSource {
        id: queryChargeLimitStatusDataSource
        command: "cat " + root.batteryChargeLimitConfigPath
    }

    // CustomDataSource for querying the current calibration status
    CustomDataSource {
        id: queryCalibrationStatusDataSource
        command: "cat " + root.batteryCalibrationConfigPath
    }

    // CustomDataSource for setting the charge limit status
    CustomDataSource {
        id: setChargeLimitStatusDataSource

        // Dynamically set in switchChargeLimitStatus(). Set a default value to avoid errors at startup.
        property string status: "off"

        property var cmds: {
            "on": `echo 1 | ${root.pkexecPath} tee ${root.batteryChargeLimitConfigPath} 1>/dev/null`
            "off": `echo 0 | ${root.pkexecPath} tee ${root.batteryChargeLimitConfigPath} 1>/dev/null`
        }
        command: cmds[status]
    }

    // CustomDataSource for setting the calibration status
    CustomDataSource {
        id: setCalibrationStatusDataSource

        // Dynamically set in switchCalibrationStatus(). Set a default value to avoid errors at startup.
        property string status: "off"

        property var cmds: {
            "on": `echo 1 | ${root.pkexecPath} tee ${root.batteryCalibrationConfigPath} 1>/dev/null`,
            "off": `echo 0 | ${root.pkexecPath} tee ${root.batteryCalibrationConfigPath} 1>/dev/null`
        }
        command: cmds[status]
    }

    // CustomDataSource for finding the charge limit configuration file
    CustomDataSource {
        id: findChargeLimitConfigPathDataSource
        command: "find /sys -name \"health_mode\" -path \"*/acer-wmi-battery/*\""
    }

    // CustomDataSource for finding the calibration configuration file
    CustomDataSource {
        id: findCalibrationConfigPathDataSource
        command: "find /sys -name \"calibration_mode\" -path \"*/acer-wmi-battery/*\""
    }

    // CustomDataSource for finding the notification tool
    CustomDataSource {
        id: findNotificationToolPathDataSource
        command: "find /usr -type f -executable \\( -name \"notify-send\" -o -name \"zenity\" \\)"
    }

    // CustomDataSource for sending notifications
    CustomDataSource {
        id: sendNotification

        // Dynamically set in showNotification(). Set a default value to avoid errors at startup.
        property string tool: "notify-send"

        property string iconURL: ""
        property string title: ""
        property string message: ""
        property string options: ""

        property var cmds: {
            "notify-send": `notify-send -i ${iconURL} '${title}' '${message}' ${options}`,
            "zenity": `zenity --notification --text='${title}\\n${message}'`
        }
        command: cmds[tool]
    }


    // Connection for querying charge limit status
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

    // Connection for querying calibration status
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

    // Connection for setting charge limit status
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

    // Connection for setting calibration status
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


    // Connection for finding the notification tool
    Connections {
        target: findNotificationToolPathDataSource
        function onExited(exitCode, exitStatus, stdout, stderr){
            if (stdout) {
                // Many Linux distros have two notification tools
                var paths = stdout.trim().split("\n")
                var path1 = paths[0]
                var path2 = paths[1]

                // Prefer notify-send because it allows using an icon; zenity v3.44.0 does not accept an icon option
                if (path1 && path1.trim().endsWith("notify-send")) {
                    root.notificationTool = "notify-send"
                } else if (path2 && path2.trim().endsWith("notify-send")) {
                    root.notificationTool = "notify-send"
                } else if (path1 && path1.trim().endsWith("zenity")) {
                    root.notificationTool = "zenity"
                } else {
                    console.warn("No compatible notification tool found.")
                }
            }
        }
    }

    // Connection for finding the charge limit config path
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

    // Connection for finding the calibration config path
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


    // Function to query the charge limit status
    function queryChargeLimitStatus() {
        root.loading = true
        queryChargeLimitStatusDataSource.exec()
    }

    // Function to query the calibration status
    function queryCalibrationStatus() {
        root.loading = true
        queryCalibrationStatusDataSource.exec()
    }

    // Function to switch charge limit status
    function switchChargeLimitStatus() {
        root.loading = true

        showNotification(root.icons[root.desiredLimitStatus], i18n("Switching Charge Limit status to %1.", root.desiredLimitStatus.toUpperCase()))

        setChargeLimitStatusDataSource.status = root.desiredLimitStatus
        setChargeLimitStatusDataSource.exec()
    }

    // Function to switch calibration status
    function switchCalibrationStatus() {
        root.loading = true

        showNotification(root.icons.calibration, i18n("Switching Calibration status to %1.", root.desiredCalibrationStatus.toUpperCase()))

        setChargeLimitStatusDataSource.status = root.desiredCalibrationStatus
        setCalibrationStatusDataSource.exec()
    }

    // Function to show notifications
    function showNotification(iconURL: string, message: string, title = i18n("Battery Limit Switcher"), options = ""){
        sendNotification.tool = root.notificationTool

        sendNotification.iconURL = iconURL
        sendNotification.title = title
        sendNotification.message = message
        sendNotification.options = options

        sendNotification.exec()
    }

    // Function to find the notification tool path
    function findNotificationToolPath() {
        findNotificationToolPathDataSource.exec()
    }

    // Function to find the charge limit config path
    function findChargeLimitConfigPath() {
        // Check if the user defined the file path manually and use it if he did.
        if(Plasmoid.configuration.batteryChargeLimitConfigPath){
            root.batteryChargeLimitConfigPath = Plasmoid.configuration.batteryChargeLimitConfigPath
        }else{
            findChargeLimitConfigPathDataSource.exec()
        }

    }

    // Function to find the calibration config path
    function findCalibrationConfigPath() {
        // Check if the user defined the file path manually and use it if he did.
        if(Plasmoid.configuration.batteryCalibrationConfigPath){
            root.batteryCalibrationConfigPath = Plasmoid.configuration.batteryCalibrationConfigPath
        }else{
            findCalibrationConfigPathDataSource.exec()
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

    Plasmoid.toolTipMainText: i18n("Switch Battery Charge Limit.")
    Plasmoid.toolTipSubText: root.isCompatibleChargeLimit ? i18n("Battery Charge Limit is %1.", root.currentLimitStatus.toUpperCase()) : i18n("The Battery Charge Limit feature is not available.")
}
