// TODO: check https://github.com/maniacx/Battery-Health-Charging for compatibility and different models, specially models with dual battery

import QtQuick 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 2.0
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.plasmoid 2.0


Item {
    id: root

    // Icons for different status and error
    property var icons: ({
        "on": Qt.resolvedUrl("./image/on.png"),
        "off": Qt.resolvedUrl("./image/off.png"),
        "calibration": Qt.resolvedUrl("./image/calibration.png"),
        "error": Qt.resolvedUrl("./image/error.png")
    })

    // The desired status for the charge limit feature ("on" or "off")
    property string desiredLimitStatus: "off"

    // The desired status for the calibration mode feature ("on" or "off")
    property string desiredCalibrationStatus: "off"

    // A flag indicating if an operation is in progress
    property bool loading: false

    // Determine the icon based on calibration status and charge limit status
    property string icon: plasmoid.configuration.currentCalibrationStatus === "on" ? root.icons.calibration : root.icons[plasmoid.configuration.currentLimitStatus ? plasmoid.configuration.currentLimitStatus : "error"]

    // Set the icon for the Plasmoid
    Plasmoid.icon: root.icon


    // Executed when the component is fully initialized
    Component.onCompleted: {
        findNotificationTool()
    }
   
    // CustomDataSource for querying the current charge limit status
    CustomDataSource {
        id: queryChargeLimitStatusDataSource
        command: "cat " + plasmoid.configuration.batteryChargeLimitConfigPath
    }

    // CustomDataSource for querying the current calibration status
    CustomDataSource {
        id: queryCalibrationStatusDataSource
        command: "cat " + plasmoid.configuration.batteryCalibrationConfigPath
    }       

    // CustomDataSource for setting the charge limit status
    CustomDataSource {
        id: setChargeLimitStatusDataSource

        // Dynamically set in switchChargeLimitStatus(). Set a default value to avoid errors at startup.
        property string status: "off"

        property var cmds: {
            "on": `echo 1 | ${plasmoid.configuration.elevatedPivilegesTool} tee ${plasmoid.configuration.batteryChargeLimitConfigPath} 1>/dev/null`,
            "off": `echo 0 | ${plasmoid.configuration.elevatedPivilegesTool} tee ${plasmoid.configuration.batteryChargeLimitConfigPath} 1>/dev/null`
        }
        command: cmds[status]
    }

    // CustomDataSource for setting the calibration status
    CustomDataSource {
        id: setCalibrationStatusDataSource

        // Dynamically set in switchCalibrationStatus(). Set a default value to avoid errors at startup.
        property string status: "off"

        property var cmds: {
            "on": `echo 1 | ${plasmoid.configuration.elevatedPivilegesTool} tee ${plasmoid.configuration.batteryCalibrationConfigPath} 1>/dev/null`,
            "off": `echo 0 | ${plasmoid.configuration.elevatedPivilegesTool} tee ${plasmoid.configuration.batteryCalibrationConfigPath} 1>/dev/null`
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
        id: findNotificationToolDataSource
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
                plasmoid.configuration.currentLimitStatus = root.desiredLimitStatus = status === "1"? "on" : "off"
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
                plasmoid.configuration.currentCalibrationStatus = root.desiredCalibrationStatus = status === "1"? "on" : "off"
            }

            //queryChargeLimitStatus()
        }
    }

    // Connection for setting charge limit status
    Connections {
        target: setChargeLimitStatusDataSource
        function onExited(exitCode, exitStatus, stdout, stderr){
            root.loading = false

            if(exitCode === 127){
                showNotification(root.icons.error, i18n("Root privileges are required."))
                root.desiredLimitStatus = plasmoid.configuration.currentLimitStatus
                return
            }

            if (stderr) {
                showNotification(root.icons.error, stderr, stdout)
            } else {
                plasmoid.configuration.currentLimitStatus = root.desiredLimitStatus
                showNotification(root.icons[plasmoid.configuration.currentLimitStatus], i18n("Charge Limit status switched to %1.", plasmoid.configuration.currentLimitStatus.toUpperCase()))
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
                root.desiredCalibrationStatus = plasmoid.configuration.currentCalibrationStatus
                return
            }

            if (stderr) {
                showNotification(root.icons.error, stderr, stdout)
            } else {
                plasmoid.configuration.currentCalibrationStatus = root.desiredCalibrationStatus
                showNotification(root.icons.calibration, i18n("Calibration status switched to %1.", plasmoid.configuration.currentCalibrationStatus.toUpperCase()))
            }
        }
    }


    // Connection for finding the notification tool
    Connections {
        target: findNotificationToolDataSource
        function onExited(exitCode, exitStatus, stdout, stderr){
            root.loading = false

            var notificationTool = ""

            if (stdout) {
                var paths = stdout.trim().split("\n")


                // Many Linux distros have two notification tools: notify-send and zenity
                // Prefer notify-send because it allows using an icon; zenity v3.44.0 does not accept an icon option
                for (let i = 0; i < paths.length; ++i) {
                    let currentPath = paths[i].trim()
                    
                    if (currentPath.endsWith("notify-send")) {
                        notificationTool = "notify-send"
                        break
                    } else if (currentPath.endsWith("zenity")) {
                        notificationTool = "zenity"
                    }
                }
            }

            if (notificationTool) {
                plasmoid.configuration.notificationToolPath = notificationTool
            } else {
                console.warn("No compatible notification tool found.")
            }

            findCalibrationConfigPath()
        }
    }

    // Connection for finding the charge limit config path
    Connections {
        target: findChargeLimitConfigPathDataSource
        function onExited(exitCode, exitStatus, stdout, stderr){
            root.loading = false

            if (stdout.trim()) {
                plasmoid.configuration.batteryChargeLimitConfigPath = stdout.trim()
                plasmoid.configuration.isCompatibleChargeLimit = true
                
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
            root.loading = false

            if (stdout.trim()) {
                plasmoid.configuration.batteryCalibrationConfigPath = stdout.trim()
                plasmoid.configuration.isCompatibleCalibration = true
                queryCalibrationStatus()
            }

            findChargeLimitConfigPath()
        }
    }

    Connections {
        target: plasmoid.configuration
        function onBatteryCalibrationConfigPathChanged(){
            if(plasmoid.configuration.batteryCalibrationConfigPath){
                plasmoid.configuration.isCompatibleCalibration = true
            }else {
                plasmoid.configuration.isCompatibleCalibration = false
            }
            findCalibrationConfigPath()
        }
    }

    Connections {
        target: plasmoid.configuration
        function onBatteryChargeLimitConfigPathChanged(){
            if(plasmoid.configuration.batteryChargeLimitConfigPath){
                plasmoid.configuration.isCompatibleChargeLimit = true
            }else {
                plasmoid.configuration.isCompatibleChargeLimit = false
            }
            findChargeLimitConfigPath()
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

        setCalibrationStatusDataSource.status = root.desiredCalibrationStatus
        setCalibrationStatusDataSource.exec()
    }

    // Function to show notifications
    function showNotification(iconURL: string, message: string, title = i18n("Battery Limit Switcher"), options = ""){
        if (plasmoid.configuration.notificationToolPath) {
            sendNotification.tool = plasmoid.configuration.notificationToolPath

            sendNotification.iconURL = iconURL
            sendNotification.title = title
            sendNotification.message = message
            sendNotification.options = options

            sendNotification.exec()
        } else {
            console.warn(title + ": " + message)
        }
    }

    // Function to find the notification tool path
    function findNotificationTool() {
        if(!plasmoid.configuration.notificationToolPath){
            findNotificationToolDataSource.exec()
        } else {
            findCalibrationConfigPath()
        }
    }

    // Function to find the charge limit config path
    function findChargeLimitConfigPath() {
        if (!plasmoid.configuration.batteryChargeLimitConfigPath && !plasmoid.configuration.isCompatibleChargeLimit){
            root.loading = true
            findChargeLimitConfigPathDataSource.exec()
        } else {
            queryChargeLimitStatus()
        }
    }

    // Function to find the calibration config path
    function findCalibrationConfigPath() {
        if (!plasmoid.configuration.batteryCalibrationConfigPath || !plasmoid.configuration.isCompatibleCalibration){
            root.loading = true
            findCalibrationConfigPathDataSource.exec()
        } else {
            queryCalibrationStatus()
        }

    }

    Plasmoid.preferredRepresentation: Plasmoid.compactRepresentation

    Plasmoid.compactRepresentation: Item {
        PlasmaCore.IconItem {
            height: plasmoid.configuration.iconSize
            width: plasmoid.configuration.iconSize
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
                text: plasmoid.configuration.isCompatibleChargeLimit ? i18n("Battery Charge Limit is %1.", plasmoid.configuration.currentLimitStatus.toUpperCase()) : i18n("The Battery Charge Limit feature is not available.")
            }
            ColumnLayout {
                Layout.alignment: Qt.AlignCenter
                visible: plasmoid.configuration.isCompatibleChargeLimit

                PlasmaComponents3.Label {
                    Layout.alignment: Qt.AlignCenter
                    text: i18n("(To turn on Charge Limit you must turn off Calibration)")
                    visible: plasmoid.configuration.currentCalibrationStatus === "on"
                }
                PlasmaComponents3.Switch {
                    Layout.alignment: Qt.AlignCenter
                    enabled: !root.loading && (!plasmoid.configuration.currentCalibrationStatus || plasmoid.configuration.currentCalibrationStatus === "off")
                    checked: root.desiredLimitStatus === "on"
                    onCheckedChanged: {
                        root.desiredLimitStatus = checked ? "on" : "off"
                        if(plasmoid.configuration.currentLimitStatus && root.desiredLimitStatus !== plasmoid.configuration.currentLimitStatus){
                            switchChargeLimitStatus()
                        }
                    }
                }
            }



            ColumnLayout {
                Layout.alignment: Qt.AlignCenter
                visible: plasmoid.configuration.isCompatibleCalibration

                PlasmaComponents3.Label {
                    Layout.alignment: Qt.AlignCenter
                    text: i18n("Battery Calibration is %1.", plasmoid.configuration.currentCalibrationStatus.toUpperCase())
                }

                PlasmaComponents3.Label {
                    Layout.alignment: Qt.AlignCenter
                    text: i18n("(Be sure you know how it works)")
                    color: "#FF0000"
                    visible: plasmoid.configuration.currentLimitStatus === "off" && plasmoid.configuration.currentCalibrationStatus === "off"
                }
                PlasmaComponents3.Label {
                    Layout.alignment: Qt.AlignCenter
                    text: i18n("(To turn on Calibration you must turn off Charge Limit)")
                    visible: plasmoid.configuration.currentLimitStatus === "on" && plasmoid.configuration.currentCalibrationStatus === "off"
                }
                PlasmaComponents3.Label {
                    Layout.alignment: Qt.AlignCenter
                    color: "#FF0000"
                    text: i18n("(You must turn this off manually)")
                    visible: plasmoid.configuration.currentCalibrationStatus === "on"
                }
                PlasmaComponents3.Switch {
                    Layout.alignment: Qt.AlignCenter
                    enabled: !root.loading && (!plasmoid.configuration.currentLimitStatus || plasmoid.configuration.currentLimitStatus === "off")
                    checked: root.desiredCalibrationStatus === "on"
                    onCheckedChanged: {
                        root.desiredCalibrationStatus = checked ? "on" : "off"
                        if(plasmoid.configuration.currentCalibrationStatus && root.desiredCalibrationStatus !== plasmoid.configuration.currentCalibrationStatus){
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
    Plasmoid.toolTipSubText: plasmoid.configuration.isCompatibleChargeLimit ? i18n("Battery Charge Limit is %1.", plasmoid.configuration.currentLimitStatus.toUpperCase()) : i18n("The Battery Charge Limit feature is not available.")
}
