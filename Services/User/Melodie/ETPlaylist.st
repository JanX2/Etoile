<< types = '{ "location" = "i8@0:4" }' >>

COGroup subclass: ETPlaylist [

	+playlistForPLSFileAtURL: aURL [
		| lines songURL playlist |
		lines := (NSString stringWithContentsOfURL: aURL)
			componentsSeparatedByNewline.
		
		playlist := ETPlaylist new.
		lines foreach: [ :line |
			(line hasPrefix: 'File') ifTrue: [
				songURL := line substringFromIndex: ((line rangeOfString: '=') location + 1).
				playlist addMember: (ETMusicFile alloc initWithURL:(NSURL URLWithString: songURL)).
			]
		].
		^ playlist.
	]

	init [
		super init.
		self tryStartPersistencyIfInstanceOfClass: (ETPlaylist class).
		^ self.
	]	
	
	isOrdered [
		^ true.
	]
]

