cd submodules/bgfx
../bx/tools/bin/darwin/genie --with-tools --gcc=osx gmake
make osx-debug64-x86 -j 8
make osx-release64-x86 -j 8
