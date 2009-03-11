<< types = '{ "volume" = "i8@0:4"; "setVolume:" = "v12@0:4i8" ; "next" = "v8@0:4" }' >>
" This class is meant as a UI controller which encapsulates access to MediaKit.
  It is designed to be connected to a 'previous' button, 'next' button,
  'play/pause' button, a song position slider, a volume slider, and a song
  information label.

  The playLayoutItem:shouldStart: method is used to start playback at a
  particular node in a layout item tree. "

NSObject subclass: MusicPlayerController
[
	| positionSlider volumeSlider songLabel playPauseButton previousButton nextButton
	  player history currentURL queueSize playImage pauseImage uiUpdateTimer |

	init [
		player := MKMusicPlayer new initWithDefaultDevice inNewThread.
		history := ETHistoryManager new.
		history setMaxHistorySize: 100.
		queueSize := 0.

		playImage := (IKIcon iconWithIdentifier: 'media-playback-start') image.
		pauseImage := (IKIcon iconWithIdentifier: 'media-playback-pause') image.
	]

	awakeFromNib [
		nextButton setImage: (IKIcon iconWithIdentifier: 'go-next') image.
		previousButton setImage: (IKIcon iconWithIdentifier: 'go-previous') image.

		nextButton cell setImageDimsWhenDisabled: true.
		previousButton cell setImageDimsWhenDisabled: true.

		uiUpdateTimer := NSTimer scheduledTimerWithTimeInterval: 1
		                                                 target: self
		                                               selector: 'timerEvent:'
		                                               userInfo: nil
		                                                repeats: true.
		uiUpdateTimer fire.
	]

	play [
		player play.
		uiUpdateTimer fire.
	]

	pause [
		player pause.
		uiUpdateTimer fire.
	]

	playPause: sender [
		player isPlaying ifTrue: [ self pause ]
		                ifFalse: [ self play ].
	]

	setPosition: sender [
		player seekTo: positionSlider intValue.
	]

	setVolume: sender [
		player setVolume: volumeSlider intValue.
	]

	next: sender [
		player next.
		uiUpdateTimer fire.
	]

	previous: sender [
		self syncHistory.
		history back.
		self playHistory: player isPlaying.
		uiUpdateTimer fire.
	]

	playLayoutItem: layoutItem start: shouldStart [
		| allObjects currentIndex newQueue |

		allObjects := layoutItem baseItem itemsIncludingAllDescendants.
		currentIndex := allObjects indexOfObjectIdenticalTo: layoutItem.
		newQueue := allObjects subarrayWithRange:
			 (NSValue rangeWithLocation: currentIndex
			                     length: allObjects count - currentIndex).

		" TODO: rebuild the queue when the playlist is modified. "
		self syncHistory.
		history setFuture: newQueue objectEnumerator.
		history forward.
		self playHistory: shouldStart.
		uiUpdateTimer fire.
	]

	" Private "

	playHistory: shouldStart [
		player stop.
		queueSize := 0.
		3 timesRepeat: [ self enqueueOne ].
		shouldStart ifTrue: [ player play ].
	]

	enqueueOne [
		| item |
		item := history peek: queueSize.
		item == nil ifFalse: [
			" TODO: deal with non-song objects in playlists (like other
			  playlists) more intelligently. "
			(item representedObject respondsToSelector: 'URL') ifTrue: [
				player addURL: item representedObject URL.
				queueSize := queueSize + 1 ] ].
	]

	timerEvent: sender [
		player isPlaying ifTrue: [ playPauseButton setImage: pauseImage ]
			        ifFalse: [ playPauseButton setImage: playImage ].

		self syncHistory.
		nextButton setEnabled: history hasNext.
		previousButton setEnabled: history hasPrevious.

		positionSlider setIntValue: player currentPosition.
		volumeSlider setIntValue: player volume.
	]

	syncHistory [
		| newURL newSize |
		" Send a value message to the proxy returned by player currentURL,
		  so that the identity comparison can detect when URL has changed. "
		newURL := player currentURL value.
		currentURL == newURL ifFalse: [
			currentURL := newURL.
			newSize := player queueSize.
			queueSize - newSize timesRepeat: [ history forward ].
			queueSize := newSize.
			songLabel setStringValue:
				history currentObject representedObject displayName.
			positionSlider setMaxValue: player duration.
			3 - newSize timesRepeat: [ self enqueueOne ].
		].
	]
]
