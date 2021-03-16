# This script tests the ALFA programme against a couple sets of photos.
#
library(exifr)
library(devtools)
load_all()

# These files have NO resolution data in them. I mean, they have Xresolution and Yresolution fields in teh exif, but they're both '1'
EBCC_images <- "/Users/cetp/Documents/Professional/Projects/Completed/PhD research - Hazelwood/Trait Data/Leaf Scans"


EBCC_exif <- data.frame(read_exif(EBCC_images, recursive = T))
head(EBCC_exif)
EBCC_exif[,c("XResolution","YResolution")]

EBCC_exif2 <- data.frame(read_exif("~/Desktop/EBCC test/prepped", recursive = T))
EBCC_exif2[,c("XResolution","YResolution")]


names(EBCC_exif)
names(EBCC_exif2)

t1 <- Sys.time()
preprocess(source = EBCC_images, output_dir = "~/Desktop/EBCC test/prepped", crop = 30)
Sys.time()-t1 # this is only the prep time! Times are in seconds. 8.9 sec
# This only processes 25 images. Not clear why it stops.


preprocess(source = "/Users/cetp/Documents/Professional/Projects/Completed/PhD research - Hazelwood/Trait Data/Leaf Scans/1-CALAVEa.jpg", output_dir = "~/Desktop/EBCC test/prepped", crop = 30)
data.frame(read_exif("/Users/cetp/Documents/Professional/Projects/Completed/PhD research - Hazelwood/Trait Data/Leaf Scans/1-CALAVEa.jpg"))
data.frame(read_exif("~/Desktop/EBCC test/prepped/1-CALAVEa.jpg"))



t1 <- Sys.time()
EBCC_out <- assess("~/Desktop/EBCC test/prepped", output_dir = "~/Desktop/EBCC test/done")
Sys.time()-t1 # this is only the prep time! Times are in seconds



# Test all teh manuplants images. Many of tehse are not leaves, and none of them are scans. But it may be helpful for detecting problems.
MP_folders <- list.dirs("/Users/cetp/Documents/Professional/Stirling/guianaplants backup/plants/species")
MP_folders <- MP_folders[-(1:2)]
MP_folders <- MP_folders[grep("aceae$", MP_folders, invert = T)]
MP_folders <- MP_folders[-14]
MP_out <- numeric()
for(i in 1:length(MP_folders)){
  MP_exif1 <- data.frame(read_exif(MP_folders[i], recursive = T))
  res_name1 <- names(MP_exif1)[grepl("x|X", names(MP_exif1)) & grepl("reso|Reso",names(MP_exif1))]
  preprocess(source = MP_folders[i], output_dir = paste0("~/Desktop/MP test/prepped/", i), crop = 30)

  MP_exif2 <- data.frame(read_exif(paste0("~/Desktop/MP test/prepped/", i), recursive = T))
  res_name2 <- names(MP_exif2)[grepl("x|X", names(MP_exif2)) & grepl("reso|Reso",names(MP_exif2))]
  MP_out.i <- assess(dir = paste0("~/Desktop/MP test/prepped/", i), output_dir = paste0("~/Desktop/MP test/done/", i))
  assess(dir = paste0("~/Desktop/MP test/prepped/", i, "/Seed_2.jpg"), output_dir = paste0("~/Desktop/MP test/done/", i))

  MP_out.i$res1 <- MP_exif1[match(sub(".*/", "", MP_out.i$Image), sub(".*/", "", MP_exif1$SourceFile)),res_name1]
  MP_out.i$res2 <- MP_exif2[match(sub(".*/Desktop", "", MP_out.i$Image), sub(".*/Desktop", "", MP_exif2$SourceFile)),res_name2]
  MP_out <- rbind(MP_out, cbind(folder = i, MP_out.i, res_name1 = res_name1, res_name2 = res_name2))
}




# test the BALI images
BALI_images <- "/Users/cetp/LEAF SCANS fixed 2019/SLF/T51/B1S"
BALI_exif <- data.frame(read_exif(BALI_images, recursive = T))
head(BALI_images)
BALI_exif[,c("XResolution","YResolution")]

t1 <- Sys.time()
preprocess(source = BALI_images, output_dir = "~/Desktop/BALI test/prepped", crop = 30)
Sys.time()-t1 # this is only the prep time! Times are in seconds. 8.9 sec

t1 <- Sys.time()
BALI_out <- assess("~/Desktop/BALI test/prepped", output_dir = "~/Desktop/BALI test/done")
Sys.time()-t1 # this is only the prep time! Times are in seconds

