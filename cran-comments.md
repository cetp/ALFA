## Test environments
* local OS X install, R 4.0.3
* win-builder (devel and release)

## R CMD check results
There were no ERRORs, WARNINGs or NOTEs. 

## Notes for windows 
This package fails the tests on win-builder (devel and release). ALFA requires that Python ≥ 3.5 be installed, and a set of python pacages be installed. That does not appear to be the case on the win-builder server. Our tests on local windows machines show that it can be built and 