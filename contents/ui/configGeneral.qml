import QtQuick 2.0
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12
import org.kde.kirigami 2.4 as Kirigami
import org.kde.plasma.core 2.0 as PlasmaCore

Kirigami.FormLayout {
    id: configGeneral

    property alias cfg_batteryChargeLimitConfigPath: batteryChargeLimitConfigPathField.text
    property alias cfg_batteryCalibrationConfigPath: batteryCalibrationConfigPathField.text
    property alias cfg_iconSize: iconSizeComboBox.currentValue

    TextField {
        id: batteryChargeLimitConfigPathField
        Kirigami.FormData.label: i18n("Battery Charge Limit config file (leave empty for autodiscovery):")
    }

    TextField {
        id: batteryCalibrationConfigPathField
        Kirigami.FormData.label: i18n("Battery Calibration config file (leave empty for autodiscovery):")
    }

    ComboBox {
        id: iconSizeComboBox

        Kirigami.FormData.label: i18n("Icon size:")
        model: [
            {text: "small", value: units.iconSizes.small},
            {text: "small-medium", value: units.iconSizes.smallMedium},
            {text: "medium", value: units.iconSizes.medium},
            {text: "large", value: units.iconSizes.large},
            {text: "huge", value: units.iconSizes.huge}
        ]
        textRole: "text"
        valueRole: "value"

        currentIndex: model.findIndex((element) => element.value === plasmoid.configuration.iconSize)
    }
}
