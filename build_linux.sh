cd submodules/bgfx
../bx/tools/bin/linux/genie --with-tools --gcc=linux-gcc gmake
make linux-debug64 -j 8
make linux-release64 -j 8
