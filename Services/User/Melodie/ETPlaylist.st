COGroup subclass: ETPlaylist [
	init [
		super init.
		'prevent crash by creating string'.
		self tryStartPersistencyIfInstanceOfClass: (ETPlaylist class).
		^ self.
	]	
	
	isOrdered [
		^ 1.
	]
]

