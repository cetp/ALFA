#' Sort images by count
#'
#' Some times it's convenient to sort images into directories such that every directory has the same number of images. This convenience function does that.
#'
#' @param path Name of folder in which to sort images.
#' @param count How many images should be placed into each subdirectory?
#'
#' @examples
#' input_dir <- "https://github.com/cetp/ALFA/blob/master/inst/extdata/raw"
#' sort_by_count(input_dir, 2)

sort_by_count <- function (path, count) {
  
  args <- paste(shQuote(path_to_script), "number_sort", shQuote(path), "--fileno", count)
  number_sort(path = path, count = count)
  }

