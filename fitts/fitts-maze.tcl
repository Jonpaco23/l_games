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


proc init_Fitts {} {
	global ob

    	set ob(programname) Fitts_experiment
	
	set ob(running) 0


	# this flag secures single game running
	set ob(n_games) 0

	set ob(Fitts,rom) long_rom

	set ob(hdir) 0
    	set ob(scale) 1500.0
    	set ob(winwidth) .44
    	set ob(winheight) .44
	set ob(half,x) [expr {$ob(winwidth) / 2.}]
    	set ob(half,y) [expr {$ob(winheight) / 2.}]
	set ob(target_height) 0.08
	set ob(target_width) 0.08
   	set ob(side) .000
    	set ob(side2) [expr {$ob(side) * 2.}]

    	set ob(npos) 8
	set ob(targets_created) 0

	# creating the canvas
    	wm withdraw .

	# domenu

    	set ob(can,x) 685
    	set ob(can,y) 685
    	set ob(can2,x) [expr {$ob(can,x) / 2.}]
   	set ob(can2,y) [expr {$ob(can,y) / 2.}]

	canvas .c -width $ob(can,x) -height $ob(can,y) -bg white
	grid .c
	wm geometry . 1015x690
	. config -bg gray20
	place .c -relx 0.5  -rely 0.5 -anchor center

	.c config -highlightthickness 0
	.c config -scrollregion [list -$ob(can2,x) -$ob(can2,y) $ob(can2,x) $ob(can2,y)]

	# binding
    	# bind . <s> stop_Fitts
    	# bind . <n> new_Fitts
    	bind . <q> { done }
	bind <Double-1> {after 700 {error [imes "please don't double-click the menu buttons"]}; break}
	bind <Triple-1> {after 700 {error [imes "please don't triple-click the menu buttons"]}; break}
    	wm protocol . WM_DELETE_WINDOW { done }

	# creating the racer
	make_racer
	size_racer

    	start_rtl

	wm deiconify .

	# after 250 menu_hide .menu

	wshm no_safety_check 1
	# changed ankle to planar
	wshm planar_damp 0.
	do_drag .c
}

proc make_racer {} {
	global ob 

	set mob(round) 1
        if {$mob(round)} {
                set shape oval
        } else {
                set shape rectangle
        }

	if {[info exists ob(racer)]} {
		.c delete $ob(racer)
	}

	set ob(racer) [.c create $shape 0 0 .1 .1  -outline "" \
		-fill black -tag racer]
	.c scale racer 0 0 $ob(scale) -$ob(scale)
}

proc size_racer {} {
	global ob mob

	# distance from screen edge to racer face
	set rdist .015

	# racer dimensions
	# set ob(racw) .0115
	set ob(racw) .015
	set ob(racw) [bracket $ob(racw) .005 .1]
	set ob(rach) $ob(racw)
	set ob(racw2) [expr {$ob(racw) / 2.}]
	set ob(rach2) [expr {$ob(rach) / 2.}]

	# racer
	set x1 -$ob(racw2)
	set y1 [expr {0-$ob(racw2)}]
	set x2 $ob(racw2)
	set y2 [expr {$y1 + $ob(rach)}]
	eval .c coords racer [swaps $x1 $y1 $x2 $y2]
	.c scale racer 0 0 $ob(scale) -$ob(scale)
}

proc do_drag {w} {
	global ob mob

	# hdir == 0 means IE
	# hdir == 1 means DP
	set x 0.0
	set y 0.0
	    set x [getptr x]
 	    set y [getptr y]
	puts "${x}_${y}"
	dragxy $w $x $y racer
	
	# set ob(cur_pos) $cur_pos

	#lappend ob(dx) [expr {abs($cur_pos-$ob(trgtcen))}]
	#lappend ob(x) $cur_pos
	# puts "vel = $vel"
	after 5 do_drag .c
}

proc dragxy {w x y what} {
	global ob

	set x1 [bracket $x -$ob(half,x) $ob(half,x)]
	set y1 [bracket $y -$ob(half,y) $ob(half,y)]
	set x1 [expr {$x1 - $ob(racw2)}]
	set x2 [expr {$x1 + $ob(racw)}]
	set y1 [expr {$y1 - $ob(rach2)}]
	set y2 [expr {$y1 + $ob(rach)}]
        .c coords $what $x1 $y1 $x2 $y2
	.c scale $what 0 0 $ob(scale) -$ob(scale)
}


proc done {} {
        global ob
	
	stop_rtl
	exit
}

init_Fitts
