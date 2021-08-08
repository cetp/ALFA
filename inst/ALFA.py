#!/usr/bin/env python3


import sys
import argparse
import multiprocessing
import os
from os import listdir
from os.path import isfile, isdir, join
import tempfile
import cv2
import csv
import numpy as np
import pandas as pd
import exif as ef
import piexif
import shutil
from pandas.core.frame import DataFrame
from skimage import measure

class ALFA:
    """Calculate leaf area."""

    def __init__(self, red_scale: int = 0, red_scale_pixels: int = 0, mask_pixels: int = 0,
                 mask_offset_y: int = 0, mask_offset_x: int = 0,
                 threshold: int = 120, cut_off: int = 10000, output_dir: str = tempfile.TemporaryDirectory().name,
                 crop: int = 0, combine: bool = True, res: int = 0,
                 workers: int = multiprocessing.cpu_count() - 1):
        """
        Initiate (default) variables.
        @param red_scale: whether or not to add a red scale
        @param red_scale_pixels: how many pixels wide the side of the scale should be
        @param mask_offset_x: offset for the masking window in number of pixels from top to bottom of the image
        @param mask_offset_y: offset for the masking window in number of pixels from right to left of the image
        @param mask_pixels: how many pixels each side of the masking window should be
        @param threshold: value for contrast analysis
        @param cut_off: patches below this number of pixels will not be counted
        @param output_dir: where to save the images
        @param crop: remove the edges of the image
        @param combine: combine all patches into a single LA estimate T/F
        @param res: specify resolution manually
        @param workers: how many cores to use for multiprocessing; def: all but one
        """
        self.red_scale = red_scale
        self.red_scale_pixels = red_scale_pixels
        self.mask_pixels = mask_pixels
        self.mask_offset_y = mask_offset_y
        self.mask_offset_x = mask_offset_x
        self.threshold = threshold
        self.cut_off = cut_off
        self.output_dir = output_dir
        self.crop = crop
        self.combine = combine
        self.res = res
        self.workers = workers

    def estimate(self, img: str) -> DataFrame:
        """
        Estimate leaf area for a given image or directory of images.

        TO DO: filter images only in the folder - ask the user for extension?

        @param img: path to the scan or images folder. respects tilde expansion
        @return pandas DF with the file name of the input and the estimated area(s)
        """

        if os.path.isfile(os.path.abspath(os.path.expanduser(img))):
            # read the image resolution
            if not self.res:
                with open(os.path.expanduser(img), 'rb') as image_meta:
                    try:
                        metadata = ef.Image(image_meta)
                    except:
                        return pd.DataFrame(data={'filename': [img], 'Area': None, 'Resolution': None, 'Error' : 'Unable to access EXIF Data for image.'})

                if (not metadata.has_exif) or not(hasattr(metadata, 'x_resolution') or hasattr(metadata, 'Xresolution')):
                    #raise ValueError("Image of unknown resolution. Please specify the res argument in dpi.")
                    return pd.DataFrame(data={'filename': [img], 'Area': None, 'Resolution': None, 'Error' : 'Image of unknown resolution. Please specify the res argument in dpi.'})
                
                if hasattr(metadata, 'x_resolution'):
                    if not metadata.x_resolution == metadata.y_resolution:
                        #raise ValueError( "X and Y resolutions differ in Image. This is unusual, and may indicate a problem.")
                        return pd.DataFrame(data={'filename': [img], 'Area': None, 'Resolution': None, 'Error' : 'X and Y resolutions differ in Image. This is unusual, and may indicate a problem.'})
                    else:
                        self.res = metadata.x_resolution
                elif hasattr(metadata, 'Xresolution'):
                    if not metadata.Xresolution == metadata.Yresolution:
                        #raise ValueError( "X and Y resolutions differ in Image. This is unusual, and may indicate a problem.")
                        return pd.DataFrame(data={'filename': [img], 'Area': None, 'Resolution': None, 'Error' : 'X and Y resolutions differ in Image. This is unusual, and may indicate a problem.'})
                    else:
                        self.res = metadata.Xresolution

                else:
                    if not metadata.XResolution == metadata.YResolution:
                        #raise ValueError( "X and Y resolutions differ in Image. This is unusual, and may indicate a problem.")
                        return pd.DataFrame(data={'filename': [img], 'Area': None, 'Resolution': None, 'Error' : 'X and Y resolutions differ in Image. This is unusual, and may indicate a problem.'})
                    else:
                        self.res = metadata.XResolution

            # read the scan
            try:
                scan = cv2.imread(os.path.expanduser(img))
            except:
                return pd.DataFrame(data={'filename': [img], 'Area': None, 'Resolution': None, 'Error' : 'Unable to open image for processing. Check the file format.'})
        
            if scan is None:
                return pd.DataFrame(data={'filename': [img], 'Area': None, 'Resolution': None, 'Error' : 'Unable to open image for processing. Check the file format.'})

            # transfer to grayscale
            scan = cv2.cvtColor(scan, cv2.COLOR_BGR2GRAY)

            # classify leaf and background
            if self.threshold < 0 or self.threshold > 255:
                #raise ValueError("Threshold must be an integer between 0 and 255.")
                return pd.DataFrame(data={'filename': [img], 'Area': None, 'Resolution': None, 'Error' : 'Error: Threshold must be an integer between 0 and 255.'})

            scan = cv2.threshold(scan, self.threshold, 255, cv2.THRESH_BINARY_INV)[1]

            # label leaflets
            leaflets = measure.label(scan, background=0)

            # count number of pixels in each label
            leaflets = np.unique(leaflets, return_counts=True)

            # create mask to remove dirt and background
            mask = np.ones(len(leaflets[1]), dtype=bool)

            # remove small patches
            if self.cut_off < 0:
                #raise ValueError("cutoff for small specks must not be negative.")
                return pd.DataFrame(data={'filename': [img], 'Area': None, 'Resolution': None, 'Error' : 'cutoff for small specks must not be negative.'})
            
            mask[leaflets[1] < self.cut_off] = False

            # remove background pixels
            mask[leaflets[0] == 0] = False  # background is labeled as 0

            # apply mask
            areas = leaflets[1][mask]

            # convert from pixels to cm2
            res = self.res / 2.54  # 2.54 cm in an inch
            res = res * res  # pixels per cm^2
            areas = areas / res

            # save image
            if self.output_dir:
                if os.path.isdir(self.output_dir):
                    write_to = os.path.join(os.path.expanduser(self.output_dir), os.path.basename(img))
                    cv2.imwrite(write_to, scan)
                    if not self.res:
                        #If we are supplying the resolution, we don't don't touch the exif data
                        piexif.transplant(os.path.abspath(os.path.expanduser(img)), write_to)

            if self.combine:
                return pd.DataFrame(data={'filename': [img], 'Area': [areas.sum()], 'Resolution': self.res, 'Error' : 'No Error'})
            else:
                return pd.DataFrame(data={'filename': [img] * areas.shape[0], 'Area': areas, 'Resolution': self.res, 'Error' : 'No Error'})
        elif os.path.isdir(os.path.abspath(os.path.expanduser(img))):
            
            if os.path.abspath(os.path.expanduser(img)) == self.output_dir:
                return None
            
            # obtain a list of images
            images = os.listdir(os.path.abspath(os.path.expanduser(img)))
            images = [os.path.join(img, i) for i in images]
            # print(self.workers)
            # create a workers pool and start processing
            pool = multiprocessing.Pool(self.workers)
            results = pool.map(self.estimate, images)
            pool.close()
            pool.join()

            # unify the results into a single dataframe
            return pd.concat(results)
        else:
            #raise ValueError('Your input {img} needs to be a path to an image or a directory.')
            return pd.DataFrame(data={'filename': [img], 'Area': None, 'Resolution': None, 'Error' : 'Your input {img} needs to be a path to an image or a directory.'})

    def preprocess(self, img):
        """
        Pre-processes an image by cropping its edges, adding a red scale, masking existing scales and converting to jpg.

        @param img: path to the image or folder of images to process
        @return None
        """
        if os.path.isfile(os.path.abspath(os.path.expanduser(img))):
            #if not self.output_dir:
            #    output_dir = f'{os.path.split(os.path.isfile(os.path.abspath(os.path.expanduser(img))))[0]}/preprocessed'
            #    os.makedirs(output_dir)

            if os.path.split(os.path.abspath(os.path.expanduser(img)))[0] == self.output_dir:
                #raise ValueError(
                #    'You have provided identical paths for the source and destination images.' +
                #    'This would cause your file to be overwritten. Execution has been halted.')
                return pd.DataFrame(data={'filename': [img], 'Pre-process Result' : 'Error: You have provided identical paths for the source and destination image.'})
            # read the image
            try:
                scan = cv2.imread(os.path.abspath(os.path.expanduser(img)))
            except:
                return pd.DataFrame(data={'filename': [img], 'Pre-process Result' : 'Error: Unable to open source file.'})

            #Check for error state
            if scan is None:
                return pd.DataFrame(data={'filename': [img], 'Pre-process Result' : 'Error: Unable to open source file.'})


            dims = scan.shape

            # crop the edges
            if self.crop:
                if self.crop < 0:
                    #print(f'You have attempted to crop a negative number of pixels.')
                    #raise ValueError('You have attempted to crop a negative number of pixels.')
                    return pd.DataFrame(data={'filename': [img], 'Pre-process Result' : 'Error: You have attempted to crop a negative number of pixels.'})
                if self.crop > dims[0] or self.crop > dims[1]:
                    #raise ValueError('You have attempted to crop away more pixels than are available in the image.')
                    return pd.DataFrame(data={'filename': [img], 'Pre-process Result' : 'Error: You have attempted to crop away more pixels than are available in the image.'})
                scan = scan[self.crop:dims[0] - self.crop, self.crop:dims[1] - self.crop]

            # mask scale
            if self.mask_pixels:
                if self.mask_offset_y < 0 or self.mask_offset_x < 0 or self.mask_pixels < 0:
                    #raise ValueError("You have attempted to mask a negative number of pixels.")
                    return pd.DataFrame(data={'filename': [img], 'Pre-process Result' : 'Error: You have attempted to mask a negative number of pixels.'})

                if self.mask_offset_y + self.mask_pixels > dims[0] or self.mask_offset_x + self.mask_pixels > dims[1]:
                    #raise ValueError("You have attempted to mask more pixels than are available in the image.")
                    return pd.DataFrame(data={'filename': [img], 'Pre-process Result' : 'Error: You have attempted to mask more pixels than are available in the image.'})

                scan[self.mask_offset_y:self.mask_offset_y + self.mask_pixels,
                     self.mask_offset_x:self.mask_offset_x + self.mask_pixels,
                     0] = 255  # b channel
                scan[self.mask_offset_y:self.mask_offset_y + self.mask_pixels,
                     self.mask_offset_x:self.mask_offset_x + self.mask_pixels,
                     1] = 255  # g channel
                scan[self.mask_offset_y:self.mask_offset_y + self.mask_pixels,
                     self.mask_offset_x:self.mask_offset_x + self.mask_pixels,
                     2] = 255  # r channel

            # add scale
            if self.red_scale:
                if self.red_scale_pixels > dims[0] or self.red_scale_pixels > dims[1]:
                    #raise ValueError("You have attempted to place a scale bar beyond the margins of the image.")
                    return pd.DataFrame(data={'filename': [img], 'Pre-process Result' : 'Error: You have attempted to place a scale bar beyond the margins of the image.'})
                scan[0:self.red_scale_pixels, 0:self.red_scale_pixels, 0] = 0  # b channel
                scan[0:self.red_scale_pixels, 0:self.red_scale_pixels, 1] = 0  # g channel
                scan[0:self.red_scale_pixels, 0:self.red_scale_pixels, 2] = 255  # red channel

            # file name
            file_name = os.path.basename(os.path.abspath(os.path.expanduser(img)))
            file_name = f'{os.path.splitext(file_name)[0]}.jpg'
            file_name = os.path.join(os.path.abspath(os.path.expanduser(self.output_dir)), file_name)

            # save as jpg
            try:
                metadata = ef.Image(os.path.abspath(os.path.expanduser(img)))
            except:
                #Image write failure
                cv2.imwrite(file_name, scan)
                return pd.DataFrame(data={'filename': [img], 'Pre-process Result' : 'Error: EXIF data could not be loaded from source image.'})

            #Create the processed image (even if EXIF data isn't viable)
            cv2.imwrite(file_name, scan)
            
            #if (not metadata.has_exif) or not(hasattr(metadata, 'x_resolution') or hasattr(metadata, 'Xresolution')):

            if (not metadata.has_exif) or not(hasattr(metadata, 'x_resolution') or hasattr(metadata, 'Xresolution')):
                # EXIF has no resolution data present
                return pd.DataFrame(data={'filename': [img], 'Pre-process Result' : 'Error: EXIF Resolution Data Not transferred to Pre-processed image.'})
            else:
                try:
                    piexif.transplant(os.path.abspath(os.path.expanduser(img)), file_name)
                except:
                    #Return a data frame to the caller to indicate success 
                    return pd.DataFrame(data={'filename': [img], 'Pre-process Result' : 'Error: Unable to copy EXIF data to processed image.'})

                #Return a data frame to the caller to indicate success 
                return pd.DataFrame(data={'filename': [img], 'Pre-process Result' : 'No Error'})
                

        elif os.path.isdir(os.path.abspath(os.path.expanduser(img))):
            
            if os.path.abspath(os.path.expanduser(img)) == self.output_dir:
                return None
            
            images = os.listdir(os.path.abspath(os.path.expanduser(img)))
            images = [os.path.join(os.path.abspath(os.path.expanduser(img)), i) for i in images]

            # create a workers pool and start processing
            pool = multiprocessing.Pool(self.workers)
            results = pool.map(self.preprocess, images)
            pool.close()
            pool.join()

            return pd.concat(results)
        else:
            #os.rmdir(output_dir)
            return pd.DataFrame(data={'filename': [img], 'Pre-process Result' : 'Unable to open file or directory.'})
            #raise ValueError(f'Your input {img} needs to be either a file or a directory')
    
    
    def resolution_sort_image_files(self,the_dir='./'):
        if os.path.isdir(os.path.abspath(os.path.expanduser(the_dir))):
            the_dir = os.path.expanduser(the_dir)
            file_list = [f for f in listdir(the_dir) if isfile(join(the_dir, f))]
            for current_file in file_list:
                current_file_path = os.path.abspath(os.path.join(the_dir,current_file))
                if os.path.isfile(current_file_path):
                    with open(current_file_path, 'rb') as image_meta:
                        # Sort by resolution
                        # Check if we are working with an image file with exif information
                        try: 
                            metadata = ef.Image(image_meta)
                            if  metadata.has_exif:
                                #EXIF Resolution variants
                                if hasattr(metadata, 'x_resolution'): 
                                    dir_name = 'resolution_'+str(round(metadata.x_resolution))
                                elif hasattr(metadata, 'Xresolution'):
                                    dir_name = 'resolution_'+str(round(metadata.Xresolution))
                                else:
                                    #EXIF with no recognised resolution attribute
                                    dir_name = 'resolution_NA'
                            else:
                                #No reported EXIF on file
                                dir_name = 'resolution_NA'         
                        except:
                            #Unaccessible EXIF or different file type
                            dir_name = 'resolution_NA'

                        dir_name = os.path.abspath(os.path.join(the_dir,dir_name))
                        if not(os.path.exists(dir_name) & isdir(dir_name)):
                            # Create the directory for the resolution
                            os.mkdir(dir_name)
                            
                        # Move the image to the directory 
                        new_file_path = os.path.abspath(dir_name+'/'+current_file)
                        image_meta.close()
                        shutil.move(current_file_path, new_file_path)

        else:
            raise ValueError('Could not find directory to sort')

    def num_file_sort_image_files(self,the_dir='./', num_img_per_dir = 2):
        if os.path.isdir(os.path.abspath(os.path.expanduser(the_dir))):
            the_dir = os.path.abspath(os.path.expanduser(the_dir))
            file_list = [f for f in listdir(the_dir) if isfile(join(the_dir, f))]
            cur_file_count = 0
            dir_count = 1
            new_dir_name = os.path.join(the_dir,'images_'+str(dir_count))
            if len(file_list) > 0:
                if not (os.path.exists(new_dir_name)):
                    os.mkdir(new_dir_name)
                    dir_count = dir_count + 1

            for curent_file in file_list:
                current_file_path = os.path.join(the_dir,curent_file)
                if os.path.isfile(current_file_path):

                    if cur_file_count >= num_img_per_dir:
                        new_dir_name = os.path.join(the_dir,'images_'+str(dir_count))
                        if not (os.path.exists(new_dir_name)):
                            os.mkdir(new_dir_name)
                        dir_count = dir_count + 1
                        cur_file_count = 0

                    new_file_path = os.path.join(new_dir_name,curent_file)
                    shutil.move(current_file_path, new_file_path)
                    cur_file_count = cur_file_count + 1
        else:
            raise ValueError('Could not find Directory to sort')

class ErrorParser(argparse.ArgumentParser):
    def error(self, message):
        sys.stderr.write('error: %s\n' % message)
        self.print_help()
        sys.exit(2)


# Parse arguments
parser = ErrorParser(prog='ALFA.py')
subparsers = parser.add_subparsers(dest='command')
subparsers.required = True

pre_processing_parser = subparsers.add_parser('preprocess',
                                              help='Pre-process images of leaves so that their areas can be assessed.')
pre_processing_parser.add_argument("-c", "--crop", type=int, default=0,
                                   help="Number of pixels to crop off the margins of the image? Cropping occurs before "
                                        "the other operations, so that they are performed on the cropped image.")
pre_processing_parser.add_argument("--red_scale", type=int, default=0,
                                   help="How many pixels wide should the side of the scale should be?")
pre_processing_parser.add_argument("--mask_pixels", type=int, default=0,
                                   help="How many pixels should each side of the masking window be?")
pre_processing_parser.add_argument("--mask_offset_x", type=int, default=0,
                                   help="Offset for positioning the masking window in number of pixels from right to "
                                        "left of the image")
pre_processing_parser.add_argument("--mask_offset_y", type=int, default=0,
                                   help="Offset for positioning the masking window in number of pixels from top to "
                                        "bottom of the image")
pre_processing_parser.add_argument('--csv', type=str, help='name of output csv (to be saved in pwd)')

estimate_parser = subparsers.add_parser('estimate', help='Assess images of leaves to determine their areas.')
estimate_parser.add_argument("-t", "--threshold", type=int, default=120,
                             help="a value between 0 (black) and 255 (white) for classification of background "
                                  "and leaf pixels. Default = 120")
estimate_parser.add_argument("--cut_off", type=int, default=10000,
                             help="Clusters with fewer pixels than this value will be discarded. Default is 10000",)
estimate_parser.add_argument("-c", "--combine", action='store_true',
                             help="If true the total area will be returned; otherwise each segment will "
                                  "be returned separately")
estimate_parser.add_argument("--res", type=int, default=0,
                             help="image resolution, in dots per inch (DPI); if False the resolution will be "
                                  "read from the exif tag")
estimate_parser.add_argument('--csv', type=str, help='name of output csv (to be saved in pwd)')

resolution_sort_parser = subparsers.add_parser('resolution_sort', help='Sort images into sub directories by resolution')
resolution_sort_parser.add_argument("input", type=str, help="Path to image or folder with images. Respects tilde expansion.")

number_sort_parser = subparsers.add_parser('number_sort', help='Sort images into sub directories by number of images')
number_sort_parser.add_argument("--fileno", type=int, default=2,
                                   help="Number of images per sub directory")
number_sort_parser.add_argument("input", type=str, help="Path to image or folder with images. Respects tilde expansion.")




for p in [pre_processing_parser, estimate_parser]:
    p.add_argument("input", type=str, help="Path to image or folder with images. Respects tilde expansion.")
    p.add_argument("--output_dir", type=str, help="Where to save the output. Respects tilde expansion.")
    p.add_argument("-w", "--workers", type=int, default=multiprocessing.cpu_count() - 1,
                   help="How many cores to use? Default is to use all available minus one. "
                        "Only relevant when assessing a folder, ignored otherwise.")


where_parser = subparsers.add_parser('example', help='Print the directory where example images are saved.')

args = parser.parse_args()


if __name__ == '__main__':
    estimator = ALFA()

    if args.command == 'estimate':
        output_dir = None
        if args.output_dir:
            output_dir = os.path.abspath(os.path.expanduser(args.output_dir))
           
            if os.path.split(os.path.abspath(os.path.expanduser(args.input)))[0] == output_dir:
                raise NameError(
                    'You have provided identical paths for the source and destination directories. '
                    'This would cause your files to be overwritten. Execution has been halted. ')
            
            estimator.output_dir = output_dir
            if not os.path.exists(output_dir):
                os.makedirs(output_dir)
                print(f'directory {output_dir} created')
            else:
                raise NameError("Output directory already exists. Output files may overwrite existing files. "
                                "Please choose a different output directory.")
        estimator.res = args.res
        estimator.workers = args.workers
        estimator.combine = args.combine
        estimator.cut_off = args.cut_off
        estimator.threshold = args.threshold

        output = estimator.estimate(args.input)
        print('###Data###')
        print(output[['filename','Area', 'Resolution','Error']].to_csv(sep=',')) #quoting=csv.QUOTE_NONE)
        if args.csv:
            output[['filename','Area', 'Resolution','Error']].to_csv(args.csv)

        #Check that there actually were some images successfully processed.
        #If not, delete the the output directory.
        if output_dir is not None:
            file_list = [f for f in listdir(output_dir) if isfile(join(output_dir, f))]
            if len(file_list) == 0:
                os.rmdir(output_dir)


    elif args.command == 'preprocess':

        if args.output_dir: 
            output_dir = os.path.abspath(os.path.expanduser(args.output_dir))
        else:

            if os.path.isdir(os.path.abspath(os.path.expanduser(args.input))):
                output_dir = os.path.join(os.path.abspath(os.path.expanduser(args.input)),'preprocessed')
            else:
                output_dir = os.path.join(os.path.split(os.path.abspath(os.path.expanduser(args.input)))[0],'preprocessed')
            
        
        if not os.path.exists(output_dir):
            estimator.output_dir = output_dir
            os.makedirs(output_dir)
            print(f'directory {output_dir} created')
        else:
            raise NameError(
                "Output directory already exists. Output files may overwrite existing files. "
                "Please choose a different output directory.")

        if os.path.split(os.path.abspath(args.input))[0] == output_dir:
            raise NameError(
                'You have provided identical paths for the source and destination directories. '
                'This would cause your files to be overwritten. Execution has been halted. ')

        estimator.crop = args.crop
        estimator.red_scale = args.red_scale
        estimator.mask_pixels = args.mask_pixels
        estimator.mask_offset_x = args.mask_offset_x
        estimator.mask_offset_y = args.mask_offset_y
        estimator.workers = args.workers

        output =  estimator.preprocess(args.input)
        print('###Data###')
        print(output[['filename','Pre-process Result']].to_csv(sep=',')) #quoting=csv.QUOTE_NONE)
        if args.csv:
            output[['filename','Pre-process Result']].to_csv(os.path.join(output_dir,args.csv))

        #Check that there actually were some images sucessfully processed.
        #If not, delete the the output directory.
        file_list = [f for f in listdir(output_dir) if isfile(join(output_dir, f))]
        if len(file_list) == 0:
            os.rmdir(output_dir)

    elif args.command == 'resolution_sort':
        estimator.resolution_sort_image_files(args.input)

    elif args.command == 'number_sort':
        estimator.num_file_sort_image_files(args.input,args.fileno)

    elif args.command == 'example':
        print(static)
