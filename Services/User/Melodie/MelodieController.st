NSObject subclass: MelodieController
[
	| window  mainContainer  playlistContainer search  musicPlayerController URLTextField addURLWindow 
	  mainModel  playlistModel smartGroup ctxt |

	KnownExtensions	[
		^ {'mp3'. 'ogg'. 'flac'. 'aac'. 'm4a'}.
	]

	newContext [
		'Creating new object context' log.

		ctxt := COObjectContext alloc init.
		
		ETPlaylist setAutomaticallyMakeNewInstancesPersistent: 1.
		ETMusicFile setAutomaticallyMakeNewInstancesPersistent: 1.

		COObjectContext setCurrentContext: ctxt.
	
		mainModel := ETPlaylist new.
		playlistModel := ETPlaylist new.

               'Registered objects: ' log.
                ctxt registeredObjects log.    

	        NSUserDefaults standardUserDefaults setObject: (ctxt UUID stringValue) forKey: 'MellodieObjectContextUUID'.
		NSUserDefaults standardUserDefaults setObject: (mainModel UUID stringValue) forKey: 'MellodieMainModelUUID'. 
		NSUserDefaults standardUserDefaults setObject: (playlistModel UUID stringValue) forKey: 'MellodiePlaylistModelUUID'. 
	]

	loadContextWithUUID: uuid [
		'Requesting object context with UUID:' log.
		uuid log.

		ctxt := COObjectContext alloc initWithUUID: (ETUUID UUIDWithString: uuid).
		ETPlaylist setAutomaticallyMakeNewInstancesPersistent: 1.
		ETMusicFile setAutomaticallyMakeNewInstancesPersistent: 1.

		COObjectContext setCurrentContext: ctxt.

		mainModel := ctxt objectForUUID: (ETUUID UUIDWithString: (NSUserDefaults standardUserDefaults stringForKey: 'MellodieMainModelUUID')).
		playlistModel := ctxt objectForUUID: (ETUUID UUIDWithString: (NSUserDefaults standardUserDefaults stringForKey: 'MellodiePlaylistModelUUID')).
		
		

		'Deserialized main model:' log.
		mainModel log.
		'Deserialized playlist model:' log.
		playlistModel log.
		'ordered?' log.
		playlistModel isOrdered log.
	]

	init [
		| uuid |
		'EtoileTunesController init' log.

		uuid := (NSUserDefaults standardUserDefaults stringForKey: 'MellodieObjectContextUUID').
		(uuid == nil) ifTrue: [ self newContext. ]
		             ifFalse: [ self loadContextWithUUID: uuid. ].	
		^ self.
	]

	addToMainModel: obj [
		'Adding song: ' log.
		obj log.
		mainModel addMember: obj.
	]

	addPath: path [
		(self KnownExtensions containsObject: (path pathExtension))
			ifTrue: [ self addToMainModel: (ETMusicFile alloc initWithPath: path). ]
			ifFalse: [ 'unknown extension: ' log. path log. ].
	]

	addFiles: sender [
	| openPanel filename fm |
		openPanel := NSOpenPanel openPanel.
		openPanel setAllowsMultipleSelection: 0.
		openPanel setCanChooseDirectories: 1.
		openPanel runModalForTypes: (self KnownExtensions).
			
		filename := openPanel filenames lastObject.
		fm := NSFileManager defaultManager.
		(fm enumeratorAtPath: filename) allObjects foreach: [ :subFile | self addPath: (filename stringByAppendingPathComponent: subFile). ].
		"(fm enumeratorAtPath: filename) allObjects foreach: [ :subFile |  mainModel addMember: subFile. ]."

		mainContainer reloadAndUpdateLayout.
	]

	undo: sender [
		'undo' log.
		ctxt undo.

                mainModel := ctxt objectForUUID: (ETUUID UUIDWithString: (NSUserDefaults standardUserDefaults stringForKey: 'MellodieMainModelUUID')).
                playlistModel := ctxt objectForUUID: (ETUUID UUIDWithString: (NSUserDefaults standardUserDefaults stringForKey: 'MellodiePlaylistModelUUID')).
		
		mainContainer reloadAndUpdateLayout.
		playlistContainer reloadAndUpdateLayout.
	]

	redo: sender [	
		'redo' log.
		ctxt redo.

                mainModel := ctxt objectForUUID: (ETUUID UUIDWithString: (NSUserDefaults standardUserDefaults stringForKey: 'MellodieMainModelUUID')).
                playlistModel := ctxt objectForUUID: (ETUUID UUIDWithString: (NSUserDefaults standardUserDefaults stringForKey: 'MellodiePlaylistModelUUID')).

		mainContainer reloadAndUpdateLayout.
                playlistContainer reloadAndUpdateLayout.
	]

	addURL: sender [
	| string |
		addURLWindow orderOut: self.
		string := URLTextField stringValue stringByAddingPercentEscapesUsingEncoding: 4. 
		mainModel addMember: (ETMusicFile alloc initWithURL:(NSURL URLWithString:string)).
		mainContainer reloadAndUpdateLayout.
	]

	newPlaylist: sender [
	| newPlaylist |
		newPlaylist := ETPlaylist new.
		newPlaylist addMember:(ETMusicFile alloc initWithURL:(NSURL URLWithString: 'http://scfire-chi0l-1.stream.aol.com/stream/1018')).
		playlistModel addMember: newPlaylist.
		playlistContainer reloadAndUpdateLayout.
	]

	awakeFromNib [
	| layoutObject |
		layoutObject := ETOutlineLayout layout.
	
		layoutObject setDisplayName: 'Title' forProperty: 'kETTitleProperty'.
		layoutObject setDisplayName: 'Artist' forProperty: 'kETArtistProperty'.
		layoutObject setDisplayName: 'Album' forProperty: 'kETAlbumProperty'.
		layoutObject setDisplayName: 'URL' forProperty: 'kETURLProperty'.
	
		layoutObject setDisplayedProperties:
		    {'icon'. 'kETTitleProperty'. 'kETArtistProperty'. 'kETAlbumProperty'. 'kETURLProperty' }.

		mainContainer setSource: (mainContainer layoutItem).
		mainContainer layoutItem setRepresentedObject: mainModel.
		mainContainer setLayout: layoutObject.
		mainContainer setHasVerticalScroller: 1.
		mainContainer setTarget: self.
		mainContainer reloadAndUpdateLayout.
		mainContainer setDoubleAction: 'doubleClickInContainer:'.

		playlistContainer setSource: (playlistContainer layoutItem).
		playlistContainer layoutItem setRepresentedObject: playlistModel.
		playlistContainer setLayout: (ETOutlineLayout layout).
		playlistContainer setHasVerticalScroller: 0.
		playlistContainer setTarget: self.
		playlistContainer setDoubleAction: 'doubleClickInContainer:'.

		search setDelegate: self.
		search log.
	]

	controlTextDidChange: notif [
		('searched for: ' stringByAppendingString: (search stringValue)) log.
		smartGroup == nil ifTrue: [ self smartGroupOn. ].
		(search stringValue length = 0)
		    ifTrue: [ 
			mainContainer layoutItem setRepresentedObject: mainModel.
		]  ifFalse: [
			mainContainer layoutItem setRepresentedObject: smartGroup.
			smartGroup setPredicate: (NSPredicate predicateWithFormat: '(%K CONTAINS[cd] %@) OR (%K CONTAINS[cd] %@)'
			                                            argumentArray: {'kETTitleProperty' . search stringValue . 'kETAlbumProperty' . search stringValue }).
		].
		mainContainer reloadAndUpdateLayout.
	]

	smartGroupOn [
		'Turning on smart group.' log.
		smartGroup := COSmartGroup alloc init.
		smartGroup setTarget: mainModel.
		mainContainer layoutItem setRepresentedObject: smartGroup.
	]
	
	clearSearch: sender [
		search setStringValue: (NSString string). "FIXME: '' for empty string ? "
		self controlTextDidChange: nil.
	]

	doubleClickInContainer: sender [
		 'Got double-click on ' log.
		sender doubleClickedItem log.
		' in ' log.
		sender log.

		musicPlayerController playObject: (sender doubleClickedItem) start: 1.
	]
]
