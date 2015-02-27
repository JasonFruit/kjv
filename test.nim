import References

var
  vref: VerseReference = VerseReference(book: 1,
                                        chapter: 1,
                                        verse: 1)
  vref2: VerseReference = vref.addVerses(1105)
  vref3: VerseReference = vref2.subtractVerses(1104)
  vref4: VerseReference = vref2.addChapters(30)
echo(vref2)
echo(vref3)  
echo(vref4)

var revelationSixSix = VerseReference(book: 66,
                                      verse: 6,
                                      chapter: 6)

echo(revelationSixSix.addChapters(20))
