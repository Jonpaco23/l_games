#!/usr/bin/tclsh

set trigger [lindex $argv 0]
set command [exec python TriggerTests.py $trigger]
puts $command
