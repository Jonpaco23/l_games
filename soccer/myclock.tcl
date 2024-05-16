   proc make_clock {} {
           #setup global vars
           global pi     cirSize
           global secLength 
           global tikLength tk2Length tk3Length
           global inrLength n1pos     n2pos
           global secWidth 
           global font      
           global fnt2Size 
	   global mob ob

	set pi [pi] ;#save pi so we don't have to call the function everytime

	set font Helvetica
	#these values are distances relative to the canvas size
	set cirSize 0.95        ;#size of the circle
	#these values are calculated from the center of the circle
	#relative to canvas sizeset w [winfo width .clock];set cx [expr $w / 2]
	set h $ob(clcksize);
	set cy [expr $h /2]

   	set inrLength 0.03      ;#where the hands start
   	set secLength 0.45      ;#where the second hand ends
   	set tikLength 0.40      ;#where all ticks start
   	set tk2Length .43       ;#where the small ticks end
   	set tk3Length .475      ;#where the big ticks end
   	set n2pos 0.35          ;#placement of numbers 1-100
   	#width of hands, relative to canvas size
   	set secWidth .015       ;#second hand

   	#size of fonts, relative to canvas size
   	set fnt2Size 0.06	

           #create canvas objects, placement does not matter
           .clock create oval 5 5 195 195 -tags {circle} -fill gray90
           .clock create line 100 100 100 5  -width 9 -tags {hands secondhand} \
                   -fill red -capstyle round -smooth true	   place .clock -in . -relx 0.05 -rely 0.37

           #create ticks, and numbers 1-$mob(endgame)
           for {set i 1} {$i <= $mob(endgame)} {incr i} {
                   .clock create line 0 0 10 10 -tags tick$i -fill gray20
			if {[expr {$mob(endgame)<250}] && ![expr $i % 10]} {
        	           	.clock create text 0 0 -text $i -tags "nn nn$i"
			} elseif {[expr {$mob(endgame)>=250}] && [expr {$mob(endgame)<500}] && ![expr $i % 25]} {
	                   	.clock create text 0 0 -text $i -tags "nn nn$i"
			} elseif {[expr {$mob(endgame)>=500}] && ![expr $i % 100]} {
	                   	.clock create text 0 0 -text $i -tags "nn nn$i"
			}
           }
           #start the timer
           updateClock
   }

   proc updateClock {} {
           #globals
           global pi     cirSize
           global secLength 
           global tikLength tk2Length tk3Length
           global inrLength n1pos     n2pos
           global secWidth 
           global font      
           global fnt2Size 
	   global mob ob

	   set cx [expr $ob(clcksize) / 2]
           set cy [expr $ob(clcksize) /2]

	   set sp [expr {double($ob(turns))/double($mob(endgame))}]
	   #puts "sp = $sp mob(turns) =$ob(turns) endgame = $mob(endgame)"
           #move the circle
           set x1 [expr $cx - round(($ob(clcksize) / 2) * $cirSize)]
           set y1 [expr $cy - round(($ob(clcksize) / 2) * $cirSize)]
           set x2 [expr $cx + round(($ob(clcksize) / 2) * $cirSize)]
           set y2 [expr $cy + round(($ob(clcksize) / 2) * $cirSize)]
           .clock coords circle $x1 $y1 $x2 $y2

                   #move the ticks, and numbers 1-$mob(endgame)
                   for {set i 1} {$i <= $mob(endgame)} {incr i} {
                           set np [expr $i / double($mob(endgame))]
			if {$mob(endgame)<200} {
                           if {[expr $i % 5]} {
                                   #long ticks
                                   set x1 [expr $cx + ($ob(clcksize) * $tikLength) * sin($np * $pi * 2)]
                                   set y1 [expr $cy - ($ob(clcksize) * $tikLength) * cos($np * $pi * 2)]
                                   set x2 [expr $cx + ($ob(clcksize) * $tk3Length) * sin($np * $pi * 2)]
                                   set y2 [expr $cy - ($ob(clcksize) * $tk3Length) * cos($np * $pi * 2)]
                                   .clock coords tick$i $x1 $y1 $x2 $y2
                           } else {
                                   #short ticks
                                   set x1 [expr $cx + ($ob(clcksize) * $tikLength) * sin($np * $pi * 2)]
                                   set y1 [expr $cy - ($ob(clcksize) * $tikLength) * cos($np * $pi * 2)]
                                   set x2 [expr $cx + ($ob(clcksize) * $tk2Length) * sin($np * $pi * 2)]
                                   set y2 [expr $cy - ($ob(clcksize) * $tk2Length) * cos($np * $pi * 2)]
                                   .clock coords tick$i $x1 $y1 $x2 $y2
                           }
			} else {
				if {![expr $i % 10]} {
			          	 #long ticks
                                   	set x1 [expr $cx + ($ob(clcksize) * $tikLength) * sin($np * $pi * 2)]
                                   	set y1 [expr $cy - ($ob(clcksize) * $tikLength) * cos($np * $pi * 2)]
                                   	set x2 [expr $cx + ($ob(clcksize) * $tk3Length) * sin($np * $pi * 2)]
                                   	set y2 [expr $cy - ($ob(clcksize) * $tk3Length) * cos($np * $pi * 2)]
                                   	.clock coords tick$i $x1 $y1 $x2 $y2
			    	}
			}
                           #move set of numbers
                           set x1 [expr $cx + ($ob(clcksize) * $n2pos) * sin($np * $pi * 2)]
                           set y1 [expr $cy - ($ob(clcksize) * $n2pos) * cos($np * $pi * 2)]
                          .clock coords nn$i $x1 $y1
                   }

                   #fonts
                   .clock itemconfigure nn -font "$font [expr round($fnt2Size * $ob(clcksize)) * -1]"
                   #resize the hands
                   .clock itemconfigure secondhand -width [expr round($secWidth * $ob(clcksize))]

           #move the hand
           set x1 [expr $cx + ($ob(clcksize) * $inrLength) * sin($sp * $pi * 2)]
           set y1 [expr $cy - ($ob(clcksize) * $inrLength) * cos($sp * $pi * 2)]
           set x2 [expr $cx + ($ob(clcksize) * $secLength) * sin($sp * $pi * 2)]
           set y2 [expr $cy - ($ob(clcksize) * $secLength) * cos($sp * $pi * 2)]
           .clock coords secondhand $x1 $y1 $x2 $y2
   }

   #short proc to remove the leading 0 from numbers
   #and make sure an int is returned
   proc unpad {int} {
           regsub ^0 $int "" int1
           if {![string is int $int1]} {
                   return 0
           }
           if {![string length $int1]} {
                   return 0
           }
           return $int1
   }

   #proc to return value of pi
   proc pi {} {expr acos(-1)}
