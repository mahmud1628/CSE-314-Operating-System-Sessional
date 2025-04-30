#!/usr/bin/bash

PATH_TO_SUBMISSION_FOLDER=$1
PATH_TO_TARGET_FOLDER=$2
# PATH_TO_TEST_FOLDER=$3
# PATH_TO_ANSWER_FOLDER=$4

# make target directory with the subdirectories

mkdir -p "$PATH_TO_TARGET_FOLDER/C" "$PATH_TO_TARGET_FOLDER/C++" "$PATH_TO_TARGET_FOLDER/Java" "$PATH_TO_TARGET_FOLDER/Python"

#unzip all the files in the submission folder
for zipped_file in "$PATH_TO_SUBMISSION_FOLDER"/*
do
    # echo "Processing $zipped_file"
    student_id=$(basename "$zipped_file" | grep -oE '_[0-9]{7}\.zip$' | grep -oE '[0-9]{7}')
    # echo "Student ID: $student_id"
    # Unzip the file
    unzip "$zipped_file" -d "$PATH_TO_SUBMISSION_FOLDER"
    rm "$zipped_file"
done




