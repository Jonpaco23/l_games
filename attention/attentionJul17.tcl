#! /usr/bin/wish
#
# Game: Shipwreck (modified for Experimental Protocol of the level of Attention)
#
# Modified and augmented by: Konstantinos P. Michmizos (konmic@mit.edu)
#
# Original Game: Pong (trb)
#
# To be used only with: Anklebot
# One can choose 1,2, or 4 live sides (Rocks).
# Rocks and barriers return the boat at random
# Sandy beaches reflect the boat
#
# Modifications:  1. Added prediction
#                         2. The time required for the boat to hit the next live wall is estimated
#                	    3. When hit in the corners, the boat is reflected towards the center of the box with random coordinates
#                         4. We make sure the boat changes axis of movement (dp <-->ie) only when the ankle angle permits it
#                         5. And much more...

package require Tk
package require counter

global ob
global mob
global img

# this controls the controller's function
set ob(ctl) 25

set ob(crobhome) $::env(CROB_HOME)
source $ob(crobhome)/shm.tcl
set ob(i18n_home) $::env(I18N_HOME)
source $ob(i18n_home)/i18n.tcl
source ../common/util.tcl
source ../common/menu.tcl
source predict_shipwr.tcl
source math.tcl

# localize ankle
localize_robot

# counter aliases
interp alias {} ctadd {} ::counter::count
interp alias {} ctget {} ::counter::get
interp alias {} ctinit {} ::counter::init
interp alias {} ctreset {} ::counter::reset

proc scale_rom {rom} {
	global ob

 	switch $rom {
		short_rom {
			set scale 2500.0
		}
		medium_rom {
			set scale 2000.0
		}
		long_rom {
			set scale 1500.0
		}
	}
	return $scale
}

# init adaptive variables
proc init_adap_var {} {
    	global ob mob

	 # adap_slot_metrics metrics
	ctinit active_power11 -lastn 11
	ctinit robot_power11 -lastn 11
    	ctinit min_jerk_deviation11 -lastn 11 
    	ctinit min_jerk_dgraph11 -lastn 11
	ctinit point_accuracy11 -lastn 11 
	ctinit min_trajectory11 -lastn 11 
    	ctinit min_dist_along_axis11 -lastn 11 
    	ctinit active_power_metric11 -lastn 11 
    	ctinit min_jerk_metric11 -lastn 11 
    	ctinit min_jerk_dgmetric11 -lastn 11
    	ctinit speed_metric11 -lastn 11
	ctinit accuracy_metric11 -lastn 11

	set ob(speed_performance_level) [list]
	set ob(accuracy_performance_level) [list]

    	# pm_display metrics
    	ctinit initiate -lastn 44
    	ctinit active_power44 -lastn 44
	ctinit robot_power44 -lastn 44
    	ctinit min_jerk_deviation44 -lastn 44 
    	ctinit min_jerk_dgraph44 -lastn 44 
	ctinit point_accuracy44 -lastn 44 
	ctinit min_trajectory44 -lastn 44 
    	ctinit min_dist_along_axis44 -lastn 44 
    	ctinit npoints44 -lastn 44
	ctinit slotlength44 -lastn 44 
	ctinit smoothness44 -lastn 44

	wshm pm_npoints 0
}

# logging every slot interesting variables for offline analysis
proc slotglog {str} {
    	global ob

    	set tailname [file tail $ob(gamename)]
    	set filename [join [list $tailname $ob(timestamp)] _]
    	set filename [file join $ob(dirname) $filename]
    	file mkdir $ob(dirname)
    	set logf [file join $ob(dirname) attention_log_$ob(timestamp)_slotmetrics.log]    
	set f [open $logf a+]
    	puts $f "$str"
    	close $f
}

# logging every section interesting variables for offline analysis
proc sectionglog {str} {
    	global ob

    	set tailname [file tail $ob(gamename)]
    	set filename [join [list $tailname $ob(timestamp)] _]
    	set filename [file join $ob(dirname) $filename]
    	file mkdir $ob(dirname)
    	set logf [file join $ob(dirname) attention_log_$ob(timestamp)_sectionmetrics.log]    
	set f [open $logf a+]
    	puts $f "$str"
    	close $f
}

# 1x per slot, 11x per section (Michmizos & Krebs, BioRob '12)
proc adap_slot_metrics {} {
	global ob mob
	# for PMz see Michmizos & Krebs, BioRob, 2012.
	set PMz 2.0

    	set npoints [rshm pm_npoints]
    	if {$npoints == 0} return

    	ctadd npoints44
	# P2
	# speed metric
    	# read from ctlr
    	set active_power [rshm pm_active_power]
	set robot_power [expr {abs($active_power)}]
    	set min_jerk_deviation [rshm pm_min_jerk_deviation]
    	set min_jerk_dgraph [rshm pm_min_jerk_dgraph]
	
	# additional PMs (for display or for off line analysis)
	set smoothness [pm_smoothness $ob(speedtraj)]
	set assistive_torque [pm_assistive_torque $ob(torque)]
	# puts "smooth = $smoothness"
    	# current avs
    	set av_active_power [expr {$active_power / $npoints}]
	set av_robot_power [expr {$robot_power / $npoints}]
    	set av_min_jerk_deviation [expr {$min_jerk_deviation / $npoints}]
    	set av_min_jerk_dgraph [expr {$min_jerk_dgraph / $npoints}]
	set av_assistive_torque  [expr {$assistive_torque / $npoints}]
	# puts "slot: av min jerk dev $av_min_jerk_deviation"
	# puts "slot: av active power $av_active_power"

    	ctadd active_power11 $av_active_power
    	ctadd active_power44 $av_active_power
	ctadd robot_power11 $av_robot_power
    	ctadd robot_power44 $av_robot_power
    	ctadd min_jerk_deviation11 $av_min_jerk_deviation
    	ctadd min_jerk_deviation44 $av_min_jerk_deviation
    	ctadd min_jerk_dgraph11 $av_min_jerk_dgraph
    	ctadd min_jerk_dgraph44 $av_min_jerk_dgraph
	ctadd smoothness44 $smoothness

    	# the 1.5, 0.65, and 6.0 are derived in paper:
    	# Krebs et al, 2003, Autonomous Robots journal.
    	set min_jerk_metric 0.0
    	if {$av_min_jerk_deviation > 0.0} {
		set min_jerk_metric [expr {6.0 * $av_min_jerk_deviation}]
    	}
    	set min_jerk_dgmetric 0.0
    	if {$av_min_jerk_dgraph > 0.0} {
		set min_jerk_dgmetric [expr {6.0 * $av_min_jerk_dgraph}]
    	}
    	set active_power_metric 0.0
    	if {$av_active_power < 0.0} {
		# that was the original (from Krebs, 2003)
		set active_power_metric [expr {0.65 * $av_active_power}]
		# this seems to work much better
		# set active_power_metric [expr {6.5 * $av_active_power}]
    	}
   	set local_speed_metric [expr {$active_power_metric + $min_jerk_metric}]

	# puts "active_power_metric = $active_power_metric"
	# puts "min_jerk_metric = $min_jerk_metric"

    	ctadd active_power_metric11 $active_power_metric
    	ctadd min_jerk_metric11 $min_jerk_metric
    	ctadd min_jerk_dgmetric11 $min_jerk_dgmetric
    	ctadd speed_metric11 $local_speed_metric

	# P3
	# accuracy metric
    	# read from ctlr
    	set point_accuracy [pm_point_accuracy $ob(dx_p)]
    	set min_trajectory [pm_min_trajectory $ob(x)]
	# puts "slot: point accuracy $point_accuracy"
	# puts "slot: min_trajectory $min_trajectory"

 	ctadd point_accuracy11 $point_accuracy
    	ctadd point_accuracy44 $point_accuracy
    	ctadd min_trajectory11 $min_trajectory
    	ctadd min_trajectory44 $min_trajectory

	set logi [logistic_function $min_trajectory]
   	set local_accuracy_metric [expr {$point_accuracy * $logi - $PMz}]

    	ctadd accuracy_metric11 $local_accuracy_metric
	# P4
	adap_mindist $ob(dx)

	slotglog "$mob(bounces)\t$ob(trgt)\t$ob(hdir)\t$ob(patient_moved)\t$ob(slot_time)\t$min_jerk_metric\t$active_power_metric\t$point_accuracy\t$min_trajectory\t$ob(pm_mindist)\t$av_assistive_torque\t$npoints\t$mob(score)"

    	# zero accumulated stuff in ctlr immediately
	clear_slot_metrics
}

proc clear_slot_metrics {} {
	global ob

	set ob(dx) []
	set ob(dx_p) []
	set ob(x) []
	set ob(speedtraj) []
	set ob(torque) []
	adap_zero_pm	
}	

# zero performance metrics
proc adap_zero_pm {} {
    global ob

    	wshm pm_active_power 0.0 ;# pm2a
    	wshm pm_min_jerk_deviation 0.0 ;# pm2b
    	wshm pm_min_jerk_dgraph 0.0 ;# pm2b
    	wshm pm_npoints 0
}

# collect adap distance stats, either on a wall hit or an animal hit
proc adap_mindist {list} {
    	global ob

	set pm_mindist [pm_min_dist_along_axis $list]
	ctadd min_dist_along_axis11 $pm_mindist
	ctadd min_dist_along_axis44 $pm_mindist
	set ob(pm_mindist) $pm_mindist
	#puts "slot: min dist = $pm_mindist"
}

# 1x per 1 circuit
proc adjust_adap_controller {} {
    	global ob mob

	set ob(speed) [expr {$ob(speed) + 0.5}]
	set ob(targetsize) [expr {ob(targetsize) - 20}]

	puts "Bounce $mob(bounces) size = $ob(targetsize) , speed = $ob(speed)"
	adap_ship
	sectionglog "$mob(bounces)\t$ob(bspeed)\t$ob(padw)"
}

proc adap_ship {} {
	global ob

	# change paddle width
	set ob(padw) $ob(targetsize)
	set_paddles 
	# change boat speed
	set ob(bspeed) $ob(speed)
}

# adaptive metrics at the end of a slot.
proc enter_target_do_adaptive {} {
  	  global ob mob

    	# every slot
    	adap_slot_metrics
    	# every per section (10 slots)
    	if {($mob(bounces) % 10) == 0} {
		adjust_adap_controller 
	}
}


# check the velocity magnitude.
# if the patient's ankle has moved enough, start the slot now.
proc adap_check_vel {} {
	global ob

	if {[info exists ob(moveit_slot)]} {
		set ob(vellim) [expr {2*1000.0*1.875 * $ob(slotlength) / $ob(time_boat_travel)}]
		if {!$ob(hdir)} {
			set ob(velmag) [expr {abs([rshm ankle_dp_vel])}]
		} else {
			set ob(velmag) [expr {abs([rshm ankle_ie_vel])}]
		}

		if {$ob(velmag) > $ob(vellim)} {
		# puts "vellim = $ob(vellim), velmag = $ob(velmag)"
			ctadd initiate
			set ob(check_move) no
			set ob(patient_moved) 1
			set ob(klok) [clock clicks -milliseconds]
			set time_passed [expr {$ob(klok)-$ob(klik)}]
			set time_to_close_slot [expr {$ob(time_boat_travel) - $time_passed}]
			set ob(ticks) [expr {int(double(($time_to_close_slot)/1000.0) * $ob(Hz))}]
			set ob(forlist_effective) {0 $ob(ticks) 1}
			set mb_command [lindex [after info $ob(moveit_slot)] 0]
			eval $mb_command
		}
	}
}

# make walls once
proc make_walls {} {
	global ob img

	set winheight $ob(winheight)
	set winwidth $ob(winwidth)
	
	# wall width
	set wwid $ob(wwid)
	set ob(ww,n) $wwid
	set ob(ww,s) [expr {$winheight-$wwid}]
	set ob(ww,w) $wwid
	set ob(ww,e) [expr {$winwidth-$wwid}]

	# four walls
	set ob(color,n) yellow
	set img(rock) [image create photo -format gif -file "images/rock_n2.gif"]
	set img(beach) [image create photo -format gif -file "images/beach_n2.gif"]

	set ob(color,s) blue
	set img(rock2) [image create photo -format gif -file "images/rock_s2.gif"]
	set img(beach2) [image create photo -format gif -file "images/beach_s2.gif"]

	set ob(color,w) red
	set img(rock3) [image create photo -format gif -file "images/rock_w2.gif"]
	set img(beach3) [image create photo -format gif -file "images/beach_w2.gif"]

	set ob(color,e) green
	set img(rock4) [image create photo -format gif -file "images/rock_e2.gif"]
	set img(beach4) [image create photo -format gif -file "images/beach_e2.gif"]
}

# in each game, set up the walls as live (rocks) or no (sandy beach)
proc set_walls {} {
	global ob mob img

	set winheight $ob(winheight)
	set winwidth $ob(winwidth)
	set x $winwidth
	set y $winheight

	foreach i {n s w e} {
		if {[string first $i $mob(whichgame)] >= 0} { 
			set ob(livewall,$i) 1
			switch $i {
				n { 
  					set ob(wall,n) [.c create image 0 0 -image $img(rock) -tag [list beach bn] -anchor nw]					
				}
				s {
  					set ob(wall,s) [.c create image $x $y -image $img(rock2) -tag [list beach bs] -anchor se]		
				}
				w {
  					set ob(wall,w) [.c create image 0 0 -image $img(rock3) -tag [list beach bw] -anchor nw]		
				}
				e {
  					set ob(wall,e) [.c create image $x $y -image $img(rock4) -tag [list beach bn] -anchor se]		
				}
			}	
		} else {
			set ob(livewall,$i) 0
			switch $i {
				n { 
  					set ob(wall,n) [.c create image 0 0 -image $img(beach) -tag [list beach bn] -anchor nw]					
				}
				s {
  					set ob(wall,s) [.c create image $x $y -image $img(beach2) -tag [list beach bs] -anchor se]		
				}
				w {
  					set ob(wall,w) [.c create image 0 0 -image $img(beach3) -tag [list beach bw] -anchor nw]		
				}
				e {
  					set ob(wall,e) [.c create image $x $y -image $img(beach4) -tag [list beach bn] -anchor se]		
				}
			}
		}
	}
}

# make paddles once.
proc make_paddles {} {
	global ob mob

	set winheight $ob(winheight)
	set winwidth $ob(winwidth)

	if {$mob(round)} {
		set shape oval
	} else {
		set shape rectangle
	}

	# distance from screen edge to paddle face
	set pdist 100
	set ob(pd,w) $pdist
	set ob(pd,e) [expr {$winwidth-$pdist}]
	set ob(pd,n) $pdist
	set ob(pd,s) [expr {$winheight-$pdist}]

	foreach i {n s w e} {
		if {[info exists ob(pad,$i)]} {
			.c delete $ob(pad,$i)
		}
		set ob(pad,$i) [.c create $shape 1 1 2 2 -outline "" \
			-fill $ob(color,$i) -tag [list paddle p$i]]
	}
}

# set up the paddles each game.
# dead paddles get stuffed behind sea
proc set_paddles {} {
	global ob mob

	set winheight $ob(winheight)
	set wh5 [expr {$winheight - 5}]
	set winwidth $ob(winwidth)
	set ww5 [expr {$winwidth - 5}]
	set cx $ob(half,x)
	set cy $ob(half,y)

	set ob(padw2) [expr {$ob(padw) / 2}]
	# four paddles
	# make them or stuff them behind sea
	# depending on whether they are declared active in mob(whichgame)
	
	# north
	if {[string first n $mob(whichgame)] >= 0} {
		set x1 [expr {$cx - $ob(padw2)}]
		set y1 $ob(pd,n)
		set x2 [expr {$cx + $ob(padw2)}]
		set y2 [expr {$ob(pd,n) - $ob(padh)}]
		.c coords $ob(pad,n) $x1 $y1 $x2 $y2 
		.c itemconfigure $ob(pad,n) -fill $ob(color,n)
		.c raise $ob(pad,n) $ob(field) 
	} else {
		.c coords $ob(pad,n) $cx 5 $cx 5
		.c itemconfigure $ob(pad,n) -fill gray
		.c lower $ob(pad,n) $ob(field) 
	}

	# south
	if {[string first s $mob(whichgame)] >= 0} {
		set x1 [expr {$cx - $ob(padw2)}]
		set y1 $ob(pd,s)
		set x2 [expr {$cx + $ob(padw2)}]
		set y2 [expr {$ob(pd,s) + $ob(padh)}]
		.c coords $ob(pad,s) $x1 $y1 $x2 $y2 
		.c itemconfigure $ob(pad,s) -fill $ob(color,s)
		.c raise $ob(pad,s) $ob(field)
	} else {
		.c coords $ob(pad,s) $cx $wh5 $cx $wh5
		.c itemconfigure $ob(pad,s) -fill gray
		.c lower $ob(pad,s) $ob(field)
	}

	# west
	if {[string first w $mob(whichgame)] >= 0} {
		set x1 $ob(pd,w)
		set y1 [expr {$cx - $ob(padw2)}]
		set x2 [expr {$ob(pd,w) - $ob(padh)}]
		set y2 [expr {$cx + $ob(padw2)}]
		.c coords $ob(pad,w) $x1 $y1 $x2 $y2 
		.c itemconfigure $ob(pad,w) -fill $ob(color,w)
		.c raise $ob(pad,w) $ob(field)
	} else {
		.c coords $ob(pad,w) 5 $cy 5 $cy
		.c itemconfigure $ob(pad,w) -fill gray
		.c lower $ob(pad,w) $ob(field) 
	}

	# east
	if {[string first e $mob(whichgame)] >= 0} {
		set x1 $ob(pd,e)
		set y1 [expr {$cx - $ob(padw2)}]
		set x2 [expr {$ob(pd,e) + $ob(padh)}]
		set y2 [expr {$cx + $ob(padw2)}]
		.c coords $ob(pad,e) $x1 $y1 $x2 $y2 
		.c itemconfigure $ob(pad,e) -fill $ob(color,e)
		.c raise $ob(pad,e) $ob(field)
	} else {
		.c coords $ob(pad,e) $ww5 $cy $ww5 $cy
		.c itemconfigure $ob(pad,e) -fill gray
		.c lower $ob(pad,e) $ob(field) 
	}
}

# this gets done every time a new game is hit
proc init_pong {} {
	global ob mob img
	
	# by default, all walls are live
	set mob(whichgame) s
	set ob(savelog) 1

	set mob(nomotorforces_x) 0
	set mob(nomotorforces_y) 0

	# maxhop - we don't want the boat going through the paddle!
	set ob(maxhop) [expr {$ob(bsize) + $ob(padh) - 1}]
	
	# centers
	set ob(half,x) [expr {$ob(winwidth) / 2}]
	set ob(half,y) [expr {$ob(winheight) / 2}]
	set cx $ob(half,x)
	set cy $ob(half,y)

	canvas .c -width $ob(winwidth) -height $ob(winheight) -bg black
	.c config -highlightthickness 0
	grid .c
	set ob(bigcan) .c

	set img(sea) [image create photo -format gif -file "images/sea.gif"]
  	set ob(field) [.c create image 0 0 -image $img(sea) -tag sea -anchor nw]

	wm geometry . 1015x690
	. config -bg gray20

	place .c -relx 0.5  -rely 0.5 -anchor center

# create menu buttons
	if {!$ob(running)} {


		label .disp -textvariable mob(score)  -font $ob(scorefont) -bg gray20 -fg yellow
		place .disp -in . -relx 1.0 -rely 0.0 -anchor ne
	
		domenu

        	grid rowconfigure . 0 -weight 1
        	grid columnconfigure . 0 -weight 1
		start_rtl

		wshm no_safety_check 1
		wshm ankle_damp 0.
	}
	set ob(running) 1

	make_walls

	set_walls

	# speed of the boat
	regsub -all {[^0-9]} $mob(level) {} mob(level)
	set mob(level) [bracket $mob(level) 1 25]
	# adjustable parameter values for boat speed
	set ob(lbspeed) [list 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.05 1.1 1.15 1.2 1.25 1.3 1.35 1.4 1.5 1.55 1.6 1.65 1.7 1.8 2.0 2.20 2.40 2.70]
	set ob(bspeed) [lindex $ob(lbspeed) [expr {$mob(level)-1}]] 
	set ob(speed) $ob(bspeed)

	# paddle dimensions
	regsub -all {[^0-9]} $mob(padw) {} mob(padw)
	set mob(padw) [bracket $mob(padw) 1 25]
	# adjustable parameter values for paddle width
	set ob(lpaddlew) [list 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100 105 110 115 120 125 130 135 140 145 150]
	set ob(padw) [lindex $ob(lpaddlew) [expr {$mob(padw)-1}]] 
	set ob(targetsize) $ob(padw)

	# setting min and max
	set ob(min_speed) [lindex $ob(lbspeed) 0]
	set ob(max_speed) [lindex $ob(lbspeed) [expr {[llength $ob(lbspeed)]-1}]]
	set ob(min_target) [lindex $ob(lpaddlew) 0]
	set ob(max_target) [lindex $ob(lpaddlew) [expr {[llength $ob(lpaddlew)]-1}]]
	# 1/4.5 s  (this is the min/max time for closing the slot)
	set ob(min_time) 1000   
	set ob(max_time) 4500  
	# ranges
    	set ob(time_range) [expr {$ob(max_time) - $ob(min_time)}]
    	set ob(speed_range) [expr {$ob(max_speed) - $ob(min_speed)}]
    	set ob(target_range) [expr {$ob(max_target) - $ob(min_target)}]

	make_paddles

	set_paddles

	# the boat (after the sea)
	set bsize $ob(bsize)
	set x1 [expr {$cx - ($bsize / 2)}]
	set x2 [expr {$cx + ($bsize / 2)}]
	set y1 [expr {$cy - ($bsize / 2)}]
	set y2 [expr {$cy + ($bsize / 2)}]

	set img(ball) [image create photo img -format gif -file "images/boat_ball40a.gif"]
  	set ob(ball) [.c create image $cx $cy -image $img(ball) -tag ball -anchor center]
	set ob(ballorig) [.c coords $ob(ball)]
	
	set img(bullseye) [image create photo -file "images/bullseye_90.gif"]
	
	bind . <s> stop_pong
	bind . <n> new_pong
	bind . <q> done
	bind . <Escape> done
    	bind . <space> ship_space
        wm protocol . WM_DELETE_WINDOW { done }

	# for prediction - lists for virtual rotation of south wall
	set ob(wlist,s) [list n s w e]
	set ob(wlist,w) [list e w n s]	
	set ob(wlist,n) [list s n w e]
	set ob(wlist,e) [list w e n s]		
	
	set ob(lastbat) none

	# for return safely the boat inside the sea when the boat hits near a corner.
	# safer = "SAFEty Reflection" width determines the "square inside which boat is returned"
	set ob(safer) [expr {2.5*$ob(ww,n)}]
	# shortest path determines the ratio between a full trajectory of the ball (up->down)
	# and the shortest trajectory (hypotinousa) to hit a side wall
	set ob(shortest_path) [expr {($ob(safer)+$ob(ww,n))/($ob(winheight)-2.0*$ob(pd,w))}]

	# for pausing the game
	set ob(paused) no

	init_adap_controller

	after 50 [list menu_hide .menu]
}

proc stop_pong {} {
	global ob mob

	# this requires hitting the stop button before hitting new game
	incr ob(n_games) -1
	if {$ob(n_games)<0} {set ob(n_games) 0}

	set mob(score) 0
	after cancel moveball
	cancel_moveit_timeouts
	end_experiment_stop_log
	if {$mob(padrow) > $mob(maxinrow)} {
		set mob(maxinrow) $mob(padrow)
	}
}

# restart each new game
proc new_pong {} {
	global ob mob img

	incr ob(n_games) 

	if {$ob(n_games) > 1} {
		error [imes "Press 'Stop Game' and then 'New Game' once"]
	}

	# anklebot stiffness for the entire game session
	wshm ankle_stiff 0

	# ob(sound) = 1 for sound on
	set ob(sound) 0

	regsub -all {[^0-9]} $mob(endgame) {} mob(endgame)
	set ob(endgame) $mob(endgame)
	regsub -all {[^0-9]} $mob(level) {} mob(level)
	set ob(level) $mob(level)

	eval .c coords $ob(ball) $ob(ballorig)
	set ob(lastbat) none

	array set mob {
		bounces 0
		score  0
		padrow  0
		maxinrow  0
		wall 0
		paddle 0
	}


	after cancel moveball
	cancel_moveit_timeouts

	destroy .c
	init_pong

	# number of live walls
	set ob(nlivewalls) [string length $mob(whichgame)]

	set ob(level) [bracket $ob(level) 1 25]
	set ob(forw)  $ob(bspeed) 
	set ob(side)  [expr {0.33*$ob(bspeed)}]
	set ob(side2) [expr {($ob(side) / 2.0 )}]

	# this variable (Probability of change walls) determines the possibility of changing sides (P>300 high possiblity)
	# we keep it low in single wall games because we want to keep the boat bouncing in the opposite wall so that it will not 
	# do a triangle that will make the boat land near the initial position.
	# we increase it in 4 wall game since we want to change sides when the ball is near 
	# the center (see ob(safer) also)
	if {$ob(nlivewalls) >=4} {
		set ob(Pofchangewall) 350
	} elseif {$ob(nlivewalls) >=2 && $ob(nlivewalls) <4} {
		set ob(Pofchangewall) 250
	} else {
		set ob(Pofchangewall) 150
	}

	# for allowing checking PM1
	set ob(check_move) no

	# for just one bounce
	set ob(goesnorth) 1

	# initializations
	set ob(trgt) 0.0
	set ob(trgt_pixels) [expr {$ob(winheight)/2.0}]

	set ob(dist) 300

	# for the first bounce of the section
	set ob(firstbounce) yes

	prepare_logging

	calculate_time

	init_adap_var

	set ob(scale) [eval scale_rom $ob(dship,rom)]

	startball
	start_experiment_start_log
}

proc startball {} {
	global ob

	set forw $ob(bspeed)

	# where does the ball start? 
	if {$ob(livewall,s)} {
		set ob(dir)   [list 0 $forw]
		set ob(hdir) 0
	} elseif {$ob(livewall,n)} {
		set ob(dir)   [list 0 [expr {0 - $forw}]]
		set ob(hdir) 0
	} elseif {$ob(livewall,w)} {
		set ob(dir)   [list [expr {0 - $forw}] 0]
		set ob(hdir) 1
	} elseif {$ob(livewall,e)} {
		set ob(dir)   [list $forw 0]
		set ob(hdir) 1
	} else {
		error "no live walls"
	}
	acenter
	after 200 moveball
}

proc dodrag {w x y} {
	global ob
	if {$ob(livewall,n)} { dragx $w $x pn }
	if {$ob(livewall,s)} { dragx $w $x ps }
	if {$ob(livewall,w)} { dragy $w $y pw }
	if {$ob(livewall,e)} { dragy $w $y pe }
}

proc dragx {w x what} {
	global ob

	set x1 [expr {[.c canvasx $x] - $ob(padw2)}]
	set x2 [expr {$x1 + $ob(padw)}]
	foreach {d1 y1 d2 y2} [.c coords $what] {break}
	.c coords $what $x1 $y1 $x2 $y2
}

proc dragy {w y what} {
	global ob

	set y1 [expr {[.c canvasy $y] - $ob(padw2)}]
	set y2 [expr {$y1 + $ob(padw)}]
	foreach {x1 d1 x2 d2} [.c coords $what] {break}
	.c coords $what $x1 $y1 $x2 $y2
}

# shake the walls.
proc shake {obj} {
	global ob

	eval .c move $obj 0 10
	after 50 [list eval .c move $obj 10 0 ]

	after 100 [list eval .c move $obj 0 -20 ]
	after 150 [list eval .c move $obj -20 0 ]

	after 200 [list eval .c move $obj 0 10 ]
	after 250 [list eval .c move $obj 10 0 ]
}

# did the ball fall completely off the table?
# this shouldn't happen at reasonable speeds,
# but it's safe to check.
proc ballofftable {bbox} {
	global ob mob

	foreach {x1 y1 x2 y2} $bbox {break}
	if {
	($x2 < 0) ||
	($x1 > $ob(winwidth)) ||
	($y2 < 0) ||
	($y1 > $ob(winheight)) } {
		# bell
		puts "ball off table, bounces $mob(bounces) bbox $bbox dir $ob(dir)"

		# throw the ball to the center of the table,
		# and send it back at half speed.
		foreach {x y} $ob(dir) {break}
		set bsize $ob(bsize)
		set cx $ob(half,x)
		set cy $ob(half,y)
		set bsize $ob(bsize)
		set x1 [expr {$cx - ($bsize / 2)}]
		set x2 [expr {$cx + ($bsize / 2)}]
		set y1 [expr {$cy - ($bsize / 2)}]
		set y2 [expr {$cy + ($bsize / 2)}]

		.c coords ball $cx $cy
		# slow it down, send it backwards
		set x [expr $x / -2.0]
		set y [expr $y / -2.0]
		set ob(dir) "$x $y"
	}
}

proc getxy {} {
	global ob

	if {$ob(ankle)} {
		set x [rshm ankle_ie_pos]
		set y [rshm ankle_dp_pos]
	}
	set x_meters $x
	set y_meters $y
	
	#puts "x = $x, y = $y"

	set x [expr int($ob(scale) * $x + $ob(half,x))]
	set y [expr int(-$ob(scale) * $y + $ob(half,y))]

	if {!$ob(hdir)} {
		set cur_pos_pixels $x
		set cur_pos_meters $x_meters
		set vel [rshm ankle_ie_vel]
	    	set torque [rshm ankle_ie_torque]
	} else {
		set cur_pos_pixels $y
		set cur_pos_meters $y_meters
		set vel [rshm ankle_ie_vel]
	    	set torque [rshm ankle_ie_torque]
	}
	# PMs
	lappend ob(dx_p) [expr {abs($cur_pos_pixels - $ob(trgt_pixels))}]
	lappend ob(dx) [expr {abs($cur_pos_meters - $ob(trgt))}]
	lappend ob(x) $cur_pos_meters
	lappend ob(speedtraj) $vel
	lappend ob(torque) $torque

	list $x $y
}

# the main loop
# note that "find overlapping" returns the objects in display list
# stacking order.  the objects were created in this order: {walls
# paddles field ball} so that if the ball overlaps both paddle and
# field, it will find paddle.

# in the switch, walls may be either live (rocks) or not (beach).
# gray walls reflect, and do not change scores.
proc moveball {} {
	global ob mob

	foreach {x y} [getxy] break
	dodrag .c $x $y

	# move ball
	eval .c move ball $ob(dir)
	set mob(balldir) $ob(dir)

	# see if the ball has hit anything - paddle or wall.
	set bbox [.c bbox ball]

	ballofftable $bbox

	set ob(bat) [lindex [eval .c find overlapping $bbox] 1]

	# lastbat hack prevents wobbles
	if {$ob(bat) != $ob(field)
		&& $ob(bat) != $ob(ball)
		&& $ob(bat) != $ob(lastbat)
		} {
		# forw is directional, (must be negated in switch)
		# side is not
		# set forw $ob(forw)
		set forw $ob(bspeed)
		set temp [irand [expr {$ob(side)*$ob(Pofchangewall)}]]
		set side [expr {(0.0 - $ob(side) + $temp)/100.}]
		# checking that a) we won't get a zero vector coordinate
		# and b) we make sure we have an adequate i/e or d/p
		if {$side<=0.5} {
			set temp [irand [expr {$ob(side)*200}]]
			set side [expr {(0.0 - $ob(side) + $temp)/100.}]
			if {$side<=0.5} {
				set side 0.5
			}
		}
		set side2 [expr {.0+ round(rand())}]
		set side [expr {$side*pow(-1,$side2)}] 
		foreach {oxr oyr} $ob(dir) {break}
		switch $ob(bat) $ob(pad,n) {
			set xr $side
			set yr $forw
			hitpaddle  north
			set i n
			if {$ob(nlivewalls)<4} {
				predict $bbox $xr $yr $i
			}
		} $ob(pad,s) {
			set xr $side
			set yr [expr {0 - $forw}]
			hitpaddle  south
			set i s
			if {$ob(nlivewalls)<4} {
				predict $bbox $xr $yr $i
			}
		} $ob(pad,w) {
			set xr $forw
			set yr $side
			hitpaddle west
			set i w
			if {$ob(nlivewalls)<4} {
				predict $bbox $xr $yr $i
			}
		} $ob(pad,e) {
			set xr [expr {0 - $forw}]
			set yr $side
			hitpaddle east
			set i e
			if {$ob(nlivewalls)<4} {
				predict $bbox $xr $yr $i
			}
		} $ob(wall,n) {
			if {$ob(livewall,n)} {
				set xr $side
				set yr $forw
				hitwall
				shake $ob(bat)
				set i n				
				if {$ob(nlivewalls)<4} {
					predict $bbox $xr $yr $i
				} 
			} else {
				set xr $oxr
				set yr [expr {0 - $oyr}]
			}
		} $ob(wall,s) {
			if {$ob(livewall,s)} {
				set xr $side
				set yr [expr {0 - $forw}]
				hitwall
				shake $ob(bat)
				set i s				
				if {$ob(nlivewalls)<4} {
					predict $bbox $xr $yr $i
				} 
			} else {
				set xr $oxr
				set yr [expr {0 - $oyr}]
			}
		} $ob(wall,w) {
			if {$ob(livewall,w)} {
				set xr $forw
				set yr $side
				hitwall
				shake $ob(bat)
				set i w
				if {$ob(nlivewalls)<4} {
					predict $bbox $xr $yr $i
				} 
			} else {
				set xr [expr {0 - $oxr}]
				set yr $oyr
			}
		} $ob(wall,e) {
			if {$ob(livewall,e)} {
				set xr [expr {0 - $forw}]
				set yr $side
				hitwall
				shake $ob(bat)
				set i e
				if {$ob(nlivewalls)<4} {
					predict $bbox $xr $yr $i
				} 
			} else {
				set xr [expr {0 - $oxr}]
				set yr $oyr
			}
		} default {
			# this sometimes happens when the ball
			# goes off the table.
			set xr $oxr
			set yr $oyr
			puts "moveball switch default, bounces $mob(bounces) bat $ob(bat) dir $ob(dir)"
		}
		# set new direction.
		set ob(dir) [format "%.2f %.2f" $xr $yr]

		if {$ob(nlivewalls)==4} {
			set temp0 [expr {[lindex $bbox 0]}]
			set temp1 [expr {[lindex $bbox 1]}]
			set temp2 [expr {[lindex $bbox 2]}]
			set temp3 [expr {[lindex $bbox 3]}]
			set safer $ob(safer)
			# upper left corner reflection safety
			if {$temp0<=($ob(ww,w)+$safer) && $temp1<($ob(ww,n)+$safer)} {
				#puts "ball reflected from upper left corner"
				set xr [expr {abs($xr)}] 
				set yr [expr {abs($yr)}]
				set ob(dir) [format "%.2f %.2f" $xr $yr]
			}
			# upper right corner reflection safety
			if {$temp2>=($ob(ww,e)-$safer) && $temp3<($ob(ww,n)+$safer)} {
				#puts "ball reflected from upper right corner"
				set xr [expr {0.0- abs($xr)}] 
				set yr [expr {abs($yr)}]
				set ob(dir) [format "%.2f %.2f" $xr $yr]
			}
			# bottom left corner reflection safety
			if {$temp0<=($ob(ww,w)+$safer) && $temp1>($ob(ww,s)-$safer)} {
				#puts "ball reflected from bottom left corner"
				set xr [expr {abs($xr)}] 
				set yr [expr {0.0- abs($yr)}]
				set ob(dir) [format "%.2f %.2f" $xr $yr]
			}
			# bottom right corner reflection safety
			if {$temp2>=($ob(ww,e)-$safer) && $temp3>($ob(ww,s)-$safer)} {
				#puts "ball reflected from bottom right corner"			
				set xr [expr {0.0 - abs($xr)}] 
				set yr [expr {0.0 - abs($yr)}]
				set ob(dir) [format "%.2f %.2f" $xr $yr]
			}
			predict $bbox $xr $yr $i
			}
			set ob(lastbat) $ob(bat)
		}

	if {$ob(check_move)} {
		adap_check_vel
	}
 
	# end of ball hits thing, schedule anew
	if {$ob(endgame) <= 0 || $mob(bounces) < $ob(endgame)} {
		if {!$ob(paused)} { 
			set ob(after) [after $ob(tick) moveball]
			# update idletasks
		}
	}
}

# oops, the ball hit a live wall.
proc hitwall {} {
	global ob mob

	if {$ob(firstbounce)} {
		set ob(firstbounce) no
		set  ob(slot_klik) [clock clicks -milliseconds]
	} else {
		set ob(slot_klok) [clock clicks -milliseconds]
		set ob(slot_time) [expr {$ob(slot_klok) - $ob(slot_klik)}]
		set ob(slot_klik) $ob(slot_klok)
	}
	if {$ob(sound)} {
		nbeep 3 A 100
	}
		
	# deletes previous prediction
	.c delete pred

	incr mob(bounces)
	wshm Fitts_target_marker $mob(bounces)
	enter_target_do_adaptive
	incr mob(score) -30

	incr mob(wall)
	if {$mob(padrow) > $mob(maxinrow)} {
		set mob(maxinrow) $mob(padrow)
	}
	set mob(padrow) 0

    	wm title . "Shipwreck    Name: $mob(whoN)    Bounces: $mob(bounces)    Score: $mob(score)"	
}

# yay, the ball hit a paddle
proc hitpaddle {{dir south}} {
	global ob mob
	
	if {$ob(firstbounce)} {
		set ob(process_time) 0
		set ob(firstbounce) no
		set  ob(slot_klik) [clock clicks -milliseconds]
	} else {
		set ob(slot_klok) [clock clicks -milliseconds]
		set ob(slot_time) [expr {$ob(slot_klok) - $ob(slot_klik)}]
		set ob(slot_klik) $ob(slot_klok)
	}
	if {$ob(sound)} {
		nbeep 1 F
	}

    	.c delete pred
	
	incr mob(bounces)
	wshm Fitts_target_marker $mob(bounces)
	incr mob(paddle)
	incr mob(score) 10

	incr mob(padrow)
	enter_target_do_adaptive

    	wm title . "Shipwreck    Name: $mob(whoN)    Bounces: $mob(bounces)    Score: $mob(score)"	
}

proc init_adap_controller {} {
	global ob mob

	# this allows the hard i/e movebox to timeout, 
	# when the player has not moved enough by himself
	set ob(hard_mb_timeout) 0

	set ob(moveit_state) pause

	# size of paddle in meters //might not be used
	set ob(pad_in_meters) [expr {0.2*$mob(padw) / ($ob(winwidth)-2*$ob(ww,n))}]
}

proc adap_moveit {forlist trgt} {
	global ob mob

    	set forlist [uplevel 1 [list subst -nocommands $forlist]]
    	set trgt [uplevel 1 [list subst -nocommands $trgt]]

	set x [rshm ankle_ie_pos]
	set y [rshm ankle_dp_pos]

	if {$ob(hdir)} {
		set src [list 0.0 $y 0.0 0.0]
		set dest [list 0.0 $trgt 0.0 0.0]
		set y1 $x
		set ob(slotlength) [expr {abs($trgt-$y)}]
		ctadd slotlength44 $ob(slotlength)
	} else {
		set src [list $x 0.0 0.0 0.0]
		set dest [list $trgt 0.0 0.0 0.0]
		set y1 $y
		set ob(slotlength) [expr {abs($trgt-$x)}]
		ctadd slotlength44 $ob(slotlength)
	}

	# starting to check if the patient moved during the time slot
	after 100 [list start_check]	

	set src [eval swaps $src]
	set dest [eval swaps $dest]

    	set nx1 [lindex $src 0]
    	set nx2 [lindex $dest 0]

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
    	# clear_slot_metrics

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
    	clear_slot_metrics

	# no need to check if the patient moved or not
	set ob(check_move) no

	if {!$ob(paused)} {
		movebox 0 $ob(ctl) {$ob(forlist_effective)} \
		    [swaps $ob(mbmid) $ob(mby1) $ob(mbwid) 0.] \
		    [swaps $ob(mbnx2) $ob(mby2) 0. 0.]
    		set ob(mb_state) movebox
	}
}

proc cancel_moveit_timeouts {} {
	global ob

    	if {[info exists ob(moveit_slot)]} {
		after cancel $ob(moveit_slot)
		unset ob(moveit_slot)
    	}
}

proc start_check {} {
	global ob
	
	set ob(check_move) yes
	set ob(klik) [clock clicks -milliseconds]
}

proc calculate_time {} {
	global ob

	switch $ob(nlivewalls) {
		"1" { 
  			set ob(bounces) 2					
		}
		"2" {
			# here we should put sthg to discriminate between side live walls and opposite directed
  			set ob(bounces) 1		
		}
		"3" {
			if {$ob(goesnorth)} {
  				set ob(bounces) 1
			} else {
				set ob(bounces) [expr {1.2* $ob(shortest_path)}]
			}		
		}
		"4" {
  			if {$ob(goesnorth)} {
  				set ob(bounces) 1
			} else {
				set ob(bounces) [expr {1.2* $ob(shortest_path)}]
			}				
		}
	}

	# for gain = x, time = 5000/x ms, ob(bounces) measures the reflection bounces
	set ob(time_boat_travel) [expr {int($ob(bounces)*5000./abs($ob(bspeed)))}]
	# this estimated the overall trajctory (but is still inferior than the upper estimation)
	#set ob(time_boat_travel) [expr {int($ob(dist)*8.5/abs($ob(bspeed)))}]
	set ob(slottime_hard_mb) [expr {int(0.5*$ob(time_boat_travel))}]
	set ob(time_to_close_slot) [expr {int($ob(time_boat_travel)-$ob(slottime_hard_mb))}]
	set ob(slotticks) [expr {int(double(($ob(time_to_close_slot)/1000.0) * $ob(Hz)))}]

    	# bracket
    	if {$ob(slotticks) < [expr {($ob(min_time)/1000.0)*$ob(Hz)}]} {
		set ob(slotticks)  [expr {int(($ob(min_time)/1000.0)*$ob(Hz))}]
    	}
    	if {$ob(slotticks) >  [expr {($ob(max_time)/1000.)*$ob(Hz)}]} {
		set ob(slotticks)  [expr {int(($ob(max_time)/1000.0)*$ob(Hz))}]
    	}
	set ob(slottime) [expr {2*$ob(slotticks)/$ob(Hz)}]
}

proc prepare_logging {} {
	global ob mob env argc argv

	# game name and patient name
	# they come in as command line args, usually from the
	# cons "game console" program
	# in a HIPAA setting, the patient name will be a numeric ID.
	set ob(logdirbase) $::env(THERAPIST_HOME)

	set ob(gamename) games/eval/Attention_log
 	set ob(patname) $mob(who)

	set env(PATID) $mob(who)

	if {![info exists env(PATID)]} {
	    	error "Please enter a Patient ID"
	   	 exit
	}
	if {$env(PATID) == ""} {
	    	error "Please enter a Patient ID"
	    	exit
	}

	if {$argc >= 1} {
		set ob(gamename) [lindex $argv 0]
    	}
	if {$argc >= 2} {
		set ob(patname) [lindex $argv 1]
	}
	set ob(gametype) ther

	if {$ob(ankle)} {
		set ob(logfnid) 17
		set ob(logvars) 18
    	} 

    	set curtime [clock seconds]
    	set ob(datestamp) [clock format $curtime -format "%Y%m%d_%a"]
    	set ob(timestamp) [clock format $curtime -format "%H%M%S"]
    	set ob(dirname) [file join $ob(logdirbase) $ob(patname) $ob(gametype) $ob(datestamp) ship ]

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
    	puts $ob(log_fd) "Dir: $ob(dirname)"
    	puts $ob(log_fd) "Game: $tailname"
	puts $ob(log_fd) "Type: $mob(whichgame)"
    	puts $ob(log_fd) "Gametype: Level of Attention experiment"
	puts $ob(log_fd) "Gametype: Experimental Protocol (Level of Attention)"
	puts $ob(log_fd) "ROM: $ob(dship,rom)"
    	puts $ob(log_fd) "Starting speed: $ob(bspeed)"
    	puts $ob(log_fd) "Starting target size: $ob(padw)"
    	puts $ob(log_fd) "Starting slottime: $ob(slottime)"
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
	
# set up the menu (once)
proc domenu {} {
	global env mob ob

	set m [menu_init .menu]
	menu_v $m who "Player's ID" $env(PATID)
	menu_v $m whoN "Player's Name" Player
	menu_v $m endgame "Game Length" 352
	menu_v $m padw "Paddle Width (1-25)" 24
	menu_v $m level "Speed Level (1-25)" 2

	menu_t $m blank0 "" ""
	menu_t $m blank1 "" ""
	frame $m.rom
 	label $m.rom.rom_label -text "Range of Motion:"
	set ob(dship,rom) medium_rom
	radiobutton $m.rom.rom_short -text [imes "Short ROM"] \
		-variable ob(dship,rom) -relief flat -value short_rom
	    radiobutton $m.rom.rom_medium -text [imes "Medium ROM"] \
		-variable ob(dship,rom) -relief flat -value medium_rom
	    radiobutton $m.rom.rom_long -text [imes "Long ROM"] \
		-variable ob(dship,rom) -relief flat -value long_rom
	pack $m.rom -anchor w
	pack $m.rom.rom_label -anchor w
	pack $m.rom.rom_short -anchor w
	pack $m.rom.rom_medium -anchor w
	pack $m.rom.rom_long -anchor w

	menu_t $m blank2a "" ""
	frame $m.dir
	label $m.dir.dir_label -text "Movement:"
	set mob(hdir) 0
	radiobutton $m.dir.dir_hriz -text [imes "Dorsal / Plantar Flexion"] \
		-variable mob(hdir) -relief flat -value 1
	radiobutton $m.dir.dir_vert -text [imes "Inversion / Eversion"] \
		-variable mob(hdir) -relief flat -value 0
	pack $m.dir -anchor w
	pack $m.dir.dir_label -anchor w
	pack $m.dir.dir_hriz -anchor w
	pack $m.dir.dir_vert -anchor w
	menu_t $m blank2d "" ""
	set mob(savelog) 1
	menu_t $m savelog "     Automatic Logging" ""
	menu_t $m blank3 "" ""

	menu_t $m blank4 "" ""

	menu_t $m padrow "Current Streak"
	menu_t $m blank6 "" ""
	menu_t $m maxinrow "Longest Streak"
	menu_t $m blank7 "" ""
	menu_t $m wall "Rock Hits"
	menu_t $m blank8 "" ""
	menu_t $m paddle "Paddle Hits"
	menu_t $m blank9 "" ""
	menu_b $m newgame "Start Experiment (n)" new_pong
	menu_t $m blank10 "" ""
	menu_b $m stopgame "Stop Experiment (s)" stop_pong
	menu_t $m blank11 "" ""
	menu_b $m quit "Quit (q)" {exit}
}

proc done {} {
	stop_pong
	stop_log
	stop_rtl
	exit
}

proc do_once {} {
	global ob mob
	# this is to know if a game was running before
	set ob(running) 0
	set mob(nomotorforces_x) 0
	set mob(nomotorforces_y) 0
	set mob(singlepaddle) 0
	set mob(bounces) 0
	wshm Fitts_target_marker $mob(bounces)

	# 200 Hz the frequency of the anklebot
	set ob(Hz) 200.0
	# 0 for vertical pads
	set ob(hriz) 0
	# 0 for rectangular paddles, 1 for oval paddles
	set mob(round) 0
	# tick - 5 means every 5 ms, or 200/sec.
	# smaller number means smoother motion, and more work for machine.
	set ob(tick) 5
	# size of sea field
	set ob(winwidth) 650 
	set ob(winheight) 650
	# wall width
	set ob(wwid) 78
	# boat diameter
	set ob(bsize) 40
	#calculate the radius of the ball 
	set ob(bradius) [expr {$ob(bsize)/2}]
	# paddle height
	set ob(padh) 25
	# this flag secures single game running
	set ob(n_games) 0
}

do_once
init_pong
