// This isn't guaranteed to catch all mobile devices, but it should catch most of them, which is good enough.

// The function will first check for a touchscreen, which all modern mobile devices should have. If one can't
// be found, then it's likely not a mobile device. If one is found, then check that it isn't a touchscreen
// enabled Windows or MacOS. Linux can't be reliably checked for as some Android devices identify as Linux.

function isMobile() {
    let hasTouchscreen = false;
    try {
        document.createEvent("TouchEvent");
        hasTouchscreen = true;
    } catch(e) {
        return false;
    }
    if (hasTouchscreen) {
        var mobileOS = ["iPhone", "iPad", "iPod", "Android", "BlackBerry"];
        if (mobileOS.indexOf(window.navigator.platform) !== -1) {
            return true;
        }
            var desktopOS = ["Win32", "Win64", "Windows", "WinCE", "Mac"];
        if (desktopOS.indexOf(window.navigator.platform) !== -1) {
            return false;
        }
    }
    return true;
}