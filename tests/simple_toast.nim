## Simple Toast Example
## 
## Demonstrates basic usage of win11toast
## 
## Compile: nim c -r simple_toast.nim

import ./win11toast
import options

when isMainModule:
    when defined(windows):
        proc main =
            initWinRT()
            defer: uninitWinRT()

            # Basic toast
            echo "Sending basic toast..."
            notify(
                title = "Hello World"
                ,body  = "This is a basic notification from Nim!"
            )

            # Toast with custom app ID (use an installed app's ID for icon)
            echo "Sending toast with app ID..."
            notify(
                title = "Custom App"
                ,body  = "Using a custom application ID"
                ,appId = "Microsoft.Windows.Explorer"
            )

            # Toast with duration
            echo "Sending long toast..."
            notify(
                title    = "Long Toast"
                ,body     = "This toast will stay longer on screen"
                ,duration = some(tdLong)
            )

            # Toast with click action
            echo "Sending clickable toast..."
            notify(
                title  = "Click Me!"
                ,body   = "Click this toast to open a URL"
                ,launch = "https://nim-lang.org"
            )

            echo "All toasts sent!"
        main()
    else:
        echo "This example only works on Windows."
