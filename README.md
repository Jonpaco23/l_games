# Overview
Fitts-maze is a game for the Bionik In-Motion Robot Arm that generates a random maze for users to traverse. Users can adjust the difficulty of the task either assisting with movement throughout the maze or resistance as requested.

# Installation and Usage
Tcl/Tk comes pre-installed on most Unix/Linux distributions. If it is not, it can be installed using the command ```apt-get install tcl```. The only other requirements to run this game are several files that should come preinstalled on the Bionik In-Motion Arm Robot:
- shm.tcl in crobhome
- util.tcl in common
- menu.tcl in common
- i18n.tcl in I18N_HOME

To run this game, run the command ```tclsh fitts-maze.tcl``` from the directory where the file is located. Upon running, this menu will appear:

![image](https://github.com/user-attachments/assets/d112832f-ed92-43fe-958f-49b696580389)

Sequential mode will increase the current level by 1 each time a level is completed by reaching the green square (each additional level will add 2 new squares to the maze). Incremental mode will increase the level by the amount specified in the slider below.

# To-do List
* Smooth out arm movement with assistance modes
* Modify the menu to include more options
* Random maze generation (currently uses preprogrammed path)
