kjv
======================================================================

A command-line tool to output information about the King James Bible,
and supply its text in various formats, currently plain text,
Markdown, HTML, and LaTeX.

Usage: kjv OPTION
----------------------------------------------------------------------

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
	  -d, --markdown      Print the text of the specified Bible passage
						  as Markdown
	  -m, --html          Print the text of the specified Bible passage
						  as HTML
	  -l, --latex         Print the text of the specified Bible passage
						  as LaTeX
	  --help              Display this usage guide

Building
----------------------------------------------------------------------

With a Nim compiler on your PATH, clone this repository.  `cd` into it
and issue `nim c kjv`.  Copy the resulting `kjv` executable somewhere
on your PATH.  It will create its database the first time it is run.
