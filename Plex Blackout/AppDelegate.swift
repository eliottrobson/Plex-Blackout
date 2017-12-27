//
//  AppDelegate.swift
//  Plex Blackout
//
//  Created by Eliott Robson on 23/12/2017.
//  Copyright © 2017 Eliott Robson. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var statusMenu: NSMenu!
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    let plexApp = "tv.plex.player";
    var screenWidth = NSScreen.main!.frame.width;
    var screenHeight = NSScreen.main!.frame.height;
    var originalBrightness = Float(1.0);
    var overlayWindow: NSWindow?;

    @IBAction func quitClicked(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(self)
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(appDidLaunch(notification:)), name: NSWorkspace.didLaunchApplicationNotification, object: nil);
        
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(appDidTerminate(notification:)), name: NSWorkspace.didTerminateApplicationNotification, object: nil);
        
        statusItem.title = "Plex Blackout";
        statusItem.menu = statusMenu;
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        NSWorkspace.shared.notificationCenter.removeObserver(self);
        
        plexTerminated();
    }

    @objc private func appDidLaunch(notification: Notification) {
        let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication;
        let appId = app?.bundleIdentifier;
        if (appId == plexApp) {
            usleep(500000);
            plexLaunched();
            activateApp(app: app!);
        }
    }
    
    @objc private func appDidTerminate(notification: Notification) {
        let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication;
        let appId = app?.bundleIdentifier;
        if (appId == plexApp) {
            plexTerminated();
        }
    }
    
    private func plexLaunched() {
        originalBrightness = getBrightness();
        setBrightness(brightness: 0);
        
        createBlackWindow();
    }
    
    private func plexTerminated() {
        setBrightness(brightness: originalBrightness);
        
        closeBlackWindow();
    }
    
    private func getBrightness() -> Float {
        var brightness = Float(1.0);
        
        let service = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IODisplayConnect"));
        
        IODisplayGetFloatParameter(service, 0, kIODisplayBrightnessKey as CFString!, &brightness);
        IOObjectRelease(service);
        
        return brightness;
    }
    
    private func setBrightness(brightness: Float) {
        let service = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IODisplayConnect"))
        
        IODisplaySetFloatParameter(service, 0, kIODisplayBrightnessKey as CFString!, brightness)
        IOObjectRelease(service)
    }
    
    private func createBlackWindow() {
        if self.overlayWindow != nil {
            self.overlayWindow?.close();
            self.overlayWindow = nil;
        }
        
        self.overlayWindow = NSWindow(contentRect: NSMakeRect(0, 0, self.screenWidth, self.screenHeight), styleMask: [.borderless], backing: .buffered, defer: false);
        
        if let win = self.overlayWindow {
            win.title = "Plex Blackout";
            win.backgroundColor = NSColor.black;
            win.makeKeyAndOrderFront(nil);
            win.level = .floating
            win.isReleasedWhenClosed = false;
            
            win.toggleFullScreen(self);
            
            usleep(500000);
            NSApp.presentationOptions = [.autoHideDock, .autoHideMenuBar]
        }
    }
    
    private func closeBlackWindow() {
        if self.overlayWindow != nil {
            self.overlayWindow?.close();
            self.overlayWindow = nil;
        }
        
        NSApp.presentationOptions = []
    }
    
    private func activateApp(app: NSRunningApplication) {
        app.activate(options: [.activateIgnoringOtherApps]);
    }
}
