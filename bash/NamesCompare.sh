#!/bin/bash

# Set the paths to the two local folders
folder1="/path/to/folder1"
folder2="/path/to/folder2"

# Function to get a list of all file names in a folder and its subfolders
function get_all_files {
  local folder="$1"
  local files=()
  for entry in "$folder"/*; do
    if [ -f "$entry" ]; then
      files+=("$(basename "$entry")")
    elif [ -d "$entry" ]; then
      files+=("$(get_all_files "$entry")")
    fi
  done
  echo "${files[@]}"
}

# Get the list of all file names in folder1 and folder2
files1=($(get_all_files "$folder1"))
files2=($(get_all_files "$folder2"))

# Loop through the file names in folder1
for file1 in "${files1[@]}"; do
  found=false

  # Check if the file name is in folder2
  for file2 in "${files2[@]}"; do
    if [ "$file1" == "$file2" ]; then
      found=true
      break
    fi
  done

  # If the file name is not in folder2, print a message
  if [ "$found" = false ]; then
    echo "$file1 not found in $folder2"
  fi
done
