# Bgfx wrapper for the Beef Programming Language

## Prerequisites
- Visual Studio 2019 Community/Professional (it can be built with other versions though, check build_windows_vs2019.cmd for more information)
- To initialize submodules run *git submodule init*  and *git submodule update*
- To build prerequisites run *build_windows_vs2019.cmd*


## Usage

Open workspace and set Example as Startup project and Run!

Example can run in two modes
- *Buildtime* mode where example/buildtime directory is found and the resources are built if they were changed or added (or not built before)
- *Runtime* mode where example/buildtime directory is not found and example/runtime is already built (used when distributing the application)

When running in *Buildtime* mode the changes to the existing assets (in example/buildtime directory) will be built on the fly.


## Art

Clouds:
http://pixelartmaker.com/art/a2cfe63f4ca5f16
Rain drop:
http://pixelartmaker.com/art/b3e0f940338bc21