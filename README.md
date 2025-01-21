# chess4tcl - Tcl library to work with the chessboard
Tcl library  using the [chess.js](https://github.com/jhlywa/chess.js)
library and the  [tcl-duktape](https://github.com/dbohdan/tcl-duktape) to work
with chess games and chess positions within Tcl.

## Installation

You need the  [tcl-duktape](https://github.com/dbohdan/tcl-duktape)  library  installed to be able to use the Javascript
code.

## Documentation (WIP)

- [Manual](https://htmlpreview.github.io/?https://raw.githubusercontent.com/mittelmark/chess4tcl/master/chess4tcl/chess4tcl.html)

## Example

```
package require chess4tcl
set chess [::chess4tcl::Chess4Tcl new]
$chess load "rnb1kbnr/pppp1ppp/8/4p3/5PPq/8/PPPPP2P/RNBQKBNR w KQkq - 1 3"
puts [$chess ascii]
```

To  display a board  within a  Markdown/HTML  document  you can use either the
`svg` or the  `gboard` methods:

```
puts [$chess $gboard]
```

## API  (WIP)

The following methods are available:

- `::chess4tcl::Chess4Tcl new` - create a new command
- `cmd load FENSTRING`         - loads the given FEN string
- WIP

## Author

@2020-2025 Detlef Groth, University of Potsdam, Germany

## License

MIT









