#' Sort images by count
#'
#' Some times it's convenient to sort images into directories such that every directory has the same number of images. This convenience function does that.
#'
#' @param path Name of folder in which to sort images.
#' @param count How many images should be placed into each subdirectory?
#'
#' @examples
#' input_dir <- area_example("raw")
#' sort_by_count(input_dir, 4)

sort_by_count <- function (path, count) {
  path_to_python <- python_version()
  path_to_script <- paste(system.file(package="ALFA"), "ALFA.py", sep="/")

  args <- paste(shQuote(path_to_script), "number_sort", shQuote(path), "--fileno", count)
  out <- system2(command = path_to_python, args = args, stdout = TRUE)
  }
