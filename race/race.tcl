#! /usr/bin/wish
#
# Game: Race to Noah's Ark
#
# Modified and augmented by:
# Konstantinos Michmizos (konmic@mit.edu), Fall 2011 - Winter 2012
#
# To be used only with: Anklebot
#
# Original Game: Race (trb 9/2000)
#
# Offline analysis of data
# e.g. for creating an ascii file: 
# wish ta.tcl / home / imt / therapist / Poli / eval / 20111125_Fri / soccer_log_123907multi.dat > / home / imt / therapist / Poli / eval / 20111125_Fri /run.asc
# e.g. for plotting:
# ./gplot /home/imt/therapist/Poli/eval/20111126_Sat/soccer_log_123907multi.dat 1 2 1 3

# normal level is 8. 

# Tk GUI library
package require Tk
package require counter

global ob
# this selects the controller's function
set ob(ctl) 25

# this is an unconventional hack, PATID should come from UI
set env(PATID) 1

set ob(crobhome) $::env(CROB_HOME)
source $ob(crobhome)/shm.tcl

source ../common/util.tcl
source ../common/menu.tcl
source myclock.tcl
source math.tcl
source $::env(I18N_HOME)/i18n.tcl

# is this ankle? (of course)
localize_robot

# for balto ankle
source ../race/race.config
# end for balto

# counter aliases
interp alias {} ctadd {} ::counter::count
interp alias {} ctget {} ::counter::get
interp alias {} ctinit {} ::counter::init
interp alias {} ctreset {} ::counter::reset

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

    	set tailname [file tail $ob(gamename)]
    	set filename [join [list $tailname $ob(timestamp)] _]
    	set filename [file join $ob(dirname) $filename]
    	file mkdir $ob(dirname)
    	set ob(adap_log_fd) [open "${filename}.asc" w]
    	puts $ob(adap_log_fd) "Time: $ob(timestamp)"
    	puts $ob(adap_log_fd) "Dir: $ob(dirname)"
    	puts $ob(adap_log_fd) "Game: $tailname"
	puts $ob(adap_log_fd) "Type: $ob(whichgame)"
	puts $ob(adap_log_fd) "Random Movements (YES = 1): $mob(random)"
    	puts $ob(adap_log_fd) "Challenge with Accuracy (YES =1): $mob(accuracy)"
	puts $ob(adap_log_fd) "Audio (OFF=1): $mob(audio)"
    	puts $ob(adap_log_fd) "Gametype: ther"
	puts $ob(adap_log_fd) "ROM: $ob(drace,rom)"
    	puts $ob(adap_log_fd) "Starting stifness: $mob(menu,stiff)"
    	puts $ob(adap_log_fd) "Starting speed: $ob(gspeed)"
    	puts $ob(adap_log_fd) "Starting slottime: $ob(slottime)"
    	puts $ob(adap_log_fd) "Starting target size: $ob(gatew)"
    	flush $ob(adap_log_fd)
}

# logging every slot interesting variables for offline analysis
proc slotglog {str} {
    	global ob

    	set tailname [file tail $ob(gamename)]
    	set filename [join [list $tailname $ob(timestamp)] _]
    	set filename [file join $ob(dirname) $filename]
    	file mkdir $ob(dirname)
    	set logf [file join $ob(dirname) race_log_$ob(timestamp)_slotmetrics.log]    
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
    	set logf [file join $ob(dirname) race_log_$ob(timestamp)_sectionmetrics.log]    
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
		# this might work better
		# set active_power_metric [expr {6.5 * $av_active_power}]
    	}
   	set local_speed_metric [expr {$active_power_metric + $min_jerk_metric}]

    	ctadd active_power_metric11 $active_power_metric
    	ctadd min_jerk_metric11 $min_jerk_metric
    	ctadd min_jerk_dgmetric11 $min_jerk_dgmetric
    	ctadd speed_metric11 $local_speed_metric

	# P3
	# accuracy metric
    	# read from ctlr
    	set point_accuracy [pm_point_accuracy $ob(dx)]
    	set min_trajectory [pm_min_trajectory $ob(x)]
	#puts "slot: point accuracy $point_accuracy"
	#puts "slot: min_trajectory $min_trajectory"

 	ctadd point_accuracy11 $point_accuracy
    	ctadd point_accuracy44 $point_accuracy
    	ctadd min_trajectory11 $min_trajectory
    	ctadd min_trajectory44 $min_trajectory

	set logi [logistic_function $min_trajectory]
   	set local_accuracy_metric [expr {$point_accuracy * $logi - $PMz}]

    	ctadd accuracy_metric11 $local_accuracy_metric
	# P4
	adap_mindist $ob(dx)

	slotglog "$mob(gates_passed)\t$ob(prevcen)\t$ob(hdir)\t$ob(patient_moved)\t$ob(slot_time)\t$min_jerk_metric\t$active_power_metric\t$point_accuracy\t$min_trajectory\t$ob(pm_mindist)\t$ob(splattime)\t$av_assistive_torque\t$npoints\t$mob(score)"

    	# zero accumulated stuff in ctlr (after allows for the gate to pass)
	after [expr {int(600.0/$ob(gspeed))}]  [list clear_slot_metrics]
}

proc clear_slot_metrics {} {
	global ob

	set ob(dx) []
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

# 1x per circuit, per 11 slots
proc adap_circuit_metrics {} {
    	global ob mob

    	# 11 slot avs
    	# speed
   	set speed_performance_level -1
    	set av_speed_metric [ctget speed_metric11 -avgn]
    	if {$av_speed_metric > -0.01 && $av_speed_metric < 0.01} {
		set speed_performance_level 0
    	}
    	if {$av_speed_metric > 0.01} {
		set speed_performance_level 1
    	}
	lappend ob(speed_performance_level) $speed_performance_level

    	# accuracy
   	set accuracy_performance_level -1
    	set av_accuracy_metric [ctget accuracy_metric11 -avgn]
    	if {$av_accuracy_metric > -0.01 && $av_accuracy_metric < 0.01} {
		set accuracy_performance_level 0
    	}
    	if {$av_accuracy_metric >= 0.01} {
		set accuracy_performance_level 1
    	}
    	lappend ob(accuracy_performance_level) $accuracy_performance_level
	#puts "av_accuracy_metric =$av_accuracy_metric, av_speed_metric = $av_speed_metric" 
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

	set i [llength $ob(speed_performance_level)]
	set cur_sp [lindex $ob(speed_performance_level) [expr {$i-1}]]
	set cur_ac [lindex $ob(accuracy_performance_level) [expr {$i-1}]]

	if {$i>=3} {
		set cur_sp_1 [lindex $ob(speed_performance_level) [expr {$i-2}]]
		set cur_ac_1 [lindex $ob(accuracy_performance_level) [expr {$i-2}]]
		set cur_sp_2 [lindex $ob(speed_performance_level) [expr {$i-3}]]
		set cur_ac_2 [lindex $ob(accuracy_performance_level) [expr {$i-3}]]
		set PLsum [expr {4*($cur_sp+$cur_ac)+2*($cur_sp_1+$cur_ac_1)+($cur_sp_2+$cur_ac_2)}]
	} elseif {$i==2} {
		set cur_sp_1 [lindex $ob(speed_performance_level) [expr {$i-2}]]
		set cur_ac_1 [lindex $ob(accuracy_performance_level) [expr {$i-2}]]
		set PLsum [expr {4*($cur_sp+$cur_ac)+3*($cur_sp_1+$cur_ac_1)}]
	} elseif {$i==1} {
		set PLsum [expr {4*($cur_sp+$cur_ac)}]
	}
   	# speed-accuracy accumulated metric
    	set alpha 0.25
	if {$PLsum<=-10} {
		set alpha 1
	} elseif {$PLsum<=-8 && $PLsum>-10} {
		set alpha 0.75
	} elseif {$PLsum<=-6 && $PLsum>-8} {
		set alpha 0.50
	} elseif {$PLsum<=-3 && $PLsum>-6} {
		set alpha 0.25
	} elseif {$PLsum<=3 && $PLsum>-3} {
		set alpha 0.25
	} elseif {$PLsum<=6 && $PLsum>3} {
		set alpha 0.50
	} elseif {$PLsum<=8 && $PLsum>6} {
		set alpha 0.75
	} elseif {$PLsum<=10 && $PLsum>8} {
		set alpha 1.00
	} elseif {$PLsum<=12 && $PLsum>10} {
		set alpha 1.50
	} elseif {$PLsum<=14 && $PLsum>12} {
		set alpha 2.00
	} 

   	set speed_metric [ctget speed_metric11 -avgn]
   	set accuracy_metric [ctget accuracy_metric11 -avgn]

if {$mob(accuracy)} {
	set gain_acc 0.066
	if {$ob(drace,rom) == "short_rom"} {
		set gain_acc 0.033
	} elseif {$ob(drace,rom) == "long_rom"} {
		set gain_acc 0.1
	}
	set gain_sp 0.05
} else {
	set gain_acc 0.132
	if {$ob(drace,rom) == "short_rom"} {
		set gain_acc 0.066
	} elseif {$ob(drace,rom) == "long_rom"} {
		set gain_acc 0.2
	}
	set gain_sp 0.05
}
	if {$i<9} {
		set ob(targetsize) [expr {$ob(targetsize) - $alpha \
		* $gain_acc *$ob(target_range) * $accuracy_metric}]

		set ob(speed) [expr {$ob(speed) + $alpha \
		* $gain_sp *$ob(speed_range) * $speed_metric}]
	} else {
		if {$mob(accuracy)} {
			set ob(targetsize) [expr {$ob(targetsize) - $alpha \
			* $gain_acc *$ob(target_range) * $accuracy_metric}]		
		} else {	
			set ob(speed) [expr {$ob(speed) + $alpha \
			* $gain_sp*$ob(speed_range) * $speed_metric}]
		}
	}
    	# bracket
    	if {$ob(speed) < $ob(min_speed)} {
		set ob(speed) $ob(min_speed)
    	}
    	if {$ob(speed) > $ob(max_speed)} {
		set ob(speed) $ob(max_speed)
    	}

    	# bracket
    	if {$ob(targetsize) < $ob(min_target)} {
		set ob(targetsize) $ob(min_target)
    	}
    	if {$ob(targetsize) > $ob(max_target)} {
		set ob(targetsize) $ob(max_target)
    	}
	puts "Gate $mob(gates_passed) size = $ob(targetsize) , speed = $ob(speed)"
	adap_race
	sectionglog "$mob(gates_passed)\t$ob(gspeed)\t$ob(gatew)\t$speed_metric\t$accuracy_metric\t$PLsum"
}

proc adap_race {} {
	global ob

	# change gate width
	set ob(gatew) $ob(targetsize)
	# change falling gates speed
	set ob(gspeed) $ob(speed)
	calculate_time
}

# adaptive metrics at the end of a slot.
proc enter_target_do_adaptive {} {
  	  global ob mob

    	# every slot
    	adap_slot_metrics
    	# every per section (11 slots)
    	if {($mob(gates_passed) % 11) == 0} {
		adap_circuit_metrics

		adjust_adap_controller 

		set circnum [expr {$mob(gates_passed) / 11}]
		# pm_display every 4 sections
		if {($circnum % 4) == 0} { 
			# stop logging
			end_section_stop_log
			pause_disp
			after 200 pm_display
			incr mob(gates_created) -1
			return
		}
	}
}
# this code gets run to display performance metrics
# the code that invokes it is somewhat subtle, because it needs
# to stop the gates falling in an unusual way.

# most of the time, every x sec, a gate is created. In this case, we call pm_display
# instead, without scheduling the next gate. 
proc pm_display {} {
	global ob mob

   	set npoints [ctget npoints44]

    	set init [ctget initiate]
    	ctreset initiate
    	set active_power [ctget active_power44 -avgn]
    	set robot_power [ctget robot_power44 -avgn]
    	set min_jerk_deviation [ctget min_jerk_deviation44 -avgn]
    	set min_jerk_dgraph [ctget min_jerk_dgraph44 -avgn]
	set point_accuracy [ctget point_accuracy44 -avgn] 
    	set min_dist_along_axis [ctget min_dist_along_axis44 -avgn]
	set smoothness [ctget smoothness44 -avgn]

	if {$mob(gates_passed) == 0} return

    	set pmv2_init [expr {int(100.0 * (44.0 -$init) / 44.0)}]
	if {$pmv2_init < 0} {set pmv2_init 0}   
	set av_slotlength [ctget 	slotlength44 -avgn]

	set min_jerk_deviation [expr {int(100. - (6.25 * 100.0 * $min_jerk_deviation))}]
    	set pmv2_min_jerk_dgraph [expr {int(1000. * $min_jerk_dgraph)}]

 	set min_jerk_dgraph [expr {100. - (6.25 * 100.0 * $min_jerk_dgraph)}]
	set pmv2_point_accuracy [expr {int((1000.0/3.0) * $point_accuracy)}]
	if {$pmv2_point_accuracy < 0} {set pmv2_point_accuracy 0}   
	if {$pmv2_point_accuracy > 1000} {set pmv2_point_accuracy 1000}   

	set pmv2_smoothness [expr {int(385*($smoothness-0.001))}]
	if {$pmv2_smoothness < 0} {set pmv2_smoothness 0}   
	if {$pmv2_smoothness > 100} {set pmv2_smoothness 100}   

	set pmv2_robot_power [expr {int($robot_power * 1000.)}]
	set pmv2_min_dist_along_axis [expr {int(1000. * $min_dist_along_axis)}]

    	# logfile
    	puts $ob(adap_log_fd) "\npm display:"
    	puts $ob(adap_log_fd) "gates created $mob(gates_passed)"
    	puts $ob(adap_log_fd) "init $pmv2_init"
    	puts $ob(adap_log_fd) "min_dist_along_axis $pmv2_min_dist_along_axis"
    	puts $ob(adap_log_fd) "robot_power $pmv2_robot_power"
    	puts $ob(adap_log_fd) "smoothness $pmv2_smoothness"
    	puts $ob(adap_log_fd) "dwell time $pmv2_point_accuracy"
    	flush $ob(adap_log_fd)

    	# fn2 is created at the end of every 44
    	# fn4 is appended at the end of every 44, for final graph report.
    	set pid [pid]

    	# puts "init $pmv2_init mdft $pmv2_min_dist_along_axis rp $pmv2_robot_power \
	jerk $pmv2_min_jerk_dgraph pa $pmv2_point_accuracy"

    	set fn2 "/tmp/race_pm2_$pid.asc"
    	set fd2 [open "$fn2" w]
    	puts $fd2 "init $pmv2_init mdft $pmv2_min_dist_along_axis rp $pmv2_robot_power \
		smooth $pmv2_smoothness pa $pmv2_point_accuracy"
    	close $fd2

    	set fn4 "/tmp/race_pm4_$pid.asc"
    	# append
    	set fd4 [open "$fn4" a]
    	puts $fd4 "init $pmv2_init mdft $pmv2_min_dist_along_axis rp $pmv2_robot_power \
		smooth $pmv2_smoothness pa $pmv2_point_accuracy"
    	close $fd4

    	if {[expr {$mob(gates_passed)}] == $ob(endgame)} {
		# save race_pm4 to be displayed on next run
		file copy -force $fn4 $ob(logdirbase)/$ob(patname)/race_pm4.asc
		exec ./gppm2.tcl $fn4 > /dev/tty &
		after 500 set ::tksleep_end 1
		vwait ::tksleep_end
    	}

   	# this one should be on top of the fn4
   	exec ./gppm2.tcl $fn2 > /dev/tty &
    	after 500 set ::tksleep_end 1
    	vwait ::tksleep_end
}

proc print_pm {} {
    global ob mob

    puts "race.tcl performance metrics dump:"

    set npoints [ctget npoints44]
    set init [ctget initiate]
    set min_dist_along_axis [ctget min_dist_along_axis44 -avg]
    set active_power [ctget active_power44 -avg]
    set robot_power [ctget robot_power44 -avg]
    set min_jerk_dgraph [ctget min_jerk_dgraph44 -avg]
    set point_accuracy [ctget point_accuracy44 -avgn] 
	set smoothness [ctget smoothness44 -avgn]

    set init [expr {100.0 * $init / $mob(gates_passed)}]
    set min_dist_along_axis [expr {100.0 * $min_dist_along_axis / 0.14}]

    set active_power [expr {100.0 - ($active_power * -100.)}]

    set min_jerk_dgraph [expr {100. - (6.25 * 100.0 * $min_jerk_dgraph)}]
    set point_accuracy [expr {int(100.0-(200.0/7.0) * $point_accuracy)}]

    puts "npoints: $npoints"
    puts "1 $init 2 $min_dist_along_axis 3 $active_power \
	4 $min_jerk_dgraph 5 $point_accuracy"
    puts ""
}

# therapist hit the space bar.
# or the program wants you to think that happened.
# funny things happen inside here
proc pause_disp {} {
    	global ob

	incr ob(pauses_count)	
	.c delete falling

    	if {[info exists ob(splat_draw)]} {
		after cancel $ob(splat_draw)
		unset ob(splat_draw)
    	}
    	if {[info exists ob(gate_draw)]} {
		after cancel $ob(gate_draw)
		unset ob(gate_draw)
    	}
	end_section_stop_log
	cancel_moveit_timeouts
	acenter
	after 1500 [stop_movebox 0]

	set ob(playgame) no
	set ob(paused) yes
}

proc unpause_disp {} {
	global ob
	set ob(playgame) yes
	set ob(firstgate) yes
	set ob(running) 1
	do_gate
	set ob(paused) no
}

proc race_space {} {
	global ob
	
	if {$ob(paused) == yes} {
		unpause_disp
	} elseif {$ob(paused) == no} {
		pause_disp
	}
}
# check the velocity magnitude.
# if the patient's ankle has moved enough, start the slot now.
proc adap_check_vel {} {
	global ob

	if {[info exists ob(moveit_slot)]} {
		set ob(vellim) [expr {2*1000.0*1.875 * $ob(slotlength) / $ob(time_gate_travel)}]
		if {$ob(hdir)} {
			set ob(velmag) [expr {abs([rshm xvel])}]
		} else {
			set ob(velmag) [expr {abs([rshm yvel])}]
		}

		if {$ob(velmag) > $ob(vellim)} {
		# puts "vellim = $ob(vellim), velmag = $ob(velmag)"
			set ob(check_move) no
			set ob(patient_moved) 1
			set ob(klok) [clock clicks -milliseconds]
			set time_passed [expr {$ob(klok)-$ob(klik)}]
			set time_to_close_slot [expr {$ob(time_gate_travel) - $time_passed}]
			set ob(ticks) [expr {int(double(($time_to_close_slot)/1000.0) * $ob(Hz))}]
			set ob(forlist_effective) {0 $ob(ticks) 1}
			set mb_command [lindex [after info $ob(moveit_slot)] 0]
			eval $mb_command
			ctadd initiate
		}
	}
}

proc rancolor {} {
	set rainbow {red orange yellow green4 blue magenta4 magenta}
	lindex $rainbow [irand 7]
}

proc do_title {} {
	global ob mob
	updateClock
	wm title . "Noah's Race   Name: $mob(whoN)   Gates: $mob(gates_passed)   Score: $mob(score)"
}

proc del_marks {} {
	.c delete mark
	.c delete marka
}

# make a new gate every 2-3 sec
proc do_gate {} {
    	global ob mob
 
    	after 10000 del_marks
    
    	if {!$ob(running) || $mob(gates_created) > $ob(endgame)} {
		return
    	}
    
    	# see note above enter_target_do_adaptive
    	if {!$ob(playgame)} {
		return
	}

	set i [expr {$mob(gates_created) % $ob(endgame)}]
    	set spacing [expr {($ob(winwidth) - ($ob(side2) + $ob(gatew)))/double($ob(npos)-1)}]
    	set randi [lindex $ob(gate_list) $i]
   	set x1 [expr {$ob(side) - $ob(half,x) + $spacing * $randi}]
    	set x2 [expr {$x1 + $ob(gatew)}]
    	set gate_edge_width 0.006
    	set x1a [expr {$x1 - $gate_edge_width}]
    	set x2a [expr {$x2 + $gate_edge_width}]

	set ob(prevcen) $ob(cen)
    	set ob(cen) [expr {($x1 + $x2) / 2.}]
	set ob(nextcen) $ob(cen)
	
    	set col [rancolor]
    	# swaps handles swapping x and y coordinates for horizontal motion
    
    	eval set r [.c create rect [swaps -.2 .185 $x1 .195]]
    	# color $col
    	if {$ob(planar)} {
		set col gray20
    	}
    	.c itemconfig $r -outline "" -fill $col -tag [list falling gate left g$i]
    	eval set r [ .c create rect [swaps $x2 .185 .2 .195]]
    	.c itemconfig $r -outline "" -fill $col -tag [list falling gate right g$i]
    
    	if {$ob(planar)} {
		set col [rancolor]
		eval set r [.c create rect [swaps $x1a .185 $x1 .195]]
		.c itemconfig $r -outline "" -fill $col -tag [list falling gate left g$i]
	
		eval set r [.c create rect [swaps $x2 .185 $x2a .195]]
		.c itemconfig $r -outline "" -fill $col -tag [list falling gate left g$i]
		if {$ob(hdir) == "0"} {
		    draw_animal .c $i $ob(cen) -.2
		} else {
		    draw_animal .c $i .2 [expr 0. - $ob(cen)]
		}
    	}	
    
    	.c scale g$i 0 0 $ob(scale) -$ob(scale)

    	incr mob(gates_created)
    
	# default 5000
	set time_to_next_gate [expr {int(4500./abs($ob(gspeed)))}]
	set ob(gate_draw) [after $time_to_next_gate do_gate]
	# right before we hit anything, we clear the flag to recognize what was the first thing we hit
	#after $time_to_next_gate [set ob(firsthit) ""]
	set ob(firsthit) ""
   	set ob(prevrandi) $randi

	if {$ob(firstgate)} {
		set ob(firstgate) no
		set dest $ob(cen)
		adap_moveit {0 $ob(slotticks) 1} $dest
		start_section_start_log
		set  ob(slot_klik) [clock clicks -milliseconds]
	} 
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

	# 4500 was empirically estimated.
	set ob(time_gate_travel) [expr {int(4500./abs($ob(gspeed)))}]
    	set ob(splattime) [expr {int(0.5*$ob(time_gate_travel))}]
	set ob(slottime_hard_mb) [expr {int(0.5*$ob(time_gate_travel))}]
	set ob(time_to_close_slot) [expr {int($ob(time_gate_travel)-$ob(slottime_hard_mb))}]
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

proc mark {x col} {
	global ob

	# until bugfix
	set pos [centxy $x -.19 .005]
	set pos [swaps $pos]
	set mark [.c create rect $pos -tag mark -fill $col]
	.c scale $mark 0 0 $ob(scale) -$ob(scale)
}

# move all the falling stuff every ob(fallms) ms (5)
# deleting the wall we hit keeps us from hitting it again.
proc fall {} {
	global ob mob

	if {!$ob(running)} {
		return
	}

	set gspeed $ob(gspeed)
	# move all the falling things $ob(level) pixels
	if {$ob(hdir)} {
		set gspeed [expr {-abs($gspeed)}]
	}
	eval .c move falling [swaps 0 $gspeed]

	set bbox [.c bbox $ob(racer)]
	set hit [lindex [eval .c find overlapping $bbox] 2]
	set tags [.c gettags $hit]
	set isanimal [lsearch -inline $tags animal]
	set isbad [lsearch -inline $tags bad]
	set lr [lsearch -inline -regexp $tags {left|right}]

	if {"$hit" != "" && $isanimal != "animal" && $isbad != "bad" } {
		if {$lr != ""} {
		    incr mob($lr)
		}
		set htag [lsearch -inline -regexp $tags {^g[0-9][0-9]*}]
		if {$htag != ""} {
		    regsub g $htag "" n
		    .c delete $htag
		    .c delete a$n
		    after 200 .c delete b$n
		}
		hit
	} elseif {"$hit" != "" && $isbad == "bad" } {
		set htag [lsearch -inline -regexp $tags {^b[0-9][0-9]*}]
		if {$htag != ""} {
		    regsub b $htag "" n
		    .c delete $htag
		    .c delete b$n
		}
		   hitsplat
	} elseif {"$hit" != "" && $isanimal == "animal"} {
		set htag [lsearch -inline -regexp $tags {^a[0-9][0-9]*}]
		if {$htag != ""} {
			regsub g $htag "" n
			thrugate
			.c delete $n
		}
		hitanimal
	}

	if {$ob(check_move)} {
		adap_check_vel
	}

	if {$ob(gates_deleted) < $ob(endgame)} {
		after $ob(fallms) fall
	}
}

# delete things with tag i
proc del_thing {i} {
	global mob

	if {[.c find withtag $i] != ""} {
		if {[string index $i 0] == "g"} {
			thrugate
		}
	}
	.c delete $i
}

proc make_racer {} {
	global ob mob

        if {$mob(round)} {
                set shape oval
        } else {
                set shape rectangle
        }

	if {[info exists ob(racer)]} {
		.c delete $ob(racer)
	}

	set ob(racer) [.c create $shape 0 0 .023 .067  -outline "" \
		-fill yellow -tag racer]
	.c scale racer 0 0 $ob(scale) -$ob(scale)
}

proc size_racer {} {
	global ob mob

	# distance from screen edge to racer face
	set rdist .015

	# racer dimensions
	set ob(racw) .0115
	set ob(racw) [bracket $ob(racw) .005 .1]
	set ob(rach) .033
	set ob(racw2) [expr {$ob(racw) / 2.}]

	# racer
	set x1 -$ob(racw2)
	set y1 -.15
	set x2 $ob(racw2)
	set y2 [expr {$y1 + $ob(rach)}]
	eval .c coords racer [swaps $x1 $y1 $x2 $y2]
	.c scale racer 0 0 $ob(scale) -$ob(scale)
}

proc init_adap_controller {} {
	global ob mob

	# for keeping the source center
	set ob(prevcen) 0.0

	# for displacement per slot 
	set ob(dx) [list]
	# for paddle position per slot
	set ob(x) [list]
	# for estimating smoothness metric per slot (used for display)
	set ob(speedtraj) [list]
	# for estimating torque metric per slot (used for off-line analysis)
	set ob(torque) [list]

	# adjustable parameter values
	# these are going to be used for the adaptive change of the variables
	# these default values are changed according to the drace menu selections 
	set ob(lgspeed) [list 0.45 0.60 0.75 0.90 1.05 1.2 1.35 1.5 1.75 1.9 2.05 2.2 2.35 2.5 2.75 3.00 3.25 3.5 3.75 4.0 4.25 4.50 4.75 5.00 5.25]
	set ob(level_gspeed) $mob(level)
	set ob(gspeed) [lindex $ob(lgspeed) [expr {$ob(level_gspeed)-1}]] 
	set ob(speed) $ob(gspeed)

	set ob(lgatew) [list 0.02 0.025 0.03 0.035 0.04 0.0425 0.045 0.0475 0.05 0.0525 0.055 0.0575 0.06 0.0625 0.065 0.675 0.07 0.0725 0.075 0.08 0.085 0.09 0.095 0.1 0.105]
	set ob(level_gatew) $mob(gatew)
	set ob(gatew) [lindex $ob(lgatew) [expr {$ob(level_gatew)-1}]] 
	set ob(targetsize) $ob(gatew)

	# setting min and max
	set ob(min_speed) [lindex $ob(lgspeed) 0]
	set ob(max_speed) [lindex $ob(lgspeed) [expr {[llength $ob(lgspeed)]-1}]]
	set ob(min_target) [lindex $ob(lgatew) 0]
	set ob(max_target) [lindex $ob(lgatew) [expr {[llength $ob(lgatew)]-1}]]
	# 1/4.5 s  (this is the min/max time for closing the slot)
	set ob(min_time) 1000   
	set ob(max_time) 4500  

	# ranges
    	set ob(time_range) [expr {$ob(max_time) - $ob(min_time)}]
    	set ob(speed_range) [expr {$ob(max_speed) - $ob(min_speed)}]
    	set ob(target_range) [expr {$ob(max_target) - $ob(min_target)}]

	calculate_time
}

# game name and patient name
# they come in as command line args, usually from the
# cons "game console" program
# in a HIPAA setting, the patient name will be a numeric ID.
proc prepare_logging {} {
	global ob mob env argc argv

    	set ob(logdirbase) $::env(THERAPIST_HOME)

	set ob(gamename) games/ther/race_log
    	set ob(gametype) ther		
	
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
		if {$mob(hdir)} {
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
		# Logging function 
		# for the lab, uncomment the following line and comment the one that corresponds to the pediatric anklebot.
		# set ob(logfnid) 17
		# for the pediatric anklebot
		set ob(logfnid) 15
		set ob(logvars) 20
    	} 

    	set curtime [clock seconds]
    	set ob(datestamp) [clock format $curtime -format "%Y%m%d_%a"]
    	set ob(timestamp) [clock format $curtime -format "%H%M%S"]
    	set ob(dirname) [file join $ob(logdirbase) $ob(patname) $ob(gametype) $ob(datestamp) race ]

    	if {$ob(savelog)} {
		wshm logfnid $ob(logfnid)
    	}
}

proc init_race {} {
    	global ob mob env 

    	set ob(programname) race

	# is the game running?
    	set ob(running) 0

    	set ob(endgame) 0

	set ob(motorforces) 0

   	set ob(whichgame) "def"
    	set mob(hdir) 0

    	# 0 for rectangular paddles, 1 for oval paddles
    	set mob(round) 1    

    	# 1 for sound
    	set ob(sound) 1

	# fallms  = 5 ms (sampling period). Sampling frequency = 200 Hz
    	set ob(fallms) 5
	set ob(Hz) 200.0

    	set ob(prevrandi) c

    	wm withdraw .

    	set ob(savelog) 0

    	set ob(asklog) 1
	
    	domenu

    	set ob(dp_scale) 2.0
    	set ob(ie_scale) 2.0

    	set mob(gates_passed) 0
	set mob(gates_created) 0
    	set ob(gates_deleted) 0
    	set ob(splathit) 0

	# this flag secures single game running
	set ob(n_games) 0

    	# initializations of gatew and stiffness 
    	# (so that we won't get an error if we press quit immediately after initialization) 
    	set ob(gatew) 0 
    	set ob(stiff) 0

    	set ob(scale) 1500.0
    	set ob(winwidth) .4
    	set ob(winheight) .4

   	set ob(side) .02
    	set ob(side2) [expr {$ob(side) * 2.}]

    	#	centers
    	set ob(half,x) [expr {$ob(winwidth) / 2.}]
    	set ob(half,y) [expr {$ob(winheight) / 2.}]
    	set ob(cx) 0.0
    	set ob(cy) 0.0

    	set ob(can,x) 600
    	set ob(can,y) 600
    	set ob(can2,x) [expr {$ob(can,x) / 2.}]
   	set ob(can2,y) [expr {$ob(can,y) / 2.}]

	canvas .c -width 600 -height 600

	if {$mob(hdir)} {
		set img(field) [image create photo -format gif -file "images/tracks/racetrack_hriz.gif"]
	} else {
		set img(field) [image create photo -format gif -file "images/tracks/racetrack_vert.gif"]		
	}
  	set ob(field) [.c create image 0 0 -image $img(field) -tag track -anchor center]

	.c config -highlightthickness 0
	.c config -scrollregion [list -$ob(can2,x) -$ob(can2,y) $ob(can2,x) $ob(can2,y)]

	# create menu buttons
	button .but1 -text " New Game" -command new_race
	place .but1 -in . -relx 0.12 -rely 0.78 -anchor ne

	button .but2 -text "Stop Game" -command stop_race
	place .but2 -in . -relx 0.265 -rely 0.78 -anchor ne

	button .but3 -text " Menu " -command {menu_hide .menu}
	place .but3 -in . -relx 0.14 -rely 0.68 -anchor center

	button .but4 -text " Exit " -command done
	place .but4 -in . -relx 0.14 -rely 0.92 -anchor center

	set ob(bigcan) .c
	grid .c

	wm geometry . 1015x690
	. config -bg gray20
	place .c -relx 0.575  -rely 0.5 -anchor center

	# create a clock canvas
	set ob(clcksize) 170
        grid [canvas .clock -width $ob(clcksize) -height $ob(clcksize) -bg gray20 -highlightthickness 0] -sticky news
        grid rowconfigure . 0 -weight 1
        grid columnconfigure . 0 -weight 1

    	label .disp -textvariable mob(score) -font $ob(scorefont) -bg gray20 -fg yellow
    	place .disp -in . -relx 1.0 -rely 0.0 -anchor ne

	set ob(hdir) $mob(hdir)

	make_racer

	size_racer

	make_clock

    	bind . <s> stop_race
    	bind . <n> new_race
    	bind . <q> {done}
    	bind . <p> print_pm
    	bind . <space> race_space
	bind <Double-1> {after 700 {error [imes "please don't double-click the menu buttons"]}; break}
	bind <Triple-1> {after 700 {error [imes "please don't triple-click the menu buttons"]}; break}
    	wm protocol . WM_DELETE_WINDOW { done }

    	start_rtl

	wm deiconify .
	do_title
	after 250 menu_hide .menu
	wshm no_safety_check 1
	wshm ankle_damp 1.
	#show_race_pm4
}

proc stop_race {} {
	global mob ob

	.c delete falling
	# this requires hitting the stop button before hitting new game
	incr ob(n_games) -1
	if {$ob(n_games)<0} {set ob(n_games) 0}

	set ob(gates_deleted) 0
	set mob(gates_passed) 0
	updateClock

	# cancel all afters
	foreach id [after info] {after cancel $id}
	# in case it's red.
	.c itemconfig racer -fill yellow

	if {$ob(motorforces)} {
		acenter
		after 100 [list stop_movebox 0]
	}	
	if {$mob(racrow) > $mob(maxinrow)} {
		set mob(maxinrow) $mob(racrow)
	}
	stop_log
}

proc make_fixed_list {n rom} {
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
    foreach j [iota [expr {$n/2}]] {
	lappend the_list $min
	lappend the_list $max
    }
    return $the_list
}

proc new_race {} {
	global ob mob

	incr ob(n_games) 

	if {$ob(n_games) > 1} {
		error [imes "Press 'Stop Game' and then 'New Game' once"]
	}

	if {$ob(running)} {
		stop_race
    	}
	set ob(running) 1

	# anklebot stiffness for the entire game session
	wshm ankle_stiff $mob(menu,stiff)

	# Initializations
	# for pausing
	set ob(playgame) yes
	set ob(firstgate) yes
	set ob(paused) no
	
	# for allowing checking PM1
	set ob(check_move) no
	
	# for finding out if patient moved during a slot
	set ob(patient_moved) 0

	# for finding out what was hit first (wall or animal)
	set ob(firsthit) ""

	# this is the old center of the gate (used for PMs)
	set ob(cen) 0.0

    	array set mob {
		gates_passed 0
		gates_created 0
		score  0
		thru 0
		racrow  0
		maxinrow  0
		left 0
		right 0
		round 1
    	}

	# for logging
	set ob(savelog) $mob(savelog)

    	# scrub args
    	regsub -all {[^0-9]} $mob(endgame) {} mob(endgame)
    	set ob(endgame) $mob(endgame)
    	set ob(endgame) [bracket $ob(endgame) 0 10000]
    
    	regsub -all {[^0-9.]} $mob(level) {} mob(level)
    	set ob(level) [bracket $mob(level) 1 25]
    
    	regsub -all {[^0-9.]} $mob(gatew) {} mob(gatew)
    	set mob(gatew) [bracket $mob(gatew) 1 25]

	set ob(targetsize) $ob(gatew)

    	set ob(npos) 8
	set ob(motorforces) 1
	acenter

	set ob(nsets) [expr {$ob(endgame)+1}]

	# 4 possible random sequences
	expr {srand(int(rand() * 4))}
	if {!$mob(random)} {
		set ob(gate_list) [make_fixed_list $ob(nsets) $ob(drace,rom)]
    	} else {
		set ob(gate_list) [make_rand_list $ob(nsets) 8]
		set ob(gate_list) [eval narrow_list {$ob(gate_list)} $ob(drace,rom)]
    	}

	# change clock if needed
	.clock delete "all"
	make_clock

	# for ob(sound) = 1, sound is on
	set ob(sound) 0
	if {!$mob(audio)} {
		set ob(sound) 1
	}

	# change track if required (vertical <--> horizontal)
	set ob(hdir) $mob(hdir) 
	.c delete track
	if {$mob(hdir)} {
		set img(field) [image create photo -format gif -file "images/tracks/racetrack_hriz.gif"]
	} else {
		set img(field) [image create photo -format gif -file "images/tracks/racetrack_vert.gif"]		
	}
  	set ob(field) [.c create image 0 0 -image $img(field) -tag track -anchor center]

	if {$mob(showing) } {
		after 50 [list menu_hide .menu]
	}

	make_racer

	size_racer

	prepare_logging

    	init_adap_controller

	init_adap_var	

    	do_gate

    	fall

    	do_drag .c
}

proc narrow_list {list rom} {

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

	set list2 [list]
	set mikos [llength $list]
	for {set i 0} {$i < $mikos} { incr i } {
		set ind [lindex $list $i]
		if {$ind < $min} { 
			lappend list2 $min
		} elseif {$ind > $max} {
			lappend list2 $max
		} else {
			lappend list2 $ind
		}
	}
	for {set i 1} {$i < $mikos} { incr i } {
		set ind1 [lindex $list2 [expr {$i-1}]]
		set ind2 [lindex $list2 $i]
		if {$ind1==$ind2} {
			if {$ind2 == $max} {
				lset list2 $i $min
			} else {
				lset list2 $i [expr {$ind2+1}]
			}
		}
	}
	return $list2	 		
}

proc do_drag {w} {
	global ob mob

	# hdir == 0 means the walls fall from the top
	# hdir == 1 means the walls "fall" from the right
	set x 0.0
	set y 0.0
	if {$ob(hdir) == 0} {
	    set x [getptr x]
	    set vel [rshm ankle_ie_vel]
	    set torque [rshm ankle_ie_torque]
	    if {$ob(ankle)} {
		foreach {x y} [ankle_ptr_scale $x $y] break
	    }
	    dragx $w $x racer
	    set cur_pos $x
	} else {
	    set y [getptr y]
	    set vel [rshm ankle_dp_vel]
	    set torque [rshm ankle_dp_torque]
	 	if {$ob(ankle)} {
			foreach {x y} [ankle_ptr_scale $x $y] break
	    	} 
	    dragy $w $y racer
	    set cur_pos $y
	}

	# for P3a
	lappend ob(dx) [expr {abs($cur_pos-$ob(trgtcen))}]
	# for P3b
	lappend ob(x) $cur_pos
	# smoothness (for display)
	lappend ob(speedtraj) $vel
	# torque (for off-line analysis)
	lappend ob(torque) $torque

	if {$ob(endgame) <= 0 || $mob(gates_passed) < $ob(endgame)} {
		after 5 do_drag .c
	}
}

proc dragx {w x what} {
	global ob

	set x1 [bracket $x -$ob(half,x) $ob(half,x)]
	set x1 [expr {$x1 - $ob(racw2)}]
	set x2 [expr {$x1 + $ob(racw)}]
	# foreach {d1 y1 d2 y2} [.c coords $what] {break}
	set y1 -.15
	set y2 [expr {$y1 + $ob(rach)}]
        .c coords $what $x1 $y1 $x2 $y2
	.c scale $what 0 0 $ob(scale) -$ob(scale)
}

proc dragy {w y what} {
	global ob

	set y1 [bracket $y -$ob(half,y) $ob(half,y)]
	set y1 [expr {$y1 - $ob(racw2)}]
	set y2 [expr {$y1 + $ob(racw)}]
	# foreach {d1 x1 d2 x2} [.c coords $what] {break}
	set x1 -.15
	set x2 [expr {$x1 + $ob(rach)}]
        .c coords $what $x1 $y1 $x2 $y2
	.c scale $what 0 0 $ob(scale) -$ob(scale)
}

# this gate was hit
proc hit {} {
	global ob mob

	if {$ob(sound)} {
		nbeep 1 A 200
	}
	.c itemconfig racer -fill red
	after [expr {int(600.0/$ob(gspeed))}] .c itemconfig racer -fill yellow

	incr mob(score) -20

	if {$mob(racrow) > $mob(maxinrow)} {
		set mob(maxinrow) $mob(racrow)
	}
	set mob(racrow) 0
	do_title
	if {$ob(splattime)<=[expr {3*$ob(time_gate_travel)/4.0}]} {
		incr ob(splattime) 25
	}

	if {$ob(firsthit) == ""} {
		incr mob(gates_passed)
		incr ob(gates_deleted)
		do_title
		updateClock
		set ob(slot_klok) [clock clicks -milliseconds]
		set ob(slot_time) [expr {$ob(slot_klok) - $ob(slot_klik)}]
		set ob(slot_klik) $ob(slot_klok)	
		enter_target_do_adaptive
		cancel_moveit_timeouts
		set dest $ob(cen)
		adap_moveit {0 $ob(slotticks) 1} $dest
		set ob(firsthit) hit
	}

	if {$mob(gates_passed) == $ob(endgame)} {
		after 2000 stop_race
	}
}

proc hitanimal {} {
	global ob mob

	if {$ob(firsthit) == ""} {
		incr mob(gates_passed)
		incr ob(gates_deleted)
		do_title
		updateClock
		set ob(slot_klok) [clock clicks -milliseconds]
		set ob(slot_time) [expr {$ob(slot_klok) - $ob(slot_klik)}]
		set ob(slot_klik) $ob(slot_klok)
		enter_target_do_adaptive
		cancel_moveit_timeouts
		set dest $ob(cen)
		adap_moveit {0 $ob(slotticks) 1} $dest
		set ob(firsthit) hitanimal
	}

	if {$mob(gates_passed) == $ob(endgame)} {
		after 2000 stop_race
	}
}	

# this gate was passed rather than hit.
proc thrugate {} {
	global ob mob

	incr mob(thru)
	incr mob(score) 20
	incr mob(racrow)

	do_title

	if {$ob(splattime)>=[expr {0.33*$ob(time_gate_travel)}]} {
		incr ob(splattime) -50
	}
	if {$ob(sound)} {
		after [expr {int(600./$ob(gspeed))}] [list nbeep 5 B 50]
	}
}

proc track_adap_param {list} {
	global ob

	set list2 [list]
	set mikos [llength $list]	
	for {set i [expr {int($mikos/2.)}]} {$i <= [expr {$mikos-1}]} { incr i } {
		lappend list2 [lindex $list $i]
	}
	set med [eval median $list2]
	return $med 
}


proc hitsplat {} {
	global ob mob

	if {$ob(sound)} {
		nbeep 1 B 200
	}
	.c itemconfig racer -fill red
	after 500 .c itemconfig racer -fill yellow

	incr mob(score) -10
	incr ob(splathit)
	if {$ob(splattime)<=[expr {3*$ob(time_gate_travel)/4.0}]} { 
		incr ob(splattime) 100
	}
	do_title
}

proc draw_animal {w num x y} {
	global ob

	set ob(pic,basedir) images/ku101
	set ob(splatpic,basedir) images/splat2

    	foreach d [glob -join $ob(pic,basedir) *] {
		lappend uilist [file rootname [file tail $d]]
    	}
    	set uilist [lsort $uilist]

    	set ilistlast [llength $uilist]
    	incr ilistlast -1

    	# shuffle sorted list
    	set ilist [lrange [shuffle $uilist] 0 $ilistlast]

    	set i [lindex $uilist [irand $ilistlast]]


   	foreach f [glob -join $ob(splatpic,basedir) *] {
		lappend uilist_splat [file rootname [file tail $f]]
    	}
    	set uilist_splat [lsort $uilist_splat]

    	set ilistlast_splat [llength $uilist_splat]
    	incr ilistlast_splat -1

    	# shuffle sorted list
    	set ilist [lrange [shuffle $uilist_splat] 0 $ilistlast_splat]

    	set j [lindex $uilist_splat [irand $ilistlast_splat]]

    	# set ob(scale) 1.0
    	if {$ob(hdir) == 0} {
		set x [expr {$x * $ob(scale)}]
		set y [expr {$y * $ob(scale)-20}]
    	} else {
		set x [expr {$x * $ob(scale)+20}]
		set y [expr {$y * $ob(scale)}]
    	}
    	set img($i,im) [image create photo -file [glob $ob(pic,basedir)/$i.gif]]
    	set splat($j,im) [image create photo -file [glob $ob(splatpic,basedir)/$j.gif]]
    	set img($i,id) [$w create image $x $y -image $img($i,im) \
	-tag [list animal a$num falling] -anchor center]
    	set ob(splat_draw) [after $ob(splattime) [list .c create image $x $y -image $splat($j,im) \
	-tag [list bad b$num falling] -anchor center]]
}

# logging
# open logfile-per-section
proc start_section_start_log {} {
	global ob mob

  	if {$ob(savelog)} {
		if {$mob(gates_passed) % 44 == 0} {
			set ob(pauses_count) 0
			set secnum [expr {1+$mob(gates_passed) / 44}]
			set ob(tailname) [file tail $ob(gamename)]
			set slotlogfilename [join [list $ob(tailname) $ob(timestamp)_s_$secnum.dat] _]
			set slotlogfilename [file join $ob(dirname) $slotlogfilename]
			start_log $slotlogfilename $ob(logvars)
			puts "logging Section $secnum in $slotlogfilename"
		} else {
			set secnum [expr {1+$mob(gates_passed) / 44}]
			set ob(tailname) [file tail $ob(gamename)]
			set slotlogfilename [join [list $ob(tailname) $ob(timestamp)_s_$secnum $ob(pauses_count).dat] _]
			set slotlogfilename [file join $ob(dirname) $slotlogfilename]
			start_log $slotlogfilename $ob(logvars)
			puts "Resuming logging after $ob(pauses_count) pause(s) during Section $secnum "
		}
    	}	
	
}

# close logfile-per-slot.
proc end_section_stop_log {} {
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
	menu_v $m endgame "Game Length" 352
	menu_v $m gatew "Gate Width (1-25)" 12
	menu_v $m level "Speed level (1-25)" 6
	frame $m.stiff
	label $m.stiff.stiff_label -text "Stiffness:"
	set mob(menu,stiff) 80
	menu_t $m blank0 "" ""
	radiobutton $m.stiff.stiff_low -text [imes "Low Stiffness"] \
		-variable mob(menu,stiff) -relief flat -value 60
	radiobutton $m.stiff.stiff_medium -text [imes "Medium Stiffness"] \
		-variable mob(menu,stiff) -relief flat -value 80
	radiobutton $m.stiff.stiff_high -text [imes "High Stiffness"] \
		-variable mob(menu,stiff) -relief flat -value 100
	pack $m.stiff -anchor w
	pack $m.stiff.stiff_label -anchor w
	pack $m.stiff.stiff_low -anchor w
	pack $m.stiff.stiff_medium -anchor w
	pack $m.stiff.stiff_high -anchor w

	frame $m.dir
	label $m.dir.dir_label -text "Movement:"
	radiobutton $m.dir.dir_hriz -text [imes "Dorsal / Plantar Flexion"] \
		-variable mob(hdir) -relief flat -value 1
	radiobutton $m.dir.dir_vert -text [imes "Inversion / Eversion"] \
		-variable mob(hdir) -relief flat -value 0
	pack $m.dir -anchor w
	pack $m.dir.dir_label -anchor w
	pack $m.dir.dir_hriz -anchor w
	pack $m.dir.dir_vert -anchor w

	frame $m.rom
 	label $m.rom.rom_label -text "Range of Motion:"
	set ob(drace,rom) medium_rom
	radiobutton $m.rom.rom_short -text [imes "Short ROM"] \
		-variable ob(drace,rom) -relief flat -value short_rom
	    radiobutton $m.rom.rom_medium -text [imes "Medium ROM"] \
		-variable ob(drace,rom) -relief flat -value medium_rom
	    radiobutton $m.rom.rom_long -text [imes "Long ROM"] \
		-variable ob(drace,rom) -relief flat -value long_rom
	pack $m.rom -anchor w
	pack $m.rom.rom_label -anchor w
	pack $m.rom.rom_short -anchor w
	pack $m.rom.rom_medium -anchor w
	pack $m.rom.rom_long -anchor w
	menu_cb $m "random" "Random ROM"
	menu_t $m blank1 "" ""
	set mob(savelog) 1
	menu_cb $m "savelog" "Logging"
	menu_t $m blank2 "" ""
	menu_cb $m "accuracy" "Challenge with accuracy"
	menu_cb $m "audio" "No Audio"
	menu_t $m blank3 "" ""
	menu_t $m thru "Through Gates"
	menu_t $m racrow "Current Streak"
	menu_t $m maxinrow "Longest Streak"
	menu_t $m blank4 "" ""
	menu_b $m newgame "New Game (n)" new_race
	menu_b $m stopgame "Stop Game (s)" stop_race
	menu_b $m quit "Quit (q)" {done}
}

proc done {} {
        global ob
	stop_race
	stop_log
	stop_rtl
	exit
}

init_race
