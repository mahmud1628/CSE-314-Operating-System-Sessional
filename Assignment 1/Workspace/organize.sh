#!/usr/bin/bash

PATH_TO_SUBMISSION_FOLDER=$1
PATH_TO_TARGET_FOLDER=$2
# PATH_TO_TEST_FOLDER=$3
# PATH_TO_ANSWER_FOLDER=$4

# make target directory with the subdirectories

# mkdir -p "$PATH_TO_TARGET_FOLDER/C" "$PATH_TO_TARGET_FOLDER/C++" "$PATH_TO_TARGET_FOLDER/Java" "$PATH_TO_TARGET_FOLDER/Python"

# # #unzip all the files in the submission folder
# for zipped_file in "$PATH_TO_SUBMISSION_FOLDER"/*
# do
#     # echo "Processing $zipped_file"
#     student_id=$(basename "$zipped_file" | grep -oE '_[0-9]{7}\.zip$' | grep -oE '[0-9]{7}')
#     # echo "Student ID: $student_id"
#     # Unzip the file
#     unzip "$zipped_file" -d "$PATH_TO_SUBMISSION_FOLDER"
#     rm "$zipped_file"
# done

# # move the files to the target directory
# for directory in "$PATH_TO_SUBMISSION_FOLDER"/*
# do
#     student_id="${directory: -7}"
#     # echo $student_id
#     code_file=$(find "$directory" -type f \( -name "*.c" -o -name "*.cpp" -o -name "*.java" -o -name "*.py" \))
#     # echo $code_file
#     file_extension="${code_file##*.}"
#     # echo $file_extension

#     case $file_extension in
#         c)  
#             mkdir -p "$PATH_TO_TARGET_FOLDER/C/$student_id"
#             cp "$code_file" "$PATH_TO_TARGET_FOLDER/C/$student_id/main.c"
#             ;;
#         cpp)
#             mkdir -p "$PATH_TO_TARGET_FOLDER/C++/$student_id"
#             cp "$code_file" "$PATH_TO_TARGET_FOLDER/C++/$student_id/main.cpp"
#             ;;
#         java)
#             mkdir -p "$PATH_TO_TARGET_FOLDER/Java/$student_id"
#             cp "$code_file" "$PATH_TO_TARGET_FOLDER/Java/$student_id/Main.java"
#             ;;
#         py)
#             mkdir -p "$PATH_TO_TARGET_FOLDER/Python/$student_id"
#             cp "$code_file" "$PATH_TO_TARGET_FOLDER/Python/$student_id/main.py"
#             ;;
#         *)
#             echo "Unknown file type: $file_extension"
#             ;;
#     esac
# done


declare -A line_counts
declare -A comment_counts


for directory in "$PATH_TO_TARGET_FOLDER"/*
do
    for student_directory in "$directory"/*
    do 
        student_id=$(basename "$student_directory")
        code_file=$(find "$student_directory" -type f \( -name "*.c" -o -name "*.cpp" -o -name "*.java" -o -name "*.py" \))
        file_extension="${code_file##*.}"
        line_count=$(wc -l < "$code_file")
        # echo -n $student_id
        # echo -n " "
        # echo $line_count
        line_counts[$student_id]=$line_count
        # computing number of single line comments
        if [[ $file_extension == "c" || $file_extension == "cpp" || $file_extension == "java" ]]; then
            comment_count=$(grep -c "//" "$code_file") // counts inside string too
            comment_counts[$student_id]=$comment_count
        elif [[ $file_extension == "py" ]]; then
            comment_count=$(grep -c "#" "$code_file") # counts inside string too
            comment_counts[$student_id]=$comment_count
        fi
        

        
    done
done




