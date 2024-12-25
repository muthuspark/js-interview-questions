#!/bin/bash

echo "Creating post folders for $1"

slugified_folder_name=$(echo "$1" | 
    tr '[:upper:]' '[:lower:]' | 
    sed 's/[^a-zA-Z0-9_-]//g' | 
    tr ' ' '-' | 
    tr -s '-' '-' | 
    sed 's/^-*//;s/-*$//')

echo "Creating folder: posts/$slugified_string" 

mkdir posts/$slugified_folder_name
touch posts/$slugified_folder_name/index.qmd

echo "---
title: \"$1\"
categories: [ advanced ]
---" > posts/$slugified_folder_name/index.qmd