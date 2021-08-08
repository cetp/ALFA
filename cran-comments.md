## Test environments
* Local OS X install, R 4.0.3
* Windows Server 2012 R2 x64, R 4.0.3
* Linux 3.10.0-1160.31.1.el7.x86_64, R 3.6.0

## R CMD check results
There were no ERRORs, WARNINGs or NOTEs. 

## Notes for Windows 
This package fails the tests on win-builder (devel and release). ALFA requires that Python ≥ 3.5 be installed, and a set of python packages be installed. That does not appear to be the case on the win-builder server. Our tests on our windows machines show that it can be built, installed, and functions as expected once Python and the required packages are installed. 
