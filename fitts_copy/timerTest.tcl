#! /usr/bin/wish


label .counter -font {Helvetica 72} -width 3 -textvariable count
grid .counter -padx 100 -pady 100

for { set count 3 } { $count >= 0 } { incr count -1 } {
	update
	after 1000
} 

exit
