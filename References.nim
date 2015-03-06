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

proc addChapters*(vref: VerseReference, chapterDiff: int): VerseReference =
  var (book, chapter, verse) = (vref.book, vref.chapter, vref.verse)
  if chapter + chapterDiff <= chapters(book):
    var new_verse: int
    if verse <= verses(book, chapter + chapterDiff):
      new_verse = verse
    else:
      new_verse = verses(book, chapter + chapterDiff)
    result = VerseReference(book: book,
                            chapter: chapter + chapterDiff,
                            verse: new_verse)
  else:
    var dist_to_end = chapters(book) - chapter
    # return rather than result= because we want validation to happen only on
    # the final recursion
    return addChapters(VerseReference(verse: verse,
                                      chapter: 1,
                                      book: book + 1),
                       chapterDiff - dist_to_end)
  if not result.valid:
    if bookExists(result.book) and chapterExists(result.book, result.chapter):
      result = VerseReference(verse: verses(result.book, result.chapter),
                              chapter: result.chapter,
                              book: result.book)
    else:
      raise InvalidVerseError(msg: "Unable to add " & $chapterDiff & " chapters to " & $vref)

proc subtractChapters*(vref: VerseReference, chapterDiff: int): VerseReference =
  if vref.chapter > chapterDiff:
    result = VerseReference(book: vref.book,
                            chapter: vref.chapter - chapterDiff,
                            verse: vref.verse)
  else:
    var book, chapter: int
    try:
      book = vref.book - 1
      chapter = chapters(book)
      return subtractChapters(VerseReference(book: book,
                                             chapter: chapter,
                                             verse: verses(book, chapter)),
                              chapterDiff - vref.chapter)
    except InvalidVerseError, InvalidBookError:
      raise InvalidVerseError(msg: "Unable to subtract " & $chapterDiff & " chapter from " & $vref & ".")

  if not result.valid:
    if bookExists(result.book):
      raise InvalidVerseError(msg: "Unable to subtract " & $chapterDiff & " chapter from " & $vref & ".")
    else:
      result = VerseReference(book: result.book,
                              chapter: result.chapter,
                              verse: verses(result.book, result.chapter))
