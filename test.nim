import References
import BibleErrors

var
  vref: VerseReference = VerseReference(book: 1,
                                        chapter: 49,
                                        verse: 33)
  diff = 0
  vref2: VerseReference = vref.addChapters(diff)
  vref3: VerseReference = vref2.subtractChapters(diff)

echo("Start with " & $vref & ".")
echo("Add " & $diff & " chapters to get " & $vref2 & ".")
echo("Subtract " & $diff & " chapters to get back to " & $vref3 & ".")
