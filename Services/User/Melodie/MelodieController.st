" This is the main class for Melodie. It coordinates CoreObject and EtoileUI,
  handles adding new songs to the library.

  Its only interaction with music playback is invoking
  'musicPlayerController playLayoutItem:start:' when a song is double-clicked. "
  
NSObject subclass: MelodieController
[
	| window  mainContainer  playlistContainer search  musicPlayerController URLTextField addURLWindow 
	  mainModel  playlistModel smartGroup ctxt |

	knownExtensions	[
		knownExtensions == nil ifTrue: [
			knownExtensions := NSMutableArray array.
			(ETUTI typeWithString: 'public.audio') allSubtypes
				foreach: [ :type | knownExtensions addObjectsFromArray: (type fileExtensions) ].
		].
		^ knownExtensions.
	]

	newContext [
		| defaults | 
		'Creating new object context' log.

		ctxt := COObjectContext alloc init.	
		COObjectContext setCurrentContext: ctxt.
	
		mainModel := ETPlaylist new.
		playlistModel := ETPlaylist new.

		'Registered objects: ' log.
		ctxt registeredObjects log.    

		defaults := NSUserDefaults standardUserDefaults.
		defaults setUUID: (ctxt UUID) forKey: 'MellodieObjectContextUUID'.
		defaults setUUID: (mainModel UUID) forKey: 'MellodieMainModelUUID'. 
		defaults setUUID: (playlistModel UUID) forKey: 'MellodiePlaylistModelUUID'. 
	]

	reloadModelVariablesFromContext [
		| defaults |
		
		defaults := NSUserDefaults standardUserDefaults.
		mainModel := ctxt objectForUUID: (defaults UUIDForKey: 'MellodieMainModelUUID').
		playlistModel := ctxt objectForUUID: (defaults UUIDForKey: 'MellodiePlaylistModelUUID').
	]

	loadContextWithUUID: uuid [
		'Requesting object context with UUID:' log.
		uuid log.

		ctxt := COObjectContext alloc initWithUUID: uuid.
		COObjectContext setCurrentContext: ctxt.
	
		self reloadModelVariablesFromContext.
			
		'Deserialized main model:' log.
		mainModel log.
		'Deserialized playlist model:' log.
		playlistModel log.
	]


	init [
		| uuid |
		'EtoileTunesController init' log.
		ETPlaylist setAutomaticallyMakeNewInstancesPersistent: true.
		ETMusicFile setAutomaticallyMakeNewInstancesPersistent: true.

		uuid := (NSUserDefaults standardUserDefaults UUIDForKey: 'MellodieObjectContextUUID').
		(uuid == nil) ifTrue: [ self newContext. ]
		             ifFalse: [ self loadContextWithUUID: uuid. ].
		
		ctxt setDelegate: self.

		^ self.
	]

	addFile: path [
		(self knownExtensions containsObject: (path pathExtension))
		    ifTrue: [ mainModel addMember: (ETMusicFile alloc initWithPath: path). ]
	]

	" The following two methods can be moved to blocks in addFiles: once Smalltalk supports
	  nested blocks accessing variables "

	addDirectory: path [
		(NSFileManager defaultManager enumeratorAtPath: path) allObjects foreach:
		    [ :file | self addFile: (path stringByAppendingPathComponent: file) ].
	]

	addPath: path [
		(NSFileManager defaultManager directoryExistsAtPath: path)
		    ifTrue: [ self addDirectory: path ]
		    ifFalse: [ self addFile: path ].
	]
	
	" Called when the user selects Add Files from the menu "
	addFiles: sender [
		| openPanel |

		openPanel := NSOpenPanel openPanel.
		openPanel setAllowsMultipleSelection: true.
		openPanel setCanChooseDirectories: true.
		openPanel runModalForTypes: (self knownExtensions).

		openPanel filenames foreach: [ :path | self addPath: path ].
		mainContainer reloadAndUpdateLayout.
	]

	undo: sender [
		ctxt undo.
	]

	redo: sender [	
		ctxt redo.
	]

	addURL: sender [
		| string |

		addURLWindow orderOut: self.
		string := URLTextField stringValue stringByAddingPercentEscapesUsingEncoding: @NSUTF8StringEncoding. 
		mainModel addMember: (ETMusicFile alloc initWithURL:(NSURL URLWithString:string)).
		mainContainer reloadAndUpdateLayout.
	]

	newPlaylist: sender [
		| newPlaylist |

		newPlaylist := ETPlaylist new.
		"Put a sample radio stream in the playlist."
		newPlaylist addMember:(ETMusicFile alloc initWithURL:
		    (NSURL URLWithString: 'http://scfire-chi0l-1.stream.aol.com/stream/1018')).
		playlistModel addMember: newPlaylist.
		playlistContainer reloadAndUpdateLayout.
	]

	awakeFromNib [
		| layout |

		'known extensions: ' log.
		self knownExtensions foreach: [ :ext | ext log ].

		layout := ETOutlineLayout layout.
	
		layout setDisplayName: 'Title' forProperty: 'kETTitleProperty'.
		layout setDisplayName: 'Artist' forProperty: 'kETArtistProperty'.
		layout setDisplayName: 'Album' forProperty: 'kETAlbumProperty'.
		layout setDisplayName: 'URL' forProperty: 'kETURLProperty'.
	
		layout setDisplayedProperties:
		    {'icon'. 'kETTitleProperty'. 'kETArtistProperty'. 'kETAlbumProperty'. 'kETURLProperty' }.

		mainContainer setSource: (mainContainer layoutItem).
		mainContainer layoutItem setRepresentedObject: mainModel.
		mainContainer setLayout: layout.
		mainContainer setHasVerticalScroller: true.
		mainContainer setTarget: self.
		mainContainer reloadAndUpdateLayout.
		mainContainer setDoubleAction: 'doubleClickInContainer:'.

		playlistContainer setSource: (playlistContainer layoutItem).
		playlistContainer layoutItem setRepresentedObject: playlistModel.
		playlistContainer setLayout: (ETOutlineLayout layout).
		playlistContainer setHasVerticalScroller: false.
		playlistContainer setTarget: self.
		playlistContainer setDoubleAction: 'doubleClickInContainer:'.

		search setDelegate: self.

		ScriptCenter sharedInstance enableScriptingWithObjects:
		    (NSDictionary dictionaryWithObjects: { musicPlayerController  }
		                                forKeys: { 'MusicPlayerController' }).
	]

	" COObjectContext delegate method "
	objectContextDidMergeObjects: notif [
		'Merge occurred, reloading models from context and updating container layouts..' log.
		self reloadModelVariablesFromContext.
		mainContainer reloadAndUpdateLayout.
		playlistContainer reloadAndUpdateLayout.
	]

	controlTextDidChange: notif [
		smartGroup == nil ifTrue: [ self smartGroupOn. ].
		(search stringValue length = 0)
		    ifTrue: [ 
			mainContainer layoutItem setRepresentedObject: mainModel.
		]  ifFalse: [
			mainContainer layoutItem setRepresentedObject: smartGroup.
			smartGroup setPredicate:
			    (NSPredicate predicateWithFormat: '(%K CONTAINS[cd] %@) OR (%K CONTAINS[cd] %@)'
			        argumentArray: {'kETTitleProperty' . search stringValue . 'kETAlbumProperty' . search stringValue }).
		].
		mainContainer reloadAndUpdateLayout.
	]

	smartGroupOn [
		smartGroup := COSmartGroup alloc init.
		smartGroup setTarget: mainModel.
		mainContainer layoutItem setRepresentedObject: smartGroup.
	]
	
	clearSearch: sender [
		search setStringValue: (NSString string). "change to ''"
		self controlTextDidChange: nil.
	]

	doubleClickInContainer: sender [
		musicPlayerController playLayoutItem: (sender doubleClickedItem) start: true.
	]
]
