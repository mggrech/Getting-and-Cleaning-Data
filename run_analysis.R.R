## 0. Data downloading, unzipping and reading into R

## Download the zip file and unzip the contents
## The unzipped data is automatically stored in a directory 
## called UCI HAR dataset

url <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"

download.file(url, destfile="./data.zip", method="curl")
unzip(zipfile="./data.zip", exdir = ".")

## Read in the features data. This is common to both the Training and Test
## data sets.

features <- read.table(file="./UCI HAR dataset/features.txt")

###############################################################################
## Read in the Test data

test_subject <- read.table(file="./UCI HAR dataset/test/subject_test.txt", 
                           col.names = "subject_ID")

test_set <- read.table(file="./UCI HAR dataset/test/x_test.txt")

test_label <- read.table(file="./UCI HAR dataset/test/y_test.txt",
                         col.names = "activity_label")

## Name the columns of the test set according to the features

colnames(test_set) <- features[,2]

## Combine all information pertaining to the Test data set, including subject, 
## activity label and the actual test data 

test_data <- cbind(test_subject,test_label,test_set)

###############################################################################
## Read in the Training data

train_subject <- read.table(file="./UCI HAR dataset/train/subject_train.txt", 
                           col.names = "subject_ID")

train_set <- read.table(file="./UCI HAR dataset/train/x_train.txt")

train_label <- read.table(file="./UCI HAR dataset/train/y_train.txt",
                         col.names = "activity_label")

## Name the columns of the training set according to the features

colnames(train_set) <- features[,2]

## Combine all information pertaining to the Training data set, 
## including subject, activity label and the actual training data. 

train_data <- cbind(train_subject,train_label,train_set)

###############################################################################
## 1. Merge the Training and Test sets to create one data set

merged_data <- rbind(train_data,test_data)

###############################################################################
## 2. Extract only the measurements on the mean and standard deviation
## for each measurement

## First find which columns contain the word "mean" and "std" (as standard deviation
## was abbreviated as "std"by the creators of the data) in the column name

mean_idx <- grep("mean",names(merged_data))
std_idx <- grep("std",names(merged_data))
idx <- c(mean_idx, std_idx)

## Then extract the corresponding measurements for mean and standard deviation
## Note: the subject ID and activity label stored in columns 1 and 2 also
## need also be kept as they are required for the next steps

mean_std_data <- merged_data[,c(1,2,idx)]

###############################################################################
## 3. Use descriptive names to name the activities in the data set

activities <- read.table(file="./UCI HAR dataset/activity_labels.txt",
                         col.names=c("activity_label","activity_name"))

## Read in the file with the activity_labels. There are 6 activities with the
## following names: 
##  1 WALKING
##  2 WALKING_UPSTAIRS
##  3 WALKING_DOWNSTAIRS
##  4 SITTING
##  5 STANDING
##  6 LAYING

## These descriptive names are used to name the activities in the 
## mean_std_data data set created above

mean_std_activity <- subset(merge(mean_std_data, activities, 
                           by="activity_label", sort=FALSE), select = -1)

###############################################################################
## 4. Appropriately label the data set with descriptive variable names

install.packages("mgsub")
library(mgsub)

## Replace underscores, non-meaningful abbreviations, brackets, duplication
## to create meaningful variable names.

colnames(mean_std_activity) <- mgsub(colnames(mean_std_activity), 
                    c("^t","^f","mean","std","\\(","\\)","_","BodyBody",
                      "Acc","Gyro","Mag"), 
                    c("Time","Frequency","Mean","Std","","","","Body",
                      "Accelerometer","Gyrometer","Magnitude"))

## Convert mean_std_activity from data.frame to data.table for efficient
## sub-setting and computation.

install.packages("data.table")
library(data.table)

my_table <- as.data.table(mean_std_activity, keep.rownames=FALSE)

## Reorder columns so that the first and second column contain the subject ID 
## and the activity name respectively.

my_table <- my_table[, c(1, 81, 2:80)]

## Reorder the rows so that the subjectID is in ascending order.

tidy_data <- my_table[order(subjectID)]

###############################################################################
## 5. From the data set in step 4, create a second independent tidy data set
## with the average of each variable for each activity and each subject

tidy_data_average <- tidy_data[,lapply(.SD, mean), 
                               by = .(subjectID, activityname)]

## Save the tidy data to a text file
write.table(tidy_data_average, file = "./tidy_data.txt")
