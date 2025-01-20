#!/usr/bin/env tclsh
##############################################################################
#  Created       : 2025-01-15 19:21:27
#  Last Modified : <250120.1147>
#
#  Description	 : Tcl class using chess.js via Duktape
#
#  Notes         : This is a Tcl class which can be used to provide chess 
#                  functionality
#  History       : 2025-01-15 - first package version
#	
##############################################################################
#
#  Copyright (c) 2025 MicroEmacs User.
# 
#  License:  MIT / Tcl part BSD: chess.js

##############################################################################


# Author: Detlef Groth
# License MIT (same as chess.js, duktape, tcl-duktape)
# Version 0.1 working and usable, not fast however ...
package require duktape
package require duktape::oo
package provide chess4tcl 0.1.0
package require fileutil

#' ---
#' author: Detlef Groth, University of Potsdam, Germany
#' title: chess4tcl package documentation 0.1.0
#' date: 2025-01-15
#' tcl:
#'   eval: 1
#' ---
#' 
#' ## NAME 
#' 
#' _chess4tcl_ - Tcl package providing a class _Chess4Tcl_ to provide functionality 
#' for chess games.
#' 
#' ## SYNOPSIS PACKAGE
#' 
#' ```{.tcl eval=FALSE}
#' # demo: synopsis
#' package require chess4tcl
#' set chess [::chess4tcl::Chess4Tcl new]
#' $chess moves
#' $chess move MOVE
#' $chess ascii
#' $chess board
#' $chess fen
#' $chess game_over
#' $chess get
#' $chess header
#' $chess history
#' $chess in_check
#' $chess in_checkmate
#' $chess in_draw
#' $chess in_stalemate
#' $chess in_threefold_repetition
#' $chess insufficient_masterial
#' $chess is_mate
#' $chess load FEN
#' $chess load_pgn
#' $chess new
#' $chess pgn
#' $chess put
#' $chess remove
#' $chess reset
#' $chess turn
#' ```
#' 
#' ## SYNOPSIS APPLICATION
#' 
#' Running the chess4tcl application required the package application runner [tclmain](https://github.com/mittelmark/tclmain).
#'
#' ```
#' tclmain -m chess4tcl --help                       # show the help page
#' tclmain -m chess4tcl --demo                       # gives out some demo game
#' tclmain -m chess4tcl FENSTRING ?OUTFILE?          # display the position or save it to a file 
#' ```
#'
#' ## DESCRIPTION
#' 
#' The package provides a Tcl class which can be used to make moves on a chess board and 
#' to display positions based on these moves or using given FEN strings or PGN files.
#'
#' 

namespace eval chess4tcl { 
    set chessfile [file join [file dirname [info script]] chess.js]
    set fontfile [file join [file dirname [info script]] chessmeridaunicode.b64]
}

#' ## Class
#'
#' __chess4tcl::Chess4Tcl__
#' 
#' ### Constructor:
#'
#' _::chess4tcl::Chess4Tcl new ?FEN?
#'
#' > initialize a new object with an optional FEN string.
#'
#' > Example:
#'
#' ```{.tcl}
#' package require chess4tcl
#' set chess [::chess4tcl::Chess4Tcl new]
#' puts [$chess fen]
#' puts [$chess board]
#' ```
#'

oo::class create ::chess4tcl::Chess4Tcl {
    variable dto
    constructor {{fen ""}} {
        set dto [::duktape::oo::Duktape new]

        # code fom dbohdan
        if {![file exists $::chess4tcl::chessfile]} {
            #rputs "fetching https://cdnjs.cloudflare.com/ajax/libs/chess.js/0.10.2/$chessfile"
            exec curl -fsSL https://cdnjs.cloudflare.com/ajax/libs/chess.js/0.10.2/chess.js -O $chess4tcl:::chessfile
        }
        
        # Set up the game.
        $dto eval [::fileutil::cat $chess4tcl::chessfile]
        if {$fen ne ""} {
            $dto eval " chess = new Chess (\"$fen\") "
        } else {
            $dto eval { chess =new Chess () }
        }
        #$dto js-method FromTo {{fromarg "" string} {toarg "" string}} { 
        #    return chess.move({from: fromarg, to: toarg}); 
        #}
        #$dto js-method myboard {} { return JSON.stringify(chess.board()); }
        #$dto js-method loadPgn2 {{pgnstr "" string}} {
        #    chess = new Chess();
        #    fixstr=pgnstr.replace(/\n  +\n/g, '\n\n');
        #    return(chess.load_pgn(fixstr));
        #}
    }
    #' ## Methods
    #'
    #' _cmd_ __ascii__
    #' 
    #' > Returns and ascii presentation fo the board
    #'
    #' > Example:
    #'
    #' ```{.tcl}
    #' puts [$chess ascii]
    #' ```
    #'
    method ascii {} {
        return [$dto call-method-str chess.ascii undefined]
    }
    #' _cmd_ __board__ _?TTF?_
    #' 
    #' > Returns and board presentation which can be mebedded into word or libreoffice documemts
    #'   for instance using the Berlin true type font-
    #'
    #' > Example:
    #'
    #' ```{.tcl eval=FALSE}
    #' puts "\n[$chess board true]"
    #' puts "\n[$chess board]"
    #' ```
    #'

    method board {{ttf false}} {
        set mboard [regsub " .+" [my fen] ""]
        set mboard [regsub -all 1 $mboard "."]
        set mboard [regsub -all 2 $mboard ".."]
        set mboard [regsub -all 3 $mboard "..."]
        set mboard [regsub -all 4 $mboard "...."]
        set mboard [regsub -all 5 $mboard "....."]
        set mboard [regsub -all 6 $mboard "......"]
        set mboard [regsub -all 7 $mboard "......."]
        set mboard [regsub -all 8 $mboard "........"]
        set mboard [regsub -all "/" $mboard ""]
        set fields [string repeat wbwbwbwbbwbwbwbw 4]
        set res ""
        if {$ttf} {
            set res "1222222223\n"
        }
        set x 0
        for {set row 0} {$row < 8} { incr row } {
            if {$ttf} {
                append res "4"
            }
            for {set col 0} {$col < 8} { incr col } {
                set field [string range $fields $x $x]
                set slot [string range $mboard [expr {$row*8+$col}] [expr {$row*8+$col}]]
                if {$slot eq "."} {
                    if {$ttf && $field eq "w"} {
                        append res " "
                    } elseif {$ttf && $field eq "b"} {
                        append res "+"
                    } elseif {$field eq "w"} {
                        append res " "
                    } else {
                        append res .
                    }
                } else {
                    if {$ttf && $field eq "w"} {
                        set piece [string map {K k Q q R r B b N h P p k l q w r t b n n j p o} $slot]
                    } elseif {$ttf && $field eq "b"} {
                        set piece [string map {K K Q Q R R B B N H P P k L q W r T b N n J p O} $slot]
                    } else {
                        set piece $slot
                    }
                    append res $piece
                }
                incr x
            }
            if {$ttf} {
                append res "5"
            }
            append res "\n"
        }
        if {$ttf} {
            append res "7888888889"
        }
        return $res
    }
    #' _cmd_ __clear__ 
    #' 
    #' > Creates an empty borad with no pieces.
    #'
    #' > Example:
    #'
    #' ```{.tcl}
    #' $chess clear
    #' puts [$chess fen]
    #' ```
    #'
    method clear { } {
        return [$dto call-method-str chess.clear undefined]
        #$dto eval "chess.clear()"
    }
    #' _cmd_ __fen__ 
    #' 
    #' > Returns the current position as a FEN string.
    #'
    #' > Example:
    #'
    #' ```{.tcl}
    #' $chess new
    #' puts [$chess fen]
    #' ```
    #'
    method fen { } {
        return [$dto call-method-str chess.fen undefined]
    }
    #' _cmd_ __load__ _?FEN?_
    #' 
    #' > Load the given fenstring.
    #'
    #' > Example:
    #'
    #' ```{.tcl}
    #' $chess load "rnb1kbnr/pppp1ppp/8/4p3/5PPq/8/PPPPP2P/RNBQKBNR w KQkq - 1 3"
    #' puts [$chess fen]
    #' ```
    #'
    method load {fen} {
        $dto eval "chess.load(\"$fen\")"
    }
    #' _cmd_ **game_over**
    #' 
    #' > Checks if the game is finished.
    #'
    #' > Example:
    #'
    #' ```{.tcl}
    #' $chess load "rnb1kbnr/pppp1ppp/8/4p3/5PPq/8/PPPPP2P/RNBQKBNR w KQkq - 1 3"
    #' $chess board
    #' puts [$chess game_over]
    #' ```
    #'
    method game_over {} {
        return [$dto call-method-str chess.game_over undefined]
    }
    method get {square} {
        if {[$dto eval "chess.get(\"$square\")"] eq "null"} {
            return [list "" ""]
        } else {
            return [list [$dto eval "chess.get(\"$square\").type"] \
                    [$dto eval "chess.get(\"$square\").color"]]
        }
    }
   method header {args} {
       foreach {key value} $args {
           $dto eval "chess.header(\"$key\",\"$value\")"
       }
       if {[llength $args] == 0} {
           return [$dto eval "Object.keys(chess.header())"]
       }
   }
   method history {{verbose false}} {
        if {$verbose} {
            set nmove [llength [[self] history]]
            set res [list]
            for {set i 0} {$i < $nmove} {incr i 1} {
                set move [list]
                foreach key [list color from to flags piece san] {
                    set val [$dto eval " chess.history({verbose:true})\[$i\].$key "]
                    lappend move $key 
                    lappend move $val
                }
                lappend res $move
            }
            return $res
       } else {
           return [split [$dto eval { chess.history() }] ,]
       }
   }
   #' ```{.tcl results=asis}
   #' puts [$chess svg]
   #' ```
   #'
   method svg {{size 400}} {
       set fontfile $::chess4tcl::fontfile
       if [catch {open $fontfile r} infh] {
           puts stderr "Cannot open $fontfile: $infh"
           exit
       } else {
           set b64 [read $infh]
           set b64 [regsub -all {[\n ]} $b64 ""]
           close $infh
       }
       set board [my board]
       set pieces {
           K \u2654 Q \u2655 R \u2656 B \u2657 N \u2658 P \u2659
           k \u265A q \u265B r \u265C b \u265D n \u265E p \u265F
       }
       set font "@font-face { 
          font-family: 'Merida'; 
          src: url(data:font/truetype;charset=utf-8;base64,$b64) format('truetype'); 
      }"
      set shadow "text-shadow: -1px -1px 0 #000, 1px -1px 0 #000, -1px 1px 0 #000, 1px 1px 0 #000;"
      #set font ""
       set svg "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 8 8\" width=\"$size\" height=\"$size\" style=\"border: 3px solid #631;\">"
       append svg "<style>$font\ntext.white { $shadow; }\ntext{ font-family: Merida; font-size:0.8px;text-anchor:middle;dominant-baseline:central; border: 2px solid #630; }</style>"
       set board [split $board "\n"]
       set row 0
       foreach rank $board {
           set col 0
           foreach char [split $rank ""] {
               set x [expr {$col + 0.5}]
               set y [expr {$row + 0.3}]
               set fill [expr {($row + $col) % 2 == 0 ? "#fdc" : "#cba"}]
               append svg "<rect x=\"$col\" y=\"$row\" width=\"1\" height=\"1\" fill=\"$fill\"/>"
               if {[string is lower $char]} {
                   set piece [string map $pieces $char]
                   append svg "<text x=\"$x\" y=\"$y\">$piece</text>"
               } elseif {[string is upper $char]} {
                   set piece [string map $pieces $char]
                   append svg "<text x=\"$x\" y=\"$y\" class=\"white\">$piece</text>"                   
               } 
               incr col
           }
           incr row
       }
       
       append svg "</svg>"
       return $svg
   }

    #' _cmd_ __moves__ 
    #' 
    #' > Returns all possible moves.
    #'
    #' > Example:
    #'
    #' ```{.tcl}
    #' $chess new
    #' puts [$chess fen]
    #' puts [$chess moves]
    #' ```
    #'
    method moves { } {
        return [split [$dto eval { moves = chess.moves() }] ,]
    }
    #' _cmd_ __move__ _?MOVE?_
    #' 
    #' > Executes the given move
    #'
    #' > Example:
    #'
    #' ```{.tcl}
    #' $chess new
    #' $chess move e4
    #' $chess move e5
    #' $chess move Ke2
    #' puts [$chess board]
    #' ```
    #'
    method move {args} {
        if {[llength $args]== 1} {
            set move [lindex $args 0]
            $dto eval " chess.move(\"$move\") "
        } else {
            set from [lindex $args 0]
            set to [lindex $args 1]
            $dto moveFromTo $from $to
        }
    }

   method in_check {} {
       return [$dto call-method-str chess.in_check undefined]
   }
   method in_checkmate {} {
       return [$dto call-method-str chess.in_checkmate undefined]
       
   }
   method in_draw {} {
       return [$dto call-method-str chess.in_draw undefined]
   }
   method in_stalemate {} {
       return [$dto call-method-str chess.in_stalemate undefined]
   }
   method in_threefold_repetition {} {
       return [$dto call-method-str chess.in_threefold_repetition undefined]
   }
   method insufficient_material {} {
       return [$dto call-method-str chess.insufficient_material undefined]
   }
   method new { } {
       $dto eval "chess =new Chess ()"
    }
    method load_pgn2 {pgn} {
        # did not work
       set pgn [regsub -all {\n +\n} $pgn {\n\n}]
       set results [$dto call-str chess.load_pgn $pgn]
       puts "results=$results"
       return 
   }
   method load_pgn {pgn} {
       return [$dto loadPgn2 $pgn]
   }

   method pgn {} {
       return [$dto call-method-str chess.pgn undefined]
   }
   method put {piece color square} {
       return [$dto eval "chess.put({type: '$piece',color: '$color'},'$square')"]
   }
   method reset {} {
       return [$dto call-method-str chess.reset undefined]
   }
   method remove {square} {
       set res [list]
       puts [$dto eval "chess.remove(\"$square\")"]
       if {[$dto eval "chess.remove(\"$square\")"] eq "null"} {
           return $res
       }
       foreach key [$dto eval "Object.keys(chess.remove(\"$square\"))"] {
           lappend res [list $key [$dto eval "chess.remove(\"$square\").$key"]]
       }
       return $res
   }
   method turn {} {
       $dto call-method-str chess.turn undefined
   }
}

proc ::chess4tcl::usage {app} {
    puts "Usage $app ?-h,--help? FENSTRING ?OUTFILE?"
}
proc ::chess4tcl::help {app argv} {
    puts help
}
proc ::chess4tcl::main {argv} {
    puts $argv
    if {[llength $argv] == 1} {
        set chess [::chess4tcl::Chess4Tcl new]
        $chess load [lindex $argv 0]
        puts [$chess board]
        
    } else {
        puts main
    }
}
if {[info exists argv0] && $argv0 eq [info script]} {
    if {[lsearch -regex $argv {(-h|--help)}] > -1} {
        ::chess4tcl::help $argv0 $argv
    } elseif {[llength $argv] < 1} {
        ::chess4tcl::usage $argv0
    } else {
       ::chess4tcl::main $argv
    }
}

if {false} {
    set chess [::chess4tcl::Chess4Tcl new]
    foreach move [$chess moves] { puts $move }
    $chess move e4
    $chess turn
    $chess move e5
    $chess move f4
    puts [$chess ascii]
    puts [$chess fen]
    $chess reset
    $chess header White Plunky Black Plinkie
    $chess move e4
    $chess move e5
    $chess move f4
    $chess move d5
    
    puts [$chess pgn]
    puts [$chess ascii]
    puts [$chess game_over]
    $chess load "4k3/4P3/4K3/8/8/8/8/8 b - - 0 78"
    puts [$chess ascii]
    if {[$chess game_over]} {
        puts "it's over!!"
    }
    $chess load "rnb1kbnr/pppp1ppp/8/4p3/5PPq/8/PPPPP2P/RNBQKBNR w KQkq - 1 3"
    puts [$chess ascii]
    puts [$chess game_over]
    puts [$chess get a8]
    puts [$chess get a5]
    puts "puts in mate? "
    puts [$chess in_check]
    $chess load "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
    $chess move e4
    $chess move e5
    $chess move f4
    puts [$chess history]
    puts [$chess history true]
    $chess load "rnb1kbnr/pppp1ppp/8/4p3/5PPq/8/PPPPP2P/RNBQKBNR w KQkq - 1 3"
    puts [$chess game_over]
    #puts [$chess in_mate]
    $chess load "rnb1kbnr/pppp1ppp/8/4p3/5PPq/8/PPPPP2P/RNBQKBNR w KQkq - 1 3"
    puts [$chess game_over]
    #puts [$chess in_mate]
    #puts [$chess in draw]
    #puts [$chess in check]
    set pgn {[Event "Casual Game"]
[Site "Berlin GER"]
[Date "1852.??.??"]
[EventDate "?"]
[Round "?"]
[Result "1-0"]
[White "Adolf Anderssen"]
[Black "Jean Dufresne"]
[ECO "C52"]
[WhiteElo "?"]
[BlackElo "?"]
[PlyCount "47"]
       
1.e4 e5 2.Nf3 Nc6 3.Bc4 Bc5 4.b4 Bxb4 5.c3 Ba5 6.d4 exd4 7.O-O
d3 8.Qb3 Qf6 9.e5 Qg6 10.Re1 Nge7 11.Ba3 b5 12.Qxb5 Rb8 13.Qa4
Bb6 14.Nbd2 Bb7 15.Ne4 Qf5 16.Bxd3 Qh5 17.Nf6+ gxf6 18.exf6
Rg8 19.Rad1 Qxf3 20.Rxe7+ Nxe7 21.Qxd7+ Kxd7 22.Bf5+ Ke8
23.Bd7+ Kf8 24.Bxe7# 1-0
}
     # did not work
    $chess load_pgn $pgn
    puts "loaded?"
    puts [$chess ascii]
    puts [$chess pgn]
    puts "result?"
    puts [$chess header]
    $chess load "k7/8/n7/8/8/8/8/7K b - - 0 1"
    $chess header White "Robert J. Fisher"
    $chess header Black "Mikhail Tal"
    puts [$chess insufficient_material]
    $chess clear
    puts [$chess put p b a5]
    puts [$chess put k w h1]
    puts [$chess fen]
    puts [$chess put z w a1] ;# invalid
    puts [$chess insufficient_material]
    puts [$chess remove a5]
    puts [$chess remove a1] ;# not possible
    $chess clear
    $chess load "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1"
    puts [$chess turn]
    puts [$chess in_check]
    $chess clear
    puts "loading start position"
    $chess load "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
    #$chess new
    $chess move e4
    $chess move e5
    $chess move Na3 
    $chess move Qh4
    $chess move Ke2
    puts "check? [$chess in_check]"
    $chess move Qxe4
    puts [$chess ascii]
    puts "check? [$chess in_check]"
    puts "mate? [$chess in_checkmate]"
    puts [$chess board]
    puts [$chess board true]
    package require Tk
    font create chessberlin -family "Chess Berlin" -size 20 
    option add *font chessberlin
    pack [text .t]
    .t insert end [regsub -all " " [$chess board true] "   "]
}
