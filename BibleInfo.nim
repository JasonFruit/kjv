import db_sqlite
import strutils
import BibleErrors

type
  Book* = object
    name*, abbrev*: string

type
  VerseInfo* = tuple[book, chapter, verse: int]
  
# assorted private connection and initialization stuff

var conn = open("KJV-PCE.db", "", "", "")

var book_rows = getAllRows(conn, sql("select * from books order by id"))

var bookList: seq[Book] = @[Book(name: "", abbrev: "")]
bookList.delete(0)

for row in book_rows:
  bookList.add(Book(name: row[1], abbrev: row[2]))

proc books*(): seq[Book] =
  bookList

proc chapters*(bookID: int): int =
  var cmd = sql("select max(chapter_num) from chapters where book_id = ?")
  try:
    result = parseInt(getValue(conn, cmd, bookID))
  except ValueError:
    raise InvalidBookError(msg: "Invalid book: " & $bookID)

proc verses*(bookID, chapterNum: int): int =
  var cmd = sql("select verses from chapters where book_id = ? and chapter_num = ?")
  result = parseInt(getValue(conn, cmd, bookID, chapterNum))

proc bookID*(bookName: string): int =
  var cmd = sql("select id from books where name = ?")
  result = parseInt(getValue(conn, cmd, bookName))

proc bookName*(bookID: int): string =
  var cmd = sql("select name from books where id = ?")
  result = getValue(conn, cmd, bookID)

proc chapters*(bookName: string): int =
  result = chapters(bookID(bookName))

proc verses*(bookName: string, chapterNum: int): int =
  result = verses(bookID(bookName), chapterNum)

proc bookExists*(bookID: int): bool =
  for id in 1..66:
    if id == bookID:
      return true
  return false

proc bookExists*(bookName: string): bool =
  for book in bookList:
    if book.name == bookName:
      return true
  return false

proc chapterExists*(bookID, chapterNum: int): bool =
  if bookExists(bookID):
    if chapterNum in 1..chapters(bookID):
      return true
  return false

proc chapterExists*(bookName: string, chapterNum: int): bool =
  if bookExists(bookName):
    if chapterNum in 1..chapters(bookName):
      return true
  return false

proc verseExists*(bookID, chapterNum, verseNum: int): bool =
  if bookExists(bookID) and chapterExists(bookID, chapterNum):
    if verseNum in 1..verses(bookID, chapterNum):
      return true
  return false

proc verseExists*(bookName: string, chapterNum, verseNum: int): bool =
  result = verseExists(bookID(bookName), chapterNum, verseNum)

proc verseID*(bookID, chapterNum, verseNum: int): int =
  var cmd = sql("select rowid from KJV where book_id = ? and chapter_num = ? and verse_num = ?;")
  result = parseInt(getValue(conn, cmd, bookID, chapterNum, verseNum))

proc verseInfoByID*(verseID: int): VerseInfo =
  var cmd = sql("select book_id, chapter_num, verse_num from KJV where rowid = ?")
  var row = getRow(conn, cmd, verseID)
  try:
    result = (parseInt(row[0]), parseInt(row[1]), parseInt(row[2]))
  except ValueError:
    raise InvalidVerseError(msg: "Invalid verse ID " & $verseID)
