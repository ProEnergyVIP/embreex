#!/usr/bin/env python
"""Build script for the embreex package.

This script compiles the Cython modules for the embreex package.
"""
import os
import shutil
import numpy as np
from Cython.Build import cythonize
from setuptools import Extension

# Get the current working directory
_cwd = os.path.abspath(os.path.expanduser(os.path.dirname(__file__)))

def build():
    """Build the Cython extensions."""
    # Define include and library directories
    if os.name == "nt":  # Windows
        includes = [
            np.get_include(),
            'c:/Program Files/Intel/Embree4/include',
            os.path.join(_cwd, 'embree4', 'include'),
            os.path.join(_cwd, 'embreex')
        ]
        libraries = [
            'c:/Program Files/Intel/Embree4/lib',
            os.path.join(_cwd, 'embree4', 'lib')
        ]
    else:  # Unix-like systems
        includes = [
            np.get_include(),
            '/opt/local/include',
            '/usr/local/include',
            '/usr/include',
            '/opt/homebrew/Cellar/embree/4.3.3/include',
            os.path.join(_cwd, 'embree4', 'include'),
            os.path.join(_cwd, 'embreex')
        ]
        libraries = [
            '/opt/local/lib',
            '/usr/local/lib',
            '/usr/lib',
            '/usr/lib64',
            '/opt/homebrew/Cellar/embree/4.3.3/lib',
            os.path.join(_cwd, 'embree4', 'lib')
        ]

    # Define compiler directives
    compiler_directives = {
        'language_level': 3,
        'embedsignature': True,
    }

    # Define extensions
    extensions = [
        Extension(
            "embreex.rtcore",
            ["embreex/rtcore.pyx"],
            include_dirs=includes,
            library_dirs=libraries,
            libraries=["embree4"],
            language="c++"
        ),
        Extension(
            "embreex.rtcore_scene",
            ["embreex/rtcore_scene.pyx"],
            include_dirs=includes,
            library_dirs=libraries,
            libraries=["embree4"],
            language="c++"
        ),
        Extension(
            "embreex.mesh_construction",
            ["embreex/mesh_construction.pyx"],
            include_dirs=includes,
            library_dirs=libraries,
            libraries=["embree4"],
            language="c++"
        ),
        Extension(
            "embreex.triangles",
            ["embreex/triangles.pyx"],
            include_dirs=includes,
            library_dirs=libraries,
            libraries=["embree4"],
            language="c++"
        )
    ]

    # Cythonize the extensions
    ext_modules = cythonize(
        extensions,
        include_path=includes,
        compiler_directives=compiler_directives
    )

    # Build the extensions
    from setuptools.command.build_ext import build_ext
    cmd = build_ext(Distribution({"ext_modules": ext_modules}))
    cmd.ensure_finalized()
    cmd.run()

    # Copy the built extensions to the embreex directory
    for ext in cmd.get_outputs():
        dest = os.path.join(_cwd, os.path.relpath(ext, cmd.build_lib))
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        shutil.copy2(ext, dest)

if __name__ == "__main__":
    # Import Distribution here to avoid importing it at the top level
    from setuptools.dist import Distribution
    build()
