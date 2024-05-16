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

set ob(crobhome) $::env(CROB_HOME)
source $ob(crobhome)/shm.tcl

source ../common/util.tcl
source ../common/menu.tcl
source $::env(I18N_HOME)/i18n.tcl

# is this ankle? (of course)
localize_robot


proc init_Fitts {} {
	global ob


    	set ob(programname) Fitts_experiment
	set ob(savelog) 1
    	set ob(asklog) 1
	
	set ob(endgame) 60
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

	domenu

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
    	bind . <s> stop_Fitts
    	bind . <n> new_Fitts
    	bind . <q> { done }
	bind <Double-1> {after 700 {error [imes "please don't double-click the menu buttons"]}; break}
	bind <Triple-1> {after 700 {error [imes "please don't triple-click the menu buttons"]}; break}
    	wm protocol . WM_DELETE_WINDOW { done }

	# creating the racer
	make_racer
	size_racer

    	start_rtl

	wm deiconify .

	after 250 menu_hide .menu

	#wshm no_safety_check 1
	#wshm ankle_damp 0.
}

proc make_fixed_list {n rom} {
	global ob

    set the_list {}
    switch $rom {
	short_rom {
	    set min 2
	    set max 5
	}
	medium_rom {
	    set min 1
	    set max 6
	}
	long_rom {
	    set min 0
	    set max 7
	}
    }
	set ob(min_randi) $min
	set ob(max_randi) $max
	
# this has been modified for the experiments
    foreach j [iota [expr {$n/4}]] {
	set rand_dir  [irand 7]
	if {$rand_dir<=3} {
		lappend the_list $min
	} else {
		lappend the_list $max
	}
	lappend the_list 3.5
	set rand_dir  [irand 7]
	if {$rand_dir<=3} {
		lappend the_list $min
	} else {
		lappend the_list $max
	}
	lappend the_list 3.5
    }
    return $the_list
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
	if {$ob(hdir) == 0} {
	    set x [getptr x]
	    set vel [rshm ankle_ie_vel]
	    if {$ob(ankle)} {
		foreach {x y} [ankle_ptr_scale $x $y] break
	    }
	    dragx $w $x racer
	    set cur_pos $x
	} else {
	    set y [getptr y]
	    set vel [rshm ankle_dp_vel]
	    if {$ob(ankle)} {
	    	foreach {x y} [ankle_ptr_scale $x $y] break
	    } 
	    dragy $w $y racer
	    set cur_pos $y
	}
	
	set ob(cur_pos) $cur_pos

	#lappend ob(dx) [expr {abs($cur_pos-$ob(trgtcen))}]
	#lappend ob(x) $cur_pos
	# puts "vel = $vel"
	if {[expr {abs($vel)}]<0.001} {
		check_target
	}

	after 5 do_drag .c
}

proc dragx {w x what} {
	global ob

	set x1 [bracket $x -$ob(half,x) $ob(half,x)]
	set x1 [expr {$x1 - $ob(racw2)}]
	set x2 [expr {$x1 + $ob(racw)}]
	set y1  [expr {0-$ob(racw2)}]
	set y2 [expr {$y1 + $ob(rach)}]
        .c coords $what $x1 $y1 $x2 $y2
	.c scale $what 0 0 $ob(scale) -$ob(scale)
}

proc dragy {w y what} {
	global ob

	set y1 [bracket $y -$ob(half,y) $ob(half,y)]
	set y1 [expr {$y1 - $ob(racw2)}]
	set y2 [expr {$y1 + $ob(racw)}]
	set x1  [expr {0-$ob(racw2)}]
	set x2 [expr {$x1 + $ob(rach)}]
        .c coords $what $x1 $y1 $x2 $y2
	.c scale $what 0 0 $ob(scale) -$ob(scale)
}

proc new_Fitts {} {
	global ob mob

	incr ob(n_games) 

	if {$ob(n_games) > 1} {
		error [imes "First press 'Stop Experiment (s)' and then 'New Experiment (n)'"]
	}
	set ob(running) 1

	set ob(step) $mob(step)
	set ob(fitts,var) $mob(fitts,var)

	if {$ob(fitts,var)==0} {
		set ob(session_movements) 10
	} elseif {$ob(fitts,var)==1} {
		set ob(session_movements) 30
	} elseif {$ob(fitts,var)==2} {
		set ob(session_movements) 20
	}

	set ob(endgame) [expr {int($ob(session_movements)*floor(($ob(target_width)-$ob(racw))/$ob(step)))}]
	set ob(nsets) [expr {$ob(endgame)+1}]
	set ob(targets_list) [make_fixed_list $ob(nsets) $ob(Fitts,rom)]

	set ob(hdir) $mob(hdir)

	prepare_logging
	start_experiment_start_log 

	if {$mob(showing) } {
		after 50 [list menu_hide .menu]
	}

	do_drag .c
	create_target
}

proc create_target {} {
	global ob

	if {$ob(targets_created) == $ob(endgame)} {
		done
	}

	do_title

	set ob(target) [.c create rect 0 0 .05 .05 -fill white -tag target]
	.c scale target 0 0 $ob(scale) -$ob(scale)
	show_target
}

proc show_target {} {
	global ob

	set i [expr {$ob(targets_created) % $ob(endgame)}]
	if {($i % 10) == 0 && $i>0} {
		set ob(target_width) [expr {$ob(target_width) - $ob(step)}]
		if {$ob(target_width) <= $ob(racw)} {
			done
		}
	}
    	set randi [lindex $ob(targets_list) $i]

    	set spacing [expr {($ob(winwidth) - ($ob(side2) + $ob(target_width)))/double($ob(npos)-1)}]
	if {$randi == 3.5} {
		set ob(centered) yes
   		set x1 [expr {$ob(side) - $ob(half,x) + $spacing * $randi}]
	} else {
		set ob(centered) no

		set rand_dir  [irand 7]
		if {$rand_dir<=3} {
			set x1 [expr {$ob(side) - $ob(half,x) + $spacing * $ob(min_randi)}]
		} else {
			set x1 [expr {$ob(side) - $ob(half,x) + $spacing * $ob(max_randi)}]
		}
	} 

	set y1 [expr {0 - $ob(target_height)/2.0}]
	set x2 [expr {$x1 + $ob(target_width)}]
	set y2 [expr {0 + $ob(target_height)/2.0}]


	set ob(left_frame) $x1
	set ob(right_frame) $x2
	set ob(upper_frame) $y1
	set ob(bottom_frame) $y2

	eval .c coords target [swaps $x1 $y1 $x2 $y2]
	.c scale target 0 0 $ob(scale) -$ob(scale)
        .c raise racer target
	incr ob(targets_created)
	wshm Fitts_target_marker $ob(targets_created)
}

proc check_target {} {
	global ob

	set bbox [.c bbox $ob(racer)]
	set hit [lindex [eval .c find overlapping $bbox] 1]
	if {$hit > 0} {
		if {$ob(cur_pos) > [expr {$ob(left_frame) + $ob(racw2) }] && $ob(cur_pos) < [expr {$ob(right_frame) - $ob(racw2) }]} {
		.c delete $ob(target)
		wshm Fitts_target_marker 0
		after 1000 [list create_target]
		}
	}
}

proc stop_Fitts {} {
	global ob

	# this requires hitting the stop button before hitting new game
	incr ob(n_games) -1
	if {$ob(n_games)<0} {set ob(n_games) 0}

	set ob(targets_created) 0
	do_title

	end_experiment_stop_log
	if {$ob(running)} {
		.c delete $ob(target)
	}
	set ob(running) 0
}	

proc done {} {
        global ob
	
	stop_Fitts
	stop_rtl
	exit
}

proc do_title {} {
	global ob mob
	
	wm title . "Fitts Experiment  ||  Name: $mob(whoN)  ||  Total Targets: $ob(endgame)  ||  Cleared Targets: $ob(targets_created)"
}


# game name and patient name
# they come in as command line args, usually from the
# cons "game console" program
# in a HIPAA setting, the patient name will be a numeric ID.
proc prepare_logging {} {
	global ob mob env argc argv

    	set ob(logdirbase) $::env(THERAPIST_HOME)

	set ob(gamename) games/exper/Fitts_log
    	set ob(gametype) exper
	
    	set ob(patname) $mob(who)

    	set env(PATID) $mob(who)

	if {$ob(asklog)} { 
		if {![info exists env(PATID)]} {
	    		error "Please enter a Patient ID"
	   	 	exit
		}
		if {$env(PATID) == ""} {
	    		error "Please enter a Patient ID"
	    		exit
		}
		set ob(whichgame) "ie"
		if {$ob(hdir)} {
			set ob(whichgame) "dp"
		}	
	}

   	if {$argc >= 1} {
		set ob(gamename) [lindex $argv 0]
    	}
    	if {$argc >= 2} {
		set ob(patname) [lindex $argv 1]
    	}

	if {$ob(ankle)} {
		# for clinic: fnid = 16
		# for lab: fnid = 18
		set ob(logfnid) 17
		set ob(logvars) 18
    	} 

    	set curtime [clock seconds]
    	set ob(datestamp) [clock format $curtime -format "%Y%m%d_%a"]
    	set ob(timestamp) [clock format $curtime -format "%H%M%S"]
    	set ob(dirname) [file join $ob(logdirbase) $ob(patname) $ob(gametype) $ob(datestamp) Fitts ]

    	if {$ob(savelog)} {
		wshm logfnid $ob(logfnid)
    	}

	init_logging
}

proc init_logging {} {
	global ob 

    	set tailname [file tail $ob(gamename)]
    	set filename [join [list $tailname $ob(timestamp)] _]
    	set filename [file join $ob(dirname) $filename]
    	file mkdir $ob(dirname)
    	set ob(log_fd) [open "${filename}.asc" w]
    	puts $ob(log_fd) "Time: $ob(timestamp)"
    	puts $ob(log_fd) "Dir: $ob(dirname)"
    	puts $ob(log_fd) "Game: $tailname"
	puts $ob(log_fd) "Type: $ob(whichgame)"
    	puts $ob(log_fd) "Gametype: Fitts experiment"
    	puts $ob(log_fd) "Step size: $ob(step)"
	puts $ob(log_fd) "Number of targets presented: $ob(endgame)" 
	puts $ob(log_fd) "Targets List:" 
	puts $ob(log_fd) "$ob(targets_list)" 
    	flush $ob(log_fd)
}


# logging
# open logfile-per-section
proc start_experiment_start_log {} {
	global ob

    	if {$ob(savelog)} {
		set ob(tailname) [file tail $ob(gamename)]
		set slotlogfilename [join [list $ob(tailname) $ob(timestamp).dat] _]
		set slotlogfilename [file join $ob(dirname) $slotlogfilename]
		start_log $slotlogfilename $ob(logvars)
		puts ""
		puts "Logging Data in $slotlogfilename"
    	}	
}

# close logfile-per-slot.
proc end_experiment_stop_log {} {
    	global ob
    
	if {$ob(savelog)} {
		stop_log
    	}
}

proc domenu {} {
	global ob mob env

	set m [menu_init .menu]
	menu_v $m who "Player's ID" $env(PATID)
	menu_v $m whoN "Player's Name" Player
	menu_v $m step "Target Decrement Step" 0.01

	menu_t $m blank0 "" ""
	menu_t $m blank1 "" ""
	menu_t $m blank2 "" ""
	menu_t $m blank3 "" ""
	menu_t $m blank4 "" ""


	frame $m.dir
	label $m.dir.dir_label -text "Movement:"
	set mob(hdir) 1
	radiobutton $m.dir.dir_hriz -text [imes "Dorsal / Plantar Flexion"] \
		-variable mob(hdir) -relief flat -value 1
	radiobutton $m.dir.dir_vert -text [imes "Inversion / Eversion"] \
		-variable mob(hdir) -relief flat -value 0
	pack $m.dir -anchor w
	pack $m.dir.dir_label -anchor w
	pack $m.dir.dir_hriz -anchor w
	pack $m.dir.dir_vert -anchor w
	menu_t $m blank5 "" ""
	menu_t $m blank6 "" ""
	menu_t $m blank12 "" ""

	frame $m.var
 	label $m.var.var_label -text "Select Experiment:"
	set mob(fitts,var) 0
	radiobutton $m.var.var_1 -text [imes "Normal Experiment"] \
		-variable mob(fitts,var) -relief flat -value 0
	    radiobutton $m.var.var_2 -text [imes "Larger Experiment"] \
		-variable mob(fitts,var) -relief flat -value 1
	    radiobutton $m.var.var_3 -text [imes "Randomly presented targets"] \
		-variable mob(fitts,var) -relief flat -value 2
	pack $m.var -anchor w
	pack $m.var.var_label -anchor w
	pack $m.var.var_1 -anchor w
	pack $m.var.var_2 -anchor w
	pack $m.var.var_3 -anchor w
	menu_t $m blank13 "" ""
	menu_t $m blank14 "" ""
	menu_t $m blank15 "" ""
	menu_t $m log "     Automatic Logging" ""

	menu_t $m blank16 "" ""
	menu_t $m blank17 "" ""
	menu_t $m blank18 "" ""
	menu_b $m newgame "New Experiment (n)" new_Fitts
	menu_t $m blank19 "" ""
	menu_b $m stopgame "Stop Experiment (s)" stop_Fitts
	menu_t $m blank20 "" ""
	menu_b $m quit "Quit (q)" {done}
	menu_t $m blank21 "" ""
}

init_Fitts
