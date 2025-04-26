<div align="center">
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="logo.png">
  <img alt="Logo" src="logo.png" height="150px">
</picture>
<br>
Acer® Battery Limit Switcher
</div>
<br>

# Acer® Battery Limit Switcher
KDE Plasma widget to turn on/off the Battery Charge Limit feature in compatible Acer® laptops.  
For more information on this topic see: 
- [Battery Charge Limit and Battery Calibration](https://community.acer.com/en/kb/articles/140-calibrate-your-battery-using-acer-care-center)
- [acer-wmi-battery](https://github.com/frederik-h/acer-wmi-battery)

## Install

### Dependencies
- The acer-wmi-battery driver is needed for the plasmoid to work.
- One of the following tools is required for notifications to work. Note that in many distros at least one of the two is installed by default, check it out.
  - [notify-send](https://www.commandlinux.com/man-page/man1/notify-send.1.html) - a program to send desktop notifications.
  - [zenity](https://www.commandlinux.com/man-page/man1/zenity.1.html) - display GTK+ dialogs.

### From KDE Store
You can find it in your software center, in the subcategories `Plasma Addons > Plasma Widgets`.  
Or you can download or install it directly from the [KDE Store](https://store.kde.org/p/2079000/) website.

### Manually
- Download/clone this repo.
- Run from a terminal the command `plasmapkg2 -i [widget folder name]`.

## Disclaimer
I'm not a widget or KDE developer, I did this by looking at other widgets, using AI chatbots, consulting documentation, etc. So use it at your own risk.
Any recommendations and contributions are welcome.

## Screenshots

![Screenshot_20250426_195356](https://github.com/user-attachments/assets/8ca62e11-33a7-4687-8015-9df8f0601db5)
