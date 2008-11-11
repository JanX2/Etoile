COGroup subclass: ETPlaylist [
	init [
		super init.

		'Prevent Smalltalk crash by creating a string (only necessary on Linux?)'.

		self tryStartPersistencyIfInstanceOfClass: (ETPlaylist class).
		^ self.
	]	
	
	isOrdered [
		^ 1.
	]
]

