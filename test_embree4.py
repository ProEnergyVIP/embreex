"""Simple test script to verify Embree4 integration.

This script tests basic ray intersection functionality with the Embree4 integration.
"""
import os
import sys
import numpy as np

# Add the current directory to the Python path
sys.path.insert(0, os.path.abspath('.'))

# Import the embreex modules
from embreex.rtcore_scene import EmbreeScene
from embreex.triangles import add_cube

def test_basic_intersection():
    """Test basic intersection with a cube."""
    # Create a scene
    scene = EmbreeScene()
    print("Adding cube to scene...")
    add_cube(scene.scene_i)
    
    # Commit the scene
    print("Committing scene...")
    scene.commit()
    
    # Create ray origins and directions
    origins = np.array([[0, 0, -10]], dtype=np.float32)  # Ray starting 10 units away
    directions = np.array([[0, 0, 1]], dtype=np.float32)  # Ray pointing towards cube
    
    # Perform intersection test
    print("Testing ray intersection...")
    result = scene.run(origins, directions, output=True)
    
    # Print results
    print("\nIntersection Results:")
    print(f"Hit primitive ID: {result['primID'][0]}")
    print(f"Hit geometry ID: {result['geomID'][0]}")
    print(f"Hit distance: {result['tfar'][0]}")
    print(f"Hit coordinates: ({origins[0, 0] + directions[0, 0] * result['tfar'][0]}, "
          f"{origins[0, 1] + directions[0, 1] * result['tfar'][0]}, "
          f"{origins[0, 2] + directions[0, 2] * result['tfar'][0]})")
    print(f"Hit normal: ({result['Ng'][0, 0]}, {result['Ng'][0, 1]}, "
          f"{result['Ng'][0, 2]})")
    print(f"Hit barycentric coordinates: u={result['u'][0]}, v={result['v'][0]}")
    
    return result

if __name__ == "__main__":
    print("Testing Embree4 integration...")
    result = test_basic_intersection()
    print("\nTest completed successfully!")
