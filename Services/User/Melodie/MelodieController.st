" This is the main class for Melodie. It coordinates CoreObject and EtoileUI,
  handles adding new songs to the library.

  Its only interaction with music playback is invoking
  'musicPlayerController playLayoutItem:start:' when a song is double-clicked. "
  
NSObject subclass: MelodieController
[
	| window search musicPlayerController knownExtensions
	  URLTextField addURLWindow ctxt
	  mainContainer  playlistContainer
	  mainLayoutItemGroup playlistLayoutItemGroup
	  mainModel playlistModel |

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

		" If loading the model objects from the context failed / the context was
		  invalid, make a new context. This happens if the user default exists
		  (maybe from a previous install of Melodie) but the CoreObjectLibrary
		  doesn't exist. This should probably be given more thought, but for now
		  should prevent confusion. "
		mainModel == nil ifTrue: [ self newContext ].
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
		mainLayoutItemGroup reloadAndUpdateLayout.
	]

	undo: sender [
		ctxt undo.
	]

	redo: sender [	
		ctxt redo.
	]

	addURL: sender [
		| string URL |

		addURLWindow orderOut: self.
		string := URLTextField stringValue stringByAddingPercentEscapesUsingEncoding: @NSUTF8StringEncoding.
		URL := NSURL URLWithString: string.

		mainModel addMember: 
			((URL relativePath pathExtension lowercaseString isEqualToString: 'pls')
				ifTrue: [ ETPlaylist playlistForPLSFileAtURL: URL ]
				ifFalse: [ ETMusicFile alloc initWithURL: URL ]).

		mainLayoutItemGroup reloadAndUpdateLayout.
	]

	newPlaylist: sender [
		| newPlaylist |

		newPlaylist := ETPlaylist new.
		"Put a sample radio stream in the playlist."
		newPlaylist addMember:
			(ETPlaylist playlistForPLSFileAtURL: (NSURL URLWithString: 'http://somafm.com/groovesalad.pls')).
		playlistModel addMember: newPlaylist.
		playlistLayoutItemGroup reloadAndUpdateLayout.
	]

	awakeFromNib [
		| layout |

		'known extensions: ' log.
		self knownExtensions foreach: [ :ext | ext log ].

		layout := ETOutlineLayout layout.
	
		layout setDisplayName: 'Title' forProperty: 'kETTitleProperty';
			setDisplayName: 'Artist' forProperty: 'kETArtistProperty';
			setDisplayName: 'Album' forProperty: 'kETAlbumProperty';
			setDisplayName: 'URL' forProperty: 'kETURLProperty'.
	
		layout setDisplayedProperties:
		    {'icon'. 'kETTitleProperty'. 'kETArtistProperty'. 'kETAlbumProperty'. 'kETURLProperty' }.

		mainLayoutItemGroup := ETLayoutItem itemGroupWithRepresentedObject: mainModel.
		mainLayoutItemGroup setSource: mainLayoutItemGroup;
			setSupervisorView: mainContainer;
			setLayout: layout;
			reloadAndUpdateLayout.
		mainContainer setHasVerticalScroller: true;
			setTarget: self;
			setDoubleAction: 'doubleClickInContainer:'.

		playlistLayoutItemGroup := ETLayoutItem itemGroupWithRepresentedObject: playlistModel.
		playlistLayoutItemGroup setSource: playlistLayoutItemGroup;
			setSupervisorView: playlistContainer;
			setLayout: (ETOutlineLayout layout);
			reloadAndUpdateLayout.
		playlistContainer setHasVerticalScroller: false;
			setTarget: self;
			setDoubleAction: 'doubleClickInContainer:'.

		search setDelegate: self.

		ScriptCenter sharedInstance enableScriptingWithObjects:
		    (NSDictionary dictionaryWithObjects: { musicPlayerController  }
		                                forKeys: { 'MusicPlayerController' }).
	]

	" COObjectContext delegate method "
	objectContextDidMergeObjects: notif [
		'Merge occurred, reloading models from context and updating container layouts..' log.
		self reloadModelVariablesFromContext.
		mainLayoutItemGroup reloadAndUpdateLayout.
		playlistLayoutItemGroup reloadAndUpdateLayout.
	]

	controlTextDidChange: notif [
		(search stringValue length = 0) ifTrue: [
			'clear' log.
			mainLayoutItemGroup filterWithPredicate: nil recursively: false.
		] ifFalse: [
			search stringValue length log.
			" FIXME: shouldn't need representedObject. should we? "
			mainLayoutItemGroup filterWithPredicate:
				(NSPredicate predicateWithFormat: '(representedObject.%K CONTAINS[cd] %@) OR (representedObject.%K CONTAINS[cd] %@)'
			  	argumentArray: {'kETTitleProperty' . search stringValue . 'kETAlbumProperty' . search stringValue })
				recursively: false.
		].
		mainLayoutItemGroup reloadAndUpdateLayout.
	]

	doubleClickInContainer: sender [
		musicPlayerController playLayoutItem: (sender doubleClickedItem) start: true.
	]
]
