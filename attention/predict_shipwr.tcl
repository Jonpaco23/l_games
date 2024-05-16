proc predict {bbox xr yr i} {
	global ob mob img
	
	set n [expr {[lindex $ob(wlist,$i) 0]}]
	
	set ob(dist) 0
	
	set temp0 [expr {[lindex $bbox 0]}]
	set temp1 [expr {[lindex $bbox 1]}]
	set temp2 [expr {[lindex $bbox 2]}]
	set temp3 [expr {[lindex $bbox 3]}]
		
	# Compute center of the ball	
	set Cx [expr {($temp0+$temp2)/2}]
	set Cy [expr {($temp1+$temp3)/2}]

	set ob(goesnorth) 0
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
				set ob(goesnorth) 1
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
				set ob(goesnorth) 1
			} elseif {$xpr<($ob(ww,w)+$ob(bradius)-1)} {
				set ob(listpr) ""
				wpredict $bbox $xr $yr $i
			} elseif {$xpr>($ob(ww,e)-$ob(bradius)+1)} {
				set ob(listpr) ""
				epredict $bbox $xr $yr $i
			}
		}
		w
		{
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
				set ob(goesnorth) 1
			} elseif {$ypr<($ob(ww,n)+$ob(bradius)-1)} {
				set ob(listpr) ""
				wpredict $bbox $xr $yr $i
			} elseif {$ypr>($ob(ww,s)-$ob(bradius)+1)} {
				set ob(listpr) ""
				epredict $bbox $xr $yr $i
			}
		}
		e
		{
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
				set ob(goesnorth) 1
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
		if {0} {
  			set ob(target) [.c create image $c_x $c_y -image $img(bullseye) -tag pred -anchor center]
		}	
	}

		if {$c_y== [expr {$ob(ww,n)+$ob(bradius)}] || $c_y == [expr {$ob(ww,s)-$ob(bradius)}]} {
			set nxpr [expr {($c_x-$ob(half,x))/$ob(scale)}]
			set ob(hdir) 0
			set ob(trgt) $nxpr
			set ob(trgt_pixels) $c_x
			calculate_time
			adap_moveit {0 $ob(slotticks) 1} $nxpr
		} elseif {$c_x== [expr {$ob(ww,w)+$ob(bradius)}] || $c_x == [expr {$ob(ww,e)-$ob(bradius)}]} {
			set nypr [expr {-($c_y-$ob(half,y))/$ob(scale)}]		
			set ob(hdir) 1
			set ob(trgt) $nypr
			set ob(trgt_pixels) $c_y
			calculate_time
			adap_moveit {0 $ob(slotticks) 1} $nypr
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
		set xpr [expr {$ob(ww,$e)-$ob(bradius)}]
		set ypr [expr {$a*$xpr+$b}]
	}
	
	if {$i=="e" || $i=="w"} {
		set ob(bradius) [expr {0-$ob(bradius)}]
	}
	
	lappend ob(listpr) $xpr $ypr 
	
	set ob(dist) [expr {hypot($Cy-$ypr,$Cx-$xpr)}]
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
	set ob(dist) [expr {hypot($Cy-$ypr,$Cx-$xpr)}]

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

		lappend ob(listpr) $xpr $ypr 
		
		set dist [expr {hypot($Cy-$ypr,$Cx-$xpr)}]
		set ob(dist) [expr {$ob(dist)+$dist}]


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
		# we already know that south wall is live
		if {$ob(hriz)} {
			set xprsd $ypr
			} else {
			set xprsd $xpr
			}
		if {$xprsd>($ob(ww,$w)+$ob(bradius)-1) && $xprsd<($ob(ww,$e)-$ob(bradius)+1)} {
			# we hit the south wall!
			set dist [expr {hypot($oypr-$ypr,$oxpr-$xpr)}]
			set ob(dist) [expr {$ob(dist)+$dist}]
			lappend ob(listpr) $xpr $ypr 
			
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
			set dist [expr {hypot($oypr-$ypr,$oxpr-$xpr)}]
			set ob(dist) [expr {$ob(dist)+$dist}]
			
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

				set dist [expr {hypot($oypr-$ypr,$oxpr-$xpr)}]
				set ob(dist) [expr {$ob(dist)+$dist}]

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
				set dist [expr {hypot($oypr-$ypr,$oxpr-$xpr)}]
				set ob(dist) [expr {$ob(dist)+$dist}]
				
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
					set dist [expr {hypot($oypr-$ypr,$oxpr-$xpr)}]
					set ob(dist) [expr {$ob(dist)+$dist}]
					
					lappend ob(listpr) $xpr $ypr
				}				
			}
		}
	}
}
