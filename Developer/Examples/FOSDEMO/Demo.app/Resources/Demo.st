NSObject subclass: Demo 
[
	run
	[ | nsapp |
		nsapp := ETApplication sharedApplication.
		nsapp setDelegate: (DemoApp new).
		NSBundle loadNibNamed: 'MainMenu' owner: nsapp.
		nsapp run.
	]
]

NSObject subclass: DemoApp
[
	applicationDidFinishLaunching: notification
	[ | scripting |
		" If the DynamicDevelopment class exists, start it! "
		(C NSClassFromString: 'DynamicDevelopment') start.
		scripting := ScriptCenter sharedInstance.
		scripting setApplicationScriptingName: 'FOSDEMO'.
		scripting enableScripting.
		"
		C objc_setAssociatedObject:  {self . 42 . 'fishes' . C enumValue: OBJC_ASSOCIATION_ASSIGN } .
		(C objc_getAssociatedObject: {self . 42 }) log.
		FakeClass new notAMessage.
		"
	]
]
