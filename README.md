Code for "Dynamic Fractional Frequency Reuse in OFDMA Systems" by Kate Harrison and Gireeja Ranade
==================================================================================================


Context
-------
This code accmpanies the paper "Dynamic Fractional Frequency Reuse in
OFDMA Systems" by Kate Harrison and Gireeja Ranade. The paper can be
found [here](http://www.eecs.berkeley.edu/~gireeja/ee224b_gireejaranade_kateharrison.pdf).

Some of the comments in the code and in particular the filenames may
assume that you have read the paper above. They may also assume that you
have read Stolyar and Viswanathan's paper "Self-organizing dynamic
fractional frequency reuse in OFDMA systems".


Code organization
-----------------
General simulation parameters are stored in get_simulation_parameter.m.
While these values are frequently used throughout the code, there is no
guarantee that changes will propagate as desired. Please double-check the
source code if you want to be sure that it's working as intended. This
file also provides definitions for each of the parameters (which are
frequently included in other files but not systematically).

Similarly, changing the length of arrays (e.g. p_array, d_array,
BS_power) may (or may not) have unintended results. The code is not as
general as it should be and is therefore unfortunately a bit fragile.

The files named figure_*.m which will generate each of the figures in the
paper.

Some figures (e.g. Figure 3 and Figure 5) are stand-alone and require no
pre-computation of data. Others require you to pre-compute some data
using other files (e.g. create_data_*.m) before generating the figures.
Whenever possible, I have tried to direct the user to the appropriate
files in the header text of the figure_* file.

The create_data_*.m files rely on main_program.m. This is where the main
implementation is housed. The create_data_*.m files are simply wrappers
which execute main_program.m with the appropriate parameters. If you are
extending this code, you will likely want to write your own wrapper and
then call main_program.m. In this case, the create_data_*.m files will
help you understand what the parameters of main_program.m are.


Directories
-----------
 * Miscellaneous useful files are kept in the Helpers/ directory to reduce
clutter and confusion.
 * All generated data is stored in the data/ directory.
 * All generated figures are stored in the Figures/ directory.
 * Since some of the computations can take a long time, partial data is stored in the case of an interruption. There are many such files (over 1200 if you generate the data required for all of the figures) and they are stored in the partial_data/ directory.

**All of these directories will be automatically added to your path when you run 'run_me_first.m'.**


Code support and maintenance
----------------------------
I (Kate) do not intend to maintain this code any longer. I may be able to
provide limited support so please email me if you have any questions or
if you find any issues.


Copyright information
---------------------
This code is freely available to anyone who wants to use it and is
provided without guarantee. If you build off of it or find it useful,
please consider citing our code or our paper (or both).


Author information
------------------
**Kate Harrison**
 * UC Berkeley graduate student in EECS
 * ASDFharriska at eecs dot berkeley dot edu (remove the characters 'ASDF' first)

**Gireeja Ranade**
 * EECS
 * UC Berkeley
 * gireeja@eecs.berkeley.edu
