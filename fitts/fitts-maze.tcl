#! /usr/bin/wish
#
# This is to test Fitts Law
#
# Developed by:
# Konstantinos Michmizos (konmic@mit.edu), Summer 2012
#
# To be used only with: Anklebot

# Tk GUI library
package require Tk

global ob
# this controls the controller's function
set ob(ctl) 26

# unconventional hack. This should come from the UI
set env(PATID) 1

set ob(crobhome) $::env(CROB_HOME)
source $ob(crobhome)/shm.tcl

source ../common/util.tcl
source ../common/menu.tcl
source $::env(I18N_HOME)/i18n.tcl

# is this arm bot? (of course)
localize_robot

proc open_start_menu {} {
    # Create the start menu window
    toplevel .menu
    wm title .menu "Maze Game Menu"
    wm geometry .menu 400x300 ; # Set the menu window size to 400x300 pixels

    # Add start button
    button .menu.start -text "Start Game" -command {start_game; destroy .menu}
    pack .menu.start -padx 10 -pady 10

    # Add game mode selection
    label .menu.mode_label -text "Select Game Mode:"
    pack .menu.mode_label -padx 10 -pady 5
    radiobutton .menu.mode_sequential -text "Sequential" -variable mode -value sequential
    pack .menu.mode_sequential -padx 10 -pady 5
    radiobutton .menu.mode_incremental -text "Incremental" -variable mode -value incremental
    pack .menu.mode_incremental -padx 10 -pady 5

    # Add level increment selection for incremental mode
    label .menu.increment_label -text "Level Increment (for Incremental Mode):"
    pack .menu.increment_label -padx 10 -pady 5
    scale .menu.increment -from 1 -to 4 -orient horizontal -variable increment
    pack .menu.increment -padx 10 -pady 5

    # Add exit button
    button .menu.exit -text "Exit" -command {exit}
    pack .menu.exit -padx 10 -pady 10
}

# Function to start the game
proc start_game {} {
    global path level max_level_length cell_width cell_height

    # Create the main game window
    toplevel .game
    wm title .game "T-Maze"

    # Create a canvas widget
    canvas .game.c -width 1800 -height 1000 -background white
    pack .game.c -expand true -fill both

    # Set up global variables and constants
    set canvas_width 1800
    set canvas_height 1000
    set grid_width 9
    set grid_height 5
    set cell_width [expr {$canvas_width / $grid_width}]
    set cell_height [expr {$canvas_height / $grid_height}]
    set half_cell_width [expr {$cell_width / 2}]
    set half_cell_height [expr {$cell_height / 2}]
    set line_width 80
    set short_arm_length [expr {$line_width / 2}]
    set pointer_size 20
    array set t_boundaries {}
    array set star_location {}
    set ob(mb_state) paused
    set ob(Hz) 200
    set ob(controller) 16
    set ob(slottime) 1.4
    # slotticks in samples, fed to movebox
    set ob(slotticks) [expr {int($ob(slottime) * $ob(Hz))}]
    
    set level 1
    set max_level_length [llength $path]

    # Function to get cell coordinates
    proc get_cell_coords {i j} {
        global cell_width cell_height half_cell_width half_cell_height
        set x [expr {$i * $cell_width + $half_cell_width}]
        set y [expr {$j * $cell_height + $half_cell_height}]
        return [list $x $y]
    }

    # Function to draw T shapes and record boundaries
    proc make_t {x1 y1 x2 y2 orientation colour} {
        global line_width t_boundaries

        set x_middle [expr {($x2 + $x1) / 2}]
        set y_middle [expr {($y2 + $y1) / 2}]

        switch $orientation {
            "N" {
                .game.c create line $x_middle $y2 $x_middle $y_middle -width $line_width -fill $colour   ;# Vertical arm
                .game.c create line $x1 $y_middle $x2 $y_middle -width $line_width -fill $colour ;# Horizontal arm
                set t_boundaries($x1,$y1) "N"
            }
            "S" {
                .game.c create line $x_middle $y1 $x_middle $y_middle -width $line_width -fill $colour   ;# Vertical arm
                .game.c create line $x1 $y_middle $x2 $y_middle -width $line_width -fill $colour ;# Horizontal arm
                set t_boundaries($x1,$y1) "S"
            }
            "E" {
                .game.c create line $x_middle $y1 $x_middle $y2 -width $line_width -fill $colour   ;# Vertical arm
                .game.c create line $x1 $y_middle $x_middle $y_middle -width $line_width -fill $colour ;# Horizontal arm
                set t_boundaries($x1,$y1) "E"
            }
            "W" {
                .game.c create line $x_middle $y1 $x_middle $y2 -width $line_width -fill $colour   ;# Vertical arm
                .game.c create line $x_middle $y_middle $x2 $y_middle -width $line_width -fill $colour ;# Horizontal arm
                set t_boundaries($x1,$y1) "W"
            }
        }
    }

    # Function to draw the path
    proc draw_path {path level_length} {
        global cell_width cell_height move_segments line_width
        .game.c delete all

        array unset t_boundaries
        array unset move_segments 

        for {set i 0} {$i < $level_length} {incr i} {
            set prev [lindex $path $i-1]
            set current [lindex $path $i]
            set next [lindex $path $i+1]

            set direction3 [lindex $prev 2]
            set direction1 [lindex $current 2]
            set direction2 [lindex $next 2]

            set x1 [expr { $cell_width * [lindex $current 1] }]
            set x2 [expr { $cell_width * ([lindex $current 1] + 1)}]

            set y1 [expr { $cell_height * [lindex $current 0]}]
            set y2 [expr { $cell_height * ([lindex $current 0] + 1)}]

            set x1_n [expr { $cell_width * [lindex $next 1]}]
            set x2_n [expr { $cell_width * ([lindex $next 1] + 1)}]
            set y1_n [expr { $cell_height * [lindex $next 0]}]
            set y2_n [expr { $cell_height * ([lindex $next 0] + 1)}]

            set x_middle [expr {($x2 + $x1) / 2}]
            set y_middle [expr {($y2 + $y1) / 2}]

            set x_middle_n [expr {($x2_n + $x1_n) / 2}]
            set y_middle_n [expr {($y2_n + $y1_n) / 2}]

            if {$direction1 == "up"} {
                set orientation "S"
            } elseif {$direction1 == "down"} {
                set orientation "N"
            } elseif {$direction1 == "left"} {
                set orientation "E"
            } elseif {$direction1 == "right"} {
                set orientation "W"
            }

            if {![info exists segment_start_index]} {
                if {$i == 0} {
                set segment_start_index [list $x2 $y_middle]
                } elseif {$x1 == $x1_n} {
                    if {$y1 > $y1_n} {
                        set segment_start_index [list $x_middle $y2]
                    } else {
                        set segment_start_index [list $x_middle $y1]
                    }
                } else {
                    if {$x1 > $x1_n} {
                        set segment_start_index [list $x2 $y_middle]
                    } else {
                        set segment_start_index [list $x1 $y_middle]
                    }
                }
            }

            if {$i == $level_length - 1} {
                make_t $x1 $y1 $x2 $y2 $orientation "green"
            } else {
                make_t $x1 $y1 $x2 $y2 $orientation "black"
            }


            # set segment_end_index 0

            if {$direction1 == "N"} {
                set direction1 "S"
            } elseif {$direction1 == "E"} {
                set direction1 "W"
            }
            if {$direction2 == "N"} {
                set direction2 "S"
            } elseif {$direction2 == "E"} {
                set direction2 "W"
            }


            if {$direction1 ne $direction2} {
                if {[lindex $current 0] == [lindex $prev 0]} {
                    if {[lindex $current 0] == [lindex $next 0]} {
                            set segment_end_index [list [expr {$x_middle_n - $line_width/2}] $y_middle_n]
                            lappend move_segments [list $segment_start_index $segment_end_index]
                            .game.c create line [lindex $segment_start_index 0] [lindex $segment_start_index 1]  [lindex $segment_end_index 0] [lindex $segment_end_index 1] -width [expr {$line_width / 2}] -fill "red"

                            unset segment_start_index
                    }
                    if {[lindex $current 1] == [lindex $next 1]} {
                        if {[lindex $current 1] > [lindex $prev 1]} {
                            set segment_end_index [list [expr {$x_middle + $line_width/2}] $y_middle]
                        } else {
                            set segment_end_index [list [expr {$x_middle - $line_width/2}] $y_middle]
                        }
                        
                        lappend move_segments [list $segment_start_index $segment_end_index]
                        .game.c create line [lindex $segment_start_index 0] [lindex $segment_start_index 1]  [lindex $segment_end_index 0] [lindex $segment_end_index 1] -width [expr {$line_width / 2}] -fill "red"

                        if {[lindex $current 0] > [lindex $next 0]} {
                            set segment_start_index [list $x_middle [expr {$y_middle + $line_width/2}]]
                        } else {
                            set segment_start_index [list $x_middle [expr {$y_middle - $line_width/2}]]
                        }
                    }                     
                } elseif {[lindex $current 1] == [lindex $prev 1]} {
                    if {[lindex $current 0] == [lindex $next 0]} {
                        if {[lindex $current 0] > [lindex $prev 0]} {
                            set segment_end_index [list $x_middle [expr {$y_middle + $line_width/2}]]
                        } else {
                            set segment_end_index [list $x_middle [expr {$y_middle - $line_width/2}]]
                        }
                        lappend move_segments [list $segment_start_index $segment_end_index]
                        .game.c create line [lindex $segment_start_index 0] [lindex $segment_start_index 1]  [lindex $segment_end_index 0] [lindex $segment_end_index 1] -width [expr {$line_width / 2}] -fill "red"
                        if {[lindex $current 1] < [lindex $next 1]} {
                            set segment_start_index [list [expr {$x_middle - $line_width/2}] $y_middle]
                        } else {
                            set segment_start_index [list [expr {$x_middle + $line_width/2}] $y_middle]
                        }
                        
                    }
                    if {[lindex $current 1] == [lindex $next 1]} {
                        set segment_end_index [list $x_middle_n [expr {$y_middle_n + $line_width/2}]]
                        lappend move_segments [list $segment_start_index $segment_end_index]
                        .game.c create line [lindex $segment_start_index 0] [lindex $segment_start_index 1]  [lindex $segment_end_index 0] [lindex $segment_end_index 1] -width [expr {$line_width / 2}] -fill "red"

                        unset segment_start_index
                    }    
                }
                # .game.c create line [lindex $segment_start_index 0] [lindex $segment_start_index 1]  [lindex $segment_end_index 0] [lindex $segment_end_index 1] -width [expr {$line_width / 2}] -fill "red"
                
                # set segment_start_index [expr {$i + 1}]
            }
        }

        puts "Move Segments: $move_segments"
        create_pointer 890 490
    }

    proc check_movebox {} {
        global pointer path level max_level_length mode increment cell_width cell_height line_width current_movebox_index move_segments
        set coords [.game.c coords $pointer]
        puts $current_movebox_index

        set cx [expr {([lindex $coords 0] + [lindex $coords 2]) / 2}]
        set cy [expr {([lindex $coords 1] + [lindex $coords 3]) / 2}]

        set segment_current [lindex $move_segments $current_movebox_index]
        set x1 [lindex [lindex $segment_current 0] 0]
        set y1 [lindex [lindex $segment_current 0] 1]
        set x2 [lindex [lindex $segment_current 1] 0]
        set y2 [lindex [lindex $segment_current 1] 1]
        if { mb_state == paused } {
            movebox 0 0 {0 $ob(slotticks) 1} [list {$x1,$y1,0.05,0.05}] [list {$x2,$y2,0.05,0.05}]
            set ob(mb_state) active
        }
        .game.c create line $x1 $y1 $x2 $y2 -width [expr {$line_width / 4}] -fill "blue"
        if { $x1 > $x2 } {
            if { $cx <= $x2 + $line_width} {
                incr current_movebox_index
                stop_movebox 0
                set ob(mb_state) paused
            }
        } elseif { $x1 < $x2 } {
            if { $cx >= $x2 - $line_width } {
                incr current_movebox_index
            }
        } elseif { $y1 > $y2 } {
            if { $cy <= $y2 + $line_width } {
                incr current_movebox_index
            } 
        } elseif { $y1 < $y2 } {
            if { $cy >= $y2 - $line_width} {
                incr current_movebox_index
            }
        }
    }


    proc check_pointer_position {} {
        global pointer path level max_level_length mode increment cell_width cell_height
        set coords [.game.c coords $pointer]
        set cx [expr {([lindex $coords 0] + [lindex $coords 2]) / 2}]
        set cy [expr {([lindex $coords 1] + [lindex $coords 3]) / 2}]
        set final_cell [lindex $path [expr {$level * 2  - 1}]]
        set final_x [expr { int($cx / $cell_width)}]
        set final_y [expr { int($cy / $cell_height)}]
        # puts "$final_cell $final_x $final_y"

        if {$final_x == [lindex $final_cell 1] && $final_y == [lindex $final_cell 0]} {
            if {$mode == "sequential"} {
                incr level
            } else {
                incr level $increment
                puts $level
            }
            if {$level * 2 > $max_level_length} {
                puts "Congratulations! You've completed all levels."
                exit
            }
            set current_movebox_index 0
            stop_movebox 0
            set ob(mb_state) active
            after 100 movebox 0 0 {0 $ob(slotticks) 1} [list {$cx,$cy,0.05,0.05}] [list {0.0,0.0,0.05,0.05}]
            after 1000 stop_movebox 0
            set ob(mb_state) paused
            
            after 500 [list draw_path $path [expr {$level * 2}]]
        }
    }

    # Function to initialize the pointer
    proc create_pointer {a b} {
        global pointer
        if {[info exists pointer]} {
            .game.c delete $pointer
        }
        set pointer [.game.c create oval $a $b [expr {$a + 20}] [expr {$b + 20}] -fill black]
        # bind .game.c <B1-Motion> {move_pointer %x %y}

	new_move_pointer
        focus -force .
    }

    proc make_star {x y color size} {

        set pi 3.1415926535897931

        set points {}
        set counter 0
        set increment [expr {$pi / 5}]

        for {set i [expr {$pi * -1 / 2}]} { $i < [expr {3 * $pi / 2}]} {set i [expr {$i + $increment}]} {
            if {$counter % 2 == 0} {
                set r $size
            } else {
                set r [expr {$size / 2}]
            }
            set cos [expr {cos($i)}]
            set sin [expr {sin($i)}]
            lappend points [expr {$x + $r * $cos}]
            lappend points [expr {$y + $r * $sin}]

            incr counter
        }
        
        .game.c create polygon $points -fill $color
    }

    

    # Function to move the pointer within boundaries
    proc isInsideBar {x y cx cy} {
        global t_boundaries pointer cell_width cell_height line_width

        set cell_x [expr {int($cx / $cell_width)}]
        set cell_y [expr {int($cy / $cell_height)}]

        set x1 [expr { $cell_width * $cell_x}]
        set x2 [expr { $cell_width * ($cell_x + 1)}]

        set y1 [expr { $cell_height * $cell_y}]
        set y2 [expr { $cell_height * ($cell_y + 1)}]

        if {![info exists t_boundaries($x1,$y1)]} {
            # puts "BOOM"
            return 0
        }
        set orientation [lindex $t_boundaries($x1,$y1)] 

        set x_middle [expr { ($x2 + $x1) / 2 }]
        set y_middle [expr { ($y2 + $y1) / 2 }]

        switch $orientation {
            "N" {
                return [expr {($x >= $x_middle - $line_width / 2) && ($x <= $x_middle + $line_width / 2) && ($y > [expr {$y_middle + $line_width / 2}]) ||
                              ($y < [expr {$y_middle + $line_width / 2}]) && ($y > [expr {$y_middle - $line_width / 2}])}]
            }
            "S" {
                return  [expr {($x >= $x_middle - $line_width / 2) && ($x <= $x_middle + $line_width / 2) && ($y < [expr {$y_middle - $line_width / 2}]) ||
                              ($y < [expr {$y_middle + $line_width / 2}]) && ($y > [expr {$y_middle - $line_width / 2}]) }]
            }
            "E" {
                return  [expr {($x > $x_middle - $line_width / 2) && ($x < $x_middle + $line_width / 2) ||
                              ($x < [expr {$x_middle - $line_width / 2}]) && ($y > [expr {$y_middle - $line_width / 2}]) && ($y < [expr {$y_middle + $line_width / 2}]) }]
            }
            "W" {
                return [expr {($x > $x_middle - $line_width / 2) && ($x < $x_middle + $line_width / 2) ||
                              ($x > [expr {$x_middle + $line_width / 2}]) && ($y > [expr {$y_middle - $line_width / 2}]) && ($y < [expr {$y_middle + $line_width / 2}]) }]
            }
        }
    }

    proc move_pointer {x y} {
        global t_boundaries pointer cell_width cell_height line_width ob .game.c pointer

        set coords [.game.c coords $pointer]
        set cx [expr {([lindex $coords 0] + [lindex $coords 2]) / 2}]
        set cy [expr {([lindex $coords 1] + [lindex $coords 3]) / 2}]

        set cell_x [expr {int($cx / $cell_width)}]
        set cell_y [expr {int($cy / $cell_height)}]

        set x1 [expr { $cell_width * $cell_x}]
        set y1 [expr { $cell_height * $cell_y}]


        set cx1 [expr {$cx + 20}]
        set cy1 $cy

        set cx2 [expr {$cx - 20}]
        set cy2 $cy

        set cx3 $cx
        set cy3 [expr {$cy + 20}]

        set cx4 $cx
        set cy4 [expr {$cy - 20}]

        set cell_x1 [expr {int($cx1 / $cell_width)}]
        set cell_y1 [expr {int($cy1 / $cell_height)}]

        set cell_x2 [expr {int($cx2 / $cell_width)}]
        set cell_y2 [expr {int($cy2 / $cell_height)}]

        set cell_x3 [expr {int($cx3 / $cell_width)}]
        set cell_y3 [expr {int($cy3 / $cell_height)}]

        set cell_x4 [expr {int($cx4 / $cell_width)}]
        set cell_y4 [expr {int($cy4 / $cell_height)}]

        set x1_1 [expr { $cell_width * $cell_x1}]
        set y1_1 [expr { $cell_height * $cell_y1}]

        set x2_1 [expr { $cell_width * $cell_x2}]
        set y2_1 [expr { $cell_height * $cell_y2}]

        set x3_1 [expr { $cell_width * $cell_x3}]
        set y3_1 [expr { $cell_height * $cell_y3}]

        set x4_1 [expr { $cell_width * $cell_x4}]
        set y4_1 [expr { $cell_height * $cell_y4}]


        if {![info exists t_boundaries($x1,$y1)]} {
            .game.c delete $pointer
            create_pointer 890 490
        } elseif {![info exists t_boundaries($x1_1,$y1_1)]} {
            .game.c delete $pointer
            create_pointer [expr {$cx - 20}] $cy
        } elseif {![info exists t_boundaries($x2_1,$y2_1)]} {
            .game.c delete $pointer
            create_pointer [expr {$cx + 20}] $cy
        } elseif {![info exists t_boundaries($x3_1,$y3_1)]} {
            .game.c delete $pointer
            create_pointer $cx [expr {$cy - 20}]
        } elseif {![info exists t_boundaries($x4_1,$y4_1)]} {
            .game.c delete $pointer
            create_pointer $cx [expr {$cy + 20}]
        } else {
            # puts "BOOM"
            # puts "$x $y"
            if {[isInsideBar $x $y $cx $cy]} {
                set pos [.game.c coords $pointer]
                lassign $pos x1 y1 x2 y2
                set dx [expr {$x - ($x1 + $x2) / 2}]
                set dy [expr {$y - ($y1 + $y2) / 2}]
                .game.c coords $pointer [expr {$x1 + $dx}] [expr {$y1 + $dy}] [expr {$x2 + $dx}] [expr {$y2 + $dy}]
                check_pointer_position
            }
        }
    }

    proc new_move_pointer {} {
	global t_boundaries pointer cell_width cell_height line_width ob .game.c pointer
	set x 0.0
	set y 0.0
	    set x [getptr x]
 	    set y [getptr y]
	puts "${x}_${y}"
	set scaled_x [expr {$x * (900 / 0.22) + 900}]
	set scaled_y [expr {$y * -1 * (500 / 0.22)} + 500]

	set pos [.game.c coords $pointer]
        lassign $pos x1 y1 x2 y2

        set dx [expr {$scaled_x - ($x1 + $x2) / 2}]
        set dy [expr {$scaled_y - ($y1 + $y2) / 2}]
        .game.c coords $pointer [expr {$x1 + $dx}] [expr {$y1 + $dy}] [expr {$x2 + $dx}] [expr {$y2 + $dy}]
        check_pointer_position
        check_movebox
	
	after 5 new_move_pointer
    }

    start_rtl

    wm deiconify .

    wshm no_safety_check 1

    wshm planar_damp 0.

    # Draw the initial path
    draw_path $path 2

    # Create and bind the pointer
    create_pointer 890 490

    movebox 0 0 {0 $ob(slotticks) 1} [list {0.0,0.0,0.05,0.05}] [list {0.10,0.0,5.0,0.05}]
    puts "active movebox"
    after 10000 stop_movebox 00

}

# Given path
set path {
    {2 4 up}
    {2 3 up}
    {2 2 right}
    {3 2 right}
    {3 3 down}
    {4 3 right}
    {4 4 left}
    {3 4 right}
    {3 5 down}
    {4 5 right}
    {4 6 up}
    {3 6 right}
    {2 6 left}
    {1 6 right}
    {0 6 down}
    {0 5 down}
    {1 5 left}
    {1 4 up}
    {1 3 up}
    {1 2 up}
    {0 2 left}
    {0 1 up}
    {1 1 right}
    {2 1 up}
    {2 0 up}
    {1 0 left}
    {0 0 left}
}

# Initialize global variables
set level 1
set ob(hdir) 0
set mode "sequential"
set increment 1
array set t_boundaries {}
array set move_segments {}

set canvas_width 1800
set canvas_height 1000
set grid_width 9
set grid_height 5

set cell_width [expr {$canvas_width / $grid_width}]
set cell_height [expr {$canvas_height / $grid_height}]
set half_cell_width [expr {$cell_width / 2}]
set half_cell_height [expr {$cell_height / 2}]
set line_width 80

set current_movebox_index 0
# Open the start menu
open_start_menu
