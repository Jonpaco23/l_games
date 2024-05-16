#! /usr/bin/wish
#
# This is to test an EEG Experiment
#
# Developed by:
# Konstantinos Michmizos (konmic@mit.edu), Summer 2012
#
# Adapted by Nick Georgiou
#  
# Used with the InMotion ArmBot

# Tk GUI library
package require Tk

global ob
# this controls the controller's function
set ob(ctl) 26

# unconventional hack. This should come from the UI
set env(PATID) 1

# These are all folders that are needed for some of the robot commands used throughouut the game
set ob(crobhome) $::env(CROB_HOME)
source $ob(crobhome)/shm.tcl
source ../common/util.tcl
source ../common/menu.tcl
source $::env(I18N_HOME)/i18n.tcl

# is this arm bot? (of course)
localize_robot

stop_lkm

# Before opening the game, the robot should be calibrated. This is done by going to the crob/tools folder and running ./plcenter
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
	#wm protocol . WM_DELETE_WINDOW quit
        start_lkm
}

start_shm
start_loop
after 100

#wshm no_safety_check 1
#wshm stiff 100
#wshm damp 5
#wshm slot_max 4
wshm Hz 100
proc init_Fitts {} {

	global ob
	

	set ob(triggerList) {}
	set ob(timeIDList) {}
	set ob(eventID) 0
	set ob(cross) 0
	set ob(leftOrDownFlag) 0
	set ob(rightOrUpFlag) 0
	set ob(middleFlag) 0
	#set ob(movingFlag) 0
	set ob(movingLeftFlag) 0
	set ob(movingRightFlag) 0
	set ob(movingUpFlag) 0
	set ob(movingDownFlag) 0
	set ob(movingInFlag) 0
	set ob(movingOutFlag) 0
	set ob(targetPresentFlag) 0
	set ob(previous) 0.0
    	set ob(programname) EEG_Experiment
	set ob(savelog) 1
    	set ob(asklog) 1
	set ob(curtime) [clock seconds]
	set ob(timestamp) [clock format $ob(curtime) -format "%H%M%S"]
	

	set ob(target) 0
	set ob(left_frame) 0
	set ob(right_frame) 0
	set ob(upper_frame) 0
	set ob(bottom_frame) 0

	set ob(endgame) 60
	set ob(numTrials) 0
	set ob(trials) [expr {$ob(endgame) / 2.}]
	set ob(running) 0
	set ob(test) 0

	# this flag secures single game running
	set ob(n_games) 0

	set ob(Fitts,rom) long_rom
	set ob(jitter_time) 800
	set ob(hdir) 0
    	set ob(scale) 1500.0
    	set ob(winwidth) .44
    	set ob(winheight) .44
	set ob(half,x) [expr {$ob(winwidth) / 2.}]
    	set ob(half,y) [expr {$ob(winheight) / 2.}]
	if {$ob(hdir) == 1} {
		set ob(target_height) 0.06
		set ob(target_width) 0.09
	} elseif {$ob(hdir) == 0} {
		set ob(target_height) 0.09
		set ob(target_width) 0.06
	}
	
   	set ob(side) .000
    	set ob(side2) [expr {$ob(side) * 2.}]

    	set ob(npos) 8
	set ob(targets_created) 0
	set ob(targets_hit) 0
	# creating the canvas
    	wm withdraw .

	domenu
	

    	set ob(can,x) 1000
    	set ob(can,y) 1000
    	set ob(can2,x) [expr {$ob(can,x) / 2.}]
   	set ob(can2,y) [expr {$ob(can,y) / 2.}]

	canvas .c -width $ob(can,x) -height $ob(can,y) -bg white
		
	grid .c
	wm geometry . 1015x690
	#wm geometry . 1800x1020
	. config -bg gray20
	place .c -relx 0.5  -rely 0.5 -anchor center

	#label .disp -textvariable 5 -font {Helvetica 72} -bg gray20 -fg black
    	#place .disp -in . -relx 1.0 -rely 0.0 -anchor se

	.c config -bd 2
	.c config -highlightthickness 2
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

	wshm no_safety_check 1
        wshm event_id 0
	wshm t_width 0
	
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
	set ob(count) 0
	
	set width $ob(target_width)
	
	#read these "random" features from pre-generated random lists
	
	#This is for "random" target widths
	set fp [open "width_list.txt" r]
	set ob(ltarget_width) [read $fp]
	close $fp
	
	#This is for "random" jitter times
	set fp [open "jittersList.txt" r]
	set ob(jitter_list) [read $fp]
	close $fp

	#This is for "random" next target location (left or right, up or down)
	set fp [open "nextTargetList.txt" r]
	set ob(nextTarget_list) [read $fp]
	close $fp
	
	# if it is passive
	if {$ob(fitts,var)==3} {
	    	center_arm
		after 2500
	}
	
	#This creates the list with the target locations (3.5 is the middle)
    	for {set ind 0} {$ind < [expr {$ob(test)}]} {incr ind} {	
		
		if { [lindex $ob(nextTarget_list) $ind] == 0 } {
			lappend the_list $min
			lappend the_list 3.5
		} else {
			lappend the_list $max
			lappend the_list 3.5
		}
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

	set ob(racer) [.c create $shape 0 0 .1 .1 -outline "" \
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
	set x 0.0
	set y 0.0
	set x [getptr x]
 	set y [getptr y]
	set velx [expr {abs([rshm xvel])}]
	set vely [expr {abs([rshm yvel])}]
	set xvel1 [rshm xvel]
	set yvel1 [rshm yvel]
	
	# This is for checking if the robot is moving up or down
	# A trigger will be sent depending on which direction the robot is moving in and a trigger will be sent at most once per trial
	if {$vely >= 0.01} {
		if {($ob(movingUpFlag) != 1 || $ob(movingDownFlag) != 1) && $ob(numTrials) != $ob(endgame)/2.} {
		    if {$yvel1 < 0 && $ob(movingUpFlag) != 1 && $ob(targetPresentFlag) == 1} {
			   
			    if {$ob(tarNum) == 3.5} {
				 if {($ob(hdir) == 0 || ($ob(hdir) ==2 && $ob(cross)%2==1))} {
					 set ob(movingUpFlag) 1
					 wshm event_id 10
			         	 set command [exec python TriggerTests.py 10]
					 puts $command
					 puts "Trigger 10 sent! I am moving down inward!"
				 } 
			    } elseif {$ob(tarNum) == 0} {
				 if {($ob(hdir) == 0 || ($ob(hdir) ==2 && $ob(cross)%2==1))} {
					 set ob(movingUpFlag) 1
					 wshm event_id 11
			         	 set command [exec python TriggerTests.py 11]
					 puts $command
					 puts "Trigger 11 sent! I am moving down outward!"
				 } 
			    }
		    } elseif {$yvel1 > 0 && $ob(movingDownFlag) != 1 && $ob(targetPresentFlag) == 1} {
			  
			   
		            
			    if {$ob(tarNum) == 3.5} {
				 if {$ob(hdir) == 0 || ($ob(hdir) ==2 && $ob(cross)%2==1)} {
					  set ob(movingDownFlag) 1
					 wshm event_id 14
			         	 set command [exec python TriggerTests.py 14]
					 puts $command
					 puts "Trigger 14 sent! I am moving up inward!"
				 } 
			    } elseif {$ob(tarNum) == 7} {
				 if {$ob(hdir) == 0 || ($ob(hdir) ==2 && $ob(cross)%2==1)} {
					         set ob(movingDownFlag) 1
						 wshm event_id 15
					 	 set command [exec python TriggerTests.py 15]
						 puts $command
						 puts "Trigger 15 sent! I am moving up outward!"
					 
				 } 
			    }
		    }
		  
		}
	} 


	# This is for checking left/right movement
	if {$velx >= 0.01} {
		if {($ob(movingLeftFlag) != 1 || $ob(movingRightFlag) != 1) && $ob(numTrials) != $ob(endgame)/2.} {
		    if {$xvel1 < 0 && $ob(movingLeftFlag) != 1 && $ob(targetPresentFlag) == 1} {
			   
			   
			    
			    if {$ob(tarNum) == 3.5} {
					
				 if {$ob(hdir) == 1 || ($ob(hdir) ==2 && $ob(cross)%2==0) && $ob(targets_created) > 1} {
					 set ob(movingLeftFlag) 1
					 wshm event_id 1
				    	 set command [exec python TriggerTests.py 1]
					 puts $command
					 puts "Trigger 1 sent! I am moving left inward!"
				 } 
			    } elseif {$ob(tarNum) == 0} {
				 if {$ob(hdir) == 1 || ($ob(hdir) ==2 && $ob(cross)%2==0) && $ob(targets_created) > 1} {
                                         set ob(movingLeftFlag) 1
					 wshm event_id 9
					 set command [exec python TriggerTests.py 9]
					 puts $command
					 puts "Trigger 9 sent! I am moving left outward!"
				 }
			    }
		    } elseif {$xvel1 > 0 && $ob(movingRightFlag) != 1 && $ob(targetPresentFlag) == 1} {
			   
			    if {$ob(tarNum) == 3.5} {
				 if {$ob(hdir) == 1 || ($ob(hdir) ==2 && $ob(cross)%2==0) && $ob(targets_created) > 1} {
					 set ob(movingRightFlag) 1
					 wshm event_id 12
				    	 set command [exec python TriggerTests.py 12]
					 puts $command
					 puts "Trigger 12 sent! I am moving right inward!"
				 } 
			    } elseif {$ob(tarNum) == 7} {
				 if {$ob(hdir) == 1 || ($ob(hdir) ==2 && $ob(cross)%2==0)} {
					         set ob(movingRightFlag) 1
						 wshm event_id 13
						 set command [exec python TriggerTests.py 13]
						 puts $command
						 puts "Trigger 13 sent! I am moving right outward!"
					
				 } 
			    }
		    }
		  
		}
	} 
	
	# This is to check if the robot is in the middle of the screen and checks for all game conditions (left/right, up/down, and cross). It will be sent at most once per trial
	if {$ob(fitts,var)<=3} {
		if {($x >= -0.001 && $x <= 0.001 && $ob(hdir) == 1) || ($y >= -0.001 && $y <= 0.001 && $ob(hdir) == 0) || ($ob(hdir) == 2 && $ob(cross)%2 == 0 && $x >= -0.01 && $x <= 0.01) || ($y >= -0.01 && $y <= 0.01 && $ob(hdir) == 2 && $ob(cross)%2 == 1)} {
			if {$ob(middleFlag) != 1 && ($ob(leftOrDownFlag) == 1 || $ob(rightOrUpFlag)==1)} {
				set ob(middleFlag) 1
				wshm event_id 3
				set command [exec python TriggerTests.py 3]
				puts $command
				puts "Trigger 3 sent! I am in the middle!"
			}
		}
		if {$ob(hdir) == 1 || ($ob(hdir) ==2 && $ob(cross)%2==0)} {
			dragx $w $x racer	
		} elseif {$ob(hdir) == 0 || ($ob(hdir) ==2 && $ob(cross)%2==1)} {
			dragy $w $y racer
		}
	}

	set cur_pos $y
	set ob(cur_pos) $cur_pos
	
	#Only when the robot has slowed down will it be checked if a target has been hit
	if {[expr {abs($velx)}]<0.001} {
			check_target
	}
	after 5 do_drag .c
}

# This is for left/right movement
proc dragx {w x what} {
	
	global ob

	set x1 [bracket $x -[expr 2*$ob(half,x)] [expr 2*$ob(half,x)]]
	set x1 [expr {$x1 - $ob(racw2)}]
	set x2 [expr {$x1 + $ob(racw)}]
	set y1  [expr {0-$ob(racw2)}]
	set y2 [expr {$y1 + $ob(rach)}]
        .c coords $what $x1 $y1 $x2 $y2
	
	.c scale $what 0 0 $ob(scale) -$ob(scale)
}

#This is for up/down movement
proc dragy {w y what} {
	global ob

	set y1 [bracket $y -[expr 2*$ob(half,y)] [expr 2*$ob(half,y)]]
	set y1 [expr {$y1 - $ob(racw2)}]
	set y2 [expr {$y1 + $ob(racw)}]
	set x1  [expr {0-$ob(racw2)}]
	set x2 [expr {$x1 + $ob(rach)}]
        .c coords $what $x1 $y1 $x2 $y2
	.c scale $what 0 0 $ob(scale) -$ob(scale)
}


proc new_Fitts {} {
		
	#This trigger is sent once the experiment begins
	wshm event_id 0
	set command [exec python TriggerTests.py 0]
	puts $command
	puts "Trigger 0 sent! Experiment begun!"
					
	global ob mob

	incr ob(n_games) 

	if {$ob(n_games) > 1} {
		error [imes "First press 'Stop Experiment (s)' and then 'New Experiment (n)'"]
	}
	set ob(running) 1

	
	set ob(test) $mob(test)
	set ob(step) .01
	set ob(fitts,var) $mob(fitts,var)
	set ob(fitts,speed) $mob(fitts,speed)
	set ob(target_widths) {}

	if {$ob(fitts,var)==0} {
		set ob(session_movements) 10
	} else {
		set ob(session_movements) 20
	} 

	set ob(endgame) [expr {int($ob(test))*2}]		
	
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

	set ob(target) [.c create rect 0 0 .05 .05 -fill white -tag target -outline black -width 4]
	.c scale target 0 0 $ob(scale) -$ob(scale)
	
	show_target
	}

proc show_target {} {
	global ob
	
	set i $ob(targets_created)
	set j $ob(targets_hit)
	set k $ob(numTrials)
	
	# Experiment will end and trigger will be sent
	if {$k >= [expr {$ob(endgame)/2.}]} {
		wshm event_id 8
		set command [exec python TriggerTests.py 8]
		puts $command
		puts "Trigger 8 sent! The experiment has ended"
		done
	}
	
	set ob(target_width) [lindex $ob(ltarget_width) $i]
	
	lappend ob(target_widths) $ob(target_width)

    	set randi [lindex $ob(targets_list) $i]
	set ob(tarNum) $randi
	
    	set spacing [expr {($ob(winwidth) - ($ob(side2) + $ob(target_width)))/double($ob(npos)-1)}]
	
	set x1 [expr {$ob(side) - $ob(half,x) + $spacing * $randi}]
	set y1 [expr {0 - $ob(target_height)/2.0}]
	set x2 [expr {$x1 + $ob(target_width)}]
	set y2 [expr {0 + $ob(target_height)/2.0}]
	
	set ob(left_frame) $x1
	set ob(right_frame) $x2
	set ob(upper_frame) $y1
	set ob(bottom_frame) $y2
	
	#First condition is for left/right movement and else condition is for up/down movement
	if {$ob(hdir) == 1 || ($ob(hdir) ==2 && $ob(cross)%2==0)} {
		eval .c coords target [list $x1 $y1 $x2 $y2]
	} elseif {$ob(hdir) == 0 || ($ob(hdir) ==2 && $ob(cross)%2==1)} {
		eval .c coords target [list $y1 $x1 $y2 $x2]
	}
	
	.c scale target 0 0 $ob(scale) -$ob(scale)
	.c raise racer target
	
	set velx [expr {abs([rshm xvel])}]
	set vely [expr {abs([rshm yvel])}]
	
	wshm t_width $ob(target_width)
	#puts $ob(target_width)

	#Trigger sent when a new target appears
	wshm event_id 7
	set command [exec python TriggerTests.py 7]
	puts $command
	puts "Trigger 7 sent! New target has appeared"
	
	
	set ob(targetPresentFlag) 1

	incr ob(targets_created)

	
	
	
	if {$ob(tarNum) != 3.5} {
		incr ob(targets_hit)
	}

	#This is for passive when the robot is moving without patient assistance
	if {$ob(fitts,var)==3} {
		after 200
			
		if {$ob(tarNum) == 0} {
			#This is for min (zero)
			moveArm $ob(previous) -0.22
			set ob(previous) -0.22
		} elseif {$ob(tarNum) == 7} {
			#This is for max (7)
			moveArm $ob(previous) 0.22
			set ob(previous) 0.22
		} elseif {$ob(tarNum) == 3.5} {
			#This is to stop in the middle and end the trial
			moveArm $ob(previous) 0.0
			set ob(previous) 0.0
		}
		after 300			
	}
}

#make the time a variable
proc check_target {} {
	global ob

	set bbox [.c bbox $ob(racer)]
	
	set hit [lindex [eval .c find overlapping $bbox] 1]

	#puts "S"
	#puts $bbox
	

	set i $ob(targets_created)
	
	set hit2 0
	
	#puts "RACER"
	set racerLeft [lindex [.c bbox $ob(racer)] 0]
	#puts $racerLeft
	set racerRight [lindex [.c bbox $ob(racer)] 2]
	#puts $racerRight
	set racerDown [lindex [.c bbox $ob(racer)] 1]
	#puts $racerDown
	set racerUp [lindex [.c bbox $ob(racer)] 3]
	#puts $racerUp

	#puts "TARGET"

	set targetLeft [lindex [.c bbox $ob(target)] 0]
	#puts $targetLeft
	set targetRight [lindex [.c bbox $ob(target)] 2]
	#puts $targetRight
	set targetDown [lindex [.c bbox $ob(target)] 1]
	#puts $targetDown
	set targetUp [lindex [.c bbox $ob(target)] 3]
	#puts $targetUp

	if {$ob(hdir) == 1 || ($ob(hdir) ==2 && $ob(cross)%2==0)} {
		if {$racerLeft >= $targetLeft && $racerRight <= $targetRight} {
			#puts "HEREEEEEEEEEEEEEE"
			set hit2 1
			#puts $hit2
		   } 
	} else {
		if {$racerDown >= $targetDown && $racerUp <= $targetUp} {
			#puts "NOT"
			set hit2 1
		}

	}

        
	if {$hit2 > 0} {
	    puts $ob(target)
	    .c delete $ob(target)
	    set ob(targetPresentFlag) 0
	    	if { ($ob(leftOrDownFlag) == 1 || $ob(rightOrUpFlag) == 1)} {
				incr ob(numTrials)
				set ob(leftOrDownFlag) 0
				set ob(rightOrUpFlag) 0
				set ob(middleFlag) 0
				set ob(movingLeftFlag) 0
				set ob(movingRightFlag) 0
				set ob(movingUpFlag) 0
				set ob(movingDownFlag) 0
				set ob(movingInFlag) 0
				set ob(movingOutFlag) 0
				puts "Stopped in the middle! Trial $ob(numTrials) Complete!"
									
				#after [lindex $ob(jitter_list) $i]	
				incr ob(cross)	

		} elseif {$ob(tarNum) == 0 || $ob(tarNum) == 1 || $ob(tarNum) == 2} { 
			if {$ob(leftOrDownFlag) != 1} {
				set ob(leftOrDownFlag) 1
				if {$ob(hdir) == 1 || ($ob(hdir) ==2 && $ob(cross)%2==0)} {
					wshm event_id 2
					set command [exec python TriggerTests.py 2]
					puts $command
					puts "Trigger 2 sent! Left target has been hit"
				} else {
					wshm event_id 5
					set command [exec python TriggerTests.py 5]
					puts $command
					puts "Trigger 5 sent! Down target has been hit"
				}
				
			}
		} elseif {$ob(tarNum) == 5 || $ob(tarNum) == 6 || $ob(tarNum) == 7} {
			    if {$ob(rightOrUpFlag) != 1} {
				set ob(rightOrUpFlag) 1
				if {$ob(hdir) == 1 || ($ob(hdir) ==2 && $ob(cross)%2==0)} {
					wshm event_id 4
					set command [exec python TriggerTests.py 4]
					puts $command
					puts "Trigger 4 sent! Right target has been hit"
				} else {
					wshm event_id 6
					set command [exec python TriggerTests.py 6]
					puts $command
					puts "Trigger 6 sent! Up target has been hit"
				}
				puts "Move to and stop in the middle to complete this trial!"
					
			    }
		}	


		set ob(jitter_time) [lindex $ob(jitter_list) $i]
		after $ob(jitter_time) [list create_target]
		
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
	stop_lkm
	exit
}

proc do_title {} {
	global ob mob
	
	wm title . "EEG Game  ||  Name: $mob(whoN)  ||  Total Targets: [expr $ob(endgame)/2]  ||  Cleared Targets: $ob(targets_hit) || Total Trials: $ob(test) || Cleared Trials: $ob(numTrials)"
}


# game name and patient name
# they come in as command line args, usually from the
# cons "game console" program
# in a HIPAA setting, the patient name will be a numeric ID.
proc prepare_logging {} {
	global ob mob env argc argv

    	set ob(logdirbase) $::env(THERAPIST_HOME)

	set ob(gamename) games/exper/EEG_log
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
		set ob(whichgame) ""
		set ob(whichmode) ""
		set ob(whichspeed) ""

		if {$ob(hdir)==0} {
			set ob(whichgame) "up/down"
		} elseif {$ob(hdir)==1} {
			set ob(whichgame) "left/right"
		} else {
			set ob(whichgame) "cross"
		}	

		if {$ob(fitts,var)==3} {
			set ob(whichmode) "passive"
		} elseif {$ob(fitts,var)==2} {
			set ob(whichmode) "active"
		}


		if {$ob(whichmode) == "active"} {
			set ob(whichspeed) "N/A"
		} else {
			if {$ob(fitts,speed)==0} {
				set ob(whichspeed) "fast"
			} elseif {$ob(fitts,var)==1} {
				set ob(whichspeed) "medium"
			} elseif {$ob(fitts,var)==2} {
				set ob(whichspeed) "slow"
			}
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
}

# logging
# open logfile-per-section
proc start_experiment_start_log {} {
	global ob

    	if {$ob(savelog)} {
		
		set ob(afn) run1
		set ob(alogfnid) 22
		#set ob(alogfnid) 0
		set ob(anlog) 7
		#set curtime [clock seconds]
		set datestamp [clock format $ob(curtime) -format "%Y%m%d_%a"]
		#set timestamp [clock format $curtime -format "%H%M%S"]
		set fn $ob(afn).$ob(timestamp).dat
		set baselogdir /home/testac/lgames/fitts/
		set logdir [file join $baselogdir $datestamp]
		file mkdir $logdir
		set ob(logf) [file join $logdir $fn]
		set ob(nlog) $ob(anlog)

		wshm logfnid $ob(alogfnid)
		#puts id
		puts "writing log file $ob(logf)"
		puts "logger $ob(alogfnid), $ob(nlog) items."
		
		puts "started at [clock format [clock seconds]]"
		
		start_log $ob(logf) $ob(nlog)

	    	set tailname [file tail $ob(gamename)]
	    	set filename [join [list $tailname $ob(timestamp)] _]
	    	set filename [file join $ob(dirname) $filename]
#	    	file mkdir $ob(dirname)
		file mkdir $logdir		
	    	set logf [file join $logdir EEG_log_$ob(timestamp)_sectionmetrics.log]    
		set f [open $logf a+]
		
	    	puts $f "$ob(whichgame)\n$ob(whichmode)\n$ob(whichspeed)"
	    	close $f


    	}	
}

# close logfile-per-slot.
proc end_experiment_stop_log {} {
    	global ob
    
	if {$ob(savelog)} {
		
		stop_log

		puts "stopped at [clock format [clock seconds]]"

		stop_shm

		after 100

		puts "done"
    	}
}

proc moveArm {start finish} {
	global ob
	
	if {$ob(fitts,speed) == 2} {
		#slow
		set ticks 2000.0
	} elseif {$ob(fitts,speed) == 1} {
		#medium		
		set ticks 1500.0
	} else {
		#fast
		set ticks 1000.0
	}

	set type 0

	if {$ob(hdir) == 1 || ($ob(hdir) ==2 && $ob(cross)%2==0)} {
		movebox 0 $type {0 $ticks 1} \
		{$start, 0.0, 0.0, 0.0} \
		{$finish, 0.0, 0.0, 0.0}
	} elseif {$ob(hdir) == 0 || ($ob(hdir) ==2 && $ob(cross)%2==1)} {
		movebox 0 $type {0 $ticks 1} \
		{0.0, $start, 0.0, 0.0} \
		{0.0, $finish, 0.0, 0.0}
	}
	
}

proc domenu {} {
	global ob mob env

	set m [menu_init .menu]
	menu_v $m who "Player's ID" $env(PATID)
	menu_v $m whoN "Player's Name" Player
	#menu_v $m step "Target Decrement Step" 0.01
	menu_v $m test "Number of Trials" 100

	frame $m.dir
	label $m.dir.dir_label -text "Movement:"
	set mob(hdir) 1
	radiobutton $m.dir.dir_hriz -text [imes "Left/Right"] \
		-variable mob(hdir) -relief flat -value 1
	radiobutton $m.dir.dir_vert -text [imes "Up/Down"] \
		-variable mob(hdir) -relief flat -value 0
	radiobutton $m.dir.dir_cross -text [imes "Cross (Left/Right & Up/Down)"] \
		-variable mob(hdir) -relief flat -value 2
	
	pack $m.dir -anchor w
	pack $m.dir.dir_label -anchor w
	pack $m.dir.dir_hriz -anchor w
	pack $m.dir.dir_vert -anchor w
	pack $m.dir.dir_cross -anchor w
	
	menu_t $m blank5 "" ""
	
	frame $m.var
 	label $m.var.var_label -text "Select Experiment:"
	set mob(fitts,var) 2
	
	radiobutton $m.var.var_3 -text [imes "Active"] \
		-variable mob(fitts,var) -relief flat -value 2
	radiobutton $m.var.var_4 -text [imes "Passive"] \
		-variable mob(fitts,var) -relief flat -value 3
	radiobutton $m.var.var_5 -text [imes "Passive (No Visual)"] \
		-variable mob(fitts,var) -relief flat -value 4
	
	pack $m.var -anchor w
	pack $m.var.var_label -anchor w

	pack $m.var.var_3 -anchor w
	pack $m.var.var_4 -anchor w
	pack $m.var.var_5 -anchor w
	menu_t $m blank14 "" ""
	
	frame $m.speed
 	label $m.speed.speed_label -text "Select Speed for Passive:"
	set mob(fitts,speed) 2
	radiobutton $m.speed.speed_1 -text [imes "Fast"] \
		-variable mob(fitts,speed) -relief flat -value 0
	radiobutton $m.speed.speed_2 -text [imes "Medium"] \
		-variable mob(fitts,speed) -relief flat -value 1
	radiobutton $m.speed.speed_3 -text [imes "Slow"] \
		-variable mob(fitts,speed) -relief flat -value 2
	
	pack $m.speed -anchor w
	pack $m.speed.speed_label -anchor w
	pack $m.speed.speed_1 -anchor w
	pack $m.speed.speed_2 -anchor w
	pack $m.speed.speed_3 -anchor w
	
	menu_t $m blank15 "" ""

	menu_t $m log "     Automatic Logging" ""

	menu_t $m blank18 "" ""
	menu_b $m newgame "New Experiment (n)" new_Fitts
	menu_t $m blank19 "" ""
	menu_b $m stopgame "Stop Experiment (s)" stop_Fitts
	menu_t $m blank20 "" ""
	menu_b $m quit "Quit (q)" {done}
}

init_Fitts
