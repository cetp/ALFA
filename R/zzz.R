# global reference to each python package (will be initialized in .onLoad)
# .onLoad <- function(libname, pkgname) {
#   reticulate::conda_create('ALFA')
# 
#   reticulate::conda_install(c("scipy", "opencv-python", "piexif", "pandas", "scikit-image"), envname = 'ALFA', pip = TRUE)
# 
#   reticulate::use_condaenv("ALFA")
#   ALFA <- reticulate::source_python("inst/ALFA.py")
#   
# }

## OR, ALTERNATIVELY, TRY THIS:
.onLoad <- function(libname, pkgname) {
  reticulate::conda_create('ALFA')
  reticulate::configure_environment(pkgname)
  reticulate::use_condaenv("ALFA")
  ALFA <- reticulate::source_python("inst/ALFA.py")
  
}



# .onAttach <- function(libname, pkgname) {
#   pv <- function(){
#     V3 <- suppressWarnings(try(system2("python3", "--version", stdout = TRUE), silent = TRUE))
#     if(class(V3) == 'try-error' | !is.null(attr(V3, 'status'))){
#       py3 <- try(system2("py", "--version", stdout = TRUE), silent = TRUE)
#     } else {
#       V3 <- as.numeric(gsub("Python |\\.\\d*$", "", V3))
#       if (V3 >= 3.5){
#         return('python3')
#       }
#     }
#     if(class(py3) == 'try-error'){
#       py3 <- 0
#     } else {
#       py3 <- as.numeric(gsub("Python |\\.\\d*$", "", py3))
#       if (py3 >= 3.5){
#         return('py')
#       }
#     }
#     if((!is.na(V3) & V3 >= 3 & V3 < 3.5)| (!is.na(py3) & py3 >= 3 & py3 < 3.5) ){
#       packageStartupMessage(paste("It appears that Python", V3, "is installed on this system. Please update it to Python 3.5 or newer, from https://www.python.org/downloads/"))
#       return(invisible())
#     }
#     V2 <- try(system2("python", "--version", stdout = TRUE), silent = TRUE)
#     V2 <- as.numeric(gsub("Python |\\.\\d*$", "", V2))
#     if(is.na(V2)){V2 <- 0}
#     if(V2 >= 3 & V2 < 3.5){
#       packageStartupMessage(paste("It appears that Python", V2, "is installed on this system. Please update it to Python 3.5 or newer, from https://www.python.org/downloads/"))
#       return(invisible())
#     } else{
#       if(V2 >= 3.5){
#         return('python')
#       } else {
#         packageStartupMessage("It appears that Python 3.5 or newer is not installed on this system. Please install it from https://www.python.org/downloads/, and try again")
#       }
#     }
#   }
#   
#   version <- pv()
#   if(length(version) == 1){packageStartupMessage("Python >= 3.5 is present")}
#   python_location <- ifelse(.Platform$OS.type == "windows", system2(command =  "where", args = version, stdout = TRUE), system2(command = "which", args = version, stdout = TRUE))
#   # below here checks to make sure that python packages are installed.
#   if(length(suppressWarnings(system2(python_location, " -m pip show opencv-python", stdout = TRUE))) == 0){
#     packageStartupMessage(paste0("It appears that the Python package cv2 is not installed on this computer. You can install it from the command line with '", python_location, " -m pip install opencv-python'. If this fails, try installing it only for the current user, with ", python_location, " -m pip install --user opencv-python'"))
#     return(invisible())
#   } else {packageStartupMessage("  cv2 is present")}
#   if(length(suppressWarnings(system2(python_location, " -m pip show numpy", stdout = TRUE))) == 0){
#     packageStartupMessage(paste0("It appears that the Python package numpy is not installed on this computer. You can install it from the command line with '", python_location, " -m pip install numpy'. If this fails, try installing it only for the current user, with ", python_location, " -m pip install --user numpy'"))
#     return(invisible())
#   }else {packageStartupMessage("  numpy is present")}
#   if(length(suppressWarnings(system2(python_location, " -m pip show pandas", stdout = TRUE))) == 0){
#     packageStartupMessage(paste0("It appears that the Python package pandas is not installed on this computer. You can install it from the command line with '", python_location, " -m pip install pandas'. If this fails, try installing it only for the current user, with '", python_location, " -m pip install --user pandas'"))
#     return(invisible())
#   }else {packageStartupMessage("  pandas is present")}
#   if(length(suppressWarnings(system2(python_location, " -m pip show exif", stdout = TRUE))) == 0){
#     packageStartupMessage(paste0("It appears that the Python package exif is not installed on this computer. You can install it from the command line with '", python_location, " -m pip install exif'. If this fails, try installing it only for the current user, with '", python_location, " -m pip install --user exif'"))
#     return(invisible())
#   }else {packageStartupMessage("  exif is present")}
#   if(length(suppressWarnings(system2(python_location, " -m pip show piexif", stdout = TRUE))) == 0){
#     packageStartupMessage(paste0("It appears that the Python package piexif is not installed on this computer. You can install it from the command line with '", python_location, " -m pip install piexif'. If this fails, try installing it only for the current user, with '", python_location, " -m pip install --user piexif'"))
#     return(invisible())
#   }else {packageStartupMessage("  piexif is present")}
#   if(length(suppressWarnings(system2(python_location, " -m pip show scikit-image", stdout = TRUE))) == 0){
#     packageStartupMessage(paste0("It appears that the Python package skimage is not installed on this computer. You can install it from the command line with '", python_location, " -m pip install scikit-image'. If this fails, try installing it only for the current user, with '", python_location, " -m pip install --user scikit-image'"))
#     return(invisible())
#   }else {packageStartupMessage("  skimage is present")}
#   packageStartupMessage("All required Python modules are present. ALFA is loaded.")
#   return(invisible())
# }
