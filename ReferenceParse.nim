import References, BibleErrors, BibleInfo, strutils

proc extractBook(s: string): auto =
  var bookEnd: int = 0
  var book, rest: string
  
  for i in 0..s.len:
    if s[i] in 'A'..'z':
      bookEnd = i

  book = s[0..bookEnd]

  book = bookName(book)
  
  if not bookExists(book):
    raise InvalidReferenceError(msg: "Unable to parse reference: '" & s & "'.")
    
  rest = s[bookEnd + 1..s.len - 1].strip()

  result = (book, rest)

proc extractChapterAndVerse(s: string): auto =
  var elems = s.split(":")
  result = (parseInt(elems[0]), parseInt(elems[1]))
  
proc parseVerseReference*(s: string): VerseReference =
  var chapterAndVerse: seq[string]

  if not s.contains(":"):
    raise InvalidReferenceError(msg: "Unable to parse reference: '" & s & "'.")
    
  var (book, rest) = extractBook(s)
  var (chapter, verse) = extractChapterAndVerse(rest)
  
  return VerseReference(book: bookID(book),
                        chapter: chapter,
                        verse: verse)

proc parseRangeReference*(s: string): RangeReference =
  if s.contains("-"):
    discard("")
  else:
    discard("")
