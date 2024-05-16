#! /usr/bin/wish
#
# This is to create a pre-generated shuffled list of target widths
#
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


proc makeList {width step tarSize} {

	global ob

	for {set ind 0} {$ind < [expr 1.5*{$tarSize}]} {incr ind} {	
		if {($ind % 10) == 0 && $ind>0} {
			puts "WIDTH"
			puts $width
			puts $step
			set width [expr {$width - $step}]
		}
		lappend ob(ltarget_width) $width
	}

	# shuffle sorted list
	set ilistlast [llength $ob(ltarget_width)]
	incr ilistlast -1
	set ob(ltarget_width) [lrange [shuffle $ob(ltarget_width)] 0 $ilistlast]

	puts $ob(ltarget_width)
	puts [llength $ob(ltarget_width)]
	set data $ob(ltarget_width)
	set filename "width_list.txt"

	set fileId [open $filename "w"]

	puts -nonewline $fileId $data
	close $fileId


}

makeList 0.06 0.001 268