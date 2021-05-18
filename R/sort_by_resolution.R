#' Sort images by resolution
#'
#' Some image-processing programs assume that ones images are sorted by resolution. This helper function looks up the resolutions of each file, and moves them into folders. Files for which no resolution data is available in exif are placed in a folder called 'resolution_NA'.
#'
#' @param path Name of folder in which to sort images.
#'
#' @examples
#' input_dir <- area_example("raw1")
#' sort_by_resolution(input_dir)

sort_by_resolution <- function (path) {
  path_to_python <- python_version()
  path_to_script <- paste(system.file(package="ALFA"), "ALFA.py", sep="/")

  args <- paste(shQuote(path_to_script), "resolution_sort", shQuote(path))
  out <- system2(command = path_to_python, args = args, stdout = TRUE)
  }

