# The invoice

The semantic model: the terms EN 16931 names and the groups it puts them in.
Every class here carries the BT and BG numbers of the standard, so a term can
be traced from the text to the code and back.

`Invoice.fromLines` builds a document from its lines and derives the VAT
breakdown and the totals. `Invoice` itself takes every term, for a document
read back from a syntax package.
