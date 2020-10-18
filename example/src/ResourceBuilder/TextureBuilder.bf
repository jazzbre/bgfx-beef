using System;
using System.IO;

namespace Example
{
	[Reflect(.Methods), AlwaysInclude(AssumeInstantiated = true, IncludeAllMethods = true)]
	public class TextureBuilder : ResourceBuilder
	{
		// TODO handle multiple input and output formats (based on filename maybe?)
		public override String Extension => "png";

		public override Type ResourceType => typeof(Texture);

		public override bool OnCheckBuild(StringView path, StringView hash)
		{
			var texBinaryPath = scope String()..AppendF("{}{}.ktx", ResourceManager.runtimeResourcesPath, hash);
			var sourceDateTime = Utils.GetLatestTimestamp(path);
			var destinationDateTime = Utils.GetLatestTimestamp(texBinaryPath);
			return sourceDateTime > destinationDateTime;
		}

		public override bool OnBuild(StringView path, StringView hash)
		{
			var texBinaryPath = scope String()..AppendF("{}{}.ktx", ResourceManager.runtimeResourcesPath, hash);
			var toolPath = scope String();
			toolPath.Set(ResourceManager.buildtimeToolsPath);
			toolPath.Append("texturecrelease");
			Utils.NormalizePath(toolPath);
			var commandLine = scope String();
			commandLine.Clear();
			commandLine.AppendF("-f \"{0}\" -o \"{1}\" -t RGBA8", path, texBinaryPath);
			// Build fragment shader
			if (Utils.ExecuteProcess(toolPath, commandLine) != 0)
			{
				var temp = scope String();
				temp.AppendF("{0} texture conversion failed!", path);
				if (Utils.ShowMessageBoxOKCancel("Texture Conversion", temp) == 1)
				{
					System.Environment.Exit(1);
				}
			}
			return true;
		}
	}
}
