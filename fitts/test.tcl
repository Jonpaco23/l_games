package require Tk

global ob

set ob(ctl) 26
set env(PATID) 1

set ob(crobhome) $::env(CROB_HOME)
source $ob(crobhome)/shm.tcl


source ../common/util.tcl
source ../common/menu.tcl
source $::env(I18N_HOME)/i18n.tcl


localize_robot

if {[is_lkm_loaded]} {
        puts "lkm already loaded."
} else {
        start_lkm
}
start_shm
#start_loop

start_log /home/testac/lgames/fitts/tmpEEG/xy.dat 9
after 200
stop_log
exit
