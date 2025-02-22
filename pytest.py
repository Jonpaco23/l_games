import Tkinter

root = Tkinter.Tk()

tcl_script = """

#!/usr/bin/tclsh

# print x/y in response to newline

puts "loading kernel module..."

# commands that talk to robot's shared memory buffer
source $::env(CROB_HOME)/shm.tcl

# start the Linux Kernel Modules, shared memory, and the control loop
start_lkm
start_shm
start_loop

# why after 100?
after 100

set in ""

puts "Newline to print, q to exit."

# print x,y and vx,vy in loop
while {$in != "q"} {
	puts "x=[rshm x], y=[rshm y],\
		vx=[rshm xvel], vy=[rshm yvel] (q to quit)"
	gets stdin in
}

puts "cleaning up kernel module..."
stop_loop
stop_shm
stop_lkm

"""

root.tk.call('eval', tcl_script)
root.mainloop()