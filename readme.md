MonitorControl (PS Module)
---

## Summary
Provides basic control over your monitor via VCP codes.

## Usage

Importing the module
```powershell
Import-Module 'C:\Path\To\MonitorControl.psd1'
```

Get Monitor Names
```powershell
Get-MonitorNames

MonitorName
-----------
\\.\DISPLAY3
\\.\DISPLAY1
\\.\DISPLAY2
```

Set brightness on a single monitor
```powershell
Set-MonitorBrightness -MonitorName '\\.\DISPLAY1' -BrightnessPercent 50
```

Set brightness on all monitors
```powershell
Get-MonitorNames | Set-MonitorBrightness -BrightnessPercent 100
```

Set all monitors OSD language to English
```powershell
Get-MonitorNames | Set-MonitorOSDLanguage -Language English
```

Turn all monitors off (note: if you set a monitor to Standby/Suspend, it will likely just turn back on again)
```powershell
Get-MonitorNames | Set-MonitorPowerMode -PowerMode Off
```

Change input of monitor 2 (you can use this to temporarily 'turn off' a monitor if you change to an input that is disconnected)
```powershell
Set-MonitorInput -MonitorName '\\.\DISPLAY2' -InputName 'HDMI-1'
```

Send arbitrary VCP codes (see DDCI_documentation_mccsV3.pdf)
```powershell
# Set Brightness to 100%
Set-VCP -MonitorName '\\.\DISPLAY1' -VCPCode 0x10 -VCPValue 100
```

## BETA FEATURES

### Remove-Display
Detaches a monitor effectively turning it off
```powershell
Remove-Display -DisplayName '\\.\DISPLAY1'
```

### Set-Display
Reattaches a monitor or allows you to set resolution/refresh-rate on a monitor already attached and in-use
```powershell
Set-Display -DisplayName '\\.\DISPLAY1' -ResolutionWidth 1920 -ResolutionHeight 1080 -RefreshRate 60
```

### Known Issues
The STRUCT used for DEVMODE does not contain the UNION needed for setting position so if your displays aren't oriented in `1 - 2 - 3` order, adding them back might put them out-of-order. I'm trying to figure out how to get this to work properly as it requires unsafe code which throws a memory access violation when trying to set the position.