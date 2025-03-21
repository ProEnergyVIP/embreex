#!/usr/bin/env fish
# Activate the virtual environment
source ./venv/bin/activate.fish

# Set the LD_LIBRARY_PATH to include the Embree4 library
set -gx LD_LIBRARY_PATH (pwd)/embree4/lib $LD_LIBRARY_PATH

# Clean any previous build artifacts
rm -rf build/ *.egg-info/ embreex/*.so

# Install the package in development mode
pip install -e .

# Run the test script
python test_embree4.py
