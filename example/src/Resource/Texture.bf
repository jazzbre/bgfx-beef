using System;
using System.Collections;
using System.IO;
using System.Diagnostics;
using Bgfx;

namespace Example
{
	[Reflect(.Methods), AlwaysInclude(AssumeInstantiated = true, IncludeAllMethods = true)]
	public class Texture : Resource
	{
		public bgfx.TextureHandle Handle { get; private set; }
		public int Width { get; private set; };
		public int Height { get; private set; }

		this()
		{
		}

		public override void OnLoad()
		{
			var texBinaryPath = scope String()..AppendF("{}{}.ktx", ResourceManager.runtimeResourcesPath, Hash);
			uint8[] binaryData;
			Utils.ReadBinaryFile(texBinaryPath, out binaryData);

			var memory = bgfx.copy(binaryData.CArray(), (uint32)binaryData.Count);
			var info = bgfx.TextureInfo();
			Handle = bgfx.create_texture(memory, 0, 0, &info);

			if (Handle.Valid)
			{
				Width = (int)info.width;
				Height = (int)info.height;
			}

			delete binaryData;
		}

		public override void OnUnload()
		{
			bgfx.destroy_texture(Handle);
		}
	}
}
