#!/usr/bin/env python
"""Setup script for the embreex package.

This script configures the build process for the Cython-based Python bindings
for Intel's Embree ray tracing engine.
"""
import os

from setuptools import setup, Extension

from Cython.Build import cythonize
from numpy import get_include

# the current working directory
_cwd = os.path.abspath(os.path.expanduser(os.path.dirname(__file__)))

def ext_modules():
    """Generate a list of extension modules for embreex."""
    if os.name == "nt":
        # embree search locations on windows
        includes = [get_include(),
                    'c:/Program Files/Intel/Embree4/include',
                    os.path.join(_cwd, 'embree4', 'include'),
                    os.path.join(_cwd, 'embreex')]
        libraries = [
            'c:/Program Files/Intel/Embree4/lib',
            os.path.join(_cwd, 'embree4', 'lib')]
    else:
        # embree search locations on posix
        includes = [get_include(),
                    '/opt/local/include',
                    '/usr/local/include',
                    '/usr/include',
                    '/opt/homebrew/Cellar/embree/4.3.3/include',
                    os.path.join(_cwd, 'embree4', 'include'),
                    os.path.join(_cwd, 'embreex')]
        libraries = ['/opt/local/lib',
                     '/usr/local/lib',
                     '/usr/lib',
                     '/usr/lib64',
                     '/opt/homebrew/Cellar/embree/4.3.3/lib',
                     os.path.join(_cwd, 'embree4', 'lib')]

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

    return cythonize(
        extensions, 
        include_path=includes, 
        compiler_directives=compiler_directives
    )


try:
    with open(os.path.join(_cwd, "README.md"), "r") as _f:
        long_description = _f.read()
except BaseException:
    long_description = ""


setup(
    name="embreex",
    version="0.2.0",
    description="Python binding for Intel's Embree ray engine",
    long_description=long_description,
    long_description_content_type="text/markdown",
    author="Your Name",
    author_email="your.email@example.com",
    url="https://github.com/trimesh/embreex",
    packages=["embreex"],
    ext_modules=ext_modules(),
    install_requires=["numpy>=2.2.0"],
    python_requires=">=3.10",
    classifiers=[
        "Development Status :: 4 - Beta",
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent"
    ]
)
