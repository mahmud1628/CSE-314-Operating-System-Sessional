#!/usr/bin/bash

PATH_TO_SUBMISSION_FOLDER=$1
PATH_TO_TARGET_FOLDER=$2
PATH_TO_TEST_FOLDER=$3
PATH_TO_ANSWER_FOLDER=$4

is_v_provided=false
is_noexecute_provided=false
is_nolc_provided=false
is_nocc_provided=false
is_nofc_provided=false

for argument in $*
do
    if [[ $argument == "-v" ]]; then
        is_v_provided=true
    elif [[ $argument == "-noexecute" ]]; then
        is_noexecute_provided=true
    elif [[ $argument == "-nolc" ]]; then
        is_nolc_provided=true
    elif [[ $argument == "-nocc" ]]; then
        is_nocc_provided=true
    elif [[ $argument == "-nofc" ]]; then
        is_nofc_provided=true
    fi
done

declare -A student_names
declare -A student_languages
declare -a student_ids
declare -A line_counts
declare -A comment_counts
declare -A passed_test_counts
declare -A failed_test_counts

# make target directory with the subdirectories

mkdir -p "$PATH_TO_TARGET_FOLDER/C" "$PATH_TO_TARGET_FOLDER/C++" "$PATH_TO_TARGET_FOLDER/Java" "$PATH_TO_TARGET_FOLDER/Python"

mkdir -p "$PATH_TO_SUBMISSION_FOLDER/unzipped"
# #unzip all the files in the submission folder
for zipped_file in "$PATH_TO_SUBMISSION_FOLDER"/*
do
    if [[ $zipped_file == *.zip ]]; then
        # echo "Processing $zipped_file"
        student_id=$(basename "$zipped_file" | grep -oE '_[0-9]{7}\.zip$' | grep -oE '[0-9]{7}')
        student_name=$(basename "$zipped_file" | grep -oE '^[^_]+')

        student_ids+=("$student_id")

        student_names[$student_id]=$student_name
        # echo "Student ID: $student_id"
        # Unzip the file
        unzip -q "$zipped_file" -d "$PATH_TO_SUBMISSION_FOLDER/unzipped"
    fi
done

# move the files to the target directory
for directory in "$PATH_TO_SUBMISSION_FOLDER"/unzipped/*
do
    student_id="${directory: -7}"
    if [[ $is_v_provided == true ]]; then
        echo "Organizing files of $student_id"
    fi
    # echo $student_id
    code_file=$(find "$directory" -type f \( -name "*.c" -o -name "*.cpp" -o -name "*.java" -o -name "*.py" \))
    # echo $code_file
    file_extension="${code_file##*.}"
    # echo $file_extension
    code_file_in_target="$PATH_TO_TARGET_FOLDER"
    code_file_directory_inside_target="$PATH_TO_TARGET_FOLDER/$file_extension/$student_id"

    case $file_extension in
        c)  
            mkdir -p "$PATH_TO_TARGET_FOLDER/C/$student_id"
            cp "$code_file" "$PATH_TO_TARGET_FOLDER/C/$student_id/main.c"
            student_languages[$student_id]="C"
            code_file_in_target="$PATH_TO_TARGET_FOLDER/C/$student_id/main.c"
            code_file_directory_inside_target="$PATH_TO_TARGET_FOLDER/C/$student_id"
            ;;
        cpp)
            mkdir -p "$PATH_TO_TARGET_FOLDER/C++/$student_id"
            cp "$code_file" "$PATH_TO_TARGET_FOLDER/C++/$student_id/main.cpp"
            student_languages[$student_id]="C++"
            code_file_in_target="$PATH_TO_TARGET_FOLDER/C++/$student_id/main.cpp"
            code_file_directory_inside_target="$PATH_TO_TARGET_FOLDER/C++/$student_id"
            ;;
        java)
            mkdir -p "$PATH_TO_TARGET_FOLDER/Java/$student_id"
            cp "$code_file" "$PATH_TO_TARGET_FOLDER/Java/$student_id/Main.java"
            student_languages[$student_id]="Java"
            code_file_in_target="$PATH_TO_TARGET_FOLDER/Java/$student_id/Main.java"
            code_file_directory_inside_target="$PATH_TO_TARGET_FOLDER/Java/$student_id"
            ;;
        py)
            mkdir -p "$PATH_TO_TARGET_FOLDER/Python/$student_id"
            cp "$code_file" "$PATH_TO_TARGET_FOLDER/Python/$student_id/main.py"
            student_languages[$student_id]="Python"
            code_file_in_target="$PATH_TO_TARGET_FOLDER/Python/$student_id/main.py"
            code_file_directory_inside_target="$PATH_TO_TARGET_FOLDER/Python/$student_id"
            ;;
        *)
            echo "Unknown file type: $file_extension"
            ;;
    esac

    # line count

    if [[ $is_nolc_provided == false ]]; then

        line_count=$(wc -l < "$code_file_in_target")

        line_counts[$student_id]=$line_count

    fi

    # comment count

    if [[ $is_nocc_provided == false ]]; then

        if [[ $file_extension == "c" || $file_extension == "cpp" || $file_extension == "java" ]]; then
            comment_count=$(grep -c "//" "$code_file_in_target") # counts inside string too
            comment_counts[$student_id]=$comment_count
        elif [[ $file_extension == "py" ]]; then
            comment_count=$(grep -c "#" "$code_file_in_target") # counts inside string too
            comment_counts[$student_id]=$comment_count
        fi
    fi

    # compile code

    if [[ $is_noexecute_provided == false ]]; then
        if [[ $is_v_provided == true ]]; then
            echo "Executing files of $student_id"
        fi

        if [[ $file_extension == "c" ]]; then
            gcc "$code_file_in_target" -o "$code_file_directory_inside_target/main.out"
        elif [[ $file_extension == "cpp" ]]; then
            g++ "$code_file_in_target" -o "$code_file_directory_inside_target/main.out"
        elif [[ $file_extension == "java" ]]; then
            javac "$code_file_in_target" -d "$code_file_directory_inside_target"
        fi

        # test code

        passed_test_counts[$student_id]=0
        failed_test_counts[$student_id]=0

        for test_file in "$PATH_TO_TEST_FOLDER"/*
        do
            test_file_name=$(basename "$test_file")
            test_file_number=$(echo "$test_file_name" | grep -oE '[0-9]+')
            # echo $test_file_name
            # echo $code_file
            if [[ $file_extension == "c" || $file_extension == "cpp" ]]; then
                ./"$code_file_directory_inside_target/main.out" < "$test_file" > "$code_file_directory_inside_target/out${test_file_number}.txt"
            elif [[ $file_extension == "java" ]]; then
                java -cp "$code_file_directory_inside_target" Main < "$test_file" > "$code_file_directory_inside_target/out${test_file_number}.txt"
            elif [[ $file_extension == "py" ]]; then
                python3 "$code_file_directory_inside_target/main.py" < "$test_file" > "$code_file_directory_inside_target/out${test_file_number}.txt"
            fi

            diff "$code_file_directory_inside_target/out${test_file_number}.txt" "$PATH_TO_ANSWER_FOLDER/ans${test_file_number}.txt" > /dev/null
            if [ $? -eq 0 ]; then
                passed_test_counts[$student_id]=$(( ${passed_test_counts[$student_id]} + 1 ))
            else 
                failed_test_counts[$student_id]=$(( ${failed_test_counts[$student_id]} + 1 ))
            fi
        done
    fi    

done

rm -rf "$PATH_TO_SUBMISSION_FOLDER/unzipped"

if [[ $is_v_provided == true ]]; then
    echo "All submissions processed successfully"
fi


# CSV file
PATH_TO_RESULT="$PATH_TO_TARGET_FOLDER/result.csv"
echo -n "student_id,student_name,language" > "$PATH_TO_RESULT"

if [[ $is_noexecute_provided == false ]]; then
    echo -n ",matched,not_matched" >> "$PATH_TO_RESULT"
fi

if [[ $is_nolc_provided == false ]]; then
    echo -n ",line_count" >> "$PATH_TO_RESULT"
fi

if [[ $is_nocc_provided == false ]]; then
    echo -n ",comment_count" >> "$PATH_TO_RESULT"
fi

echo "" >> "$PATH_TO_RESULT"

for student_id in "${student_ids[@]}"
do
    echo -n "$student_id,"\"${student_names[$student_id]}\"",${student_languages[$student_id]}" >> "$PATH_TO_RESULT"

    if [[ $is_noexecute_provided == false ]]; then
        echo -n ",${passed_test_counts[$student_id]},${failed_test_counts[$student_id]}" >> "$PATH_TO_RESULT"
    fi
    if [[ $is_nolc_provided == false ]]; then
        echo -n ",${line_counts[$student_id]}" >> "$PATH_TO_RESULT"
    fi
    if [[ $is_nocc_provided == false ]]; then
        echo -n ",${comment_counts[$student_id]}" >> "$PATH_TO_RESULT"
    fi
    echo "" >> "$PATH_TO_RESULT"
done

