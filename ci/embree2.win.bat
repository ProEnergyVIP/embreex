
curl -L -o embree.zip https://github.com/embree/embree/releases/download/v2.17.7/embree-2.17.7.x64.windows.zip

7z x embree.zip

move embree-2.17.7.x64.windows embree2
del embree.zip

dir
