proc check_target {} {
#	global ob

#	set bbox [.c bbox $ob(racer)]
#	set hit [lindex [eval .c find overlapping $bbox] 1]
        
	#if {$hit > 0} {
	#	puts "HERE"
		.c delete $ob(target)

		if {$ob(tarNum) == 0 || $ob(tarNum) == 1 || $ob(tarNum) == 2} { 
			if($ob(zero) != 1} {
				set ob(zero) 1
				puts "Trigger 0 sent! Left target has been hit"
				set command [exec python TriggerTests.py 0]
				puts $command
				puts $ob(tarNum)
			}
		} else {
			if {$ob(one) != 1} {
		#		set ob(one) 1
		#		puts "Trigger 1 sent! Right target has been hit"
		#		set command [exec python TriggerTests.py 1]
		#		puts $command
		#		puts $ob(tarNum)
		#	}
	#	}
	        #wshm Fitts_target_maker 0
		#after 1000 [list create_target]
	 #   }
}
