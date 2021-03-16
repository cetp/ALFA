
import os
from os import listdir
from os.path import isfile,isdir, join
from exif import Image
import shutil

def resolution_sort_image_files(the_dir='./'):
    the_dir = os.path.expanduser(the_dir)
    file_list = [f for f in listdir(the_dir) if isfile(join(the_dir, f))]
    for curent_file in file_list:
        current_file_path = os.path.abspath(os.path.join(the_dir,curent_file))
        if os.path.isfile(current_file_path):
            with open(current_file_path, 'rb') as image_meta:
                # Sort by resolution
                # Check if we are working with an image file with exif information
                # We will not touch the file if it doesn't have enough info.
                metadata = Image(image_meta)
                if  metadata.has_exif:
                    print(metadata.x_resolution)
                    dir_name = 'resolution_'+str(round(metadata.x_resolution))
                    #dir_name = dir_name.replace('.','_')
                    dir_name = os.path.abspath(os.path.join(the_dir,dir_name))
                    if not(os.path.exists(dir_name) & isdir(dir_name)):
                        # Create the directory for the resolution
                        os.mkdir(dir_name)
                        
                    # Move the image to the directory 
                    print(dir_name)
                    new_file_path = os.path.abspath(dir_name+'/'+curent_file)
                    image_meta.close()
                    shutil.move(current_file_path, new_file_path)

def num_file_sort_image_files(the_dir='./', num_img_per_dir  = 2):
    the_dir = os.path.abspath(os.path.expanduser(the_dir))
    file_list = [f for f in listdir(the_dir) if isfile(join(the_dir, f))]
    cur_file_count = 0
    dir_count = 1
    new_dir_name = os.path.join(the_dir,'images_')
    if len(file_list) > 0:
        if not (os.path.exists(new_dir_name)):
            os.mkdir(new_dir_name)

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



#num_file_sort_image_files('./extdata/raw',3)

resolution_sort_image_files('./extdata/raw_2')





