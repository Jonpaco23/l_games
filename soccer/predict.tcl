proc predict2 {bbox xr yr i} {
	global ob mob
	
	set n [expr {[lindex $ob(wlist,$i) 0]}]
	
	set temp0 [expr {[lindex $bbox 0]}]
	set temp1 [expr {[lindex $bbox 1]}]
	set temp2 [expr {[lindex $bbox 2]}]
	set temp3 [expr {[lindex $bbox 3]}]
		
	# Compute center of the ball	
	set Cx [expr {($temp0+$temp2)/2}]
	set Cy [expr {($temp1+$temp3)/2}]

	switch $i {
		s {		
			set ob(hriz) 0
			if {$xr!=0} {
				set a [expr {$yr/$xr}]
				set b [expr {($Cy - $a*$Cx)}]
				set xpr [expr {(($ob(ww,$n)+$ob(bradius))-$b)/$a}]
			} else { 
				set xpr $Cx
			}
			if {$xpr>($ob(ww,w)+$ob(bradius)) && $xpr<($ob(ww,e)-$ob(bradius))} {
				set ob(listpr) ""
				npredict $bbox $xr $yr $i
			} elseif {$xpr<($ob(ww,w)+$ob(bradius)-1)} {
				set ob(listpr) ""
				wpredict $bbox $xr $yr $i
			} elseif {$xpr>($ob(ww,e)-$ob(bradius)+1)} {
				set ob(listpr) ""
				epredict $bbox $xr $yr $i
			}
		}
		n {
			set ob(hriz) 0
			if {$xr!=0} {
				set a [expr {$yr/$xr}]
				set b [expr {($Cy - $a*$Cx)}]
				set xpr [expr {(($ob(ww,$n)+$ob(bradius))-$b)/$a}]
			} else { 
				set xpr $Cx
			}
			if {$xpr>($ob(ww,w)+$ob(bradius)) && $xpr<($ob(ww,e)-$ob(bradius))} {
				set ob(listpr) ""
				npredict $bbox $xr $yr $i
			} elseif {$xpr<($ob(ww,w)+$ob(bradius)-1)} {
				set ob(listpr) ""
				wpredict $bbox $xr $yr $i
			} elseif {$xpr>($ob(ww,e)-$ob(bradius)+1)} {
				set ob(listpr) ""
				epredict $bbox $xr $yr $i
			}
		}
		w {
			set ob(hriz) 1
			if {$xr!=0} {
				set a [expr {$yr/$xr}]
				set b [expr {($Cy - $a*$Cx)}]
				set ypr [expr {$a*$ob(ww,$n)+$b}]
			} else { 
				set ypr $Cy
			}
			if {$ypr>($ob(ww,n)+$ob(bradius)) && $ypr<($ob(ww,s)-$ob(bradius))} {
				set ob(listpr) ""
				npredict $bbox $xr $yr $i
			} elseif {$ypr<($ob(ww,n)+$ob(bradius)-1)} {
				set ob(listpr) ""
				wpredict $bbox $xr $yr $i
			} elseif {$ypr>($ob(ww,s)-$ob(bradius)+1)} {
				set ob(listpr) ""
				epredict $bbox $xr $yr $i
			}
		}
		e {
			set ob(hriz) 1
			if {$xr!=0} {
				set a [expr {$yr/$xr}]
				set b [expr {($Cy - $a*$Cx)}]
				set ypr [expr {$a*$ob(ww,$n)+$b}]
			} else { 
				set ypr $Cy
			}
			if {$ypr>($ob(ww,n)+$ob(bradius)) && $ypr<($ob(ww,s)-$ob(bradius))} {
				set ob(listpr) ""
				npredict $bbox $xr $yr $i
			} elseif {$ypr<($ob(ww,n)+$ob(bradius)-1)} {
				set ob(listpr) ""
				wpredict $bbox $xr $yr $i
			} elseif {$ypr>($ob(ww,s)-$ob(bradius)+1)} {
				set ob(listpr) ""
				epredict $bbox $xr $yr $i
			}
		}
	}
		
	set listsize [llength $ob(listpr)]
	for { set j 0 } { $j <= ($listsize-2)} {set j [expr {$j + 2}]} {
		set c_x [lindex $ob(listpr) $j]
		set c_y [lindex $ob(listpr) [expr {$j+1}]]
		if {$i == "s"} {
			if {$c_y <= [expr {$ob(ww,n)+$ob(bradius)}] && [expr {abs($c_x - $ob(winwidth)/2)}]< [expr {$ob(ww,gp)/2-5}]} {
				set ob(ngoal) 1
				set ob(ngoalx) [expr {$c_x - $ob(winwidth)/2}]
			}
		} elseif {$i == "n"} {
			set ob(sgoal) 1
			if {$c_y >= [expr {$ob(ww,s)-$ob(bradius)}] && [expr {abs($c_x - $ob(winwidth)/2)}]< [expr {10+$ob(ww,gp)/2}]} {
				set ob(sgoalx) [expr {($c_x-$ob(half,x))/$ob(scale_ie)}]
				set ob(goalxforP4) $ob(sgoalx)
				set ob(c_x) $c_x
				.c delete pred
				if {!$mob(novisual)} {
					set ob(target) [.c create oval [expr {$c_x-4}] [expr {$c_y-4}] [expr {$c_x+4}] [expr {$c_y+4}] -fill $ob(predfill2) -outline $ob(predout2) -width 1 -tag pred]]
				}
				if {$ob(motorforces_x) && $ob(sgk_D)} {
					set ob(check_move_ie) 1
					# that allows to move in an i/e direction
					set ob(move_ie) 1
				} elseif {!$ob(motorforces_x) && $ob(sgk_D)} {
					stop_movebox 0
				}
			
			}
		}
	}
}

proc epredict {bbox xr yr i} {
	global ob

	set n [expr {[lindex $ob(wlist,$i) 0]}]
	set s [expr {[lindex $ob(wlist,$i) 1]}]
	set w [expr {[lindex $ob(wlist,$i) 2]}]
	set e [expr {[lindex $ob(wlist,$i) 3]}]
	
	set temp0 [expr {[lindex $bbox 0]}]
	set temp1 [expr {[lindex $bbox 1]}]
	set temp2 [expr {[lindex $bbox 2]}]
	set temp3 [expr {[lindex $bbox 3]}]
		
	# Compute center of the ball	
	set Cx [expr {($temp0+$temp2)/2}]
	set Cy [expr {($temp1+$temp3)/2}]
	
	# Estimate line
	set a [expr {$yr/$xr}]
	set b [expr {($Cy - $a*$Cx)}]

	if {$i=="e" || $i=="w"} {
		set ob(bradius) [expr {0-$ob(bradius)}]
	}
	
	if {$ob(hriz)} {
		set ypr [expr {$ob(ww,$e) + $ob(bradius)}]
		set xpr [expr {($ypr - $b)/$a}]
	} else {
		set xpr [expr {$ob(ww,$e) - $ob(bradius)}]
		set ypr [expr {$a * $xpr + $b}]
	}
	
	if {$i=="e" || $i=="w"} {
		set ob(bradius) [expr {0-$ob(bradius)}]
	}
	#set ob(target) [.c create oval $ob(ww,$e) $ypr [expr {$ob(ww,$e)+5}] [expr {$ypr+5}] -fill $ob(predfill) -outline $ob(predout) -width 2 -tag pred]
	
	lappend ob(listpr) $xpr $ypr 
	
	set dist1 [expr {hypot($Cy-$ypr,$Cx-$xpr)}]
	if {!$ob(livewall,$e)} {
	# Ball goes towards the north wall
	set oxr $xr
	set oyr $yr
	set xr [expr {0 - $oxr}]
	set yr $oyr
	
	set x1 [expr {$xpr - ($ob(bsize) / 2)}]
	set x2 [expr {$xpr + ($ob(bsize) / 2)}]
	set y1 [expr {$ypr - ($ob(bsize) / 2)}]
	set y2 [expr {$ypr + ($ob(bsize) / 2)}]
	
	set bbox2 [list $x1 $y1 $x2 $y2]
	npredict $bbox2 $xr $yr $i
	}
}

proc wpredict {bbox xr yr i} {
	global ob
	
	set n [expr {[lindex $ob(wlist,$i) 0]}]
	set s [expr {[lindex $ob(wlist,$i) 1]}]
	set w [expr {[lindex $ob(wlist,$i) 2]}]
	set e [expr {[lindex $ob(wlist,$i) 3]}]

	
	set temp0 [expr {[lindex $bbox 0]}]
	set temp1 [expr {[lindex $bbox 1]}]
	set temp2 [expr {[lindex $bbox 2]}]
	set temp3 [expr {[lindex $bbox 3]}]
		
	# Compute center of the ball	
	set Cx [expr {($temp0+$temp2)/2}]
	set Cy [expr {($temp1+$temp3)/2}]
	
	# Estimate line
	set a [expr {$yr/$xr}]
	set b [expr {($Cy - $a*$Cx)}]
	
	if {$ob(hriz)} {
		set ypr [expr {$ob(ww,$w) + $ob(bradius)}]
		set xpr [expr {($ypr - $b)/$a}]
	} else {
		set xpr [expr {$ob(ww,$w) + $ob(bradius)}]
		set ypr [expr {$a*$xpr + $b}]
	}
	set dist1 [expr {hypot($Cy-$ypr,$Cx-$xpr)}]
	
	#set ob(target) [.c create oval [expr {$ob(ww,$w)-5}] $ypr $ob(ww,$w) [expr {$ypr+5}] -fill $ob(predfill) -outline $ob(predout) -width 2 -tag pred]
	lappend ob(listpr) $xpr $ypr 
	
	# Ball goes towards the north wall
	if {!$ob(livewall,$w)} {
	set oxr $xr
	set oyr $yr
	set xr [expr {0 - $oxr}]
	set yr $oyr
	
	set x1 [expr {$xpr - ($ob(bsize) / 2)}]
	set x2 [expr {$xpr + ($ob(bsize) / 2)}]
	set y1 [expr {$ypr - ($ob(bsize) / 2)}]
	set y2 [expr {$ypr + ($ob(bsize) / 2)}]
	
	set bbox2 [list $x1 $y1 $x2 $y2]
	npredict $bbox2 $xr $yr $i
	}	
	}	
	
proc npredict {bbox xr yr i} {
	
	global ob
	
	# set location of north/south/west/east with respect to each live wall
	set n [expr {[lindex $ob(wlist,$i) 0]}]
	set s [expr {[lindex $ob(wlist,$i) 1]}]
	set w [expr {[lindex $ob(wlist,$i) 2]}]
	set e [expr {[lindex $ob(wlist,$i) 3]}]
	
	# Compute center of the ball:
	# Take x1,y1 and x2,y2...
	set temp0 [expr {[lindex $bbox 0]}]
	set temp1 [expr {[lindex $bbox 1]}]
	set temp2 [expr {[lindex $bbox 2]}]
	set temp3 [expr {[lindex $bbox 3]}]
	# ... and then compute the center
	set Cx [expr {($temp0+$temp2)/2}]
	set Cy [expr {($temp1+$temp3)/2}]
	
	if {$xr == 0} {
		set xpr $Cx
		if {$yr<0} {
			error "Prediction (npredict): We shouldn't get here"
		}
		if {$yr>0} {
			error "Prediction (npredict): We shouldn't get here"
		}
		} else {
	
		# hit $north wall
		set a [expr {$yr/$xr}]
		set b [expr {($Cy - $a*$Cx)}]
		
		# we change the sign
		if {$i == "n" || $i=="w"} {
			set ob(bradius) [expr {0-$ob(bradius)}]
		}
		
		if {$ob(hriz)} {
			set xpr [expr {($ob(ww,$n)+$ob(bradius))}]
			set ypr [expr {$a*$xpr+$b}]
		} else {
			set ypr [expr {($ob(ww,$n)+$ob(bradius))}]
			set xpr [expr {($ypr-$b)/$a}]
		}
		# and we change the sign back	
		if {$i == "n" || $i=="w"} {
			set ob(bradius) [expr {0-$ob(bradius)}]
		}

		#set ob(target) [.c create oval $xpr  [expr {$ob(ww,$n)-5}] [expr {$xpr-5}] $ob(ww,$n) -fill $ob(predfill) -outline $ob(predout) -width 2 -tag pred]
		
		lappend ob(listpr) $xpr $ypr 
		
		set dist1 [expr {hypot($Cy-$ypr,$Cx-$xpr)}]

	# if north wall is not live estimate one more wall hit
	if {!$ob(livewall,$n)} {
		# Ball goes towards the south wall
		set oxr $xr
		set oyr $yr
		set xr $oxr
		set yr [expr {0 - $oyr}]
		set oxpr $xpr
		set oypr $ypr
		
		set a [expr {$yr/$xr}]
		set b [expr {($ypr - $a*$xpr)}]
		
		# we change the sign
		if {$i == "n" || $i=="w"} {
			set ob(bradius) [expr {0-$ob(bradius)}]
		}
		
		if {$ob(hriz)} {
			set xpr [expr {($ob(ww,$s)-$ob(bradius))}]
			set ypr [expr {$a*$xpr+$b}]
		} else {
			set ypr [expr {($ob(ww,$s)-$ob(bradius))}]
			set xpr [expr {($ypr-$b)/$a}]
		}
		
		# we change the sign back
		if {$i == "n" || $i=="w"} {
			set ob(bradius) [expr {0-$ob(bradius)}]
		}

		# check to see if it will hit a side wall
		# we already know that south wall is live(!!!)
		if {$ob(hriz)} {
			set xprsd $ypr
			} else {
			set xprsd $xpr
			}
		if {$xprsd>($ob(ww,$w)+$ob(bradius)-1) && $xprsd<($ob(ww,$e)-$ob(bradius)+1)} {
			# we hit the south wall!
			set dist2 [expr {hypot($oypr-$ypr,$oxpr-$xpr)}]
			#set ob(target) [.c create oval $xpr $ob(ww,$s) [expr {$xpr+5}] [expr {$ob(ww,$s)+5}] -fill $ob(predfill) -outline $ob(predout) -width 2 -tag pred]
			lappend ob(listpr) $xpr $ypr 
			set dist [expr {$dist1+$dist2}]
			
		} elseif {$xprsd<($ob(ww,$w)+$ob(bradius)-1)} {		
			# calculate west wall hit coordinates
			if {$i=="e" || $i=="w"} {
				set ob(bradius) [expr {0-$ob(bradius)}]
			}
			if {$ob(hriz)} {
				set ypr [expr {($ob(ww,$w)-$ob(bradius))}]
				set xpr [expr {($ypr-$b)/$a}]
			} else {
				set xpr [expr {$ob(ww,$w)+$ob(bradius)}]
				set ypr [expr {$a*$xpr+$b}]
			}
			if {$i=="e" || $i=="w"} {
				set ob(bradius) [expr {0-$ob(bradius)}]
			}
			set dist2 [expr {hypot($oypr-$ypr,$oxpr-$xpr)}]
			#set ob(target) [.c create oval [expr {$ob(ww,$w)-5}] $ypr $ob(ww,$w) [expr {$ypr+5}] -fill $ob(predfill) -outline $ob(predout) -width 2 -tag pred]
			lappend ob(listpr) $xpr $ypr 
			
			if {!$ob(livewall,$w)} {
				# calculate south wall hit coordinates
				set oxr $xr
				set oyr $yr
				set xr [expr {0 - $oxr}]
				set yr $oyr
				set oxpr $xpr
				set oypr $ypr
				
				set a [expr {$yr/$xr}]
				set b [expr {($ypr - $a*$xpr)}]
				
				# we change the sign
				if {$i == "n" || $i=="w"} {
					set ob(bradius) [expr {0-$ob(bradius)}]
				}

				if {$ob(hriz)} {
					set xpr [expr {($ob(ww,$s)-$ob(bradius))}]
					set ypr [expr {$a*$xpr+$b}]
				} else {				
					set ypr [expr {($ob(ww,$s)-$ob(bradius))}]
					set xpr [expr {($ypr-$b)/$a}]
				}
				# we change the sign back 
				if {$i == "n" || $i=="w"} {
					set ob(bradius) [expr {0-$ob(bradius)}]
				}

				set dist3 [expr {hypot($oypr-$ypr,$oxpr-$xpr)}]
				set dist [expr {$dist1+$dist2+$dist3}]
				#set ob(target) [.c create oval $xpr $ob(ww,$s) [expr {$xpr+5}] [expr {$ob(ww,$s)+5}] -fill $ob(predfill) -outline $ob(predout) -width 2 -tag pred]
				lappend ob(listpr) $xpr $ypr
			}				
			} elseif {$xprsd>$ob(ww,$e)-$ob(bradius)+1} {
				# calculate east wall hit coordinates
				
				if {$ob(hriz)} {
					set ypr [expr {($ob(ww,$e)-$ob(bradius))}]
					set xpr [expr {($ypr-$b)/$a}]
				} else {
					set xpr [expr {($ob(ww,$e)-$ob(bradius))}]
					set ypr [expr {$a*$xpr+ $b}]
				}
				set dist2 [expr {hypot($oypr-$ypr,$oxpr-$xpr)}]
				
				#set ob(target) [.c create oval $ob(ww,$e) $ypr [expr {$ob(ww,$e)+5}] [expr {$ypr+5}] -fill $ob(predfill) -outline $ob(predout) -width 2 -tag pred]
				lappend ob(listpr) $xpr $ypr 
				
				if {!$ob(livewall,$e)} {
					# calculate south wall hit coordinates
					set oxr $xr
					set oyr $yr
					set xr [expr {0 - $oxr}]
					set yr $oyr
					set oxpr $xpr
					set oypr $ypr
					
					set a [expr {$yr/$xr}]
					set b [expr {($ypr - $a*$xpr)}]	

					# we change the sign
					if {$i == "n" || $i=="w"} {
						set ob(bradius) [expr {0-$ob(bradius)}]
					}
					if {$ob(hriz)} {
						set xpr [expr {($ob(ww,$s)-$ob(bradius))}]
						set ypr [expr {$a*$xpr+$b}]
					} else {	
						set ypr [expr {($ob(ww,$s)-$ob(bradius))}]
						set xpr [expr {($ypr-$b)/$a}]
					}
					# we change the sign back
					if {$i == "n" || $i=="w"} {
						set ob(bradius) [expr {0-$ob(bradius)}]
					}					
					set dist3 [expr {hypot($oypr-$ypr,$oxpr-$xpr)}]
					set dist [expr {$dist1+$dist2+$dist3}]
					#set ob(target) [.c create oval $xpr $ob(ww,$s) [expr {$xpr+5}] [expr {$ob(ww,$s)+5}] -fill $ob(predfill) -outline $ob(predout) -width 2 -tag pred]
					lappend ob(listpr) $xpr $ypr
				}				
			}
		}
	}
}
