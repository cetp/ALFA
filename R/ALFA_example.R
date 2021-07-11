#' Get Path to Example Image
#'
#' ALFA comes bundled with a number of sample files in its inst/extdata directory. This function make them easy to access.
#'
#' @param path Name of file. If NULL, the example files will be listed.
#'
#' @examples
#' ALFA_example("raw/img1.jpg")
#' input_dir <- ALFA_example("raw")

ALFA_example <- function (path = NULL) {
  if (is.null(path)) {
    dir(system.file("extdata", package = "ALFA"))
  }
  else {
    system.file("extdata", path, package = "ALFA", mustWork = TRUE)
  }
}
