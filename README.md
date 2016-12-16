# cygwinxp
Replicate last Cygwin repository compatible with Windows XP

Created based on information and support of the FruitBat.org TimeMachine: http://www.fruitbat.org/Cygwin/timemachine.html

The script will pull the required setup.exe, setup.ini file and cygwin mirror list from the right places. Then it will retrieve the latest version of packages from mirrors picked randomly so it would not overload a single site. There are 2 preferred mirrors with probably outdated packages and one main location where are all packages with right version (on slow link). Once done retrieving all files, then it will compare the sizes of the files with the content of setup.ini to do a simple validation. To download also the sources, you must remove the "A" from all occurrences of "^Asource".

Script can be interrupted and restarted later, it will not re-retrieve packages already downloaded.

Once downloaded, then it can be used to install Cygwin from disk or create your own local "mirror".
