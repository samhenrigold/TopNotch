# ``TopNotch``

![TopNotch. Hide a message under the notch. It'll be our little secret.](./TopNotch/TopNotch.docc/Resources/banner.png)

## Overview

TopNotch is a lil Swift package that lets you **hide a custom view underneath the device’s notch**. Since it’ll only be visible in screenshots and screen recordings, you can have some fun. **Put a version string in there**, maybe use it as a branding moment to **stick your logo there**, write your darkest secrets, whatever your little heart desires.

If you opt to actually write your little secrets there, you can set `shouldHideForTaskSwitcher` on `TopNotchConfiguration` to hide the view when `sceneWillDeactivateNotification` gets called. It'll come back after `sceneDidActivateNotification` is called or if you ask nicely. 

It automatically calculates the notch’s exclusion area (using an undocumented `_exclusionArea` property on UIScreen). Since it doesn't always return the right values for older notch styles, I'm applying some manual, device-specific adjustments to make sure it stays hidden on all devices.

> [!WARNING]
> Because TopNotch relies on undocumented APIs, it may not be App Store safe. Give it a shot though. I dare you.

https://github.com/samhenrigold/TopNotch/blob/main/TopNotch/TopNotch.docc/Resources/demo.mp4

## TODO
- Reduce logging pollution
- Make the SwiftUI adapter useful

## Usage

I've attached a little demo project if that's how you roll. TL;DR:

```swift
// Create a custom view (or use your own) to display behind the notch.
let notchLabel = UILabel()
notchLabel.text = "Hi Mom"
notchLabel.textAlignment = .center
notchLabel.textColor = .white
notchLabel.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.7)

// Show the notch view.
TopNotchManager.shared.show(customView: notchLabel, with: TopNotchConfiguration(animationDuration: 0.3,
                                                                                   shouldAnimate: true,
                                                                                   shouldHideForTaskSwitcher: true))

// To hide it:
TopNotchManager.shared.hide()
```
