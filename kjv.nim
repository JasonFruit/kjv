import os
import strutils
import db_sqlite
import createDb
import parseopt

let rcDir = absolutePath(getHomeDir() & ".kjv")
let dbPath = absolutePath(rcDir & "/kjv.db")

proc createRcDir(): void =
  discard execShellCmd("mkdir $HOME/.kjv")

proc createDb(): void =
  writeFile("/tmp/createDb.sql", createSql)
  discard execShellCmd("cat /tmp/createDb.sql | sqlite3 \"" & dbPath & "\"")

# create the data directory and database file if they don't exist already
if not existsFile(dbPath):
  createRcDir()
  createDb()    

let db = open(dbPath, "", "", "")

let book_order_rows = db.getAllRows(sql"select name from book order by id")
var book_order = newSeq[string](0)

for row in book_order_rows:
  book_order.add(row[0])

# base object for verse and range references
type Ref = ref object of RootObj;

method toString(rf: Ref): string {.base.} =
  "..." # there's no reason the base toString would ever be called, so
        # let's not put too much effort into it

# represents a verse reference
type Verse = ref object of Ref
  book: string
  chapter: int
  verse: int

method toString(v: Verse): string =
  return v.book & " " & intToStr(v.chapter) & ":" & intToStr(v.verse)

type Range = ref object of Ref
  first: Verse
  last: Verse

method toString(r: Range): string =
  if r.first.book != r.last.book:
    return r.first.toString() & "-" & r.last.toString()
  elif r.first.chapter != r.last.chapter:
    return r.first.toString() & "-" & intToStr(r.last.chapter) & ":" & r.last.verse.intToStr()
  else:
    return r.first.toString() & "-" & r.last.verse.intToStr()


method toRange(v: Verse): Range {.base.} =
  Range(first: v,
        last: v)

# a hashtable whose keys are common abbreviations of Biblical books
let abbrevs = db.getAllRows(sql"select a.abbrev, b.name from book_abbr a inner join book b on a.book_id = b.id")

# return the canonical name corresponding to an abbreviation of a book
# of the Bible
proc canonicalName(abbrev: string): string =

  # if it's already canonical, return it
  for name in book_order:
    if name.toLower() == abbrev.toLower():
      return name

  # otherwise, look it up in the hash
  for row in abbrevs:
    if row[0].toLower() == abbrev.toLower():
      return row[1]

  # not found
  var e = new(KeyError)
  e.msg = "Unknown book specifier: '" & abbrev & "'."
  raise e

proc chapterCount(book: string): int =
  return parseInt(db.getValue(
    sql"select max(chapter) from bible b inner join book bk on b.book_id = bk.id where name = ?",
    book))

proc verseCount(book: string, chapter: int): int =
  return parseInt(db.getValue(
    sql"select max(verse) from bible b inner join book bk on b.book_id = bk.id where name = ? and chapter = ?",
    book,
    chapter))

proc verseId(v: Verse): int =
  parseInt(db.getValue(
    sql"""
select b.id
from bible b
inner join book bk
on b.book_id = bk.id
where name = ? and
chapter = ? and
verse = ?""",
    v.book,
    v.chapter,
    v.verse))

# some comparison functions for verses
proc `<`(v1: Verse, v2: Verse): bool =
  return verseId(v1) < verseId(v2)

proc `>`(v1: Verse, v2: Verse): bool =
  return verseId(v1) > verseId(v2)

proc `==`(v1: Verse, v2: Verse): bool =
  return (v1.book == v2.book) and (v1.chapter == v2.chapter) and (v1.verse <= v2.verse)

proc `<=`(v1: Verse, v2: Verse): bool =
  return (v1 < v2) or (v1 == v2)

# check if a reference is valid
method isValid(rf: Ref): bool {.base.} =
  try:
    return ((Verse)rf).isValid()
  except ObjectConversionError:
    return ((Range)rf).isValid()

# return why a reference is invalid
method invalidMessage(rf: Ref): string {.base.} =
  try:
    return ((Verse)rf).invalidMessage()
  except ObjectConversionError:
    return ((Range)rf).invalidMessage()
    
method isValid(v: Verse): bool =
  return (v.chapter <= chapterCount(v.book)) and (v.verse <= verseCount(v.book, v.chapter))

method invalidMessage(v: Verse): string =
  if v.chapter > chapterCount(v.book):
    return v.book & " has only " & intToStr(chapterCount(v.book)) & " chapters."
  elif v.verse > verseCount(v.book, v.chapter):
    return v.book & " " & intToStr(v.chapter) & " has only " & intToStr(verseCount(v.book, v.chapter)) & " verses."
  else:
    return "Unknown reference"
    
method isValid(r: Range): bool =
  return r.first.isValid() and r.last.isValid() and r.first <= r.last

method invalidMessage(r: Range): string =
  if not r.first.isValid():
    return r.first.invalidmessage()
  else:
    return r.last.invalidmessage()
    
# parse a reference to a single verse
proc parseVerseRef(rf: string): Verse =
  let colonInd = rf.find(':')

  var lastSpace = colonInd

  while rf[lastSpace] != ' ' and lastSpace > 0:
    lastSpace -= 1

  var bk = rf[0 .. lastSpace-1]
  bk = canonicalName(bk)
  
  var rest = rf[lastSpace .. rf.high]
  var elems = rest.split(':')
  var chap = parseInt(elems[0].strip())
  var v = parseInt(elems[1].strip())

  return Verse(book: bk,
               chapter: chap,
               verse: v)

# parse references to a range of verses
proc parseRangeRef(rf: string): Range =
  let splitPos = rf.find("-")
  var first: Verse
  var last: Verse

  # If there's a hyphen, it can be parsed
  if splitPos > 0:
    # the start verse is easy, because it has to be a full reference
    first = parseVerseRef(rf[0 .. splitPos-1])
    
    var rest = rf[splitPos + 1 .. rf.high].strip()
    
    # try to parse the remainder as a verse
    try:
      last = parseVerseRef(rest)
      return Range(first: first,
                   last: last)
    except:
      last = Verse(book: first.book,
                   chapter: first.chapter,
                   verse: first.verse)
      
      # not a full verse reference, so see if there's a colon
      let colonPos = rest.find(':')

      # if there isn't, then it's just a verse number
      if colonPos < 0:
        try:
          last.verse = parseInt(rest)
        except:
          var e = ValueError.new()
          e.msg = "Invalid range reference: '" & rf & "'."
          raise e

      else: # otherwise, it's a chapter and verse
        try:
          last.chapter = parseInt(rest[0 .. colonPos-1])
          last.verse = parseInt(rest[colonPos+1 .. rest.high])
        except:
          var e = ValueError.new()
          e.msg = "Invalid range reference: '" & rf & "'."
          raise e

      return Range(first: first,
                   last: last)
          
      
  else:
    var e = new(ValueError)
    e.msg = "Not a range reference: '" & rf & "'."
    raise e

# parse a base reference (by determining the type and dispatching
# accordingly)
proc parseRef(rf: string): Ref =
  if rf.find("-") > 0:
    return parseRangeRef(rf)
  else:
    return parseVerseRef(rf)

# get database rows for a range of verses
proc getBibleRows(rng: Range): seq[Row] =
  return db.getAllRows(sql"""
select name, 
chapter, 
verse, 
content 
from bible b 
inner join book bk 
on b.book_id = bk.id 
where b.id between
 (select b.id
  from bible b
  inner join book bk
  on b.book_id = bk.id
  where bk.name = ? and 
  chapter = ? and 
  verse = ?) 
and
 (select b.id
  from bible b
  inner join book bk
  on b.book_id = bk.id
  where bk.name = ? and
  chapter = ? and
  verse = ?)
order by book_id, chapter, verse""",
                       rng.first.book,
                       rng.first.chapter,
                       rng.first.verse,
                       rng.last.book,
                       rng.last.chapter,
                       rng.last.verse)

# return plain text for a Bible passage
proc getBibleText(rng: Range): string =
  var res: string = ""
  var book: string = ""
  var chap: string = ""

  for row in getBibleRows(rng):
    if row[0] != book:
      res = res & "\n\n" & row[0] & " " & row[1] & ":"
      book = row[0]
      chap = row[1]
    elif row[1] != chap:
      res = res & "\n" & row[1] & ":"
      chap = row[1]
      
    res = res & row[2] & " " & row[3] & "\n"

  return res.strip()

# return Bible text for a reference
proc getBibleText(r: Ref): string =
  try:
    return getBibleText((Range)r)
  except:
    return getBibleText(((Verse)r).toRange())

# return Bible text as HTML for a range of verses
proc getBibleHtml(rng: Range): string =
  var res: string = ""
  var book: string = ""
  var chap: string = ""

  for row in getBibleRows(rng):
    if row[0] != book:
      res = res & "<h2>" & row[0] & " " & row[1] & "</h2>\n"
      book = row[0]
      chap = row[1]
    elif row[1] != chap:
      res = res & "<h3>" & row[1] & "</h3>\n"
      chap = row[1]
      
    res = res & "<div class=\"verse\"><span class=\"verse-num\">" & row[2] & "</span> <span class=\"verse-text\">" & row[3] & "</span></div>\n"

  res = res.replace("<<", "<div class=\"psalm-header\">")
  res = res.replace(">>", "</div>")
  
  res = res.replace("[", "<em class=\"added\">")
  res = res.replace("]", "</em>")

  res = res.replace("LORD", "<span class=\"divine-name\" style=\"font-variant: small-caps\">Lord</span>")

  return res.strip()

# return Bible text as HTML for a reference
proc getBibleHtml(r: Ref): string =
  try:
    return getBibleHtml((Range)r)
  except:
    return getBibleHtml(((Verse)r).toRange())
    

# return Bible text as LaTeX for a range of verses
proc getBibleLatex(rng: Range): string =
  var res: string = ""
  var book: string = ""
  var chap: string = ""

  for row in getBibleRows(rng):
    if row[0] != book:
      res = res & "\\textbf{" & row[0] & " " & row[1] & ":" & row[2] & "} " & row[3] & "\\\\\n"
      book = row[0]
      chap = row[1]
    elif row[1] != chap:
      res = res & "\\textbf{" & row[1] & ":" & row[2] & "} " & row[3] & "\\\\\n"
      chap = row[1]
    else:
      res = res & "\\textbf{" & row[2] & "} " & row[3] & " \\\\\n"

  res = res.replace("<<", "\\marginpar{")
  res = res.replace(">>", "}\n\n")
  
  res = res.replace("[", "\\textsl{")
  res = res.replace("]", "}")

  res = res.replace("LORD", "\\textsc{Lord}")

  return res.strip()

# return Bible text as LaTeX for a reference
proc getBibleLatex(r: Ref): string =
  try:
    return getBibleLatex((Range)r)
  except:
    return getBibleLatex(((Verse)r).toRange())
    
  
var usage = """
Usage: kjv OPTION

Print a passage from or information about a book or chapter of the
King James Version of the Holy Bible.

The options are mutually exclusive; options after the first will be
discarded.
  -b, --books         Print a list of the books of the Bible, each
                      on a separate line
  -c, --chapters      Print the number of chapters in the specified
                      book
  -v, --verses        Print the number of verses in the specified
                      book and chapter
  -p, --passage       Print the text of the specified Bible passage
                      as plain text
  -m, --html          Print the text of the specified Bible passage
                      as HTML
  -l, --latex         Print the text of the specified Bible passage
                      as LaTeX
  --help              Display this usage guide

"""

# parse options
var p = initOptParser()

for kind, key, val in p.getOpt():
  case kind
  of cmdArgument:

    # there shouldn't be anything other than options with values; bail
    # with error and show usage info
    stdErr.write("error: unable to parse options\n\n")
    stdErr.write(usage)
    
    quit(1)
    
  of cmdLongOption, cmdShortOption:
    
    case key:
      of "books", "b":
        for book in book_order:
          echo book
        quit()
        
      of "chapters", "c":
        echo chapterCount(canonicalName(val))
        quit()
        
      of "verses", "v":
        var lastSpacePos: int = val.rfind(" ")
        echo verseCount(canonicalName(val[0 .. lastSpacePos-1]),
                        parseInt(val[lastSpacePos+1 .. val.high]))
        quit()
        
      of "passage", "p":
        var r = parseRef(val)
        if r.isValid():
          echo getBibleText(r)
          quit()
        else:
          stdErr.write("Invalid reference '" & val & "': " & r.invalidMessage())
          quit(1)
          
      of "html", "m":
        var r = parseRef(val)
        if r.isValid():
          echo getBibleHtml(r)
          quit()
        else:
          stdErr.write("Invalid reference '" & val & "': " & r.invalidMessage())
          quit(1)

      of "latex", "l":
        var r = parseRef(val)
        
        if r.isValid():
          echo getBibleLatex(r)
          quit()
        else:
          stdErr.write("Invalid reference '" & val & "': " & r.invalidMessage())
          quit(1)
        
        
      of "help", "h":
        echo usage
        quit()
        
      else:
        # any other option is an error; show usage information
        stdErr.write("Invalid option -- '" & key & "'\n\n")
        stdErr.write(usage)
        quit(1)
        
  of cmdEnd:
    quit(1) # this shouldn't happen

# if you get here, no options were supplied; show usage info
echo usage
