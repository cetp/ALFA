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
#' @param workers By default, preprocess will use all but one core for processing a folder of images. Here, you can control how many cores are used. Ignored when preprocessing a single image. Note that on virtual 
#'
#' @return No value is returned. The side effect is that the processed image is saved in the directory specified in \code{output_dir}.
#'
#' @examples
#' img <- "https://github.com/cetp/ALFA/blob/master/inst/extdata/raw/img1.jpg"
#' input_dir <- "https://github.com/cetp/ALFA/blob/master/inst/extdata/raw"
#'
#' \dontrun{
#' A new directory, 'prepared1' will be created in the working directory 
#' to hold the thresholded files. 
#' output_dir <- "prepared1"
#' preprocess(img, output_dir, 
#'   crop = 300, mask_pixels = 500, mask_offset_x = 0, mask_offset_y = 20)
#'
#' preprocess(input_dir, output_dir, 
#'   crop = 300, mask_pixels = 500, mask_offset_x = 0, mask_offset_y = 2300)
#' }


preprocess <- function(source, output_dir, crop = 0, red_scale = 0, mask_pixels = 0, mask_offset_x = 0, mask_offset_y = 0, workers = NULL) {

  # Create an output directory if none exists, or if it exists with no files in it.
  if(length(output_dir) != 1) {
      print("'output_dir' must be a path to a single directory.")
      return(NULL)
  } else {
    args <- paste(args, "--output_dir", shQuote(output_dir))
  }
  if(!is.null(workers)){args <- paste(args, "--workers", workers)}
  
  if(workers > parallel::detectCores()){
    workers <- parallel::detectCores()
    cat(paste("You have requested more cores than are available. All", parallel::detectCores(), "cores will be used"))
  }
  out <- preprocess(source = source, output_dir = output_dir, crop = crop, red_scale = red_scale, mask_pixels = mask_pixels, mask_offset_x = mask_offset_x, mask_offset_y = mask_offset_y, workers = workers)
  if('status' %in% attributes(out)){
    return(out)
  } else {
    out <- sub("\\r", "", out)
#    if (any(grepl("^directory", out))){
      out <- out[-grep("^directory", out)] # drop announcement about a directory being created.
#    }
    if (any(grepl("^###", out))){
      out <- out[-grep("###Data###", out)] # drop the ###Data### marker
    }
    if (any(grepl("^$", out))){
      out <- out[-grep("^$", out)] # drop any blank rows
    }
    if (any(grepl("^,filename", out))){
      out <- out[-grep("^,filename", out)] # drop any header rows
    }
    
    out2 <- data.frame(matrix(unlist(strsplit(out, ",")), byrow= TRUE, ncol = 3))
    out2$X1 <- NULL
    names(out2) <- c('Filename', 'Error')
    #table(out2$Error)
    if(any(out2$Error != "No Error")){
      to_print <- out2
      to_print$Filename <- sub(".*/", "", to_print$Filename)
      tab <- table(to_print$Error[to_print$Error != 'No Error'])
      print(paste("NOTE: The following", sum(tab), "errors were found while preprocessing the directory:", source))
      print(paste(" ", names(tab), tab, collapse = "; "))
      print("  See returned data.frame for details.")
    }
    return(out2)
  }
}
