COGroup subclass: ETPlaylist [
	init [
		super init.
		self tryStartPersistencyIfInstanceOfClass: (ETPlaylist class).
		^ self.
	]	
	
	isOrdered [
		^ true.
	]
]

