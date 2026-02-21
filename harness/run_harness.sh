#!/bin/bash

#usage: test-run.sh <Ollama Server IP or Name>

# First note, this script should be within harness/ which includes questions/, answers/
# We need to make one time-date stamp we use for the whole run, and make this the base 
#  level of this run's worktree, the RunDate folder
printf -v DATE '%(%Y-%m-%d-%H-%M)T\n' -2
mkdir $DATE
cd $DATE

# Gather intel about the models
mkdir model-info
for model in $(OLLAMA_HOST=$1 ollama list | tail -n +2 | awk '{print $1}'); do
  OLLAMA_HOST=$1 ollama show "$model" > "model-info/${model}.txt"
done

# Build filtered list
## Current filter is separating embedding models (I might make more tests for 
##  them later, but not now.
for info in model-info/*.txt; do
  model=$(basename "$info" .txt)
  if grep "^Capabilities" "$info" | grep -q "embedding"; then
    echo "$model" >> models-embed.txt
  else
    echo "$model" >> models-text.txt
  fi
done

# Here we make the Clean output directory, needed later but not visited
mkdir out-clean
# Now we need to make and move into the Raw output directory
mkdir out-raw
cd out-raw

#  Run through each model
  for MODEL in $(cat ../models-text.txt); do
    # Create and move into the model's output directory
    mkdir $MODEL
    cd $MODEL/
    # Run through each question
      for FILE in ../../../questions/*; do
        if [ -f "$FILE" ]; then
          CONTENT=$(cat "$FILE")
          BASENAME=$(basename "$FILE")
          { time OLLAMA_HOST=$1 ollama run $MODEL "$CONTENT" > "${BASENAME}"; } 2> "${BASENAME}.time"
        fi
        ## Do we clean files here?  Could that unload the model if we are too slow?
      done # going through each question
    ## Do we clean files here?  Between each model?
    OLLAMA_HOST=$1 ollama stop $MODEL
    cd ../
  done # going through each Model
# Here we process the files
cd ../ # Leave Raw for RunDate folder
# And here we write the final report
cd ../ # Leave RunDate for harness/
