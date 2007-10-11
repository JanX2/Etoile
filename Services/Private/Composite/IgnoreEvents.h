typedef struct _ignore
{
	struct _ignore *next;
	unsigned long	sequence;
} ignore;

extern ignore         *ignore_head, **ignore_tail;

static inline void
discard_ignore(Display * dpy, unsigned long sequence)
{
	while (ignore_head)
	{
		if ((long)(sequence - ignore_head->sequence) > 0)
		{
			ignore         *next = ignore_head->next;

			free(ignore_head);
			ignore_head = next;
			if (!ignore_head)
				ignore_tail = &ignore_head;
		}
		else
			break;
	}
}

static inline void
set_ignore(Display * dpy, unsigned long sequence)
{
	ignore         *i = malloc(sizeof(ignore));

	if (!i)
		return;
	i->sequence = sequence;
	i->next = 0;
	*ignore_tail = i;
	ignore_tail = &i->next;
}

static inline int
should_ignore(Display * dpy, unsigned long sequence)
{
	discard_ignore(dpy, sequence);
	return ignore_head && ignore_head->sequence == sequence;
}
