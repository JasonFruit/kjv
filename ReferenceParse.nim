import References, BibleErrors, BibleInfo, strutils

proc ParseVerseReference*(s: string): VerseReference =
  var bookEnd: int = 0
  var book, rest: string
  var chapterAndVerse: seq[string]
  var chapter, verse: int

  if not s.contains(":"):
    raise InvalidReferenceError(msg: "Unable to parse reference: '" & s & "'.")
    
  for i in 0..s.len:
    if s[i] in 'A'..'z':
      bookEnd = i

  book = s[0..bookEnd]

  book = bookName(book)
  
  if not bookExists(book):
    raise InvalidReferenceError(msg: "Unable to parse reference: '" & s & "'.")
    
  rest = s[bookEnd + 1..s.len - 1].strip()

  chapterAndVerse = rest.split(":")

  chapter = parseInt(chapterAndVerse[0])
  verse = parseInt(chapterAndVerse[1])
  
  return VerseReference(book: bookID(book),
                        chapter: chapter,
                        verse: verse)
