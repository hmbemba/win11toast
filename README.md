# Win11Toast for Nim

A pure Nim library for creating Windows 10/11 toast notifications using the Windows Runtime (WinRT) APIs.

Based on the Python [win11toast](https://github.com/GitHub30/win11toast) library and [valinet's plain C implementation](https://gist.github.com/valinet/3283c79ba35fc8f103c747c8adbb6b23).

## Features

- Pure Nim implementation (no C++ shim required)
- Fluent builder API for constructing complex toasts
- Support for:
  - Title, body, and attribution text
  - App icons and images (local or URL)
  - Action buttons
  - Text input fields
  - Selection dropdowns
  - Progress bars
  - Custom audio sounds
  - Click-to-launch URLs
  - Toast scenarios (default, alarm, reminder, incoming call, urgent)
  - Toast duration (short/long)
  - Tag and group for toast management

## Installation

```bash
nimble install winim
# Then copy win11toast.nim to your project
```

Or add to your `.nimble` file:
```nim
requires "winim >= 3.9.0"
```

## Quick Start

```nim
import win11toast

# Simple notification (fire and forget)
notify("Hello World", "This is a notification!")

# Notification with click action
notify(
    title  = "Click Me!"
    ,body   = "Click to open Nim website"
    ,launch = "https://nim-lang.org"
)

# Get handle for later use
let handle = toast("Title", "Body")
# ... do something ...
releaseToast(handle)
```

## Builder API

For more complex notifications, use the `ToastBuilder`:

```nim
import win11toast

let xml = newToastBuilder()
    .setTitle("Download Complete")
    .setBody("Your file has been downloaded.")
    .setIcon("https://example.com/icon.png")
    .setImage("https://example.com/preview.png")
    .addButton("Open", "action:open")
    .addButton("Dismiss", "action:dismiss")
    .setAudio("ms-winsoundevent:Notification.Mail")
    .buildXml()

let handle = showToast(xml)
releaseToast(handle)
```

## API Reference

### High-Level Functions

#### `notify(...)`
Fire-and-forget notification. Resources are automatically released.

```nim
proc notify*(
    title      : string = ""
    ,body       : string = ""
    ,appId      : string = DEFAULT_APP_ID
    ,icon       : string = ""
    ,image      : string = ""
    ,duration   : Option[ToastDuration] = none(ToastDuration)
    ,scenario   : ToastScenario = tsDefault
    ,launch     : string = ""
    ,audio      : string = ""
    ,silent     : bool = false
    ,inputs     : seq[string] = @[]
    ,buttons    : seq[string] = @[]
    ,tag        : string = ""
    ,group      : string = ""
)
```

#### `toast(...)`
Show notification and return handle for later use.

```nim
proc toast*(...): ToastNotificationHandle
```

#### `releaseToast(handle)`
Release toast notification resources.

### ToastBuilder Methods

| Method | Description |
|--------|-------------|
| `setTitle(title)` | Set notification title |
| `setBody(body)` | Set notification body text |
| `setAttribution(text)` | Set attribution text (bottom line) |
| `setScenario(scenario)` | Set toast scenario (default, alarm, reminder, etc.) |
| `setDuration(duration)` | Set display duration (short or long) |
| `setLaunch(url)` | Set click action URL |
| `setIcon(src, placement, hintCrop)` | Set app logo icon |
| `setImage(src, placement, alt)` | Set hero/inline image |
| `setProgress(title, status, value, override)` | Add progress bar |
| `setAudio(src, loop, silent)` | Set notification sound |
| `setSilent()` | Make notification silent |
| `addInput(id, type, placeholder, title)` | Add text input field |
| `addSelection(inputId, items)` | Add selection dropdown |
| `addButton(content, arguments, activationType)` | Add action button |
| `setTag(tag)` | Set toast tag for updates |
| `setGroup(group)` | Set toast group for management |
| `buildXml()` | Generate toast XML string |

### Enums

#### `ToastScenario`
- `tsDefault` - Standard notification
- `tsAlarm` - Alarm notification (stays until dismissed)
- `tsReminder` - Reminder notification
- `tsIncoming` - Incoming call style
- `tsUrgent` - Urgent notification

#### `ToastDuration`
- `tdShort` - Short display (~5 seconds)
- `tdLong` - Long display (~25 seconds)

## Audio Sources

Use Microsoft's built-in sounds:
- `ms-winsoundevent:Notification.Default`
- `ms-winsoundevent:Notification.Mail`
- `ms-winsoundevent:Notification.Reminder`
- `ms-winsoundevent:Notification.SMS`
- `ms-winsoundevent:Notification.Looping.Alarm`
- `ms-winsoundevent:Notification.Looping.Call`

## App ID

The `appId` parameter determines which app icon appears on the toast. Use a valid Application User Model ID (AUMID) from an installed app.

To find valid AUMIDs, run in PowerShell:
```powershell
Get-StartApps
```

Common examples:
- `Microsoft.Windows.Explorer` - File Explorer
- `Microsoft.WindowsTerminal_8wekyb3d8bbwe!App` - Windows Terminal

## Requirements

- Windows 10 or later
- Nim >= 1.6.0
- winim >= 3.9.0

## Limitations

1. **Event Handlers**: This version does not support event handlers for activated/dismissed/failed events. The Python version uses async callbacks which require implementing COM delegate interfaces.

2. **Progress Updates**: True progress updates (NotificationData) require additional WinRT interfaces. The current implementation shows static progress bars.

3. **COM Activation**: For activation when the app is closed, you need COM server registration which is beyond this library's scope.

## License

MIT License

## Credits

- [win11toast](https://github.com/GitHub30/win11toast) - Python implementation
- [valinet's gist](https://gist.github.com/valinet/3283c79ba35fc8f103c747c8adbb6b23) - Plain C implementation
- [winim](https://github.com/khchen/winim) - Windows API for Nim
