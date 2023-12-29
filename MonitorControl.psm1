Add-Type -TypeDefinition (Get-Content -Path "$PSScriptRoot\private\monitor.cs" -Raw)
Add-Type -TypeDefinition (Get-Content -Path "$PSScriptRoot\private\display.cs" -Raw)

function Get-PhysMonitorHandles {
    param(
        
    )
    [MonitorCtrlCS.Program]::InvokeEnumMethod() | Out-Null

    $MonitorInfosArr = [MonitorCtrlCS.Program]::_monitorInfos

    $MonitorHandlesObj = $MonitorInfosArr | ForEach-Object {
        $mon = [MonitorCtrlCS.Physical_Monitor]::new()
        [MonitorCtrlCS.Program]::GetPhysicalMonitorsFromHMONITOR($_.MonitorHandle, 1, [ref]$mon) | Out-Null
        [PSCustomObject]@{
            MonitorName       = $_.MonitorInfo.DeviceName
            PhysMonitorObj    = $mon
            PhysMonitorHandle = $mon.hPhysicalMonitor
        }
    }

    [MonitorCtrlCS.Program]::_monitorInfos.Clear()

    return $MonitorHandlesObj
}

function Remove-PhysMonHandle {
    param (
        [Parameter(ValueFromPipelineByPropertyName = $true, Mandatory = $true)]
        [System.IntPtr]$PhysMonitorHandle,
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [string]$MonitorName
    )
    process {
        if (-not ([MonitorCtrlCS.Program]::DestroyPhysicalMonitor($PhysMonitorHandle))) {
            throw "Failed to destroy monitor handle for: $MonitorName"
        }
        else {
            Write-Verbose "Destroyed monitor handle for: $MonitorName"
        }
    }

}

function Set-VCP {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipelineByPropertyName = $true, Mandatory = $true)]
        [string]$MonitorName,
        [Uint32]$VCPCode,
        [Uint32]$VCPValue
    )
    $PhysMons = Get-PhysMonitorHandles
    $MonitorHandle = ($PhysMons | Where-Object { $_.MonitorName -eq $MonitorName }).PhysMonitorHandle
    [MonitorCtrlCS.Program]::SetVCPFeature($MonitorHandle, $VCPCode, $VCPValue)
    $PhysMons | Remove-PhysMonHandle
}

function Get-MonitorNames {
    [CmdletBinding()]
    param (
    )
    $hnd = Get-PhysMonitorHandles
    $hnd | Select-Object MonitorName
    $hnd | Remove-PhysMonHandle
}

function Set-MonitorOSDLanguage {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipelineByPropertyName = $true, Mandatory = $true)]
        [string]$MonitorName,
        [ValidateSet(
            'Chinese',
            'English',
            'French',
            'German',
            'Italian',
            'Japanese',
            'Korean',
            'Portuguese',
            'Russian',
            'Spanish',
            'Swedish',
            'Turkish',
            'SimplifiedChinese',
            'PortugueseBrazilian',
            'Arabic',
            'Bulgarian',
            'Croatian',
            'Czech',
            'Danish',
            'Dutch',
            'Estonian',
            'Finnish',
            'Greek',
            'Hebrew',
            'Hindi',
            'Hungarian',
            'Latvian',
            'Lithuanian',
            'Norwegian',
            'Polish',
            'Romanian',
            'Serbian',
            'Slovak',
            'Slovenian'
        )]
        [string]$Language
    )
    process {
        $Languages = @{
            Chinese             = 0x01
            English             = 0x02
            French              = 0x03
            German              = 0x04
            Italian             = 0x05
            Japanese            = 0x06
            Korean              = 0x07
            Portuguese          = 0x08
            Russian             = 0x09
            Spanish             = 0x0A
            Swedish             = 0x0B
            Turkish             = 0x0C
            SimplifiedChinese   = 0x0D
            PortugueseBrazilian = 0x0E
            Arabic              = 0x0F
            Bulgarian           = 0x10
            Croatian            = 0x11
            Czech               = 0x12
            Danish              = 0x13
            Dutch               = 0x14
            Estonian            = 0x15
            Finnish             = 0x16
            Greek               = 0x17
            Hebrew              = 0x18
            Hindi               = 0x19
            Hungarian           = 0x1A
            Latvian             = 0x1B
            Lithuanian          = 0x1C
            Norwegian           = 0x1D
            Polish              = 0x1E
            Romanian            = 0x1F
            Serbian             = 0x20
            Slovak              = 0x21
            Slovenian           = 0x22
        }
        Set-VCP -MonitorName $MonitorName -VCPCode 0xCC -VCPValue $Languages[$Language]
    }
}

function Set-MonitorBrightness {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipelineByPropertyName = $true, Mandatory = $true)]
        [string]$MonitorName,
        [ValidateRange(1, 100)]
        [int]$BrightnessPercent
    )
    process {
        Set-VCP -MonitorName $MonitorName -VCPCode 0x10 -VCPValue $BrightnessPercent
    }
}

function Set-MonitorPowerMode {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipelineByPropertyName = $true, Mandatory = $true)]
        [string]$MonitorName,
        [ValidateSet('On', 'Standby', 'Suspend', 'Off', 'PhysicallyOff')]
        [string]$PowerMode
    )
    begin {
        $PowerModes = @{
            'On'            = 0x01
            'Standby'       = 0x02
            'Suspend'       = 0x03
            'Off'           = 0x04
            'PhysicallyOff' = 0x05 #Not part of the DPM or DPMS standards
        }
    }
    process {
        Set-VCP -MonitorName $MonitorName -VCPCode 0xD6 -VCPValue $PowerModes[$PowerMode]
    }
}

function Invoke-AllMonitorsStandbyMode {
    [MonitorCtrlCS.Program]::PowerOff(0xffff)
}

function Set-MonitorInput {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipelineByPropertyName = $true, Mandatory = $true)]
        [string]$MonitorName,
        [ValidateSet('Composite-1', 'Composite-2', 'S-Video-1', 'S-Video-2', 'Tuner-1', 'Tuner-2', 'Tuner-3', 'Component-1', 'Component-2', 'Component-3', 'DisplayPort-1', 'DisplayPort-2', 'HDMI-1', 'HDMI-2')]
        [string]$InputName
    )
    begin {
        $Inputs = @{
            'VGA-1'         = 0x01
            'VGA-2'         = 0x02
            'DVI-1'         = 0x03
            'DVI-2'         = 0x04
            'Composite-1'   = 0x05
            'Composite-2'   = 0x06
            'S-Video-1'     = 0x07
            'S-Video-2'     = 0x08
            'Tuner-1'       = 0x09
            'Tuner-2'       = 0x0A
            'Tuner-3'       = 0x0B
            'Component-1'   = 0x0C
            'Component-2'   = 0x0D
            'Component-3'   = 0x0E
            'DisplayPort-1' = 0x0F
            'DisplayPort-2' = 0x10
            'HDMI-1'        = 0x11
            'HDMI-2'        = 0x12
        }
    }
    process {
        Set-VCP -MonitorName $MonitorName -VCPCode 0x60 -VCPValue $Inputs[$InputName]
    }
}

function Remove-Display {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $DisplayName
    )
    [DisplayControl.Functions]::DetachDisplay($DisplayName)
}

function Set-Display {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $DisplayName,
        [Parameter()]
        [int]
        $ResolutionWidth,
        [Parameter()]
        [int]
        $ResolutionHeight,
        [Parameter()]
        [int]
        $RefreshRate
    )
    process {
        $devmode1 = [DisplayControl.DEVMODE1]::new()
        $devmode1.dmSize = [System.Runtime.InteropServices.Marshal]::SizeOf($devmode1)

        $devmode1arr = [System.Collections.Generic.List[DisplayControl.DEVMODE1]]::new()

        $i = 0
        while ([DisplayControl.User32]::EnumDisplaySettingsEx($DisplayName, $i, [ref] $devmode1, 0)) {
            $devmode1arr.Add($devmode1)
            $i++
        }

        $devmode1_tmp = $devmode1arr.where({ $_.dmPelsHeight -eq $ResolutionHeight -and $_.dmPelsWidth -eq $ResolutionWidth -and $_.dmDisplayFrequency -eq $RefreshRate })
        if ($devmode1_tmp.count -ge 1) {
            $devmode1 = $devmode1_tmp[0]
        }
        else {
            throw 'No matching display mode found'
        }

        $updateflags = [DisplayControl.User32+ChangeDisplaySettingsFlags]::CDS_UPDATEREGISTRY -bor [DisplayControl.User32+ChangeDisplaySettingsFlags]::CDS_NORESET
        $updateflags2 = [DisplayControl.User32+ChangeDisplaySettingsFlags]::CDS_UPDATEREGISTRY -bor [DisplayControl.User32+ChangeDisplaySettingsFlags]::CDS_RESET


        $res1 = [DisplayControl.User32]::ChangeDisplaySettingsEx($DisplayName, [ref] $devmode1, [System.IntPtr]::Zero, $updateflags, [System.IntPtr]::Zero)
        $res2 = [DisplayControl.User32]::ChangeDisplaySettingsEx($DisplayName, [ref] $devmode1, [System.IntPtr]::Zero, $updateflags2, [System.IntPtr]::Zero)

        if ($res1 -ne 0 -or $res2 -ne 0) {
            throw "Failed to set display mode for display: $DisplayName"
        }
        else {
            [PSCustomObject]@{
                DisplayName = $DisplayName
                Success     = $true
            }
        }
    }
}