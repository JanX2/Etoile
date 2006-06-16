/* #io
   docCopyright("Yen-Ju Chen", 2006)
   docLicense("BSD revised") 
   
   Usage: 'ioobjc example.io'

*/

ObjcBridge autoLookupClassNamesOn 

/* Application */
NSApp := NSApplication sharedApplication

frame := Box clone set( vector(200, 500), vector(420, 150) )

win := NSWindow alloc initWithContentRect:styleMask:backing:defer:(frame, 15, 2, 0)
win setTitle:("Io Window")

frame := Box clone set( vector(330, 10), vector(76, 25) )
actionButton := NSButton alloc initWithFrame:(frame)
actionButton setBezelStyle:(4)
actionButton setTitle:("Action")

frame := Box clone set( vector(30, 100), vector(300, 25) )
textField := NSTextField alloc initWithFrame:(frame)
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
