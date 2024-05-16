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


if {![is_robot_cal_done]} {
    puts "This robot is not calibrated."
    exit 1
}

# start the robot process, shared memory, and the control loop
puts "loading robot process"
if {[is_lkm_loaded]} {
        puts "lkm already loaded."
	exit
} else {
	wm protocol . WM_DELETE_WINDOW quit
        start_lkm
}
start_shm
start_loop
after 100
#wshm no_safety_check 1
#wshm stiff 100
#wshm damp 5
#wshm slot_max 4



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
	set ob(target_height) 0.06
	set ob(target_width) 0.04
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

	#.c create oval 8 8 8 8 -outline #f50 -fill #f50

    	start_rtl

	wm deiconify .

	after 250 menu_hide .menu

	wshm no_safety_check 1
	# changed ankle to planar
	wshm planar_damp 0.
}

proc make_fixed_list {rom} {
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
	    set one 1
	    set two 2
	    set five 5
	    set six 6
	    set max 7
	}
    }
	set ob(min_randi) $min
	set ob(max_randi) $max
	
	set width $ob(target_width)

	for {set ind 0} {$ind < [expr {$ob(endgame)}]} {incr ind} {	
		if {($ind % $ob(session_movements)) == 0 && $ind>0} {
			set width [expr {$width - $ob(step)}]
		}
		lappend ob(ltarget_width) $width
	}
	
	if {$ob(fitts,var)==3} {
	    	center_arm
	}
	if {$ob(fitts,var)==2 || $ob(fitts,var)==3} {
	    	# shuffle sorted list
		set ilistlast [llength $ob(ltarget_width)]
    		incr ilistlast -1
    		set ob(ltarget_width) [lrange [shuffle $ob(ltarget_width)] 0 $ilistlast]
	}

	# this has been modified for the experiments
    	for {set ind 0} {$ind < [expr {$ob(endgame)}]} {incr ind} {	
		#set rand_dir  [irand 7]
		set rand_dir  [irand 3]
		puts $rand_dir
		#before it was $rand_dir<=3
		
		if {0} {
		# This is for left and right appearing in order 
		if {$ind%6==0} {
			lappend the_list $min
		} elseif {$ind%6==1} {
			lappend the_list $max
		} elseif {$ind%6==2} {
			lappend the_list $one
		} elseif {$ind%6==3} {
			lappend the_list $six
		} elseif {$ind%6==4} {
			lappend the_list $two
		} else {
			lappend the_list $five
		}
		
		}
		
		
		# This is for left and right appearing randomly
		if {$ind%2==0} {
			if {$rand_dir == 0} {
				lappend the_list $min
			} elseif {$rand_dir == 1} {
				lappend the_list $one
			} else {
				lappend the_list $two
			}
		} else {
			if {$rand_dir == 0} {
				lappend the_list $max
			} elseif {$rand_dir == 1} {
				lappend the_list $six
			} else {
				lappend the_list $five
			}
		}
				
		
	}
	#puts $the_list
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
	set ob(racw) .01
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
	
	# set x_val_list {}
	# hdir == 0 means IE
	# hdir == 1 means DP
	#puts "here"	
	#puts $ob(hdir)
	set x 0.0
	set y 0.0
	    set x [getptr x]
 	    set y [getptr y]

	if {$ob(hdir) == 0} {
	    set vel [rshm ankle_ie_vel]
	    if {$ob(planar)} {
		foreach {x y} [ankle_ptr_scale $x $y] break
	    }
	    if {$ob(fitts,var)<=2} {
	    	dragx $w $x racer
	    } elseif {$ob(fitts,var)==3} {
	     	dragxy $w $x $y racer	
	    }
	    set cur_pos $x
	} else {
	    #set vel [rshm ankle_dp_vel]
	    set vel [expr {abs([rshm xvel])}]
	    #puts $vel
            #moving is 0 if it is stopped 
	    
	    if {$vel >= 0.002 && $vel<=0.0028} {
		#set moving 1
		#puts "MOVING!!!!!!"
		puts "Trigger 3 sent! I am moving!"
		set command [exec python TriggerTests.py 3]
		puts $command
		puts $vel
	    } else {
		set moving 0
	    }
	    # this needs to be fixed.
	    #if {$ob(planar)} {
	    #	foreach {x y} [ankle_ptr_scale $x $y] break
	    #} 
 	    if {$ob(fitts,var)<=2} {
	    	#dragy $w $y racer
		if {$x >= -0.001 && $x <= 0.001} {
			puts "Trigger 2 sent! I am in the middle!"
			set command [exec python TriggerTests.py 2]
			puts $command
		}
		
		dragx $w $x racer
	    } elseif {$ob(fitts,var)==3} {
	     	dragxy $w $x $y racer
	     }
	    set cur_pos $y
	    
	}
	
	set ob(cur_pos) $cur_pos
	
	
	#puts $ob(cur_pos)
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
	} else {
		set ob(session_movements) 20
	} 

	set ob(endgame) [expr {int($ob(session_movements)*floor(($ob(target_width)-$ob(racw))/$ob(step)))}]
	set ob(nshuffle_movements) [expr {int($ob(endgame)/$ob(session_movements))}]

	set ob(targets_list) [make_fixed_list $ob(Fitts,rom)]

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

	do_title

	set ob(target) [.c create rect 0 0 .05 .05 -fill white -tag target]
	.c scale target 0 0 $ob(scale) -$ob(scale)
	show_target
}

proc show_target {} {
	global ob

	set i $ob(targets_created)
	if {$i >= [expr {$ob(endgame)}]} {
			done
	}
	set ob(target_width) [lindex $ob(ltarget_width) $i]
    	set randi [lindex $ob(targets_list) $i]
	set ob(tarNum) $randi
	#puts $randi
	#puts $ob(tarNum)

    	set spacing [expr {($ob(winwidth) - ($ob(side2) + $ob(target_width)))/double($ob(npos)-1)}]
	
	set x1 [expr {$ob(side) - $ob(half,x) + $spacing * $randi}]
	set y1 [expr {0 - $ob(target_height)/4.0}]
	set x2 [expr {$x1 + $ob(target_width)}]
	set y2 [expr {0 + $ob(target_height)/4.0}]
	
	set ob(left_frame) $x1
	set ob(right_frame) $x2
	set ob(upper_frame) $y1
	set ob(bottom_frame) $y2

	#The line below is for a game where the user must move up and down
	#eval .c coords target [swaps $x1 $y1 $x2 $y2]
	
	eval .c coords target [swaps $y1 $x1 $y2 $x2]
	.c scale target 0 0 $ob(scale) -$ob(scale)
        .c raise racer target
	incr ob(targets_created)
	
	puts "I AM SHOWING THE TARGET"
	puts $ob(fitts,var)
	if {$ob(fitts,var)==3} {
		moveArm 0.1
	#	center_arm
	}
	#wshm Fitts_target_marker $ob(targets_created)
}

proc check_target {} {
	global ob

	set bbox [.c bbox $ob(racer)]
	set hit [lindex [eval .c find overlapping $bbox] 1]
	if {$hit > 0} {
		
		#originally left went before right
		#if {$ob(cur_pos) > [expr {$ob(left_frame) + $ob(racw2) }] && $ob(cur_pos) < [expr {$ob(right_frame) - $ob(racw2) }]} {
		

		#puts $ob(fitts,var)
		.c delete $ob(target)
		if {$ob(tarNum) == 0 || $ob(tarNum) == 1 || $ob(tarNum) == 2} { 
			puts "Trigger 0 sent! Left target has been hit"
			set command [exec python TriggerTests.py 0]
			puts $command
			puts $ob(tarNum)
		} else {
			puts "Trigger 1 sent! Right target has been hit"
			set command [exec python TriggerTests.py 1]
			puts $command
			puts $ob(tarNum)
		}
		
		#wshm Fitts_target_marker 0
		after 1000 [list create_target]
		#}
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

	if {$ob(planar)} {
		set ob(logfnid) 15
		set ob(logvars) 20
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
	global ob mob

    	set tailname [file tail $ob(gamename)]
    	set filename [join [list $tailname $ob(timestamp)] _]
    	set filename [file join $ob(dirname) $filename]
    	file mkdir $ob(dirname)
    	set ob(log_fd) [open "${filename}.asc" w]
    	puts $ob(log_fd) "Time: $ob(timestamp)"
    	puts $ob(log_fd) "Name: $mob(whoN)"
    	puts $ob(log_fd) "Dir: $ob(dirname)"
    	puts $ob(log_fd) "Game: $tailname"
	puts $ob(log_fd) "Type: $ob(whichgame)"
    	puts $ob(log_fd) "Gametype: Fitts experiment"
    	puts $ob(log_fd) "Step size: $ob(step)"
	puts $ob(log_fd) "Number of targets presented: $ob(endgame)" 
	puts $ob(log_fd) "Variation of Experiment: $ob(fitts,var)"
	puts $ob(log_fd) "Target Presentation: "
	puts $ob(log_fd) "$ob(ltarget_width)"
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

proc moveArm {xcoord} {
	global ob
	set ticks 1000.0
	set type 0
	movebox 0 $type {0 $ticks 1} \
		{0.0, 0.0, 0.0, 0.0} \
		{$xcoord, 0.0, 0.0, 0.0}
}

proc adap_moveit {forlist trgt} {
	global ob mob

    	set forlist [uplevel 1 [list subst -nocommands $forlist]]
    	set trgt [uplevel 1 [list subst -nocommands $trgt]]

	# take the center for the old and the new gates 
	set ob(trgtcen) $ob(nextcen)

	set x [rshm x]
	set y [rshm y]

	if {$ob(hdir)} {
		set src [list 0.0 $y 0.0 0.0]
		set dest [list 0.0 $trgt 0.0 0.0]
		set ob(slotlength) [expr {abs($trgt-$y)}]
		ctadd slotlength44 $ob(slotlength)
	} else {
		set src [list $x 0.0 0.0 0.0]
		set dest [list $trgt 0.0 0.0 0.0]
		set ob(slotlength) [expr {abs($trgt-$x)}]
		ctadd slotlength44 $ob(slotlength)
	}

	# starting to check if the patient moved during the time slot
	after 100 [list start_check]

	set src [eval swaps $src]
	set dest [eval swaps $dest]

    	set nx1 [lindex $src 0]
    	set nx2 [lindex $dest 0]

	set y1 0.0
	set y2 0.0

	set wid [expr {abs($nx2 - $nx1)}]
	set mid [expr {($nx1 + $nx2) / 2.}] 
   	
	set ob(forlist) $forlist
	set ob(mbmid) $mid
	set ob(mbwid) $wid
	set ob(mby1) $y1
	set ob(mby2) $y2
	set ob(mbnx2) $nx2

    	# zero the pm counters
    	adap_zero_pm

	# this will become 1 if patient moved enough
	set ob(patient_moved) 0

	# a stationary slot immediately
	movebox 0 $ob(ctl) {0 $ob(slotticks) 0} \
	[swaps $ob(mbmid) $ob(mby1) $ob(mbwid) 0.] \
	[swaps $ob(mbnx2) $ob(mby2) 0. 0.]
    	set ob(mb_state) open_slot
		
	set ob(forlist_effective) $ob(forlist)	
	# closing slot movebox
	set ob(moveit_slot) [after $ob(slottime_hard_mb) [list moveit]]
}

proc moveit {} {
	global ob mob

    	set ob(forlist_effective) [uplevel 1 [list subst -nocommands $ob(forlist_effective)]]

   	 # don't cancel do_slot_timeout here!
    	cancel_moveit_timeouts

    	# zero the pm counters
    	adap_zero_pm
		
	# no need to check if the patient moved or not
	set ob(check_move) no

	if {!$ob(paused)} {
		movebox 0 $ob(ctl) {$ob(forlist_effective)} \
	    	[swaps $ob(mbmid) $ob(mby1) $ob(mbwid) 0.] \
	    	[swaps $ob(mbnx2) $ob(mby2) 0. 0.]
    		set ob(mb_state) movebox
	}
}

proc domenu {} {
	global ob mob env

	set m [menu_init .menu]
	menu_v $m who "Player's ID" $env(PATID)
	menu_v $m whoN "Player's Name" Player
	menu_v $m step "Target Decrement Step" 0.01

	#menu_t $m blank0 "" ""
	#menu_t $m blank1 "" ""
	#menu_t $m blank2 "" ""
	#menu_t $m blank3 "" ""
	#menu_t $m blank4 "" ""


	frame $m.dir
	label $m.dir.dir_label -text "Movement:"
	set mob(hdir) 1
	radiobutton $m.dir.dir_hriz -text [imes "Dorsal / Plantar Flexion"] \
		-variable mob(hdir) -relief flat -value 1
	#radiobutton $m.dir.dir_vert -text [imes "Inversion / Eversion"] \
	#	-variable mob(hdir) -relief flat -value 0
	pack $m.dir -anchor w
	pack $m.dir.dir_label -anchor w
	pack $m.dir.dir_hriz -anchor w
	#pack $m.dir.dir_vert -anchor w
	menu_t $m blank5 "" ""
	#menu_t $m blank6 "" ""
	#menu_t $m blank12 "" ""

	frame $m.var
 	label $m.var.var_label -text "Select Experiment:"
	set mob(fitts,var) 2
	#radiobutton $m.var.var_1 -text [imes "Normal Experiment"] \
	#	-variable mob(fitts,var) -relief flat -value 0
	#radiobutton $m.var.var_2 -text [imes "Larger Experiment"] \
	#	-variable mob(fitts,var) -relief flat -value 1
	#radiobutton $m.var.var_3 -text [imes "Randomly presented targets"] \
	#	-variable mob(fitts,var) -relief flat -value 2
	radiobutton $m.var.var_3 -text [imes "Active"] \
		-variable mob(fitts,var) -relief flat -value 2
	radiobutton $m.var.var_4 -text [imes "Passive"] \
		-variable mob(fitts,var) -relief flat -value 3
	#radiobutton $m.var.var_4 -text [imes "2-D movements (DP+IE)"] \
	#	-variable mob(fitts,var) -relief flat -value 3
	pack $m.var -anchor w
	pack $m.var.var_label -anchor w
	#pack $m.var.var_1 -anchor w
	#pack $m.var.var_2 -anchor w
	pack $m.var.var_3 -anchor w
	pack $m.var.var_4 -anchor w
	menu_t $m blank14 "" ""
	#menu_t $m blank15 "" ""
	menu_t $m log "     Automatic Logging" ""

	#menu_t $m blank16 "" ""
	#menu_t $m blank17 "" ""
	menu_t $m blank18 "" ""
	menu_b $m newgame "New Experiment (n)" new_Fitts
	menu_t $m blank19 "" ""
	menu_b $m stopgame "Stop Experiment (s)" stop_Fitts
	menu_t $m blank20 "" ""
	menu_b $m quit "Quit (q)" {done}
	#menu_t $m blank21 "" ""
}


init_Fitts
