cd submodules/bgfx
../bx/tools/bin/darwin/genie --with-tools --gcc=osx-x64 gmake
make osx-x64-debug -j 8
make osx-x64-release -j 8
