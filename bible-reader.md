Bible Reader — Components and API
======================================================================

Components:
----------------------------------------------------------------------

 - Bible information (books, chapters, verses)
 - References (datatype, comparison, math, formatting)
 - Reference parsing (string->reference)
 - Text Retrieval
 - Searching
 - Formatting (conversion of bible content to various formatting, may
   be multiple components)
 - Bookmarking
 - Commentary
 - User interface (may be multiple components)


Bible Information
----------------------------------------------------------------------

### (books)

Returns an alist in the form

    ((<book-name> . <book-id>) … )

### (chapters book-id)

Returns a list of chapter numbers in the specified book.

### (verses book-id chapter-num)

Returns a list of verse numbers in the specified book and chapter.

### (book-id book-name)

Returns an integer book ID for the specified book name.

### (book-name book-id)

Returns the string name for the specified book ID.

### (book-exists? book-id)

Boolean.

### (book-name-exists? book-name)

Boolean

### (chapter-exists? book-id chapter-num)

Boolean.

### (verse-exists? book-id chapter-num verse-num)

Boolean.

References
----------------------------------------------------------------------

This component defines two datatypes, `verse-ref` and `range-ref`; a
`range-ref` consists of a start and end `verse-ref` representing the
inclusive beginning and end of the range.

### verse-ref

#### (make-verse-ref book-id chapter-num verse-num)

Creates a new `verse-ref`.

#### (verse-ref? thing)

Returns #t if `thing` is a `verse-ref`, otherwise #f.

#### (verse-ref-book verse-ref)

Returns the book ID for the specified verse-ref.

#### (verse-ref-chapter verse-ref)

Returns the chapter number for the specified verse-ref.

#### (verse-ref-verse verse-ref)

Returns the verse number for the specified verse-ref.

#### (set-verse-ref-book! verse-ref book-id)

Sets the book ID for the specified verse-ref.

#### (set-verse-ref-chapter! verse-ref chapter-num)

Sets the chapter number for the specified verse-ref.

#### (set-verse-ref-verse! verse-ref verse-num)

Sets the verse number for the specified verse-ref.

#### (verse-ref> verse-ref-1 verse-ref-2)

Returns #t if `verse-ref-1` > `verse-ref-2`; otherwise #f.

#### (verse-ref= verse-ref-1 verse-ref-2)

Returns #t if `verse-ref-1` refers to the same verse as `verse-ref-2`;
otherwise #f.

#### (verse-ref< verse-ref-1 verse-ref-2)

Returns #t if `verse-ref-1` < `verse-ref-2`; otherwise #f.

#### (verse-ref-valid? ref)

Returns #t if `ref` refers to an existing verse; otherwise #f.

### range-ref

#### (make-range-ref start-verse-ref end-verse-ref)

Creates a new `range-ref`.

#### (range-ref? thing)

Returns #t if `thing` is a `range-ref`; otherwise #f.

#### (range-ref-start range-ref)

Returns the start `verse-ref` of a `range-ref`.

#### (range-ref-end range-ref)

Returns the end `verse-ref` of a `range-ref`.

#### (set-range-ref-start! range-ref start)

Sets the start `verse-ref` of a `range-ref` to `start`.

#### (set-range-ref-end! range-ref end)

Sets the end `verse-ref` of a `range-ref` to `end`.

#### (range-ref-contains? range-ref verse-or-range-ref)

Returns #t if the entirety of `verse-or-range-ref` is contained in
`range-ref`; otherwise #f.

#### (range-refs-overlap? ref1 ref2)

Returns #t if `ref1` and `ref2` refer to any of the same verses;
otherwise #f.

#### (range-ref-valid? ref)

Returns #t if both ends of `ref` are valid verses and the start <= the
end; otherwise #f.

### Reference math

#### (add-chapters verse-ref chapters)

Returns a reference to the verse `chapters` chapters after
`verse-ref`.  If the verse number of `verse-ref` does not exist in the
final chapter, returns a reference to the last verse of the final
chapter.

#### (subtract-chapters verse-ref chapters)

Returns a reference to the verse `chapters` chapters before
`verse-ref`.  If the verse number of `verse-ref` does not exist in the
final chapter, returns a reference to the last verse of the final
chapter.

#### (add-verses verse-ref verses)

Returns a reference to the verse `verses` verses after `verse-ref`.

#### (subtract-verses verse-ref verses)

Returns a reference to the verse `verses` verses before `verse-ref`.

### Representation

#### (verse-ref->string verse-ref)

Represents `verse-ref` as a string in the form **Book C:V**, where
**Book** is the book name, **C** is the chapter number, and **V** is
the verse number.

#### (range-ref->string range-ref)

Represents `range-ref` as a string in one of the following forms:

 - John 1:3
 - John 1:3-5
 - John 1:3-2:1
 - John 1:3-Acts 3:1

#### (ref->string ref)

Represents `ref` as a string, using `verse-ref->string` or
`range-ref->string`, as appropriate.

Reference Parsing
----------------------------------------------------------------------

### (string->verse-ref s)

Parses a string `s` and represents it as a `verse-ref`, if possible;
if not, error.

### (string->range-ref s)

Parses a string `s` and represents it as a `range-ref`, if possible;
if not, error.

### (string->ref s)

Parses a string `s` and represents it as a `verse-ref` or a
`range-ref`, as appropriate and if possible; if not, error.

Text Retrieval
----------------------------------------------------------------------

## (verse-content verse-ref)

Returns a list of the book, chapter, and verse numbers along with the
associated text for  `verse-ref`.

## (range-content range-ref)

Returns a list of the book, chapter, and verse numbers along with the
associated text for each `verse-ref` contained in `range-ref`.

Searching
----------------------------------------------------------------------

## (find-phrase phrase within-range)

Return references to verses containing the string `phrase` within
`within-range`.

## (find-words words within-range)

Return references to verses containing all the words in the list
`words` within `within-range`.
