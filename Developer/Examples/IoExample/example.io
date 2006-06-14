/* #io
   docCopyright("Yen-Ju Chen", 2006)
   docLicense("BSD revised") 
   
   Usage: 'ioobjc example.io'

*/

ObjcBridge autoLookupClassNamesOn // useless

/* Application */
NSApp := ObjcBridge classNamed("NSApplication") sharedApplication

frame := Box clone set( vector(200, 500), vector(420, 150) )

Window := ObjcBridge classNamed("NSWindow")
win := Window alloc initWithContentRect:styleMask:backing:defer:(frame, 15, 2, 0)
win setTitle:("Io Window")

frame := Box clone set( vector(330, 10), vector(76, 25) )
ActionButton := ObjcBridge classNamed("NSButton")
actionButton := ActionButton alloc initWithFrame:(frame)
actionButton setBezelStyle:(4)
actionButton setTitle:("Action")

frame := Box clone set( vector(30, 100), vector(300, 25) )
textField := ObjcBridge classNamed("NSTextField") alloc initWithFrame:(frame)
textField setEditable: (1)

Delegate := Object clone
Delegate field :=  textField
Delegate buttonAction: := method (
	sender, self field setStringValue: ("Hello World")
) 
actionButton setTarget:(Delegate)
actionButton setAction:("buttonAction:")

win contentView addSubview:(actionButton)
win contentView addSubview:(textField)
win makeKeyAndOrderFront: NSApp

NSApp run
