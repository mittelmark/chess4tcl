#!/usr/bin/env tclsh
##############################################################################
#  Created       : 2025-01-15 19:21:27
#  Last Modified : <250122.0827>
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
#' ```{.tcl eval=false}
#' package require chess4tcl
#' set chess [::chess4tcl::Chess4Tcl new]
#' $chess moves
#' $chess move MOVE
#' $chess ascii
#' $chess board
#' $chess fen
#' $chess game_over
#' $chess get a1
#' $chess header
#' $chess history
#' $chess in_check
#' $chess in_checkmate
#' $chess in_draw
#' $chess in_stalemate
#' $chess in_threefold_repetition
#' $chess insufficient_material
#' $chess in_checkmate
#' $chess load FEN-STRING
#' $chess load_pgn PGN-STRING
#' $chess new
#' $chess pgn
#' $chess put B w e4
#' $chess remove a1
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
#' _::chess4tcl::Chess4Tcl_ __new__ ?FEN?
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
    #' > Returns and board presentation which can be embedded into word or libreoffice documemts
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
    
    #' _cmd_ **game_over**
    #' 
    #' > Checks if the game is finished.
    #'
    #' > Example:
    #'
    #' ```{.tcl}
    #' $chess load "rnb1kbnr/pppp1ppp/8/4p3/5PPq/8/PPPPP2P/RNBQKBNR w KQkq - 1 3"
    #' puts [$chess board]
    #' puts [$chess game_over]
    #' ```
    #'
    method game_over {} {
        return [$dto call-method-str chess.game_over undefined]
    }
    
    #' _cmd_ **gboard**
    #' 
    #' > Displays the current board using the javascript web component gchessboard.
    #'
    #' > Example:
    #'
    #' ```{.tcl results=asis}
    #' puts [$chess gboard]
    #' ```
    #'
    method gboard {} {
        variable gboard
        set res ""
        set fen [regsub { .+} [my fen] ""]
        set style "--square-color-dark: hsl(27deg, 36%, 55%);--square-color-light: hsl(37deg, 66%, 83%);"
        if {![info exists gboard]} {
            append res {<script type="module" src="https://unpkg.com/gchessboard"></script>}
            set gboard true
        }
        append res {<div style="max-width: 400px;margin-left:35px;"><g-chess-board fen="FEN" style="STYLE"></g-chess-board></div>}
        set res [regsub FEN $res $fen]
        set res [regsub STYLE $res $style]
        return $res
    }
    
    #' _cmd_ **get** *square*
    #' 
    #' > Returns the stone on the given square.
    #'
    #' > Example:
    #'
    #' ```{.tcl}
    #' $chess load "rnb1kbnr/pppp1ppp/8/4p3/5PPq/8/PPPPP2P/RNBQKBNR w KQkq - 1 3"
    #' puts [$chess board]
    #' puts [$chess get e1]
    #' ```
    #'

    method get {square} {
        if {[$dto eval "chess.get(\"$square\")"] eq "null"} {
            return [list "" ""]
        } else {
            return [list [$dto eval "chess.get(\"$square\").type"] \
                    [$dto eval "chess.get(\"$square\").color"]]
        }
    }
    #' _cmd_ __goto\_half\_move__ _N_
    #' 
    #' > Load the current game and goto the given half move, so move 5 with white to move is half move 9.
    #'   Please note that this creates a new game, so the play through a game and display certain positions you have
    #'   to store the current PGN
    #' 
    #' > Returns: true if loaded, false otherwise
    #'
    #' > Example: See [load_pgn](#loadpgn) for an example.
    #'
    
    method goto_half_move {hm} {
        set moves [my history]
        my new
        for {set i 0} {$i < $hm} {incr i 1} {
            my move [lindex $moves $i]
        }
    }
    #' _cmd_ **header** *?args?*
    #' 
    #' > Returns the the available header keys or returns the given header value
    #'
    #' > Example:
    #'
    #' ```{.tcl}
    #' puts [$chess header]
    #' $chess header White "James White"
    #' $chess header Black "Jonny Black"
    #' puts [$chess header]
    #' ```
    #'
    method header {args} {
        foreach {key value} $args {
            $dto eval "chess.header(\"$key\",\"$value\")"
        }
        if {[llength $args] == 0} {
            return [$dto eval "Object.keys(chess.header())"]
        }
    }
    #' _cmd_ **history** *?verbose?*
    #' 
    #' > Returns the last moves of a game.
    #'
    #' > Example:
    #'
    #' ```{.tcl}
    #' $chess new
    #' $chess move e4
    #' $chess move e5
    #' $chess move f4
    #' puts [$chess history]
    #' ```
    #'
    #' ```{.tcl}
    #' puts [$chess history true]    
    #' ```
    #'
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
    #' _cmd_ **in_check**
    #' 
    #' > Returns if King is in check.
    #'
    #' > Example:
    #'
    #' ```{.tcl}
    #' $chess new
    #' $chess move e4
    #' $chess move e5
    #' $chess move f4
    #' puts [$chess in_check]
    #' $chess move Qh4
    #' puts [$chess noard]
    #' puts [$chess in_check]
    #' ```
    #' 
    #'
    method in_check {} {
        return [$dto call-method-str chess.in_check undefined]
    }
    #' _cmd_ **in_checkmate**
    #' 
    #' > Returns if King is checkmate.
    #'
    #' > Example:
    #'
    #' ```{.tcl}
    #' $chess new
    #' $chess move e4
    #' $chess move e5
    #' $chess move Ke2
    #' $chess move Qh4
    #' $chess move Na3
    #' puts [$chess in_checkmate]
    #' $chess move Qxe4
    #' puts [$chess in_checkmate]
    #' ```
    #'
    method in_checkmate {} {
        return [$dto call-method-str chess.in_checkmate undefined]
        
    }
    #' _cmd_ **in_draw**
    #' 
    #' > Returns if teh game is a technical draw.
    #'
    #' > Example:
    #'
    #' ```{.tcl}
    #' $chess load "1k6/1N6/1K6/8/8/8/8/8 w - - 0 1" ; # just a knight
    #' puts [$chess ascii]
    #' puts "draw: [$chess in_draw]"
    #' $chess load "1k6/1N6/1K6/8/8/8/8/7B w - - 0 1" ; # adding a bishop
    #' puts [$chess ascii]
    #' puts "draw: [$chess in_draw]"
    #' ```
    #'
    method in_draw {} {
        return [$dto call-method-str chess.in_draw undefined]
    }
    #' _cmd_ **in_stalemate**
    #' 
    #' > Returns if teh game is a technical draw.
    #'
    #' > Example:
    #'
    #' ```{.tcl}
    #' $chess load "1k6/1N6/1K6/8/8/8/8/8 b - - 0 1" ; # just a knight
    #' puts [$chess ascii]
    #' puts "stalemate: [$chess in_stalemate]"
    #' $chess load "1k6/1P6/1K6/8/8/8/8/8 b - - 0 1" ; # adding a pawn
    #' puts [$chess ascii]
    #' puts "stalemate: [$chess in_stalemate]"
    #' ```
    #'
    method in_stalemate {} {
        return [$dto call-method-str chess.in_stalemate undefined]
    }
    #' _cmd_ __in\_threefold\_repetition__
    #' 
    #' > Returns if the game is in threefold repetition.
    #'
    #' > Example:
    #'
    #' ```{.tcl}
    #' $chess new
    #' $chess move e4
    #' $chess move e5
    #' $chess move Ke2
    #' $chess move Ke7
    #' puts [$chess ascii]
    #' puts "repetition: [$chess in_threefold_repetition]"
    #' $chess move Ke1
    #' $chess move Ke8
    #' $chess move Ke2
    #' $chess move Ke7
    #' $chess move Ke1
    #' $chess move Ke8
    #' $chess move Ke2
    #' $chess move Ke7
    #' $chess move Ke1
    #' $chess move Ke8
    #' puts "repetition: [$chess in_threefold_repetition]"
    #' ```
    #'
    method in_threefold_repetition {} {
        return [$dto call-method-str chess.in_threefold_repetition undefined]
    }
    #' _cmd_ __insufficient\_material__
    #' 
    #' > Returns if the game is finshed due to insufficnet material.
    #'
    #' > Example:
    #'
    #' ```{.tcl}
    #' $chess new
    #' $chess load "1k6/2R5/1K6/8/8/8/8/8 w - - 0 1" ;# rook it is not
    #' puts "draw by insufficent material - K vs RK? [$chess insufficient_material]"
    #' $chess load "1k6/2N5/1K6/8/8/8/8/8 w - - 0 1" ;# bishop it is not
    #' puts "draw by insufficent material - K vs NK? [$chess insufficient_material]"
    #' ```
    #'
    method insufficient_material {} {
        return [$dto call-method-str chess.insufficient_material undefined]
    }
    #'
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
    #' _cmd_ __new__
    #' 
    #' > Create a new game with default position.
    #'
    #' > Example:
    #'
    #' ```{.tcl}
    #' $chess new
    #' puts [$chess ascii]
    #' ```
    method new { } {
        $dto eval "chess =new Chess ()"
    }
    method load_pgn2 {pgn} {
        # did not work
        set pgn [regsub -all {\n +\n} $pgn {\n\n}]
        set result [$dto call-str chess.load_pgn $pgn]
        return $result
    }
    #' <a name="loadpgn"></a>
    #' _cmd_ __load\_pgn__ _PGN_
    #' 
    #' > Load the given PGN string.
    #' 
    #' > Returns: true if loaded, false otherwise
    #'
    #' > Example:
    #'
    #' ```{.tcl}
    #' $chess new
    #' set PGN {[Event "F/S Return Match"]
    #' [Site "Belgrade, Serbia JUG"]
    #' [Date "1992.11.04"]
    #' [Round "29"]
    #' [White "Fischer, Robert J."]
    #' [Black "Spassky, Boris V."]
    #' [Result "1/2-1/2"]
    #' 
    #' 1.e4 e5 2.Nf3 Nc6 3.Bb5 {This opening is called the Ruy Lopez.} 3...a6
    #' 4.Ba4 Nf6 5.O-O Be7 6.Re1 b5 7.Bb3 d6 8.c3 O-O 9.h3 Nb8 10.d4 Nbd7
    #' 11.c4 c6 12.cxb5 axb5 13.Nc3 Bb7 14.Bg5 b4 15.Nb1 h6 16.Bh4 c5 17.dxe5
    #' Nxe4 18.Bxe7 Qxe7 19.exd6 Qf6 20.Nbd2 Nxd6 21.Nc4 Nxc4 22.Bxc4 Nb6
    #' 23.Ne5 Rae8 24.Bxf7+ Rxf7 25.Nxf7 Rxe1+ 26.Qxe1 Kxf7 27.Qe3 Qg5 28.Qxg5
    #' hxg5 29.b3 Ke6 30.a3 Kd6 31.axb4 cxb4 32.Ra5 Nd5 33.f3 Bc8 34.Kf2 Bf5
    #' 35.Ra7 g6 36.Ra6+ Kc5 37.Ke1 Nf4 38.g3 Nxh3 39.Kd2 Kb5 40.Rd6 Kc5 41.Ra6
    #' Nf2 42.g4 Bd3 43.Re6 1/2-1/2
    #' }
    #' $chess load_pgn $PGN
    #' puts [$chess ascii]
    #' puts [$chess history]
    #' $chess goto_half_move 10
    #' puts [$chess ascii]
    #' $chess load_pgn $PGN
    #' $chess goto_half_move 5
    #' puts [$chess ascii]
    #' ```
    #'
    method load_pgn {pgn} {
        #return [$dto loadPgn2 $pgn]
        return [my load_pgn2 $pgn]
    }
    #' <a name="loadpgn"></a>
    #' _cmd_ __pgn__
    #' 
    #' > Return the current load game as PGN
    #' 
    #' > Returns: a PGN string, cimments are probably removed
    #'
    #' > Example:
    #'
    #' ```{.tcl}
    #' $chess new
    #' $chess move e4
    #' $chess move e5
    #' $chess move f4
    #' $chess header White "James White"
    #' $chess header Black "Jimmy Black"    
    #' $chess header Event "Documentation Game"
    #' puts [$chess pgn]
    #' ```
    #'
    method pgn {} {
        return [$dto call-method-str chess.pgn undefined]
    }
    #' <a name="put"></a>
    #' _cmd_ __put__ _piece ?color square?_
    #' 
    #' > Places the given piece(s). If only piece is given it must have the form like
    #'   "`White: Kh1,Pa2,Rg1`" and "`Black: Kh8,Qa6`". That way you can much easier
    #'   and faster setup a position.
    #' 
    #' > Returns: true if correctly placing the pieces / all pieces, false otherwise.
    #'
    #' > Example:
    #'
    #' ```{.tcl}
    #' $chess clear
    #' $chess put k w a1
    #' $chess put k b h8
    #' $chess put q w g6
    #' puts [$chess insufficient_material]
    #' puts [$chess ascii]
    #' $chess clear
    #' $chess put "White: Ka1,Pa2"
    #' $chess put "Black: Kh8,Nh1"    
    #' puts [$chess ascii]
    #' ```
    #'
    method put {piece {color ""} {square ""}} {
        if {$color eq ""} {
            if {[regexp {^Black: } $piece]} {
                set pieces [regsub {Black: +} $piece ""]
                foreach piece [split $pieces ,] {
                    regexp {([A-Z])([a-z][0-9])} $piece -> p square
                    my put $p b $square
                }
            } elseif {[regexp {^White: } $piece]} {
                set pieces [regsub {White: +} $piece ""]
                foreach piece [split $pieces ,] {
                    regexp {([A-Z])([a-z][0-9])} $piece -> p square
                    set result [my put $p w $square]
                    if {!$result} {
                        return false
                    }
                }
            }
            return true
        } else {
            array set pieces [list K KING Q QUEEN] 
            return [$dto eval "chess.put({type: '$piece',color: '$color'},'$square')"]
        }
    }
    #' <a name="reset"></a>
    #' _cmd_ __reset__ 
    #' 
    #' > Reset a board to the initial starting position.
    #' 
    #' > Returns: true if correctly sucess, otherwise false
    #'
    #' > Example:
    #'
    #' ```{.tcl}
    #' $chess new
    #' $chess move e4
    #' puts [$chess ascii]
    #' $chess reset
    #' puts [$chess ascii]
    #' ```
    
    method reset {} {
        return [$dto call-method-str chess.reset undefined]
    }
    #' <a name="remove"></a>
    #' _cmd_ __remove__ _square_
    #' 
    #' > Remove a piece from the given square.
    #' 
    #' > Returns: true if correctly sucess, otherwise false
    #'
    #' > Example:
    #'
    #' ```{.tcl}
    #' $chess clear
    #' $chess put "White: Ka1,Pa2,Ph2"
    #' $chess put "Black: Kh8,Nh1"    
    #' puts [$chess ascii]
    #' puts [$chess remove h3]
    #' puts [$chess remove h2]
    #' puts [$chess ascii]
    #' ```

    method remove {square} {
        set res [list]
        if {[$dto eval "chess.remove(\"$square\")"] eq "null"} {
            return false
        } else {
            return true
        }
        #foreach key [$dto eval "Object.keys(chess.remove(\"$square\"))"] {
        #    lappend res [list $key [$dto eval "chess.remove(\"$square\").$key"]]
        #}
        #return $res
    }
    #' <a name="svg"></a>
    #' _cmd_ __svg__ _?args?_
    #' 
    #' > Creates a SVG image with the Merida font embedded. In contrast to the gboard representation
    #'   this the display of this board does not require an internet connection.
    #' 
    #' > Arguments:
    #' - _-size_ - board size, default: 400
    #' - _-font_ - the used font, currently only Merida should be used, default: Merida
    #' - _-white-square_ - color of the white squares, default: #fdc
    #' - _-black-square_ - color of the black squares: default: #ca9
    #'
    #' > Returns: a SVG image of the current board.
    #'
    #' > Example:
    #'
    #' ```{.tcl results="asis"}
    #' $chess clear
    #' $chess put "White: Ka1,Pa2,Pb2"
    #' $chess put "Black: Kh8,Na8"    
    #' puts [$chess svg -size 300]
    #' ```
    #'
    method svg {args} {
        array set arg [list -size 400 -font Merida -white-square  "#fdc" -black-square "#ca9"]
        array set arg $args
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
        if {$arg(-font) eq "Merida"} {
            set font "@font-face { 
            font-family: 'Merida'; 
            src: url(data:font/truetype;charset=utf-8;base64,$b64) format('truetype'); 
            }"
        } else {
            set font ""
        }
        set shadow "text-shadow: -1px -1px 0 #000, 1px -1px 0 #000, -1px 1px 0 #000, 1px 1px 0 #000;"
        #set font ""
        set svg "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 8 8\" width=\"$arg(-size)\" height=\"$arg(-size)\" style=\"border: 3px solid #631;\">"
        append svg "<style>$font\ntext.white { $shadow; }\ntext{ font-family: Merida; font-size:0.8px;text-anchor:middle;dominant-baseline:central; border: 2px solid #630; }</style>"
        set board [split $board "\n"]
        set row 0
        foreach rank $board {
            set col 0
            foreach char [split $rank ""] {
                set x [expr {$col + 0.5}]
                set y [expr {$row + 0.5}]
                set fill [expr {($row + $col) % 2 == 0 ? "$arg(-white-square)" : "$arg(-black-square)"}]
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
    #' <a name="turn"></a>
    #' _cmd_ __turn__
    #' 
    #' > Evaluates which turn it is.
    #'
    #' > Returns: a SVG image of the current board.
    #'
    #' > Example:
    #'
    #' ```{.tcl}
    #' $chess new
    #' $chess move e4
    #' $chess move e5
    #' puts [$chess turn]
    #' $chess move f4
    #' puts [$chess turn]
    #' ```
    #'
   method turn {} {
       return [$dto call-method-str chess.turn undefined]
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

#' ## Author
#' 
#' @2020-2025 Detlef Groth, University of Potsdam, Germany
#'
#' ## License
#' 
#' ```
#' MIT License
#' 
#' Copyright (c) 2020-2025 Detlef Groth
#'
#' Permission is hereby granted, free of charge, to any person obtaining a copy
#' of this software and associated documentation files (the "Software"), to deal
#' in the Software without restriction, including without limitation the rights
#' to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#' copies of the Software, and to permit persons to whom the Software is
#' furnished to do so, subject to the following conditions:
#' 
#' The above copyright notice and this permission notice shall be included in all
#' copies or substantial portions of the Software.
#' 
#' THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#' IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#' FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#' AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#' LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#' OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#' SOFTWARE.
#' ```
#'
