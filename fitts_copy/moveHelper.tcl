#! /usr/bin/wish

# Tk GUI library
package require Tk

global ob

set ob(ctl) 26

# unconventional hack. This should come from the UI
set env(PATID) 1

set ob(crobhome) $::env(CROB_HOME)
source $ob(crobhome)/shm.tcl


source ../common/util.tcl
source ../common/menu.tcl
source $::env(I18N_HOME)/i18n.tcl

proc init_Fitts {} {

	global ob
    	set ob(scale) 1500.0
    	set ob(winwidth) .44
    	set ob(winheight) .44
	set ob(half,x) [expr {$ob(winwidth) / 2.}]
    	set ob(half,y) [expr {$ob(winheight) / 2.}]
	
   	set ob(side) .000
    	set ob(side2) [expr {$ob(side) * 2.}]

    	set ob(npos) 8
	
	# creating the canvas
    	wm withdraw .

	domenu
	set ob(hdir) 0
    	set ob(can,x) 1000	
    	set ob(can,y) 1000
    	set ob(can2,x) [expr {$ob(can,x) / 2.}]
   	set ob(can2,y) [expr {$ob(can,y) / 2.}]

	canvas .c -width $ob(can,x) -height $ob(can,y) -bg white
		
	grid .c
	wm geometry . 1015x690
	. config -bg gray20
	place .c -relx 0.5  -rely 0.5 -anchor center

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
	# changed ankle to planar
	wshm planar_damp 0.
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
	
	#set ob(helper) [.c create $shape 0 0 .4 .4 -outline red \
	#	-fill "" -tag helper]
	
	.c scale racer 0 0 $ob(scale) -$ob(scale)

	#.c scale helper 0 0 $ob(scale) -$ob(scale)
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

	#eval .c coords helper [swaps $x1 $y1 $x2 $y2]
	#.c scale helper 0 0 [expr $ob(scale)*4] [expr -$ob(scale)*4]
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
	
	radiobutton $m.var.var_3 -text [imes "Passive"] \
		-variable mob(fitts,var) -relief flat -value 2
	radiobutton $m.var.var_4 -text [imes "Active"] \
		-variable mob(fitts,var) -relief flat -value 3
	
	pack $m.var -anchor w
	pack $m.var.var_label -anchor w

	pack $m.var.var_3 -anchor w
	pack $m.var.var_4 -anchor w
	menu_t $m blank14 "" ""

	frame $m.speed
 	label $m.speed.speed_label -text "Select Speed for Passive:"
	set mob(fitts,speed) 0
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

