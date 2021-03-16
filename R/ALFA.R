#' ALFA-package R Documentation
#'
#'ALFA is a tool to quickly and accurately measure the surface area of leaves, from scans
#'
#'ALFA's \code{preprocess} function uses Python to process leaf scans to prepare them for analysis
#'
#'ALFA's \code{assess} function also uses Python to calculate the area (in cm^2) occupied by leaves in the prepared image. Thus, the standard wrkflow is to use \code{preprocess} on a raw image or directory of images, then to call \code{assess} on the prepared image(s)
#'


#'@author
#'Maintainer: C. E. Timothy Paine cetpaine@gmail.com.
#' Contributors:
#' Mitchell Welch mwelch8@une.edu.au,
#' Boris Bongalov b.bongalov@gmail.com,
#' Sabine Both sabineboth.mail@gmail.com
#'@aliases alfa
#'@references
#'Paine, C.E.T., Bongalov, B., Welch, M., Both, S. In review. "‘ALFA’ (Assess LeaF Area): An optimal method for assessing leaf area" Methods in Ecology & Evolution
#' @docType package
#' @name ALFA
NULL
