import BibleInfo

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

