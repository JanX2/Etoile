#! /usr/bin/env ioobjc

/* First we load some frameworks we rely on 
*/
DynLib open("./Source/obj/libIconKit.so")


// This is part of ObjcBridge now

addVariableNamed: := method(name,
  self setSlot(name, doString("method(?_" .. name .. ")"))
  self setSlot("set" .. name asCapitalized .. ":", doString("method(value, self _" .. name .. " := value ; self)"))
  nil
)

NSMakePoint := method(x, y, Point clone set(x, y))
NSMakeSize := method(w, h, Point clone set(w, h))
NSMakeRect := method(x, y, w, h, Box clone set(NSMakePoint(x, y), NSMakeSize(w, h)))

IKCompositedImagePositionNone := 0
IKCompositedImagePositionCenter := 16
IKCompositedImagePositionBottom := 1
IKCompositedImagePositionLeft := 2
IKCompositedImagePositionTop := 4
IKCompositedImagePositionRight := 8
IKCompositedImagePositionTopLeft := IKCompositedImagePositionTop + IKCompositedImagePositionLeft
IKCompositedImagePositionTopRight := IKCompositedImagePositionTop + IKCompositedImagePositionRight
IKCompositedImagePositionBottomRight := IKCompositedImagePositionBottom + IKCompositedImagePositionRight
IKCompositedImagePositionBottomLeft := IKCompositedImagePositionBottom + IKCompositedImagePositionLeft

ObjcBridge autoLookupClassNamesOn

app := NSApplication sharedApplication

provider := IKApplicationIconProvider alloc initWithBundlePath:("/System/Applications/Gorm.app")

icon := provider applicationIcon

// Test Compositor

provider := IKApplicationIconProvider alloc initWithBundlePath:("/System/Applications/ProjectCenter.app")
icon2 := provider applicationIcon

compositor := IKCompositor alloc initWithImage:(icon)
/*compositor compositeImage:withPosition:(icon2, 1)
compositor compositeImage:withPosition:(icon2, 2)
compositor compositeImage:withPosition:(icon2, 4)
compositor compositeImage:withPosition:(icon2, 8)
compositor compositeImage:withPosition:(icon2, 16)*/
compositor compositeImage:withPosition:(icon2, IKCompositedImagePositionTop)
/*compositor compositeImage:withPosition:(icon2, IKCompositedImagePositionTopLeft)
compositor compositeImage:withPosition:(icon2, IKCompositedImagePositionTopRight)
compositor compositeImage:withPosition:(icon2, IKCompositedImagePositionBottomLeft)
compositor compositeImage:withPosition:(icon2, IKCompositedImagePositionBottomRight)*/


newIcon := compositor render

//icon := provider documentIconForExtension:("gorm")

contentRect := NSMakeRect(100, 100, 400, 350)
window := NSWindow alloc initWithContentRect:styleMask:backing:defer:(contentRect, 1, 2, false)

iconView := NSImageView alloc initWithFrame:(contentRect)
window setContentView:(iconView)

iconView setImage:(newIcon)
window makeKeyAndOrderFront:(nil)

//NSFileManager defaultManager buildDirectoryStructureForPath:("/home/qmathe/whatever/whenever/wherever")

ObjcBridge main
