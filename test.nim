import BibleInfo
import References

var vref = VerseReference(book: 1, chapter: 1, verse: 1)
var vref2 = VerseReference(book: 1, chapter: 1, verse: 1)
var vref3 = VerseReference(book: 3, chapter: 2, verse: 1)
var rref = RangeReference(startRef: vref, endRef: vref3)
var rref2 = RangeReference(startRef: vref2, endRef: vref2)

echo(vref == vref2)
echo(vref == vref3)
echo(vref3 > vref2)
echo(vref > vref2)
echo(rref.startRef < rref.endRef)

echo(vref)
echo(rref)
echo(rref.valid)
if rref2.contains(vref3):
  echo("Yup")
else:
  echo("Nope.")

if rref.overlaps(rref2):
  echo("Yup")
else:
  echo("Nope.")
