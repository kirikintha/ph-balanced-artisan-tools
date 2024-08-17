#!/bin/bash

# Directory containing GIF files
DIRECTORY="resources"
SCALE="800:-1"

# Loop through each GIF file in the directory
for file in "$DIRECTORY"/*.gif; do
    # Check if the file size is greater than 1MB (1048576 bytes)
    if [ $(stat -f%z "$file") -gt 1048576 ]; then
        # Check if the GIF is animated
        frames=$(ffprobe -v error -select_streams v:0 -count_frames -show_entries stream=nb_read_frames -of default=nokey=1:noprint_wrappers=1 "$file")
        if [ "$frames" -gt 1 ]; then
            # Apply ffmpeg to optimize the GIF
            optimized="${file%.gif}.optimized.gif"
            ffmpeg -i "$file" -vf "fps=15,scale=$SCALE:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" -loop -1 "$optimized"
            if [ $? -eq 0 ]; then
                rm "$file"
                mv "$optimized" "$file"
                echo "Optimized $file. echo "New size: $(du -h "$file" | cut -f1)""
            else
                echo "Error optimizing $file"
                rm "$optimized"
            fi
        else
            echo "$file is not animated, skipping optimization."
        fi
    fi
done
