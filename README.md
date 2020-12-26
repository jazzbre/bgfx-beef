# [bgfx-beef](https://github.com/jazzbre/bgfx-beef) Bgfx wrapper for the Beef Programming Language

[bgfx](https://github.com/bkaradzic/bgfx)

## Prerequisites
- To initialize submodules run *git submodule update --init --recursive*

## Windows
- Visual Studio 2019 Community/Professional (it can be built with other versions though, check build_windows_vs2019.cmd for more information)
- To build prerequisites run *build_windows_vs2019.cmd*

## MacOS
- To build prerequisites run *./build_macos.sh*

## Linux
- To build prerequisites run *./build_linux.sh*


## Usage

Open workspace and set Example as Startup project and Run!

Example can run in two modes
- *Buildtime* mode where example/buildtime directory is found and the resources are built if they were changed or added (or not built before)
- *Runtime* mode where example/buildtime directory is not found and example/runtime is already built (used when distributing the application)

When running in *Buildtime* mode the changes to the existing assets (in example/buildtime directory) will be built on the fly.

## Future work
iOS and Android build scripts.

## Art

Clouds:
http://pixelartmaker.com/art/a2cfe63f4ca5f16
Rain drop:
http://pixelartmaker.com/art/b3e0f940338bc21