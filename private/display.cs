using System;
using System.Runtime.InteropServices;

namespace DisplayControl
{

    public struct POINT
    {
        /// <summary>
        ///  The x-coordinate of the point.
        /// </summary>
        public int x;

        /// <summary>
        /// The x-coordinate of the point.
        /// </summary>
        public int y;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct DISPDEV1
    {
        public int cb;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
        public string DeviceName;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)]
        public string DeviceString;
        public int StateFlags;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)]
        public string DeviceID;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)]
        public string DeviceKey;
    };


    [StructLayout(LayoutKind.Sequential)]
    public struct DEVMODE1
    {
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
        public string dmDeviceName;
        public short dmSpecVersion;
        public short dmDriverVersion;
        public short dmSize;
        public short dmDriverExtra;
        public int dmFields;

        public short dmOrientation;
        public short dmPaperSize;
        public short dmPaperLength;
        public short dmPaperWidth;

        public short dmScale;
        public short dmCopies;
        public short dmDefaultSource;
        public short dmPrintQuality;
        public short dmColor;
        public short dmDuplex;
        public short dmYResolution;
        public short dmTTOption;
        public short dmCollate;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
        public string dmFormName;
        public short dmLogPixels;
        public short dmBitsPerPel;
        public int dmPelsWidth;
        public int dmPelsHeight;

        public int dmDisplayFlags;
        public int dmDisplayFrequency;

        public int dmICMMethod;
        public int dmICMIntent;
        public int dmMediaType;
        public int dmDitherType;
        public int dmReserved1;
        public int dmReserved2;

        public int dmPanningWidth;
        public int dmPanningHeight;
    };



    public class User32
    {
        [DllImport("user32.dll")]
        public static extern int EnumDisplaySettings(string deviceName, int modeNum, ref DEVMODE1 devMode);
        [DllImport("user32.dll")]
        public static extern int ChangeDisplaySettings(ref DEVMODE1 devMode, int flags);

        public const int ENUM_CURRENT_SETTINGS = -1;
        public const int CDS_UPDATEREGISTRY = 0x01;
        public const int CDS_TEST = 0x02;
        public const int DISP_CHANGE_SUCCESSFUL = 0;
        public const int DISP_CHANGE_RESTART = 1;
        public const int DISP_CHANGE_FAILED = -1;


        [Flags()]
        public enum ChangeDisplaySettingsFlags : uint
        {
            CDS_NONE = 0,
            CDS_UPDATEREGISTRY = 0x00000001,
            CDS_TEST = 0x00000002,
            CDS_FULLSCREEN = 0x00000004,
            CDS_GLOBAL = 0x00000008,
            CDS_SET_PRIMARY = 0x00000010,
            CDS_VIDEOPARAMETERS = 0x00000020,
            CDS_ENABLE_UNSAFE_MODES = 0x00000100,
            CDS_DISABLE_UNSAFE_MODES = 0x00000200,
            CDS_RESET = 0x40000000,
            CDS_RESET_EX = 0x20000000,
            CDS_NORESET = 0x10000000
        }

        [DllImport("user32.dll")]
        public static extern int ChangeDisplaySettingsEx(string lpszDeviceName, ref DEVMODE1 lpDevMode, IntPtr hwnd, ChangeDisplaySettingsFlags dwflags, IntPtr lParam);

        [DllImport("user32.dll")]
        public static extern int EnumDisplaySettingsEx(string lpszDeviceName, int iModeNum, ref DEVMODE1 lpDevMode, uint dwFlags);

        [DllImport("user32.dll")]
        public static extern int EnumDisplayDevices(string lpDevice, uint iDevNum, ref DISPDEV1 lpDisplayDevice, uint dwFlags);
    }



    public class Functions
    {

        static public void EnumerateDisplays(uint dispNumber, ref DISPDEV1 dispDevice)
        {
            User32.EnumDisplayDevices(null, dispNumber, ref dispDevice, (uint)0);
        }

        // static public string ChangeResolution(string deviceName, int width, int height, int freq)
        static public string DetachDisplay(string deviceName)
        {

            DEVMODE1 dm = GetDevMode1();

            if (0 != User32.EnumDisplaySettingsEx(deviceName, User32.ENUM_CURRENT_SETTINGS, ref dm, 0))
            {

                dm.dmPelsWidth = 0;
                dm.dmPelsHeight = 0;
                dm.dmFields = 1572896;
                // dm.dmDisplayFrequency = freq;

                int iRet = User32.ChangeDisplaySettings(ref dm, User32.CDS_TEST);

                if (iRet == User32.DISP_CHANGE_FAILED)
                {
                    return "Unable to process your request. Sorry for this inconvenience.";
                }
                else
                {
                    iRet = User32.ChangeDisplaySettingsEx(deviceName, ref dm, (IntPtr)null, User32.ChangeDisplaySettingsFlags.CDS_UPDATEREGISTRY, (IntPtr)0);
                    switch (iRet)
                    {
                        case User32.DISP_CHANGE_SUCCESSFUL:
                            {
                                return "Success";
                            }
                        case User32.DISP_CHANGE_RESTART:
                            {
                                return "You need to reboot for the change to happen.\n If you feel any problems after rebooting your machine\nThen try to change resolution in Safe Mode.";
                            }
                        default:
                            {
                                return iRet.ToString();
                            }
                    }

                }


            }
            else
            {
                return "Failed to change the resolution.";
            }
        }

        private static DEVMODE1 GetDevMode1()
        {
            DEVMODE1 dm = new DEVMODE1();
            dm.dmDeviceName = new String(new char[32]);
            dm.dmFormName = new String(new char[32]);
            dm.dmSize = (short)Marshal.SizeOf(dm);
            return dm;
        }
    }
}