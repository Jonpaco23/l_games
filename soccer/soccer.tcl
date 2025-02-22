#! /usr/bin/wish
#
# Game: Soccer 2014 (Partida di Calcio)
#
# Designed by: Hermano Igo Krebs and Konstantinos P. Michmizos 
# Developed by: Konstantinos P. Michmizos (konmic@mit.edu)
# Fall 2011 - Winter 2012
#
# To be used only with: Anklebot
# a game of soccer with 2 goalkeepers
# sides reflect the ball.
#
# Offline analysis of data
# e.g. for creating an ascii file: 
# wish ta.tcl / home / imt / therapist / Poli / eval / 20111125_Fri / soccer_log_123907multi.dat > / home / imt / therapist / Poli / eval / 20111125_Fri /run.asc
# e.g. for plotting:
# ./gplot /home/imt/therapist/Poli/eval/20111126_Sat/soccer_log_123907multi.dat 1 2 1 3

package require Tk
package require counter

global ob

# this selects the controller's function
set ob(ctl) 25

# unconventional hack
set env(PATID) 1

set ob(crobhome) $::env(CROB_HOME)
source $ob(crobhome)/shm.tcl
set ob(i18n_home) $::env(I18N_HOME)
source $ob(i18n_home)/i18n.tcl
source ../common/util.tcl
source ../common/menu.tcl
source predict.tcl
source math.tcl
source myclock.tcl

# this game only works with anklebot
localize_robot

# counter aliases
interp alias {} ctadd {} ::counter::count
interp alias {} ctget {} ::counter::get
interp alias {} ctinit {} ::counter::init
interp alias {} ctreset {} ::counter::reset

proc scale_rom_ie {rom} {
	global ob

 	switch $rom {
		short_rom {
			set scale 1250.0
		}
		medium_rom {
			set scale 1000.0
		}
		long_rom {
			set scale 750.0
		}
	}
	return $scale
}

proc scale_rom_dp {rom} {
	global ob

 	switch $rom {
		short_rom {
			set scale 2000.0
			set ob(trgt_dp) [expr {double($ob(winheight)/2- $ob(ww,s) + 2*$ob(padh))/(-$scale)}]
		}
		medium_rom {
			set scale 1600.0
			set ob(trgt_dp) [expr {double($ob(winheight)/2- $ob(ww,s) + 2*$ob(padh))/(-$scale)}]
		}
		long_rom {
			set scale 1200.0	
			set ob(trgt_dp) [expr {double($ob(winheight)/2- $ob(ww,s) + 2*$ob(padh))/(-$scale)}]	
		}
	}
	return $scale
}

# init adaptive variables
proc init_adap_var {} {
    	global ob mob

	 # adap_slot_metrics metrics
	ctinit active_power20 -lastn 20
	ctinit robot_power20 -lastn 20
    	ctinit min_jerk_deviation20 -lastn 20 
    	ctinit min_jerk_dgraph20 -lastn 20
	ctinit point_accuracy5 -lastn 5 
	ctinit min_trajectory5 -lastn 5 
    	ctinit min_dist_along_axis5 -lastn 5 
    	ctinit active_power_metric20 -lastn 20 
    	ctinit min_jerk_metric20 -lastn 20 
    	ctinit min_jerk_dgmetric20 -lastn 20
    	ctinit speed_metric20 -lastn 20
	ctinit accuracy_metric5 -lastn 5

	set ob(speed_performance_level) [list]
	set ob(accuracy_performance_level) [list]

    	# pm_display metrics
    	ctinit initiate -lastn 40
    	ctinit active_power40 -lastn 40
	ctinit robot_power40 -lastn 40
    	ctinit min_jerk_deviation40 -lastn 40 
    	ctinit min_jerk_dgraph40 -lastn 40 
	ctinit point_accuracy10 -lastn 10 
	ctinit min_trajectory10 -lastn 10 
    	ctinit min_dist_along_axis10 -lastn 10 
    	ctinit npoints40 -lastn 40
	ctinit slotlength40 -lastn 40 
	ctinit smoothness40 -lastn 40

	wshm pm_npoints 0

    	set tailname [file tail $ob(gamename)]
    	set filename [join [list $tailname $ob(timestamp)] _]
    	set filename [file join $ob(dirname) $filename]
    	file mkdir $ob(dirname)
    	set ob(adap_log_fd) [open "${filename}.asc" w]
    	puts $ob(adap_log_fd) "Time: $ob(timestamp)"
    	puts $ob(adap_log_fd) "Dir: $ob(dirname)"
    	puts $ob(adap_log_fd) "Game: $tailname"
    	puts $ob(adap_log_fd) "Challenge with Accuracy (YES =1): $mob(accuracy)"
	puts $ob(adap_log_fd) "Visual Aid (OFF=1): $mob(novisual)"
	puts $ob(adap_log_fd) "Audio (OFF=1): $mob(audio)"
    	puts $ob(adap_log_fd) "Gametype: ther"
	puts $ob(adap_log_fd) "ROM: $ob(dsoccer,rom)"
	puts $ob(adap_log_fd) "IE motorforces: $ob(motorforces_x)"
	puts $ob(adap_log_fd) "DP motorforces: $ob(motorforces_y)"
    	puts $ob(adap_log_fd) "Starting stifness: $mob(menu,stiff)"
    	puts $ob(adap_log_fd) "Starting speed: $ob(bspeed)"
    	puts $ob(adap_log_fd) "Starting slottime: $ob(slottime)"
    	puts $ob(adap_log_fd) "Starting target (gk) size: $ob(padw)"
    	flush $ob(adap_log_fd)
}

# logging every slot interesting variables for offline analysis
proc slotglog {str} {
    	global ob

    	set tailname [file tail $ob(gamename)]
    	set filename [join [list $tailname $ob(timestamp)] _]
    	set filename [file join $ob(dirname) $filename]
    	file mkdir $ob(dirname)
    	set logf [file join $ob(dirname) soccer_log_$ob(timestamp)_slotmetrics.log]    
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
    	set logf [file join $ob(dirname) soccer_log_$ob(timestamp)_sectionmetrics.log]    
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

    	ctadd npoints40
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

    	# current avs
    	set av_active_power [expr {$active_power / $npoints}]
	set av_robot_power [expr {$robot_power / $npoints}]
    	set av_min_jerk_deviation [expr {$min_jerk_deviation / $npoints}]
    	set av_min_jerk_dgraph [expr {$min_jerk_dgraph / $npoints}]
	set av_assistive_torque  [expr {$assistive_torque / $npoints}]
	# puts "slot: av min jerk dev $av_min_jerk_deviation"
	# puts "slot: av active power $av_active_power"

    	ctadd active_power20 $av_active_power
    	ctadd active_power40 $av_active_power
	ctadd robot_power20 $av_robot_power
    	ctadd robot_power40 $av_robot_power
    	ctadd min_jerk_deviation20 $av_min_jerk_deviation
    	ctadd min_jerk_deviation40 $av_min_jerk_deviation
    	ctadd min_jerk_dgraph20 $av_min_jerk_dgraph
    	ctadd min_jerk_dgraph40 $av_min_jerk_dgraph
	ctadd smoothness40 $smoothness

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

	# puts "active_power_metric = $active_power_metric"
	# puts "min_jerk_metric = $min_jerk_metric"

    	ctadd active_power_metric20 $active_power_metric
    	ctadd min_jerk_metric20 $min_jerk_metric
    	ctadd min_jerk_dgmetric20 $min_jerk_dgmetric
    	ctadd speed_metric20 $local_speed_metric

	# P3
	# accuracy metric
	if {$ob(itsgoal) | $ob(itspaddle)} {
		set ob(itsgoal) 0
		set ob(itspaddle) 0
		set point_accuracy [pm_point_accuracy $ob(dx_p)]
    		set min_trajectory [pm_min_trajectory $ob(x)]
		#puts "slot: point accuracy $point_accuracy"
		#puts "slot: min_trajectory $min_trajectory"

 		ctadd point_accuracy5 $point_accuracy
    		ctadd point_accuracy10 $point_accuracy
    		ctadd min_trajectory5 $min_trajectory
    		ctadd min_trajectory10 $min_trajectory

		set logi [logistic_function $min_trajectory]
   		set local_accuracy_metric [expr {$point_accuracy * $logi - $PMz}]

    		ctadd accuracy_metric5 $local_accuracy_metric
		# P4
		adap_mindist $ob(dx)
		slotglog "$ob(turns)\t$ob(trgt)\t$ob(hdir)\t$ob(patient_moved)\t$min_jerk_metric\t$active_power_metric\t$point_accuracy\t$min_trajectory\t$ob(pm_mindist)\t$av_assistive_torque\t$npoints\t$mob(bluescore)\t$mob(redscore)"
	} else {
	slotglog "$ob(turns)\t$ob(trgt)\t$ob(hdir)\t$ob(patient_moved)\t$min_jerk_metric\t$active_power_metric\t-1\t-1\t-1\t$av_assistive_torque\t$npoints\t$mob(bluescore)\t$mob(redscore)"
	}
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

# 1x per circuit, per 20 slots
proc adap_circuit_metrics {} {
    	global ob mob

    	# 20 slot avs
    	# speed
   	set speed_performance_level -1
    	set av_speed_metric [ctget speed_metric20 -avgn]
    	if {$av_speed_metric > -0.01 && $av_speed_metric < 0.01} {
		set speed_performance_level 0
    	}
    	if {$av_speed_metric > 0.01} {
		set speed_performance_level 1
    	}
	lappend ob(speed_performance_level) $speed_performance_level

    	# 5 slot avs
    	# accuracy
   	set accuracy_performance_level -1
    	set av_accuracy_metric [ctget accuracy_metric5 -avgn]
    	if {$av_accuracy_metric > -0.01 && $av_accuracy_metric < 0.01} {
		set accuracy_performance_level 0
    	}
    	if {$av_accuracy_metric >= 0.01} {
		set accuracy_performance_level 1
    	}
    	lappend ob(accuracy_performance_level) $accuracy_performance_level
	# puts "av_accuracy_metric =$av_accuracy_metric, av_speed_metric = $av_speed_metric" 
}

# collect adap distance stats, either on a wall hit or an animal hit
proc adap_mindist {list} {
    	global ob

	set pm_mindist [pm_min_dist_along_axis $list]
	ctadd min_dist_along_axis5 $pm_mindist
	ctadd min_dist_along_axis10 $pm_mindist
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

   	set speed_metric [ctget speed_metric20 -avgn]
   	set accuracy_metric [ctget accuracy_metric5 -avgn]

if {$mob(accuracy)} {
	set gain_acc 0.066
	if {$ob(dsoccer,rom) == "short_rom"} {
		set gain_acc 0.033
	} elseif {$ob(dsoccer,rom) == "long_rom"} {
		set gain_acc 0.1
	}
	set gain_sp 0.05
} else {
	set gain_acc 0.132
	if {$ob(dsoccer,rom) == "short_rom"} {
		set gain_acc 0.066
	} elseif {$ob(dsoccer,rom) == "long_rom"} {
		set gain_acc 0.2
	}
	set gain_sp 0.05
}

	if {$ob(turns)<=20} {
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
	puts "Turn $ob(turns) size = $ob(targetsize) , speed = $ob(speed)"
	adap_soccer
	sectionglog "$ob(turns)\t$ob(bspeed)\t$ob(padw)\t$speed_metric\t$accuracy_metric\t$PLsum"
}

proc adap_soccer {} {
	global ob

	# change gk width
	set ob(padw) $ob(targetsize) 
	# change ball speed
	set ob(bspeed) $ob(speed)
	calculate_time
}

# adaptive metrics at the end of a slot.
proc enter_target_do_adaptive {} {
  	  global ob mob

	if {!$ob(adaptive)} {return}

    	# every slot
    	adap_slot_metrics
	if {$ob(turns) == 0 | $ob(same_slot)} {return}

    	# every per section (5 turns / 20 slots)
    	if {($ob(turns) % 5) == 0} {
		set ob(same_slot) 1
		adap_circuit_metrics

		adjust_adap_controller 

		set circnum [expr {$ob(turns) / 5}]
		# pm_display every 2 sections
		if {($circnum % 2) == 0} { 
			# stop logging
			updateClock 
			wm title . "Soccer   Name: $mob(whoN)   Turns: $ob(turns)"
			end_section_stop_log
			pause_disp
			after 200 pm_display
			return
		}
	}
}

# this code gets run to display performance metrics
# the code that invokes it is somewhat subtle, because it needs
# to stop the ball.
proc pm_display {} {
	global ob mob

   	set npoints [ctget npoints40]

    	set init [ctget initiate]
    	ctreset initiate
    	set active_power [ctget active_power40 -avgn]
    	set robot_power [ctget robot_power40 -avgn]
    	set min_jerk_deviation [ctget min_jerk_deviation40 -avgn]
    	set min_jerk_dgraph [ctget min_jerk_dgraph40 -avgn]
	set point_accuracy [ctget point_accuracy10 -avgn] 
    	set min_dist_along_axis [ctget min_dist_along_axis10 -avgn]
	set smoothness [ctget smoothness40 -avgn]

	if {$ob(turns) == 0} return

    	set pmv2_init [expr {int(100.0 * (20.0 -$init) / 20.0)}]
	if {$pmv2_init < 0} {set pmv2_init 0}   
	set av_slotlength [ctget 	slotlength40 -avgn]

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
    	puts $ob(adap_log_fd) "turns $ob(turns)"
    	puts $ob(adap_log_fd) "init $pmv2_init"
    	puts $ob(adap_log_fd) "min_dist_along_axis $pmv2_min_dist_along_axis"
    	puts $ob(adap_log_fd) "robot_power $pmv2_robot_power"
    	puts $ob(adap_log_fd) "smoothness $pmv2_smoothness"
    	puts $ob(adap_log_fd) "dwell time $pmv2_point_accuracy"
    	flush $ob(adap_log_fd)

    	# fn2 is created at the end of every 40
    	# fn4 is appended at the end of every 40, for final graph report.
    	set pid [pid]

    	# puts "init $pmv2_init mdft $pmv2_min_dist_along_axis rp $pmv2_robot_power \
	jerk $pmv2_min_jerk_dgraph pa $pmv2_point_accuracy"

    	set fn2 "/tmp/soccer_pm2_$pid.asc"
    	set fd2 [open "$fn2" w]
    	puts $fd2 "init $pmv2_init mdft $pmv2_min_dist_along_axis rp $pmv2_robot_power \
		smooth $pmv2_smoothness pa $pmv2_point_accuracy"
    	close $fd2

    	set fn4 "/tmp/soccer_pm4_$pid.asc"
    	# append
    	set fd4 [open "$fn4" a]
    	puts $fd4 "init $pmv2_init mdft $pmv2_min_dist_along_axis rp $pmv2_robot_power \
		smooth $pmv2_smoothness pa $pmv2_point_accuracy"
    	close $fd4

    	if {[expr {$ob(turns)}] == $ob(endgame)} {
		# save race_pm4 to be displayed on next run
		file copy -force $fn4 $ob(logdirbase)/$ob(patname)/soccer_pm4.asc
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

	puts "soccer.tcl performance metrics dump:"

	set npoints [ctget npoints40]
    	set init [ctget initiate]
    	set min_dist_along_axis [ctget min_dist_along_axis40 -avg]
    	set active_power [ctget active_power40 -avg]
    	set robot_power [ctget robot_power40 -avg]
    	set min_jerk_dgraph [ctget min_jerk_dgraph40 -avg]
    	set point_accuracy [ctget point_accuracy10 -avgn] 
	set smoothness [ctget smoothness40 -avgn]

    	set init [expr {100.0 * $init / $ob(turns)}]
    	set min_dist_along_axis [expr {100.0 * $min_dist_along_axis / 0.14}]

    	set active_power [expr {100.0 - ($active_power * -100.)}]

    	set min_jerk_dgraph [expr {100. - (6.25 * 100.0 * $min_jerk_dgraph)}]
    	set point_accuracy [expr {int(100.0-(200.0/7.0) * $point_accuracy)}]

   	puts "npoints: $npoints"
    	puts "1 $init 2 $min_dist_along_axis 3 $active_power \
		4 $min_jerk_dgraph 5 $point_accuracy"
    	puts ""
}

# close logfile-per-slot.
proc end_section_stop_log {} {
    	global ob
    
	if {$ob(savelog)} {
		stop_log
    	}
}

# therapist hit the space bar.
# or the program wants you to think that happened.
# funny things happen inside here
proc pause_disp {} {
    	global ob

	incr ob(pauses_count)

	# deletes previous prediction
	.c delete pred

	set ob(paused) yes	
	end_section_stop_log
	cancel_moveit_timeouts
	acenter
	after 400 [list stop_movebox 0]
}

proc unpause_disp {} {
	global ob

	set ob(paused) no

	# for allowing checking PM1
	set ob(check_move) no

	set ob(same_slot) 0

	# when south GK defended and moves back	
	set ob(sgk_D_B) 0
	set ob(ndefended) 0

	set ob(itsgoal) 0
	set ob(itspaddle) 0

	set ob(hdir) 0
	set ob(trgt) 0
	set ob(trgt_pixels) 0

	set cx $ob(half,x)
	set cy $ob(half,y)
	.c coords ball $cx $cy

	set ob(lastbat) none

	set ob(firstkick) yes

	startball n

	moveball
}

proc soccer_space {} {
	global ob
	
	if {$ob(paused)} {
		unpause_disp
	} else {
		pause_disp
	}
}

# check the velocity magnitude.
# if the patient's ankle has moved enough, start the slot now.
proc adap_check_vel {} {
	global ob

	if {[info exists ob(moveit_slot)]} {
		set ob(vellim) [expr {2*1000.0*1.875 * $ob(slotlength) / $ob(time_ball_travel)}]
		if {$ob(hdir)} {
			set ob(velmag) [expr {abs([rshm yvel])}]
		} else {
			set ob(velmag) [expr {abs([rshm xvel])}]
		}
		if {$ob(velmag) > $ob(vellim)} {
		# puts "vellim = $ob(vellim), velmag = $ob(velmag)"
			ctadd initiate
			set ob(check_move) no
			set ob(patient_moved) 1
			set ob(klokslot) [clock clicks -milliseconds]
			set time_passed [expr {$ob(klokslot)-$ob(klikslot)}]
			set time_to_close_slot [expr {$ob(time_ball_travel) - $time_passed}]
			set ob(ticks) [expr {int(double(($time_to_close_slot)/1000.0) * $ob(Hz))}]
			set ob(forlist_effective) {0 $ob(ticks) 1}
			set mb_command [lindex [after info $ob(moveit_slot)] 0]
			eval $mb_command
		}
	}
}

proc calculate_time {} {
	global ob

	# 2000 was empirically estimated.
	set ob(time_ball_travel) [expr {int(2750./abs($ob(bspeed)))}]
	set ob(slottime_hard_mb) [expr {int(0.5*$ob(time_ball_travel))}]
	set ob(time_to_close_slot) [expr {int($ob(time_ball_travel)-$ob(slottime_hard_mb))}]
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

proc make_walls {} {
	global ob

	set winheight $ob(winheight)
	set winwidth $ob(winwidth)
	# wall width
	set wwid 50
	set ob(ww,n) $wwid
	set ob(ww,s) [expr {$winheight-$wwid}]
	set ob(ww,w) $wwid
	set ob(ww,e) [expr {$winwidth-$wwid}]

	set ob(ww,gp) 280
	
	set img(ar_right) [image create photo -format gif -file "images/arena_right_whiteline.gif"]
	set img(ar_left) [image create photo -format gif -file "images/arena_left_whiteline.gif"]
	set img(ar_nw) [image create photo -format gif -file "images/nw.gif"]
	set img(ar_sw) [image create photo -format gif -file "images/sw.gif"]
	set img(ar_ne) [image create photo -format gif -file "images/ne.gif"]
	set img(ar_se) [image create photo -format gif -file "images/se.gif"]

	# four walls
	set ob(color,n) black
	set ob(wall,nw) [.c create image 0 0 -image $img(ar_nw) -tag arena -anchor nw]	
	set ob(wall,ne) [.c create image [expr {$winwidth-85}] 0 -image $img(ar_ne) -tag arena -anchor nw]	

	# north goalpost
	set x1 [expr {($winwidth/2) - ($ob(ww,gp)/2)}]
	set y1 0
	set x2 [expr {($winwidth/2) + ($ob(ww,gp)/2)}]
	set y2 [expr {$ob(ww,n)}]
	set ob(wallgp,n) [.c create rect $x1 $y1 $x2 $y2 -outline "" \
		-fill $ob(color,n) -tag [list wall wngp]]

	set ob(color,s) gray
	set ob(wall,sw) [.c create image 0 $winheight -image $img(ar_sw) -tag arena -anchor sw]		
	set ob(wall,se) [.c create image [expr {$winwidth-85}] [expr {$winheight-50}] -image $img(ar_se) -tag arena -anchor nw]

	# south goalpost
	set ob(gps,x1) [expr {($winwidth/2) - ($ob(ww,gp)/2)}]
	set ob(gps,y1) $ob(ww,s)
	set ob(gps,x2) [expr {($winwidth/2) + ($ob(ww,gp)/2)}]
	set ob(gps,y2) $winheight
	set ob(wallgp,s) [.c create rect $ob(gps,x1) $ob(gps,y1) $ob(gps,x2) $ob(gps,y2) -outline "" \
		-fill $ob(color,s) -tag [list wall wsgp]]     	
	
	set ob(color,w) gray	

	#west goalpost
	set ob(colorgp,w) cyan
	
	set ob(color,e) gray
	set ob(wall,e) [.c create image $winwidth $winheight -image $img(ar_right) -tag arena -anchor se]	

	# for east goalpost
	set ob(colorgp,e) orange
	
	set ob(wall,w) [.c create image 0 0 -image $img(ar_left) -tag arena -anchor nw]

	set ob(wall,first) $ob(wall,ne)
	set ob(wall,last) $ob(wall,e)

	foreach i {n s w e} {
		set ob(livewall,$i) 0
		set ob(livewallgp,$i) 0
	}
}

# in each game, set up the walls as live (colored) or no (gray)
proc set_walls {} {
	global ob mob

	foreach i {ne nw se sw w e} {
		if {[string first $i $mob(whichgame)] >= 0} { 
		        set ob(livewall,$i) 0
		        .c itemconfigure $ob(wall,$i) -fill $ob(color,$i)
		} else {
		        set ob(livewall,$i) 0
		        #.c itemconfigure $ob(wall,$i) -fill gray
		}
	}
	
	foreach i {n s w e} {
		if {[string first $i $mob(whichgame)] >= 0} { 
				set ob(livewallgp,$i) 1
				.c itemconfigure $ob(wallgp,$i) -fill $ob(colorgp,$i)
		} else {
				set ob(livewallgp,$i) 0
				#.c delete $ob(wallgp,$i) -fill gray	
		}
	}
}

# make paddles once
proc make_paddles {} {
	global ob mob

	# paddle dimensions
	set ob(padw) 50

	# height of the paddles
	set ob(padh) 15

	# distance from screen edge to paddle face
	set pdist 70
	set ob(npd) $pdist
	set ob(spd) [expr {$ob(winheight)-$pdist}]

	set ob(pad,n) [.c create oval 1 1 2 2 -outline "grey" \
		-fill $ob(colorgp,n) -tag [list paddle pn]]
	set ob(pad,s) [.c create oval 1 1 2 2 -outline "grey" \
		-fill $ob(colorgp,s) -tag [list paddle ps]]
	set ob(pad,w) [.c create oval 1 1 2 2 -outline "grey" \
		-fill $ob(colorgp,w) -tag [list paddle pw]]
	set ob(pad,e) [.c create oval 1 1 2 2 -outline "grey" \
		-fill $ob(colorgp,e) -tag [list paddle pe]]
}

# set up the paddles each game.
# dead paddles get stuffed behind dead walls,
# but they're still there.
# (call Andy lazy)
proc set_paddles {} {
	global ob mob

	set cx $ob(half,x)
	set cy $ob(half,y)


	set ob(padw2) [expr {$ob(padw) / 2}]

	# goalkeepers
	# north
	if {[string first n $mob(whichgame)] >= 0} {
		set x1 [expr {$cx - $ob(padw2)}]
		set y1 $ob(npd)
		set x2 [expr {$cx + $ob(padw2)}]
		set y2 [expr {$ob(npd) - $ob(padh)}]
		.c coords $ob(pad,n) $x1 $y1 $x2 $y2 
		.c itemconfigure $ob(pad,n) -fill $ob(colorgp,n)
	} 
	# south
	if {[string first s $mob(whichgame)] >= 0} {
		set x1 [expr {$cx - $ob(padw2)}]
		set y1 $ob(spd)
		set x2 [expr {$cx + $ob(padw2)}]
		set y2 [expr {$ob(spd) + $ob(padh)}]
		.c coords $ob(pad,s) $x1 $y1 $x2 $y2 
		.c itemconfigure $ob(pad,s) -fill $ob(colorgp,s)
	} 
}

proc set_lines {} {
	
	global ob

	set ob(line) [.c create line $ob(ww,w) [expr {$ob(winheight)/2}] $ob(ww,e) [expr {$ob(winheight)/2}] -width 2 -fill grey]
	set circleR 35	
	set ob(circle) [.c create oval [expr {$ob(winwidth)/2-$circleR}] [expr {$ob(winheight)/2 - $circleR}] [expr {$ob(winwidth)/2+$circleR}] [expr {$ob(winheight)/2 + $circleR}] -width 2 -outline grey]
	set ob(gkarea1,s) [.c create line [expr {($ob(winwidth)/2) - ($ob(ww,gp)/2)}] [expr {$ob(winheight)/2+4*$circleR}] [expr {($ob(winwidth)/2) + ($ob(ww,gp)/2)}]  [expr {$ob(winheight)/2+4*$circleR}] -width 2 -fill grey]
	set ob(gkarea1,n) [.c create line [expr {($ob(winwidth)/2) - ($ob(ww,gp)/2)}] [expr {$ob(winheight)/2-4*$circleR}] [expr {($ob(winwidth)/2) + ($ob(ww,gp)/2)}]  [expr {$ob(winheight)/2-4*$circleR}] -width 2 -fill grey]
	set ob(gkarea2,s) [.c create line [expr {($ob(winwidth)/2) - ($ob(ww,gp)/2)}] [expr {$ob(winheight)/2+4*$circleR}] [expr {($ob(winwidth)/2) - ($ob(ww,gp)/2)}]  $ob(ww,s) -width 2 -fill grey]
	set ob(gkarea3,s) [.c create line [expr {($ob(winwidth)/2) + ($ob(ww,gp)/2)}] [expr {$ob(winheight)/2+4*$circleR}] [expr {($ob(winwidth)/2) + ($ob(ww,gp)/2)}]  $ob(ww,s) -width 2 -fill grey]
	set ob(gkarea2,n) [.c create line [expr {($ob(winwidth)/2) - ($ob(ww,gp)/2)}] [expr {$ob(winheight)/2-4*$circleR}] [expr {($ob(winwidth)/2) - ($ob(ww,gp)/2)}]  $ob(ww,n) -width 2 -fill grey]
	set ob(gkarea3,n) [.c create line [expr {($ob(winwidth)/2) + ($ob(ww,gp)/2)}] [expr {$ob(winheight)/2-4*$circleR}] [expr {($ob(winwidth)/2) + ($ob(ww,gp)/2)}]  $ob(ww,n) -width 2 -fill grey]
}

proc init_adap_controller {} {
	global ob mob

	# for checking if the patient has moved
	set ob(check_move) no

	# for displacement per slot 
	set ob(dx) [list]
	# for paddle position per slot
	set ob(x) [list]
	# for estimating smoothness metric per slot (used for display)
	set ob(speedtraj) [list]
	# for estimating torque metric per slot (used for off-line analysis)
	set ob(torque) [list]

	set ob(sgk_S) 0

	set ob(slotlength) 0.0

	# this allows the hard i/e movebox to timeout, 
	# when the player has not moved enough by himself
	set ob(hard_mb_timeout) 0

	# for moving moveboxe ie
	set ob(move_ie) 0

	set ob(moveit_state) pause

	set ob(deltay) 0
	set ob(shootspeed) 0
	set ob(addspeed) 0
	set ob(aggrspeed) 0
	set ob(gainspeed) 25000

	set ob(startmeasuretime) 1	
	set ob(klik) 0
	set ob(klok) 0
	set ob(time2shoot) 0
	
	# speed of the ball
	regsub -all {[^0-9]} $mob(level) {} mob(level)
	set mob(level) [bracket $mob(level) 1 25]
	# adjustable parameter values for ball speed
	set ob(lbspeed) [list 0.45 0.60 0.75 0.90 1.05 1.2 1.3 1.4 1.5 1.6 1.7 1.8 2.0 2.20 2.40 2.70 2.85 3.00 3.20 3.40 3.70 4.00 4.50 4.75 5.25]
	set ob(bspeed) [lindex $ob(lbspeed) [expr {$mob(level)-1}]] 
	set ob(speed) $ob(bspeed)

	# paddle dimensions
	regsub -all {[^0-9]} $mob(padw) {} mob(padw)
	set mob(padw) [bracket $mob(padw) 1 25]
	# adjustable parameter values for paddle width
	set ob(lpaddlew) [list 30 32 34 36 38 40 42 44 46 48 50 52 54 56 58 60 62 64 66 68 70 72 74 76 78]
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

	calculate_time
}

# this gets done once.
proc init_soccer {} {
	global ob mob

	# some colors first...
	set ob(predfill) orange
	set ob(predfill2) yellow
	set ob(predout) black
	set ob(predout2) orange

	# game refresh rate (and sampling period) in ms
	set ob(tick) 5
	set ob(Hz) [expr {1000*(1.0/$ob(tick))}]

	# field dimensions
	set ob(winwidth) 450 
	set ob(winheight) 650
	
	# This is for the two goalposts, inherited from pong game
	set mob(whichgame) ns

	# red and blue score
	set mob(redscore) 0
	set mob(bluescore) 0

	# is the game running?
   	set ob(running) 0

	# this counts the turns in the game
	set ob(turns) 0

	# colors of paddles (firebrick4,goldenrod2,gold2,DodgerBlue,lightcoral,lightblue)
	set ob(colorgp,n) lightsalmon1
	set ob(colorgp,s) DodgerBlue

	# centers
	set ob(half,x) [expr {$ob(winwidth) / 2}]
	set ob(half,y) [expr {$ob(winheight) / 2}]
	set cx $ob(half,x)
	set cy $ob(half,y)

	canvas .c -width $ob(winwidth) -height $ob(winheight) -bg gray90
	grid .c

	set img(field) [image create photo -format gif -file "images/field2.gif"]
  	set ob(field) [.c create image 0 0 -image $img(field) -tag field -anchor nw]

	button .but1 -text " New Game" -command new_soccer
	place .but1 -in . -relx 0.11 -rely 0.8 -anchor ne

	button .but2 -text "Stop Game" -command stop_soccer
	place .but2 -in . -relx 0.25 -rely 0.8 -anchor ne

	button .but3 -text " Menu " -command {menu_hide .menu}
	place .but3 -in . -relx 0.14 -rely 0.7 -anchor center

	button .but4 -text " Exit " -command done
	place .but4 -in . -relx 0.14 -rely 0.94 -anchor center

	font create boardfont -family Helvetica -size 18
	canvas .board -width 250 -height 150 -bg gray90 -borderwidth 2 -relief sunken
	place .board -in . -relx 0.8625 -rely 0.5 -anchor center

	.board create text 72 30 -text "Player" -font boardfont -tags "playname name" -anchor center
	.board create text 182 30 -text "Computer" -font boardfont -tag "compname name" -anchor center
	.board itemconfigure name -font boardfont
	label .disp -textvariable mob(bluescore) -font $ob(scorefont) -bg gray90 -fg $ob(colorgp,n)
	place .disp -in .board -x 182 -y 87 -anchor center

	label .disp2 -textvariable mob(redscore) -font $ob(scorefont) -bg gray90 -fg $ob(colorgp,s)
	place .disp2 -in .board -x 72 -y 87 -anchor center
	.board create rectangle 34 49 110 125 -fill gray90 -outline black
	.board create rectangle 144 49 220 125 -fill gray90 -outline black
	
    	wm geometry . 1015x690
    	. config -bg gray20

	# create a clock canvas
	set ob(clcksize) 170
        grid [canvas .clock -width $ob(clcksize) -height $ob(clcksize) -bg gray20 -highlightthickness 0] -sticky news
        grid rowconfigure . 0 -weight 1
        grid columnconfigure . 0 -weight 1

	domenu

	make_walls
	
	set_walls

	set_lines

	make_paddles

	set_paddles

	make_clock

	# the ball (after field!)
	set ob(bsize) 20
	set ob(bsize2) [expr {$ob(bsize)/2}]
	set ob(bradius) [expr {$ob(bsize)/2}]
	set bsize $ob(bsize)
	set x1 [expr {$cx - ($bsize / 2)}]
	set x2 [expr {$cx + ($bsize / 2)}]
	set y1 [expr {$cy - ($bsize / 2)}]
	set y2 [expr {$cy + ($bsize / 2)}]

	set img(ball) [image create photo img -format gif -file "images/ball10.gif"]
  	set ob(ball) [.c create image $cx $cy -image $img(ball) -tag ball -anchor center]
	set ob(ballorig) [.c coords $ob(ball)]

	bind . <s> stop_soccer
	bind . <n> new_soccer
	bind . <q> done
	bind . <Escape> done
	bind . <space> soccer_space
	wm protocol . WM_DELETE_WINDOW { done }

	set ob(lastbat) none
	
	# These two allow the anklebot to help in i/e (x) or/and in d/p (y) motion
	set ob(motorforces_x) 0
	set ob(motorforces_y) 0

	# south (north) goalpost defended (the ball was caught by goalkeeper)
	set ob(sgk_D_B) 0
	set ob(ndefended) 0

	# North Goalkeeper attacks when flag is set
	set ob(attack) 0

	# This secures exact positioning of the south paddle after plantar flexion
	set ob(lowlimit) [expr {$ob(ww,s)-$ob(padh)}]

	# for moving the north goalkeeper
	set ob(ngoal) 0 
	set ob(moveback) 0
	set ob(moveback_v) 0

	# South GK shot and moves back when this flag is set
	set ob(sgk_S_B) 0

	# this allows i/e movement of the anklebot (we must be near 0 angle d/p flexion)
	set ob(sgk_D) 1

	# this flag is raised when the ball aims for the south goalpost	
	set ob(sgoal) 0

	# this flag secures single game running
	set ob(n_games) 0

	# for estimating the speed of the shoot
	set ob(y_old) 0
	set ob(y_old2) 0

	# for pausing the game
	set ob(paused) no

	set mob(startlogging) 1

	# (so that we won't get an error if we press quit immediately after initialization) 
	set ob(bspeed) 0

	# lists for virtual rotation of the wall
	set ob(wlist,s) [list n s w e]
	set ob(wlist,w) [list e w n s]	
	set ob(wlist,n) [list s n w e]
	set ob(wlist,e) [list w e n s]

	if {!$mob(audio)} {
		set ob(sound) 1
	} else {
		set ob(sound) 0
	}

	if {[regexp ^(Linux|Unix|QNX) [tclos]]} {
		.c config -cursor {crosshair gray}
	}
	start_rtl
	wshm no_safety_check 1
 
	wshm planar_damp 0.4
 	
	after 250 [list menu_hide .menu]

	#show_soccer_pm4
}

proc stop_soccer {} {
	global mob ob

	# this requires hitting the stop button before hitting new game
	incr ob(n_games) -1
	if {$ob(n_games)<0} {set ob(n_games) 0}

	# zero-ing display
	set mob(shots) 0
	set mob(redscore) 0
	set mob(bluescore) 0
	set ob(turns) 0

	updateClock 
	after cancel moveball

	if {$ob(motorforces_x) || $ob(motorforces_y)} {
		cancel_moveit_timeouts
		acenter
		after 300 stop_movebox 0
	}

	if {$mob(goalrow) > $mob(maxinrow)} {
		set mob(maxinrow) $mob(goalrow)
	}
	stop_log
}

# restart each new game
proc new_soccer {} {
	global ob mob

	incr ob(n_games) 

	if {$ob(n_games) > 1} {
		error [imes "Press 'Stop Game' and then 'New Game' once"]
	}
	
	.c delete pred

	# anklebot stiffness for the entire game session
	wshm planar_stiff $mob(menu,stiff)
	
	if {$ob(running)} {
		stop_soccer
	}
    	set ob(running) 1
	
	set ob(motorforces_x) 1
	set ob(motorforces_y) 1

	if {$mob(nomotorforces_x)} {
		set ob(motorforces_x) 0
	} 
	if {$mob(nomotorforces_y)} {
		set ob(motorforces_y) 0
	} 

	set ob(adaptive) yes
	if {!$ob(motorforces_x) | !$ob(motorforces_y)} {
		puts "Attention! No adaptive!"
		set ob(adaptive) no
	}
	# for ob(sound) = 1, sound is on
	set ob(sound) 0
	if {!$mob(audio)} {
		set ob(sound) 1
	}

	# for allowing checking PM1
	set ob(check_move) no

	regsub -all {[^0-9]} $mob(endgame) {} mob(endgame)
	set ob(endgame) $mob(endgame)
	regsub -all {[^0-9]} $mob(level) {} mob(level)
	set ob(level) $mob(level)

	eval .c coords $ob(ball) $ob(ballorig)
	set ob(lastbat) none

	array set mob {
		saves 0
		redscore  0
		bluescore 0
		shots 0
		goalrow  0
		maxinrow  0
		wall 0
		paddle 0
	}

	# for logging
	set ob(savelog) $mob(savelog)
	
	set ob(turns) 0
	set ob(same_slot) 0

	# when south GK defended and moves back	
	set ob(sgk_D_B) 0
	set ob(ndefended) 0

	set ob(itsgoal) 0
	set ob(itspaddle) 0

	set_walls

	set ob(level) [bracket $ob(level) 1 15]
	set ob(forw)  [expr {$ob(level) * 2.0 * $ob(tick) / 10.0 }]
	set ob(side)  [expr {$ob(level) * 4.0 * $ob(tick) / 10.0 }]
	
	.clock delete "all"
	make_clock
	.board delete playname
	.board delete compname
	.board create text 72 30 -text $mob(whoN) -font boardfont -tag "playname" -anchor center
	.board create text 182 30 -text $mob(comp) -font boardfont -tag "compname" -anchor center

	init_adap_controller
	
	# watch out! this is for the vertical speed of the ball shoot (default 0.7*speed)
	set ob(by_traj) [expr {0.7*$ob(bspeed)}]

	prepare_logging

    	init_adap_controller

	init_adap_var

	# this is for short/medium/long ROM selection
	set ob(scale_ie) [eval scale_rom_ie $ob(dsoccer,rom)]
	set ob(scale_dp) [eval scale_rom_dp $ob(dsoccer,rom)]	

	set ob(hdir) 0
	set ob(trgt) 0
	set ob(trgt_pixels) 0
	set ob(outofbounds) 0

	if {$mob(showing) } {
		after 50 [list menu_hide .menu]
	}

	set ob(firstkick) yes

	startball n
	moveball
}

# startball starts on a new game or after a goal
proc startball {i} {
	global ob
	# where does the ball start?  When i = "n", ball moves towards north.

	if {$ob(firstkick)} {
		set ob(firstkick) no
		start_section_start_log
	}

	set ob(kickoff) 1
	set ob(ngoal) 0
	set ob(sgoal) 0

	set ob(forw) 2
	if {$i == "s"} {
		set ob(dir)   [list 0.0 [expr {1.0 + ($ob(forw)} / 5.0)]]
	} elseif {$i == "n"} {
		set ob(dir)   [list 0.0 [expr {-1.0 - ($ob(forw)} / 5.0)]]
	} else {
		error "startball: i should be s or n"
	}
	set_paddles

	# if motors are powered, then move them to zero position and raise the flag for horizontal movements.
	if {$ob(motorforces_x) || $ob(motorforces_y)} {
		if {$ob(running)} {
			acenter
			after 300 stop_movebox 0
		}
		set ob(sgk_D) 1
	} else {
		stop_movebox 0
	}
}

proc movegoalkeeper {} {
	global ob

	set ob(gkspeed) [expr {$ob(bspeed)/2.0}]

	scan [.c coords $ob(pad,n)] "%s %s" origx origy

	set origx [expr {$origx - $ob(winwidth)/2 + $ob(padw)/2}]
	
	if {[expr {$ob(ngoalx)-$origx}]<-1} {
		if {$origx > $ob(ngoalx)} {
			eval .c move pn "-$ob(gkspeed) 0"
			}
		} elseif {[expr {$ob(ngoalx)-$origx}]>0} {
			if {$origx < [expr {$ob(ngoalx)+$ob(padw)/2}]} {
			eval .c move pn "$ob(gkspeed) 0"
		}
	}
}


proc movegoalkeeperback {} {
	global ob

	# set ob(gkspeed) 1
	set ob(gkspeed) $ob(bspeed)
	set ob(ngoal) 0
	scan [.c coords $ob(pad,n)] "%s %s" origx origy
	scan [.c coords $ob(pad,s)] "%s %s" origxs origys
	if {$origx <  [expr {$ob(winwidth)/2 - $ob(padw)/2-1}]} {
		eval .c move pn "$ob(gkspeed) 0"
		eval .c move ball "$ob(gkspeed) 0"
	} elseif {$origx > [expr {$ob(winwidth)/2 - $ob(padw)/2+1}]} {
		eval .c move pn "-$ob(gkspeed) 0"
		eval .c move ball "-$ob(gkspeed) 0"
	} else {
		# goalkeeper is centered
		set ob(moveback) 0
		set ob(attack) 1
	}
}

proc start_attack {} {
	global ob
	
	# set ob(sp_fwd) 0.75
	set ob(sp_fwd) $ob(bspeed)

	scan [.c coords $ob(pad,n)] "%s %s" origx origy

	if {[expr {$origy+$ob(bsize)}] <= $ob(winheight)/2} {
		eval .c move pn "0 $ob(sp_fwd)"
		eval .c move ball "0 $ob(sp_fwd)"
	} else {
		shoot n
		set ob(moveback_v) 1
	}
}

proc movegoalkeeperback_v {} {
	global ob

	set ob(sp_back) [expr {0-$ob(sp_fwd)}]
	set ob(ngoal) 0

	scan [.c coords $ob(pad,n)] "%s %s" origx origy

	if {$origy >=  [expr {$ob(ww,n) +5}]} {
		eval .c move pn "0 -2"
	} else {
		# goalkeeper is centered
		set ob(moveback_v) 0
		set ob(ndefended) 0 
	}
}

proc dodrag {w x y} {
	global ob
	
	scan [.c coords $ob(pad,s)] "%s %s" origx origy	
	if {$ob(livewallgp,s)} {
		if { [expr {$ob(ww,s) -$origy}]>=25} {		
			dragy $w $y ps
		} else {
			dragx $w $x ps
			if {$ob(sgk_S_B)} {
				enter_target_do_adaptive
				# this statement is executed once
				set ob(sgk_S_B) 0
				set ob(sgk_D) 1
				.c delete pred
				set ob(outofbounds) 0
				cancel_moveit_timeouts
				stop_movebox 0
			}
		} 
	}
}

proc dodragball {w x y} {
	global ob mob

       set ob(deltay) [expr {0-($y-$ob(y_old))}]

	scan [.c coords $ob(ball)] "%s %s" ballorigx ballorigy
	scan [.c coords $ob(pad,s)] "%s %s" origx origy

	set paddlepos [expr {$origx+$ob(padw)/2-$ob(winwidth)/2}]
	set centralpixels 20 

		if { [expr {abs($paddlepos)}]<$centralpixels } {
			if {$ob(startmeasuretime)} {
				set ob(startmeasuretime) 0
				set ob(klik) [clock clicks -milliseconds]
				set_paddles
			}
			set ob(addspeed) 1
			if {$ob(sgk_S)} {
				.c delete pred
				if {$ob(motorforces_y)} {
					if {!$mob(novisual)} {
						set ob(target) [.c create oval [expr {$ob(half,x)-4}] [expr {$ob(half,y)-4}] \
						[expr {$ob(half,x)+4}] [expr {$ob(half,y)+4}] -fill $ob(predfill2) -outline $ob(predout2) -width 1 -tag pred]]
					}
					enter_target_do_adaptive
					set ob(sgoaly) $ob(trgt_dp)
					set dest [list 0.0 $ob(sgoaly)]
					set ob(hdir) 1
					set ob(trgt) $ob(sgoaly)
					set ob(trgt_pixels) [expr int(-$ob(scale_dp) * $ob(trgt) + $ob(half,y))]
					adap_moveit {0 $ob(slotticks) 1} $dest
				} else {
					stop_movebox 0
				}
				set ob(sgk_S) 0
			} 
			if {$y>$ob(lowlimit)} {
				dragy $w $ob(lowlimit) ps
				dragyball $w $ob(lowlimit) ball
			} elseif {$y< $ob(lowlimit)} {
				dragy $w $y ps
				dragyball $w $y ball
			}
			if {$origy <= $ob(winheight)/2} {
				set ob(klok) [clock clicks -milliseconds]
				set ob(time2shoot) [expr {$ob(klok)-$ob(klik)}]
				shoot s
				set ob(aggrspeed) 0
				set ob(addspeed) 0
				set ob(startmeasuretime) 1
			}
		} else {
			if {$origx>=[expr {$ob(ww,w)}] && $origx<=[expr {$ob(ww,e)-$ob(padw)/2}]} { 
				dragx $w $x ps
				dragxball $w $x ball
			} elseif {$origx<[expr {$ob(ww,w)}]} {
				set ob(outofbounds) 1
				dragx $w [expr {1+$ob(ww,w)+$ob(padw)/2}] ps
				dragxball $w [expr {1+$ob(ww,w)+$ob(padw)/2}] ball
			} elseif {$origx>[expr {$ob(ww,e)-$ob(padw)/2}]} {
				set ob(outofbounds) 1
				dragx $w [expr {$ob(ww,e)-$ob(padw)/2}] ps
				dragxball $w [expr {$ob(ww,e)-$ob(padw)/2}] ball
			}
		set ob(y_old) $y
	}
}

proc shoot {i} {
	global ob mob

	stop_movebox 0
	set side [expr {.0+ round(rand())}]
	if {$i =="s"} {
		.c delete pred
		set ob(sgk_D_B) 0
		if {$ob(time2shoot)>0} {
			set speed [expr {$ob(gainspeed)*$ob(aggrspeed)/$ob(time2shoot)}]
		} else {
			startball s
			set speed 0
		}
		if {$speed>3} {
			set speed 3
		} elseif {$speed <0.35} {
			set speed 0.35
		}
		set ob(sgk_S_B) 1

		set xr [expr {$speed*pow(-1,$side)}] 
		set yr [expr {-abs($xr)*3}]
		defend $ob(bbox) $xr $yr $i
		incr mob(shots)

		if {$ob(motorforces_y)} {
			if {!$mob(novisual)} {
				set ob(target) [.c create oval [expr {$ob(half,x)-4}] [expr {$ob(spd)+$ob(padh)/2-4}] \
				[expr {$ob(half,x)+4}] [expr {$ob(spd)+$ob(padh)/2+4}] -fill $ob(predfill2) -outline $ob(predout2) -width 1 -tag pred]]
			}
			enter_target_do_adaptive
			set ob(sgoaly) -0.05
			set dest [list 0.0 $ob(sgoaly)]
			set ob(hdir) 1
			set ob(trgt) $ob(sgoaly)
			set ob(trgt_pixels) [expr int(-$ob(scale_dp) * $ob(trgt) + $ob(half,y))]
			after 250 [list adap_moveit {0 $ob(slotticks) 1} $dest]
		} 
	} elseif {$i == "n"} {
		set ob(ndefended) 0
		set gain $ob(bspeed)
		set xr [expr {$gain * 0.4 * pow(-1,$side)}] 
		# ob(by_traj) is coming from calculate_ball_traj_time
		# set yr $ob(by_traj)
		set yr $gain
		set ob(moveback_v) 1
		defend $ob(bbox) $xr $yr $i
		#set ob(klik2) [clock clicks -milliseconds]
	}
	set ob(dir) "$xr $yr" 
}	

proc dragx {w x p} {
	global ob

	set x1 [expr {[.c canvasx $x] - $ob(padw2)}]
	set x2 [expr {$x1 + $ob(padw)}]
	foreach {d1 y1 d2 y2} [.c coords $p] {break}
	# this is inserted here to prevent south paddle to go "inside" the goalpost,
	# just like in dragxball if - statement...
	if {$y1>$ob(spd)} {
		set y1 $ob(spd)
	}
	.c coords $p $x1 $y1 $x2 [expr {$y1+$ob(padh)}]
}

proc dragy {w y p} {
	global ob

	set y1 [expr {[.c canvasy $y] - $ob(padw2)}]
	set y2 [expr {$y1 + $ob(padw)}]
	foreach {x1 d1 x2 d2} [.c coords $p] {break}
	.c coords $p $x1 $y1 $x2 $y2
}

proc dragxball {w x p} {
	global ob

	set x1 [expr {[.c canvasx $x]-$ob(bsize)/2}]
	set x2 [expr {$x1 + $ob(bsize)}]
	foreach {d1 y1 d2 y2} [.c coords $p] {break}
	if {$y1>$ob(spd)} {
		set y1 $ob(spd)
	}
	.c coords $p [expr {($x1+$x2)/2}] $y1
}

proc dragyball {w y p} {
	global ob

	set y1 [expr {[.c canvasy $y] - $ob(bsize)}]
	set y2 [expr {$y1 + $ob(bsize)}]
	foreach {x1 d1 x2 d2} [.c coords $p] {break}
	.c coords $p $x1 [expr {($y1+$y2)/2}]
}

proc getxy {} {
	global ob

	set x [rshm x]
	set y [rshm y]

	set x_meters $x
	set y_meters $y

	set ob(shootspeed) [expr {($y-$ob(y_old2))/$ob(tick)}]
	set ob(y_old2) $y
	if {$ob(addspeed)} {
		incr ob(aggrspeed) $ob(shootspeed)
		lappend ob(speedtraj) $ob(shootspeed)
	}
	set x [expr int($ob(scale_ie) * $x + $ob(winwidth)/2)]
	set y [expr int(-$ob(scale_dp) * $y + $ob(ww,s)-2*$ob(padh))]

	if {!$ob(hdir)} {
		set cur_pos_pixels $x
		set cur_pos_meters $x_meters
		set vel [rshm xvel]
	    	set torque [rshm xvel]
		set dist_pixels [expr {$cur_pos_pixels -$ob(winwidth)/2}]
	} else {
		set cur_pos_pixels $y
		set cur_pos_meters $y_meters
		set vel [rshm yvel]
	    	set torque [rshm yvel]
		set dist_pixels [expr {$cur_pos_pixels -$ob(winheight)/2}]
	}
	# PMs
	lappend ob(dx_p) [expr {abs($cur_pos_pixels - $ob(trgt_pixels))}]
	lappend ob(dx) [expr {abs($cur_pos_meters - $ob(trgt))}]
	lappend ob(x) $cur_pos_meters
	lappend ob(speedtraj) $vel
	lappend ob(torque) $torque

	list $x $y
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

# did the ball fall off the table?
proc ballofftable {bbox} {
	global ob

	foreach {x1 y1 x2 y2} $bbox {break}
	if {
	($x1 < 0) ||
	($x2 > $ob(winwidth)) ||
	($y1 < 0) ||
	($y2 > $ob(winheight)) } {
		# puts "ball off table, bbox $bbox dir $ob(dir)"
		set y1_old $y1
		# throw the ball to the center of the table,
		# and send it back at half speed.
		foreach {x y} $ob(dir) {break}
		set bsize $ob(bsize)
		set cx $ob(half,x)
		set cy $ob(half,y)
		set x1 [expr {$cx - ($bsize / 2)}]
		set x2 [expr {$cx + ($bsize / 2)}]
		set y1 [expr {$cy - ($bsize / 2)}]
		set y2 [expr {$cy + ($bsize / 2)}]
		.c coords ball $cx $cy
		# slow it down, send it backwards
		set x [expr $x / -2.0]
		set y [expr $y / -2.0]
		set ob(dir) "$x $y"
		if {$y1_old<0} {
			after 200 {startball n}
		} else {
			after 200 {startball s}
		}
	}
}

# the ball was a goal.
proc hitwall {} {
	global ob

	.c delete pred
	set ob(ngoal) 0
	set ob(sgoal) 0
	if {$ob(motorforces_x) || $ob(motorforces_y)} {
		after 50 stop_movebox 0 		
	}
}

# the ball was saved
proc hitpaddle_s {} {
	global ob mob
	
	if {$ob(outofbounds)} { return }

	# this is for measuring shooting ball trajectory time 
	# goes together with ob(klik2) found in process shoot
	#set ob(klok2) [clock clicks -milliseconds]
	#set cl [expr {$ob(klok2)-$ob(klik2)}]
	#puts "time = $cl"
	.c delete pred

	if {$ob(sound)} {
		nbeep 5 A 50
	} 

	set ob(sgoal) 0	
	set ob(sgk_D_B) 1
	set ob(sgk_S) 1
	set ob(sgk_D) 0
	set ob(itspaddle) 1

	if {$ob(kickoff)} {
		if {$ob(motorforces_y)} {
			if {!$mob(novisual)} {
				set ob(target) [.c create oval [expr {$ob(half,x)-4}] [expr {$ob(half,y)-4}] \
				[expr {$ob(half,x)+4}] [expr {$ob(half,y)+4}] -fill $ob(predfill2) -outline $ob(predout2) -width 1 -tag pred]]
			}
			set ob(sgoaly) $ob(trgt_dp)
			set dest [list 0.0 $ob(sgoaly)]
			set ob(hdir) 1
			set ob(trgt) $ob(sgoaly)
			set ob(trgt_pixels) [expr int(-$ob(scale_dp) * $ob(trgt) + $ob(half,y))]
			adap_moveit {0 $ob(slotticks) 1} $dest
		} else {
			stop_movebox 0
		}
		set ob(kickoff) 0
	} else {
		set ob(same_slot) 0
		incr mob(saves)
		incr ob(turns)
		do_title
		updateClock 	
		if {$ob(motorforces_x)} {
			if {!$mob(novisual)} {
				set ob(target) [.c create oval [expr {$ob(half,x)-4}] [expr {$ob(spd)+$ob(padh)/2-4}]  \
				[expr {$ob(half,x)+4}] [expr {$ob(spd)+$ob(padh)/2+4}]  -fill $ob(predfill2) -outline $ob(predout2) -width 1 -tag pred]]
			}
			enter_target_do_adaptive
			set ob(sgoalx) 0
			set dest [list $ob(sgoalx) 0.0]
			set ob(hdir) 0
			set ob(trgt) $ob(sgoalx)
			set ob(trgt_pixels) [expr int($ob(scale_ie) * $ob(trgt) + $ob(half,x))]
			adap_moveit {0 $ob(slotticks) 1} $dest	
		} else {
			stop_movebox 0
		}
	}
}

proc hitpaddle_n {} {
	global ob mob

	set ob(ndefended) 1

	set ob(moveback) 1
	if {$ob(sound)} {
 		nbeep 3 E 50
	} 
	if {$ob(kickoff)} {
		set ob(kickoff) 0
	} else {
		set mob(goalrow) 0
	}
	do_title
}	

proc do_title {} {
	global ob mob
	updateClock
	wm title . "Soccer   Name: $mob(whoN)   Turns: $ob(turns)"
}

proc defend {bbox xr yr i} {
	global ob
	if {$i == "s"} {
		if {$ob(motorforces_x) || $ob(motorforces_y)} {
			stop_movebox 0
		}
	}
	predict2 $bbox $xr $yr $i
}

proc adap_moveit {forlist dest} {
	global ob mob

    	set forlist [uplevel 1 [list subst -nocommands $forlist]]
    	set dest [uplevel 1 [list subst -nocommands $dest]]

	set x [rshm x]
	set y [rshm y]

	if {!$ob(hdir)} {
		set src [list $x 0.0 0.0 0.0]
    		set nx1 [lindex $src 0]
    		set nx2 [lindex $dest 0]
		set y1 $y
		set ob(slotlength) [expr {abs($nx2-$x)}]
		ctadd slotlength40 $ob(slotlength)
	} else {
		set src [list 0.0 $y 0.0 0.0]
    		set nx1 [lindex $src 1]
    		set nx2 [lindex $dest 1]
		set y1 $x
		set ob(slotlength) [expr {abs($nx2-$y)}]
		ctadd slotlength40 $ob(slotlength)
	}

	# starting to check if the patient moved during the time slot
	after 100 [list start_check]	
	
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
    	clear_slot_metrics

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
	set ob(klikslot) [clock clicks -milliseconds]
}

# the main loop
proc moveball {} {
	global ob mob

	if {!$ob(ndefended) && !$ob(sgk_D_B)} {
		eval .c move ball $ob(dir)
		set mob(balldir) $ob(dir)
	}

	# see if the ball has hit anything - paddle or wall.
	set bbox [.c bbox ball]
    	set ob(bbox) $bbox

	ballofftable $bbox

	set ob(bat) [lindex [eval .c find overlapping $bbox] 0]
	if {$ob(bat) == $ob(field)} {
		set ob(bat) [lindex [eval .c find overlapping $bbox] 1]
	}

	# lastbat hack prevents wobbles
	if {$ob(bat) != $ob(ball)
		&& $ob(bat) != $ob(lastbat)
		&& $ob(bat) != $ob(line)
		&& $ob(bat) != $ob(circle)
		&& $ob(bat) != $ob(gkarea1,s)	
		&& $ob(bat) != $ob(gkarea2,s)	
		&& $ob(bat) != $ob(gkarea3,s)	
		&& $ob(bat) != $ob(gkarea1,n)	
		&& $ob(bat) != $ob(gkarea2,n)	
		&& $ob(bat) != $ob(gkarea3,n)
		&& $ob(bat) != $ob(field)
		} {
		set forw [expr {1.0 + (($ob(forw) + [irand $ob(forw)])/50.0)}]
		set side [expr {(0.0 - $ob(side) + [irand $ob(side)])/50.0}]
		
		foreach {oxr oyr} $ob(dir) {break}

		switch $ob(bat) $ob(pad,n) {
		        set xr $side
		        set yr $forw
		        hitpaddle_n
		} $ob(pad,s) {
		        set xr $side
		        set yr [expr {0 - $forw}]
		        hitpaddle_s      
		} $ob(wall,ne) {
		        if {$ob(livewall,n)} {
		                set xr $side
		                set yr $forw
		                hitwall
		                shake $ob(bat)
		        } else {
		                set xr $oxr
		                set yr [expr {0 - $oyr}]
				defend $ob(bbox) $xr $yr n	
		        }
		} $ob(wall,nw) {
		        if {$ob(livewall,n)} {
		                set xr $side
		                set yr $forw
		                hitwall
		                shake $ob(bat)
		        } else {
		                set xr $oxr
		                set yr [expr {0 - $oyr}]
				defend $ob(bbox) $xr $yr n
		        }
		}	$ob(wall,se) {
		        if {$ob(livewall,s)} {
		                set xr $side
		                set yr [expr {0 - $forw}]
		                hitwall
		                shake $ob(bat)
		        } else {
		                set ob(sgoal) 0
				set xr $oxr
		                set yr [expr {0 - $oyr}]
				defend $ob(bbox) $xr $yr s
		        }
		}	$ob(wall,sw) {
		        if {$ob(livewall,s)} {
		                set xr $side
		                set yr [expr {0 - $forw}]
		                hitwall
		                shake $ob(bat)
		        } else {
				set ob(sgoal) 0
		                set xr $oxr
		                set yr [expr {0 - $oyr}]
				defend $ob(bbox) $xr $yr s
		        }
		} $ob(wall,w) {
		        if {$ob(livewall,w)} {
		                set xr $forw
		                set yr $side
		                hitwall
		                shake $ob(bat)
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
		        } else {
		                set xr [expr {0 - $oxr}]
		                set yr $oyr
		        } 
		} $ob(wallgp,n) {
		        if {$ob(livewallgp,n)} {
		                set xr [expr {$side/10.}]
				set yr [expr {-$forw/10.}]
				hitwall
				if {$ob(sound)} {
					nbeep 5 C 300
				}
		                shake $ob(bat)
				incr mob(redscore)
				incr mob(goalrow)
				if {$mob(goalrow) > $mob(maxinrow)} {
					set mob(maxinrow) $mob(goalrow)
				}
				after 1000 startball n
		        } else {
		                set xr $oxr
		                set yr [expr {0 - $oyr}]
		        }
		} $ob(wallgp,s) {
		        if {$ob(livewallgp,s)} {
				set xr [expr {$side/10.}]
				set yr [expr {($forw)/10.}]
		                hitwall
 				if {$ob(sound)} {
					nbeep 1 A 500
				}
				incr ob(turns)
				set ob(itsgoal) 1
				set ob(same_slot) 0 
		                shake $ob(bat)
				incr mob(bluescore)
				after 1000 startball s
		        } else {
		                set xr [expr {0 - $oxr}]
		                set yr $oyr
		        } 
		} $ob(wall,w) {
		        if {$ob(livewallgp,w)} {
		                set xr $forw
		                set yr $side
		                hitwall
		                shake $ob(bat)
		        } else {
		                set xr [expr {0 - $oxr}]
		                set yr $oyr
		        } 
		} $ob(wall,e) {
		        if {$ob(livewallgp,e)} {
		                set xr [expr {0 - $forw}]
		                set yr $side
		                hitwall
		                shake $ob(bat)
		        } else {
		                set xr [expr {0 - $oxr}]
		                set yr $oyr
		        }
		} default {
			error "woops! switch default should not get here, bat = $ob(bat)"
		}
		
		# set new direction.
		set ob(dir) "$xr $yr"                

		set ob(lastbat) $ob(bat)
		}
	# end of ball hits thing, schedule a new
	
	foreach {x y} [getxy] break

	if {!$ob(sgk_D_B)} {
	# ball moves towards south wall, but not yet defended from the goalkeeper
		dodrag .c $x $y
	} else { 
		dodragball .c $x $y		
	} 

	# for moving north goalkeeper
	if {$ob(ngoal)} {
		movegoalkeeper
	}
	if {$ob(ndefended)} { 
		if {$ob(moveback)} {
			movegoalkeeperback
		} 
		if {$ob(attack)} {
			start_attack
		} 
	}
	if {$ob(moveback_v)} {
		movegoalkeeperback_v
	}

	if {$ob(move_ie)} {
		set dest [list $ob(sgoalx) 0.0]
		set ob(hdir) 0
		set ob(trgt) $ob(sgoalx)
		set ob(trgt_pixels) [expr int($ob(scale_ie) * $ob(trgt) + $ob(half,x))]
		adap_moveit {0 $ob(slotticks) 1} $dest
		set ob(move_ie) 0
	}

	# did the patient move?
	if {$ob(check_move)} {
		adap_check_vel
	}

	# every $ob(ticks) ms, the ball moves
	if {$ob(endgame) <= 0 || $ob(turns) <= $ob(endgame)} {
		if {$ob(paused)== "no"} { 
			set ob(after) [after $ob(tick) moveball]
		}
	}
}

# logging
# open logfile-per-section
proc start_section_start_log {} {
	global ob mob

  	if {$ob(savelog)} {
		if {$ob(turns) % 10 == 0} {
			set ob(pauses_count) 0
			set secnum [expr {1+$ob(turns) / 10}]
			set ob(tailname) [file tail $ob(gamename)]
			set slotlogfilename [join [list $ob(tailname) $ob(timestamp)_s_$secnum.dat] _]
			set slotlogfilename [file join $ob(dirname) $slotlogfilename]
			start_log $slotlogfilename $ob(logvars)
			puts "logging Section $secnum in $slotlogfilename"
		} else {
			set secnum [expr {1+$ob(turns) / 44}]
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



proc prepare_logging {} {
	global ob mob env argc argv

    # game name and patient name
    # they come in as command line args, usually from the
    # cons "game console" program
    # in a HIPAA setting, the patient name will be a numeric ID.
    set ob(logdirbase) $::env(THERAPIST_HOME)

    set ob(gamename) games/ther/soccer_log
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

	if {$ob(planar)} {
		# Logging function 
		# for the lab, uncomment the following line and comment the one that corresponds to the pediatric anklebot.
		# set ob(logfnid) 17
		# for the pediatric anklebot
		set ob(logfnid) 15
		set ob(logvars) 20
    	} 

	# shall we log each slot in its own file?
	set ob(logperslot) no

    	set curtime [clock seconds]
    	set ob(datestamp) [clock format $curtime -format "%Y%m%d_%a"]
    	set ob(timestamp) [clock format $curtime -format "%H%M%S"]
    	set ob(dirname) [file join $ob(logdirbase) $ob(patname) $ob(gametype) $ob(datestamp) soccer ]

    	if {$mob(savelog)} {
		wshm logfnid $ob(logfnid)
    	}
}

# set up the menu (once)
proc domenu {} {
	global env mob ob
	set m [menu_init .menu]
	menu_v $m who "Player's ID" $env(PATID)
	menu_v $m whoN "Player's Name" Player
	menu_v $m comp "Opponent's Name" Computer
	menu_v $m endgame "Game Length (turns)" 80
	menu_v $m padw "Goalkeeper Width (1-25)" 12
	menu_v $m level "Speed level (1-25)" 12
	
	frame $m.stiff
	label $m.stiff.stiff_label -text "Stiffness:"
	set mob(menu,stiff) 80
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

	frame $m.rom
 	label $m.rom.rom_label -text "Range of Motion:"
	set ob(dsoccer,rom) medium_rom
	radiobutton $m.rom.rom_short -text [imes "Short ROM"] \
		-variable ob(dsoccer,rom) -relief flat -value short_rom
	    radiobutton $m.rom.rom_medium -text [imes "Medium ROM"] \
		-variable ob(dsoccer,rom) -relief flat -value medium_rom
	    radiobutton $m.rom.rom_long -text [imes "Long ROM"] \
		-variable ob(dsoccer,rom) -relief flat -value long_rom
	pack $m.rom -anchor w
	pack $m.rom.rom_label -anchor w
	pack $m.rom.rom_short -anchor w
	pack $m.rom.rom_medium -anchor w
	pack $m.rom.rom_long -anchor w

	menu_t $m blank0 "" ""
	set mob(savelog) 1
	menu_cb $m "savelog" "Logging"
	menu_t $m blank1 "" ""
	menu_cb $m "accuracy" "Challenge with accuracy"
	menu_cb $m "nomotorforces_y" "No Motor Forces (D/P)"
	menu_cb $m "nomotorforces_x" "No Motor Forces (I/E)"
	menu_t $m blank2 "" ""
	menu_cb $m "novisual" "No Visual Aid"
	menu_cb $m "audio" "No Audio"
	menu_t $m blank3 "" ""

	menu_t $m saves Saves
	menu_t $m shots Shots
	menu_t $m goalrow "Current Streak"
	menu_t $m maxinrow "Longest Streak"
	menu_b $m newgame "New Game (n)" new_soccer
	menu_b $m stopgame "Stop Game (s)" stop_soccer
	menu_b $m quit "Quit (q)" {done}
}

proc done {} {
	stop_log
	stop_soccer
	stop_rtl
	exit
}

init_soccer
