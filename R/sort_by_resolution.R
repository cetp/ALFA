#' Sort images by resolution
#'
#' Some image-processing programs assume that ones images are sorted by resolution. This helper function looks up the resolutions of each file, and moves them into folders. Files for which no resolution data is available in exif are placed in a folder called 'resolution_NA'.
#'
#' @param path Name of folder in which to sort images.
#'
#' @examples
#' input_dir <- "https://github.com/cetp/ALFA/blob/master/inst/extdata/raw"
#' sort_by_resolution(input_dir)

sort_by_resolution <- function (path) {
  out <- resolution_sort(path = path)
  return(out)
  }

