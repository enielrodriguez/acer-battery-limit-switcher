import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: configGeneral

    property alias cfg_batteryChargeLimitConfigPath: batteryChargeLimitConfigPathField.text
    property alias cfg_batteryCalibrationConfigPath: batteryCalibrationConfigPathField.text
    property alias cfg_iconSize: iconSizeComboBox.currentValue
    property alias cfg_needSudo: needSudoField.checked

    TextField {
        id: batteryChargeLimitConfigPathField
        Kirigami.FormData.label: i18n("Battery Charge Limit config file (if the plugin works don't touch this):")
    }

    TextField {
        id: batteryCalibrationConfigPathField
        Kirigami.FormData.label: i18n("Battery Calibration config file (if the plugin works don't touch this):")
    }

    CheckBox {
        id: needSudoField
        text: i18n("I need sudo")
        anchors.top: batteryCalibrationConfigPathField.bottom
        anchors.topMargin: 15
        onCheckedChanged: {
            plasmoid.configuration.elevatedPivilegesTool = checked ? "/usr/bin/pkexec" : "/usr/bin/sudo";
        }
    }

    Label {
        id: noteDisableSudo
        text: "NOTE: Uncheck if you can run 'sudo tee' without entering the root password."
        anchors.top: needSudoField.bottom
    }

    Label {
        id: labelCmdDisableSudo
        text: "TIP: Commands to allow execution without root password:"
        anchors.top: noteDisableSudo.bottom
    }

    TextField {
        id: cmdDisableSudo
        text: "echo \"%$(id -gn) ALL=(ALL) NOPASSWD: /usr/bin/tee " + configGeneral.cfg_batteryChargeLimitConfigPath.replace(/:/g, "\\:") + "\" | sudo tee /etc/sudoers.d/battery_limit"
        wrapMode: Text.Wrap
        readOnly: true
        Layout.fillWidth: true
        anchors.top: labelCmdDisableSudo.bottom
    }

    TextField {
        text: "echo \"%$(id -gn) ALL=(ALL) NOPASSWD: /usr/bin/tee " + configGeneral.cfg_batteryCalibrationConfigPath.replace(/:/g, "\\:") + "\" | sudo tee /etc/sudoers.d/battery_calibration"
        wrapMode: Text.Wrap
        readOnly: true
        Layout.fillWidth: true
        anchors.top: cmdDisableSudo.bottom
    }

    ComboBox {
        id: iconSizeComboBox

        Kirigami.FormData.label: i18n("Icon size:")
        model: [
            {text: "small", value: Kirigami.Units.iconSizes.small},
            {text: "small-medium", value: Kirigami.Units.iconSizes.smallMedium},
            {text: "medium", value: Kirigami.Units.iconSizes.medium},
            {text: "large", value: Kirigami.Units.iconSizes.large},
            {text: "huge", value: Kirigami.Units.iconSizes.huge},
            {text: "enormous", value: Kirigami.Units.iconSizes.enormous}
        ]
        textRole: "text"
        valueRole: "value"

        currentIndex: model.findIndex((element) => element.value === plasmoid.configuration.iconSize)
    }
}
