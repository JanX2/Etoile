NSObject subclass: OverlayShelfController
[
	| isVisible window controller |

	init [
		'OverlayShelfController init' log.

		"Shelf is initially hidden"
		isVisible := 'no'.
	
		NSApplication sharedApplication setDelegate: self.
		ScriptCenter sharedInstance enableScripting.
		ScriptCenter sharedInstance scriptObject:self withName:'Shelf'.

		ScriptCenter scriptDictionaryForApplication: 'OverlayShelf' log.
		
		controller := OverlayShelfControllerObjC alloc init.
		window := controller window.
		^ self.
	]

	" scripting methods "
	
	toggle [
		'Toggled' log.
		(isVisible = 'no') ifTrue:[
			self show.
		] ifFalse:[
			self hide.
		].
	]

	show [
		'(Shelf to be shown now)' log.
		isVisible := 'yes'.
		window makeKeyAndOrderFront: self.
	]

	hide [
		'(Shelf to be hidden now)' log.
		isVisible := 'no'.
		window orderOut: self.
	]
]
