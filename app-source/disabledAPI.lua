-----------------------------------------------------------------------------------------------------------------------
-- These functions are disabled due to (current) HTML5 build, GitHub pages/CORS and/or other Playground limitations. --
-- NB! Some of these functions do work, like opening web views, but they've been disabled to keep the app contained. --
-----------------------------------------------------------------------------------------------------------------------

local prefix = "WARNING: "
local msg = "has been disabled in Solar2D Playground. To use it, you need to download and install Solar2D from https://solar2d.com/."

-- physics --------------------------------------------------------
local physics = physics or require("physics")
function physics.setDrawMode()
    print( prefix .. "physics.setDrawMode() " .. msg )
end

-- display --------------------------------------------------------
function display.loadRemoteImage()
    print( prefix .. "display.loadRemoteImage() " .. msg )
end

function display.save()
    print( prefix .. "display.save() " .. msg )
end

-- network --------------------------------------------------------
function network.request()
    print( prefix .. "network.request() " .. msg )
end

function network.cancel()
    print( prefix .. "network.cancel() " .. msg )
end

function network.download()
    print( prefix .. "network.download() " .. msg )
end

function network.upload()
    print( prefix .. "network.upload() " .. msg )
end

function network.canDetectNetworkStatusChanges()
    print( prefix .. "network.canDetectNetworkStatusChanges() " .. msg )
end

function network.setStatusListener()
    print( prefix .. "network.setStatusListener() " .. msg )
end

-- media --------------------------------------------------------
function media.capturePhoto()
    print( prefix .. "media.capturePhoto() " .. msg )
end

function media.captureVideo()
    print( prefix .. "media.captureVideo() " .. msg )
end

function media.hasSource()
    print( prefix .. "media.hasSource() " .. msg )
end

function media.newRecording()
    print( prefix .. "media.newRecording() " .. msg )
end

function media.playVideo()
    print( prefix .. "media.playVideo() " .. msg )
end

function media.save()
    print( prefix .. "media.save() " .. msg )
end

function media.selectPhoto()
    print( prefix .. "media.selectPhoto() " .. msg )
end

function media.selectVideo()
    print( prefix .. "media.selectVideo() " .. msg )
end

-- system --------------------------------------------------------
function system.cancelNotification()
    print( prefix .. "system.cancelNotification() " .. msg )
end

function system.canOpenURL()
    print( prefix .. "system.canOpenURL() " .. msg )
end

function system.openURL()
    print( prefix .. "system.openURL() " .. msg )
end

function system.scheduleNotification()
    print( prefix .. "system.scheduleNotification() " .. msg )
end

function system.setAccelerometerInterval()
    print( prefix .. "system.setAccelerometerInterval() " .. msg )
end

function system.setGyroscopeInterval()
    print( prefix .. "system.setGyroscopeInterval() " .. msg )
end

function system.setLocationAccuracy()
    print( prefix .. "system.setLocationAccuracy() " .. msg )
end

function system.setLocationThreshold()
    print( prefix .. "system.setLocationThreshold() " .. msg )
end

function system.vibrate()
    print( prefix .. "system.vibrate() " .. msg )
end

-- native --------------------------------------------------------
function native.cancelWebPopup()
    print( prefix .. "native.cancelWebPopup() " .. msg )
end

function native.getSync()
    print( prefix .. "native.getSync() " .. msg )
end

function native.newMapView()
    print( prefix .. "native.newMapView() " .. msg )
end

function native.newVideo()
    print( prefix .. "native.newVideo() " .. msg )
end

function native.newWebView()
    print( prefix .. "native.newWebView() " .. msg )
end

function native.requestExit()
    print( prefix .. "native.requestExit() " .. msg )
end

function native.showAlert()
    print( prefix .. "native.showAlert() " .. msg )
end

function native.showPopup()
    print( prefix .. "native.showPopup() " .. msg )
end

function native.showWebPopup()
    print( prefix .. "native.showWebPopup() " .. msg )
end

function native.setSync()
    print( prefix .. "native.setSync() " .. msg )
end

-- io --------------------------------------------------------
function io.close()
    print( prefix .. "io.close() " .. msg )
end

function io.flush()
    print( prefix .. "io.flush() " .. msg )
end

function io.input()
    print( prefix .. "io.input() " .. msg )
end

function io.lines()
    print( prefix .. "io.lines() " .. msg )
end

function io.open()
    print( prefix .. "io.open() " .. msg )
end

function io.output()
    print( prefix .. "io.output() " .. msg )
end

function io.read()
    print( prefix .. "io.read() " .. msg )
end

function io.tmpfile()
    print( prefix .. "io.tmpfile() " .. msg )
end

function io.type()
    print( prefix .. "io.type() " .. msg )
end

function io.write()
    print( prefix .. "io.write() " .. msg )
end