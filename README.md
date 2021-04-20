# ALFA
ALFA (Assess LeaF Area) is a simple collection of functions to aid with the estimation of leaf area from scanned images. It can process single scans or multiple images in a single directory using one or multiple cores. ALFA returns estimated areas for all leaf fragments in an image, or for each of them individually. 

ALFA is written in Python and utilises the power of the [OpenCV](https://opencv.org/) library to quickly analyse your images. You can interface with the functions via python, R or the command line to best match your workflow. Instructions on how to get going can be found below. 

This package was developed by [Boris Bongalov](https://bongalov.com) with substantial input from [Sabine Both](https://www.une.edu.au/staff-profiles/ers/sabine-both) and [C. E. Timothy Paine](https://www.une.edu.au/staff-profiles/ers/timothy-paine) and [Mitchell Welch](https://www.une.edu.au/staff-profiles/science-and-technology/mitchell-welch). For detail on the background and motivation of this project, please consult our article introducing ALFA: Paine CET, Bongalov B, Welch, M, and Both S. "‘ALFA’ (Assess LeaF Area): An optimal method for assessing leaf area" (in prep). Methods in Ecology & Evolution.

Please report any bugs or problems to [C. E. Timothy Paine](mailto:cetpaine@gmail.com). Pull requests are welcome!

# Installation
ALFA can be installed as an R package, via [CRAN](https://cran.r-project.org). Alternatively, the python script is available on Github, at https://github.com/cetp/ALFA/blob/master/inst/ALFA.py. Both will require you to have Python ≥3.5 on your system. this should already be the case if you are using Mac, Linux or updated version of Windows 10. Python is downloadable from https://www.python.org/downloads/. Several Python modules are also required: cv2, numpy, pandas, exif, piexif, and skimage. The can be installed using pip from the command line.

# Workflow
Using ALFA requires first that you process your images using the function `preprocess`, then assess the size of the leaves in the processed images using `assess`. The use of two separate functions is intentional: it gives the user the opportunity to examine the processed images, to assure themselves that the assessed leaf area reflects the leaves in the images, rather than shadows or dirt. Both `preprocess` and `assess` function either on a single image, or on an entire directory of images. Currently, ALFA works only on .jpgs. 

## `preprocess`
The preprocess() function reads an image or directory of images, giving the user the opportunity to edit it to prepare it for analysis. Common modifications include placing a mask over an existing scale bar, adding a scale bar of a given size, and cropping away the margins of an image. `preprocess` accepts the following arguments: 
* source The path to the image, or directory of images, which you want to prepare for assessment.
* output_dir The directory where to save the processed images, so that they can be assessed using \code{assess}. Respects tilde expansion. This must not be a directory that already exists, so that existing files are not over-written.
* crop Should the margins of the image be cropped? Cropping occurs before the other operations, meaning that they are performed on the cropped image. Value is one integer; number of pixels to be removed from (top, bottom, left, right) of the image. Default = 0.
* red_scale How many pixels wide should the side of the scale should be? Default = 0.
* mask_pixels How many pixels should each side of the masking window be? Default = 0.
* mask_offset_x Offset for positioning the masking window in number of pixels from right to left of the image.
* mask_offset_y Offset for positioning the masking window in number of pixels from bottom to top of the image.
* workers By default, preprocess will use all but one core for processing a folder of images. Here, you can control how many cores are used. Ignored when preprocessing a single image. If you are limited by RAM or wish to do other computationally-intensive work while you are processing the images, you may wish to reduce the number of cores made available to the function.

## `assess`
The `assess` function reads a prepared image or directory of prepared images, and returns a dataframe with the image name, resolution of the image (in dots per inch [DPI]) and leaf area estimate (in cm^2). It combines all leaf patches by default but it can also return the area of each leaf(let) if needed. Currently, there is no way to know which area corresponds to each leaf fragment, but this functionality may be added in the future. 

`assess` accepts the following arguments: 
* source The path to the image or directory on which you want to assess the leaf area(s)
* output_dir The path to the directory where processed images should be saved, so that you can check that thresholding occurred as expected. Respects tilde expansion. By default, processed images are not saved. This must not be a directory that already exists, so that existing files are not over-written.
* threshold A value between 0 (black) and 255 (white) for classification of background and leaf pixels. Default = 120
* cut_off Clusters with fewer pixels than this value will be discarded. Default is 10000, which is about 3.3mm x 3.3mm, in a 300 DPI image.
* combine If TRUE the total area will be returned; otherwise each segment will be returned separately. Defaults to FALSE.
* res Image resolution, in dots per inch (DPI); if FALSE, the resolution will be read from the exif tag.
* workers By default, assess will use all but one core for processing a folder of images. Here, you can control how many cores are used. Ignored when assessing a single image. If you are limited by RAM or wish to do other computationally-intensive work while you are processing the images, you may wish to reduce the number of cores made available to the function.

# python interface
Once the package is installed, its functions can be called directly in Python:

```python 
# process a single scan and save the estimate to a variable and the processed image to the current working directory
est = ALFA.estimate("./images/image.jpg", output_dir="./")
est = ALFA.estimate("./images/*jpg", output_dir="./")
```

# command line interface

leafareavision includes two command line tools to processes single images or batch process entire directories. On Mac and Linux, pip will make those available to your command line interface as long as your path is set up correctly. pip will issue a warning if this is not the case. I am not sure how thigs work on windows systems, feedback from your experiments is appreciated. 

Running the scripts with an -h argument will print help message with instructions on how to use them.

For individual scnas use scanLA:
```bash
usage: scanLA [-h] [-threshold THRESHOLD] [-cut_off CUT_OFF]
              [-output_dir OUTPUT_DIR] [-crop_top CROP_TOP]
              [-crop_bottom CROP_BOTTOM] [-crop_left CROP_LEFT]
              [-crop_right CROP_RIGHT] [-combine COMBINE] [-res RES]
              [-csv CSV]
              img

Estimate the area of a scanned leaf

positional arguments:
  img                   path to the scan

optional arguments:
  -h, --help            show this help message and exit
  -threshold THRESHOLD  a value between 0 (black) and 255 (white) for
                        classification of background and leaf pixels
  -cut_off CUT_OFF      integer; clusters with number of pixels lower than
                        this value will be discarded
  -output_dir OUTPUT_DIR
                        path, if specified, the classified image will be saved
                        there
  -crop_top CROP_TOP    four integers; number of pixels to be removed form
                        (top, bottom, left, right) of the image
  -crop_bottom CROP_BOTTOM
                        four integers; number of pixels to be removed form
                        (top, bottom, left, right) of the image
  -crop_left CROP_LEFT  four integers; number of pixels to be removed form
                        (top, bottom, left, right) of the image
  -crop_right CROP_RIGHT
                        four integers; number of pixels to be removed form
                        (top, bottom, left, right) of the image
  -combine COMBINE      boolean; if true the total area will be returned;
                        otherwise each segment will be returned separately
  -res RES              image resolution; if False the resolution will be read
                        from the exif tag
  -csv CSV              path to a csv file to save the output

```

For folders of scans use batchLA:
```bash
usage: batchLA [-h] [-workers WORKERS] [-threshold THRESHOLD]
               [-cut_off CUT_OFF] [-output_dir OUTPUT_DIR]
               [-crop_top CROP_TOP] [-crop_bottom CROP_BOTTOM]
               [-crop_left CROP_LEFT] [-crop_right CROP_RIGHT]
               [-combine COMBINE] [-res RES] [-csv CSV]
               path

Estimate the area of a scanned leaves in batch

positional arguments:
  path                  folder to list images in; specifying file format (e.g.
                        *.jpg) is expected

optional arguments:
  -h, --help            show this help message and exit
  -workers WORKERS      how many cores to use - default is all available but
                        one
  -threshold THRESHOLD  a value between 0 (black) and 255 (white) for
                        classification of background and leaf pixels
  -cut_off CUT_OFF      integer; clusters with number of pixels lower than
                        this value will be discarded
  -output_dir OUTPUT_DIR
                        path, if specified, the classified image will be saved
                        there
  -crop_top CROP_TOP    four integers; number of pixels to be removed form
                        (top, bottom, left, right) of the image
  -crop_bottom CROP_BOTTOM
                        four integers; number of pixels to be removed form
                        (top, bottom, left, right) of the image
  -crop_left CROP_LEFT  four integers; number of pixels to be removed form
                        (top, bottom, left, right) of the image
  -crop_right CROP_RIGHT
                        four integers; number of pixels to be removed form
                        (top, bottom, left, right) of the image
  -combine COMBINE      boolean; if true the total area will be returned;
                        otherwise each segment will be returned separately
  -res RES              image resolution; if False the resolution will be read
                        from the exif tag
  -csv CSV              path to a csv file to save the output
```








