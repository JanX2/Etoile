#define NSIntMapGet(table, index) \
	((intptr_t)NSMapGet(table, (void*)(intptr_t)index))
#define NSIntMapInsert(table, index, value) \
   	NSMapInsert(table, (void*)(intptr_t)index, (void*)(intptr_t)value)
