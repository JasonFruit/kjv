import References

var
  vref: VerseReference = VerseReference(book: 1,
                                        chapter: 1,
                                        verse: 1)
  vref2: VerseReference = vref.addVerses(1105)
  vref3: VerseReference = vref2.subtractVerses(1104)

echo(vref2)
echo(vref3)  
