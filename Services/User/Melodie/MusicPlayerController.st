NSObject subclass: MusicPlayerController
[
	| positionSlider volumeSlider songLabel playPauseButton previousButton nextButton
	  uiUpdateTimer player |
	
	init [
		player := MKMusicPlayer alloc initWithDefaultDevice inNewThread.
		player retain.

		uiUpdateTimer := NSTimer scheduledTimerWithTimeInterval: 1
		                                                 target: self
		                                               selector: 'timerEvent:'
		                                               userInfo: nil
		                                                repeats: 1.
		^ self.
	]

	awakeFromNib [
		playPauseButton setImage: ((IKIcon iconWithIdentifier: 'media-playback-start') image).
		nextButton setImage: ((IKIcon iconWithIdentifier: 'go-next') image).
		previousButton setImage: ((IKIcon iconWithIdentifier: 'go-previous') image).	
		volumeSlider setIntValue: (player volume).
	]

	play [
		player play.
	]

	pause [
		player pause.
		playPauseButton setImage: ((IKIcon iconWithIdentifier: 'media-playback-start') image).
	]

	playPause: sender [
		player isPlaying ifTrue: [ self pause. ]
		                ifFalse: [ self play. ].
	]

	setPosition: sender [
		player seekTo: (positionSlider intValue).
	]

	setVolume: sender [
		player setVolume: (volumeSlider intValue).
	]

	next: sender [
		player next.
	]

	previous: sender
	[
		'TODO: previous' log.
	]

	playObject: anObject start: shouldStart [
		| allObjects currentIndex newQueue URLs |
		'Playing URL: ' log.
		anObject representedObject URL log.

		allObjects := anObject baseItem itemsIncludingAllDescendants.
		currentIndex := (allObjects indexOfObjectIdenticalTo: anObject).
		newQueue := (allObjects subarrayWithLocation: currentIndex length: ((allObjects count) - currentIndex)).

		
		" Fill URLs with the URLs of the repobjects of the items in newQueue, if they have URLs.
		  Without the ifTrue: [1.] ifFalse: [nil.]. hack, select: would include objects which should have failed. 
		  Unboxing problem? "
		"  URLs := (newQueue select: [ :x | (x representedObject respondsToSelector: 'URL') ifTrue: [1.] ifFalse: [nil.]. ]) map: [ :x | x representedObject URL.]. "
		URLs := newQueue map: [ :x | x representedObject URL.].

		player stop.

		" TODO: rebuild the queue when the playlist is modified. "
		player setQueue: URLs.

		shouldStart ifTrue: [ self play. ].
		songLabel setStringValue: (anObject representedObject valueForProperty:'kETTitleProperty').
	]

	setIconToPlay [
		" Workaround until ivar access from within blocks works."
		 playPauseButton setImage: ((IKIcon iconWithIdentifier: 'media-playback-pause') image).
	]

	setIconToPause [
		 playPauseButton setImage: ((IKIcon iconWithIdentifier: 'media-playback-start') image).
	]

	timerEvent: sender [
		player isPlaying ifTrue: ['playing' log. self setIconToPlay. ] 
		                  ifFalse: ['paused' log. self setIconToPause. ].
		positionSlider setMaxValue: (player duration).
		positionSlider setIntValue: (player currentPosition).

		" songLabel setStringValue: (player currentURL absoluteString)."

		" FIXME: calling player currentURL in this timer callback causes a segfault the second time it happens, but not until there's a song playing
		  i.e. currentURL is non-nil "
	]
]
