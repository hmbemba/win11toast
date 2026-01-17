## Advanced Toast Example
## 
## Demonstrates the ToastBuilder API for creating complex notifications
## 
## Compile: nim c -r advanced_toast.nim

import ./win11toast
import std/options

when isMainModule:
    when defined(windows):
        proc main =
            initWinRT()
            defer: uninitWinRT()

            # Example 1: Toast with icon and image
            echo "Example 1: Toast with icon and image"
            block:
                let xml = newToastBuilder()
                    .setTitle("Image Toast")
                    .setBody("This toast has an icon and an image!")
                    .setIcon("https://unsplash.it/64?image=669")
                    .setImage("https://unsplash.it/300/200?image=1005")
                    .buildXml()

                let handle = showToast(xml)
                releaseToast(handle)

            # Example 2: Toast with buttons
            echo "Example 2: Toast with buttons"
            block:
                let xml = newToastBuilder()
                    .setTitle("Action Toast")
                    .setBody("Choose an option:")
                    .addButton("Yes", "action:yes")
                    .addButton("No", "action:no")
                    .addButton("Maybe", "action:maybe")
                    .buildXml()

                let handle = showToast(xml)
                releaseToast(handle)

            # Example 3: Toast with text input
            echo "Example 3: Toast with text input"
            block:
                let xml = newToastBuilder()
                    .setTitle("Reply Toast")
                    .setBody("Enter your response:")
                    .addInput("reply", placeHolderContent = "Type here...")
                    .addButton("Send", "action:send")
                    .buildXml()

                let handle = showToast(xml)
                releaseToast(handle)

            # Example 4: Toast with selection dropdown
            echo "Example 4: Toast with selection"
            block:
                let xml = newToastBuilder()
                    .setTitle("Select Toast")
                    .setBody("Choose a fruit:")
                    .addSelection("fruit", @[
                        ("apple", "Apple")
                        ,("banana", "Banana")
                        ,("cherry", "Cherry")
                    ])
                    .addButton("Submit", "action:submit")
                    .buildXml()

                let handle = showToast(xml)
                releaseToast(handle)

            # Example 5: Toast with custom audio
            echo "Example 5: Toast with custom audio"
            block:
                let xml = newToastBuilder()
                    .setTitle("Audio Toast")
                    .setBody("This toast plays a notification sound!")
                    .setAudio("ms-winsoundevent:Notification.Looping.Alarm")
                    .buildXml()

                let handle = showToast(xml)
                releaseToast(handle)

            # Example 6: Alarm scenario
            echo "Example 6: Alarm toast"
            block:
                let xml = newToastBuilder()
                    .setTitle("Wake Up!")
                    .setBody("Time to get going!")
                    .setScenario(tsAlarm)
                    .setDuration(tdLong)
                    .addButton("Snooze", "action:snooze")
                    .addButton("Dismiss", "action:dismiss")
                    .buildXml()

                let handle = showToast(xml)
                releaseToast(handle)

            # Example 7: Silent toast
            echo "Example 7: Silent toast"
            block:
                let xml = newToastBuilder()
                    .setTitle("Silent Toast")
                    .setBody("This toast makes no sound")
                    .setSilent()
                    .buildXml()

                let handle = showToast(xml)
                releaseToast(handle)

            # Example 8: Toast with attribution
            echo "Example 8: Toast with attribution"
            block:
                let xml = newToastBuilder()
                    .setTitle("News Alert")
                    .setBody("Breaking news: Something happened!")
                    .setAttribution("via NewsApp")
                    .buildXml()

                let handle = showToast(xml)
                releaseToast(handle)

            echo "All advanced toasts sent!"
        main()
    else:
        echo "This example only works on Windows."
