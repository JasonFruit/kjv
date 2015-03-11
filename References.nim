import BibleInfo
import BibleErrors

type VerseReference* = object
  book*, chapter*, verse*: int

type RangeReference* = object
  startRef*, endRef*: VerseReference

proc `$`*(vref: VerseReference): string =
  result = bookName(vref.book) & " " & $vref.chapter & ":" & $vref.verse

proc `$`*(rref: RangeReference): string =
  result = $rref.startRef & "-" & $rref.endRef

proc `>`*(a, b: VerseReference): bool =
  if a.book != b.book:
    return a.book > b.book
  else:
    if a.chapter != b.chapter:
      return a.chapter > b.chapter
    else:
      return a.verse > b.verse

proc `<`*(a, b: VerseReference): bool =
  if a.book != b.book:
    return a.book < b.book
  else:
    if a.chapter != b.chapter:
      return a.chapter < b.chapter
    else:
      return a.verse < b.verse

proc `==`*(a, b: VerseReference): bool =
  result = (a.book == b.book and
            a.chapter == b.chapter and
            a.verse == b.verse)

proc `<=`*(a, b: VerseReference): bool =
  result = (a < b) or (a == b)

proc `>=`*(a, b: VerseReference): bool =
  result = (a > b) or (a == b)

proc contains*(a, b: RangeReference): bool =
  result = (b.startRef >= a.startRef and
            b.startRef <= a.endRef and
            b.endRef >= a.startRef and
            b.endRef <= a.endRef)

proc contains*(a: RangeReference, b: VerseReference): bool =
  result = (b >= a.startRef and
            b <= a.endRef)

proc overlaps*(a, b: RangeReference): bool =
  result = (b.startRef >= a.startRef and
            b.startRef <= a.endRef) or
           (b.endRef >= a.startRef and
            b.endRef <= a.endRef)

proc valid*(vref: VerseReference): bool =
  result = verseExists(vref.book, vref.chapter, vref.verse)

proc valid*(rref: RangeReference): bool =
  result = (valid(rref.startRef) and
            valid(rref.endRef) and
            (rref.startRef < rref.endRef or
             rref.startRef == rref.endRef))

proc addVerses*(vref: VerseReference, verses: int): VerseReference =
  var vID = verseID(vref.book, vref.chapter, vref.verse)
  var verseInfo = verseInfoByID(vID + verses)
  result = VerseReference(book: verseInfo.book,
                          chapter: verseInfo.chapter,
                          verse: verseInfo.verse)

proc subtractVerses*(vref: VerseReference, verses: int): VerseReference =

  var vID = verseID(vref.book, vref.chapter, vref.verse)

  var verseInfo: VerseInfo
  # if the subtraction ends in a non-existent verseID, an InvalidVerseError will be raised;
  # we should change that to an InvalidReferenceError
  try:
    verseInfo = verseInfoByID(vID - verses)
  except InvalidVerseError:
    raise InvalidReferenceError(msg: "Unable to subtract " & $verses & " verses from " & $vref & ".")

  result = VerseReference(book: verseInfo.book,
                          chapter: verseInfo.chapter,
                          verse: verseInfo.verse)

  if not result.valid:
    raise InvalidReferenceError(msg: "Unable to subtract " & $verses & " verses from " & $vref & ".")

discard """ proc addChapters*(vref: VerseReference, chapterDiff: int): VerseReference =
  var lastChapter: int

  try:
    lastChapter = chapters(vref.book)
  except InvalidBookError:
    raise InvalidReferenceError(msg: "Unable to add chapters past end of Bible.")

  if lastChapter >= vref.chapter + chapterDiff:
    result = VerseReference(book: vref.book,
                            chapter: vref.chapter + chapterDiff,
                            verse: vref.verse)
    if not result.valid:
      result.verse = verses(result.book, result.chapter)
  else:
    return addChapters(VerseReference(book: vref.book + 1,
                                      chapter: 1,
                                      verse: vref.verse),
                       chapterDiff - (lastChapter - vref.chapter) - 1)
 """

proc addChapters*(vref: VerseReference, chapterDiff: int): VerseReference =
  
  if not vref.valid:
    raise InvalidReferenceError(msg: "Invalid starting verse: " & $vref & ".")

  if chapterDiff < 0:
    raise InvalidReferenceMathError(msg: "Unable to add a negative number of chapters.  (Use subtractChapters instead.)")
    
  var (book, chapter, verse, diff) = (vref.book, vref.chapter, vref.verse, chapterDiff)
  
  while true:
    var lastChapter: int

    try:
      lastChapter = chapters(book)
    except InvalidBookError:
      raise InvalidReferenceError(msg: "Unable to add chapters past end of Bible.")

    if lastChapter >= chapter + diff:
      var lastVerse: int = verses(book, chapter + diff)
      
      if verse > lastVerse:
        verse = lastVerse
        
      return VerseReference(book: book,
                            chapter: chapter + diff,
                            verse: verse)
    else:
      diff = diff - (lastChapter - chapter) - 1
      book = book + 1
      chapter = 1

proc subtractChapters*(vref: VerseReference, chapterDiff: int): VerseReference =
  var diff, book, chapter, verse: int

  diff = chapterDiff
  book = vref.book
  chapter = vref.chapter
  verse = vref.verse

  while true:
    if chapter >= diff:
      if verses(book, chapter) >= verse:
        return VerseReference(book: book,
                              chapter: chapter - diff,
                              verse: verse)
      else:
        return VerseReference(book: book,
                              chapter: chapter - diff,
                              verse: verses(book, chapter))
    else:
      diff = diff - chapter
      book = book - 1
      chapter = chapters(book)
