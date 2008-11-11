" This class is meant as a UI controller which encapsulates access to MediaKit.
  It is designed to be connected to a 'previous' button, 'next' button, 
  'play/pause' button, a song position slider, a volume slider, and a song
  information label. 

  The playLayoutItem:shouldStart: method is used to start playback at a
  particular node in a layout item tree. "

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

	playLayoutItem: layoutItem start: shouldStart [
		| allObjects currentIndex newQueue URLs |
		'Playing URL: ' log.
		layoutItem representedObject URL log.

		allObjects := layoutItem baseItem itemsIncludingAllDescendants.
		currentIndex := (allObjects indexOfObjectIdenticalTo: layoutItem).
		newQueue := (allObjects subarrayWithLocation: currentIndex
		                                      length: ((allObjects count) - currentIndex)).
		URLs := newQueue map: [ :x | x representedObject URL.].

		player stop.
		" TODO: rebuild the queue when the playlist is modified. "
		player setQueue: URLs.

		shouldStart ifTrue: [ self play. ].
		songLabel setStringValue: (layoutItem representedObject valueForProperty:'kETTitleProperty').
	]

	" Private "

	timerEvent: sender [
		player isPlaying ifTrue: [ playPauseButton setImage:
		                               ((IKIcon iconWithIdentifier: 'media-playback-pause') image). ]
		                ifFalse: [ playPauseButton setImage:
		                               ((IKIcon iconWithIdentifier: 'media-playback-start') image). ].

		positionSlider setMaxValue: (player duration).
		positionSlider setIntValue: (player currentPosition).
		"songLabel setStringValue: (player currentURL absoluteString)."

		" FIXME: calling player currentURL in this timer callback causes a segfault the second time it
		   happens, but not until there's a song playing  i.e. currentURL is non-nil "
	]
]
