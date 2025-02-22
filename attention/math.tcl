
	#  for P3a
	proc pm_point_accuracy {list} {
		global ob
		# for exact, almost, near positioning
		set nExact 0
		set nAlmost 0
		set nNear 0
		set mikos [llength $list]
		set Pmetric 0
		for {set i 1} {$i <= $mikos} { incr i } {
			set ind [lindex $list $i]
			if { $ind <= [expr { double($ob(padw)/2) }]} {
				incr nExact 1
			} elseif {$ind>[expr {double($ob(padw)/2)}] && $ind <=[expr {$ob(padw)}]} {
				incr nAlmost 1
			} elseif {$ind>$ob(padw) && $ind <[expr {1.5*$ob(padw)}]} {
				incr nNear 1
			}
		}
		if {$mikos>0} {
			set Pmetric [expr {(4*$nExact + 2*$nAlmost + $nNear)/double($mikos)}]
		} 
		return $Pmetric
	}

	# for P3b
	proc pm_min_trajectory {list} {
		global ob
		set dist 0
		set mikos [llength $list]
		set Pmetric 0
		set i 0
		while {$i<[expr {$mikos-1}]} {
			set temp1 [lindex $list $i]
			incr i
			set temp2 [lindex $list $i]
			set dist [expr {$dist+double((abs($temp2-$temp1)))}]
		}
		if {$mikos>0 && $dist>0} {
			set mdist [expr {abs($ob(trgt) - [lindex $list 0])}]
			set Pmetric [expr {$mdist/$dist}]
			if {$Pmetric>1} {set Pmetric 1}
		} 	
		return $Pmetric
	}

	# PM4
	proc pm_min_dist_along_axis {list} {
		global ob
		set Pmetric [lindex $list [expr {[llength $list]-1}]]
		return $Pmetric
	}

	# see Michmizos & Krebs, BioRob, 2012
	proc logistic_function {r} {
		set d -0.25
		set s 0.30
		set logi [expr {1-exp(-pow(($r-$d)/$s,2))}]
		return $logi
	}

	proc median {list} {
		global ob

		set mikos [llength $list]
		set list2 [lsort -real $list]
		set median [lindex $list2 [expr {round($mikos/2)}]]
		return $median
	}	

	proc average {args} {
		
		set mikos [llength $args]
		if {$mikos>0} {
			return [expr [eval sum $args] / $mikos]
		}
	}

	proc sum {args} {
		set result 0
		foreach n $args {
			set result [expr $result+$n]
		}
		return $result
	}

	# for display
	proc pm_smoothness {list} {
		global ob
		
		set list2 [list]
		set list3 [list]
		set i 0
		set mikos [llength $list]
		set Pmetric 0
		set start 0
		if {$mikos>0} {
			while {$i<$mikos} {
				set temp [lindex $list $i]
				if {$start || [expr {abs($temp)}] > 0.001} {
					lappend list2 [expr {abs($temp)}]
					set start 1		
				}
				incr i
			}
			set mikos2 [llength $list2]
			if {$mikos2>0} {
				set i [expr {$mikos2-1}]
				set start 0
				while {$i>=0} {
					set temp [lindex $list2 $i]
					if {$start || [expr {abs($temp)}] > 0.001} {
						lappend list3 $temp
						set start 1		
					}
					incr i -1
				}
			}	
			set av [eval average $list3]
			#set av [eval median {$list3}]
			set list3 [lsort -real $list3]
			set meg [lindex $list3 end]
			#puts "av = $av, meg = $meg"
			if {$meg!=""} {
				set Pmetric [expr {abs($av/$meg)}]
			} 
		} 
		return $Pmetric
	}

	# for averaging over only the assistive torque
	proc pm_assistive_torque {list} {
		global ob

		set Pmetric 0.0	
		set av [eval average $list]
		if {$av!=0.0} {
			set list2 [list]		

			set i 0
			set mikos [llength $list]	
			if {$mikos>0} {
				while {$i<$mikos} {
					set temp [lindex $list $i]
					if {$temp == 0.0} {
						#we throw it away	
					} elseif {$ob(trgt)<0 && [expr {$temp*$ob(trgt)}] > 0} {
						lappend list2 [expr {abs([lindex $list $i])}]		
					} elseif {$ob(trgt)>0 && [expr {$temp*$ob(trgt)}] > 0} {
						lappend list2 [lindex $list $i]
					}		
					incr i
				} 
				if {[llength $list2]>0} {
					set Pmetric [eval average $list2]
				} 			
			} 
		} 
		return $Pmetric
	}	

