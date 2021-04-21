#' Prepare an Image of Leaves for the Assessment of Leaf Area
#'
#' \code{preprocess} prepares images of leaves for assessment using \code{assess}. Not all images require preprocessing. It provides options to crop away colored margins from an image, to mask out an un-needed scale bar, or to insert a scale bar of a particular size. Either a single image or single directory of images can be processed at once. If the latter, processing can be performed in parallel.
#'
#' @param source The path to the image, or directory of images, which you want to prepare for assessment.
#' @param output_dir The directory where to save the processed images, so that they can be assessed using \code{assess}. Respects tilde expansion. This must not be a directory that already exists, so that existing files are not over-written.
#' @param crop Should the margins of the image be cropped? Cropping occurs before the other operations, meaning that they are performed on the cropped image. Value is one integer; number of pixels to be removed from (top, bottom, left, right) of the image. Default = 0.
#' @param red_scale How many pixels wide should the side of the scale should be? Default = 0.
#' @param mask_pixels How many pixels should each side of the masking window be? Default = 0.
#' @param mask_offset_x Offset for positioning the masking window in number of pixels from right to left of the image.
#' @param mask_offset_y Offset for positioning the masking window in number of pixels from bottom to top of the image.
#' @param workers By default, preprocess will use all but one core for processing a folder of images. Here, you can control how many cores are used. Ignored when preprocessing a single image.
#'
#' @return No value is returned. The side effect is that the processed image is saved in the directory specified in \code{output_dir}.
#'
#' @examples
#' img <- ALFA_example("raw/img4.jpg")
#' input_dir <- ALFA_example("raw")
#' output_dir <- ALFA_example("prepared")
#'
#' \dontrun{
#' preprocess(img, output_dir, crop = -300), mask_pixels = 500, mask_offset_x = 0, mask_offset_y = 20)
#'
#' preprocess(input_dir, output_dir, crop = 300, mask_pixels = 500, mask_offset_x = 0, mask_offset_y = 2300)
#' }


preprocess <- function(source, output_dir, crop = 0, red_scale = 0, mask_pixels = 0, mask_offset_x = 0, mask_offset_y = 0, workers = NULL) {
  path_to_python <- python_version()
  path_to_script <- paste(system.file(package="ALFA"), "ALFA.py", sep="/")
  args <- paste(shQuote(path_to_script), "preprocess", shQuote(source), "-c", crop, "--red_scale", red_scale, "--mask_pixels", mask_pixels, "--mask_offset_x", mask_offset_x, "--mask_offset_y", mask_offset_y)
  if(!is.null(output_dir)){args <- paste(args, "--output_dir", shQuote(output_dir))}
  if(!is.null(workers)){args <- paste(args, "--workers", workers)}
  
  out <- system2(path_to_python, args = args, stdout = T)
  if('status' %in% attributes(out)){
    return(out)
  } else {
    out <- sub("\\r", "", out)
    if (any(grepl("^directory", out))){
      out <- out[-grep("^directory", out)] # drop announcement about a directory being created.
    }
    if (any(grepl("^###", out))){
      out <- out[-grep("###Data###", out)] # drop the ###Data### marker
    }
    if (any(grepl("^$", out))){
      out <- out[-grep("^$", out)] # drop any blank rows
    }
    if (any(grepl("^,filename", out))){
      out <- out[-grep("^,filename", out)] # drop any header rows
    }
    
    out2 <- data.frame(matrix(unlist(strsplit(out, ",")), byrow= T, ncol = 3))
    out2$X1 <- NULL
    names(out2) <- c('Filename', 'Error')
    table(out2$Error)
    if(any(out2$Error != "No Error")){
      to_print <- out2
      to_print$Filename <- sub(".*/", "", to_print$Filename)
      tab <- table(to_print$Error[to_print$Error != 'No Error'])
      print(paste("NOTE: The following", sum(tab), "errors were found while preprocessing the directory:", source))
      print(paste(" ", names(tab), tab, collapse = "; "))
      print(" See returned data.frame for details.")
    }
    return(out2)
  }
}
