using System;
using System.Collections;
using System.IO;
using System.Diagnostics;
using Bgfx;

namespace Example
{
	[Reflect(.Methods), AlwaysInclude(AssumeInstantiated = true, IncludeAllMethods = true)]
	public class Shader : Resource
	{
		public bgfx.ProgramHandle Handle { get; private set; }

		this()
		{
		}

		public override void OnLoad()
		{
			var vsBinaryPath = scope String()..AppendF("{}{}.vsbin", ResourceManager.runtimeResourcesPath, Hash);
			var fsBinaryPath = scope String()..AppendF("{}{}.fsbin", ResourceManager.runtimeResourcesPath, Hash);

			uint8[] vsBinaryData;
			Utils.ReadBinaryFile(vsBinaryPath, out vsBinaryData);

			var vsMemory = bgfx.copy(vsBinaryData.CArray(), (uint32)vsBinaryData.Count);
			var vsHandle = bgfx.create_shader(vsMemory);

			uint8[] fsBinaryData;
			Utils.ReadBinaryFile(fsBinaryPath, out fsBinaryData);

			var fsMemory = bgfx.copy(fsBinaryData.CArray(), (uint32)fsBinaryData.Count);
			var fsHandle = bgfx.create_shader(fsMemory);

			Handle = bgfx.create_program(vsHandle, fsHandle, true);

			delete vsBinaryData;
			delete fsBinaryData;
		}

		public override void OnUnload()
		{
			bgfx.destroy_program(Handle);
			Handle = bgfx.ProgramHandle();
		}
	}
}
