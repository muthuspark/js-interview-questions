#!/bin/bash

quarto render
cp CNAME docs/CNAME
cp ads.txt docs/ads.txt
cp robots.txt docs/robots.txt
git add .
current_date=$(date +"%Y-%m-%d")
git commit -m "release $current_date"
git push
