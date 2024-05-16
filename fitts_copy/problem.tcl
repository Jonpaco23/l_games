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

center_arm

stop_movebox