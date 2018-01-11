GOLEM LITECOIN MINER

Written by Stacey Rieck

----------------------------------------
-- REGENERATING PROJECT
----------------------------------------

Open Vivado.
Click Tools -> Run Tcl Script
Navigate to the project root directory

Run golem_top.tcl

Project is now ready for synthesis


----------------------------------------
-- MODIFYING PROJECT
----------------------------------------

If a modification has been made to the block diagram, do the following to
generate a new tcl script:

With the block diagram open, go to File -> Export -> Export Block Design

Save this new tcl file over the one named Create_bd.tcl
The other tcl files (golem_top and Generate_wrapper) don't need to be changed.

Only the new tcl file needs to  be added to version control.
