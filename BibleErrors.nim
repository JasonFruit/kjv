# Yes, I know the Bible has no errors.  My code does.

type InvalidVerseError* = ref object of ValueError
type InvalidChapterError* = ref object of ValueError
type InvalidBookError* = ref object of ValueError
