#' Assess Leaf Area for a Single Image
#'
#'This function assesses the area of leaves taken from a single image. Ideally, the image will be obtained from a flatbed scanner, and will include resolution information in the exif metadata. Images derived from cameras can also be used, but in that case, you will probably need to supply the resolution explictly, using the argument res.
#'
#' @param source The path to the image or the directory of images for which you want to assess the leaf area
#' @param output_dir The directory where to save the processed images, so that you can check that thresholding occurred as expected. Respects tilde expansion. By default, processed images are not saved. This must not be a directory that already exists, so that existing files are not over-written.
#' @param threshold A value between 0 (black) and 255 (white) for classification of background and leaf pixels. Default = 120
#' @param cut_off Clusters with fewer pixels than this value will be discarded. Default is 10000, which is about 3.3mm x 3.3mm, in a 300 dots per inch image.
#' @param combine If true the total area will be returned; otherwise each segment will be returned separately
#' @param res Image resolution, in dots per inch (DPI); if False the resolution will be read from the exif tag.'
#' @param workers By default, assess will use all but one core for processing a folder of images. Here, you can control how many cores are used. Ignored when assessing a single image.

#'
#' @return The assessed leaf area for a single image or entire folder of images, in cm^2 is returned as a \code{data.frame}.
#'
#' @examples
#' img <- ALFA_example("prepared/img1.jpg")
#' input_dir <- ALFA_example("prepared")
#' # If the argument output_dir is omitted,  do not save  processed images
#' assess(source = img, res = 400, combine = FALSE)
#' assess(source = input_dir, combine = FALSE)
#' \dontrun{
#' A new directory, 'processed1' will be created in the working directory
#' to hold the thresholded files. 
#' output_dir <- "processed1"
#' assess(source = input_dir, output_dir = output_dir, res = 400, combine = FALSE)
#' }

assess <- function(source, output_dir = NULL, threshold = 120, cut_off = 10000, combine = FALSE, res = NULL, workers = NULL) {
  path_to_python <- python_version()
  path_to_script <- paste(system.file(package="ALFA"), "ALFA.py", sep="/")
  
  args <- paste(shQuote(path_to_script), "estimate", shQuote(source), "--threshold", threshold, "--cut_off", cut_off)
  if(!is.null(output_dir)){args <- paste(args, "--output_dir", shQuote(output_dir))}
  if(!is.null(res)){args <- paste(args, "--res", shQuote(res))}
  if(combine){args <- paste(args, "--combine")}
  if(!is.null(workers)){args <- paste(args, "--workers", workers)}
  
  out <- system2(command = path_to_python, args = args, stdout = TRUE)
  if('status' %in% attributes(out)){
    return(out)
  } else{
    #If we have some data returned by Python, then process it
    out <- sub("\\r", "", out)
    if (any(grepl("^directory", out))){
      print(out[grep("^directory", out)])
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
    out2 <- data.frame(matrix(unlist(strsplit(out, ",")), byrow= TRUE, ncol = 5))
    names(out2) <- c('Chunk_number', 'Image', 'Area', 'Resolution', 'Error')
    out2$Chunk_number <- as.numeric(out2$Chunk_number) + 1
    out2$Area <- as.numeric(out2$Area)
    out2 <- out2[order(out2$Image, out2$Chunk_number),]
    rownames(out2) <- NULL
    return(out2)
  }
}


