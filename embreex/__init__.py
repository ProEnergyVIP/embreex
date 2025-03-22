"""Embreex: Python bindings for Intel's Embree ray tracing engine.

This package provides Python bindings for Intel's Embree ray tracing kernels,
allowing for high-performance ray tracing operations from Python.
"""

__version__ = '0.2.0'

# Import modules to make them available
from . import rtcore
from . import rtcore_scene
from . import mesh_construction
from . import triangles

__all__ = ['rtcore', 'rtcore_scene', 'mesh_construction', 'triangles']