NSObject subclass: SmalltalkTool  [
	run [
		Tell application: 'FOSDEMO' to: [ :d |
			| app |
			app := d objectForKey: 'Application'.
			(nil == app) ifTrue: [
				ETTranscript show: 'Demo application is not running'; cr.
			].
			[ app terminate: nil ] onException: nil do: [].
		]
	]
]
