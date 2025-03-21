#!/bin/bash
# Activate the virtual environment
source ./venv/bin/activate

# Set the LD_LIBRARY_PATH to include the Embree4 library
export LD_LIBRARY_PATH=$(pwd)/embree4/lib:$LD_LIBRARY_PATH

# Install the package in development mode
pip install -e .

# Run the test script
python test_embree4.py
