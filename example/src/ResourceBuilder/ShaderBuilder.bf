using System;
using System.IO;

namespace Example
{
	[Reflect(.Methods), AlwaysInclude(AssumeInstantiated = true, IncludeAllMethods = true)]
	public class ShaderBuilder : ResourceBuilder
	{
#if BF_PLATFORM_WINDOWS
		private const String VSFlags = "--platform windows --profile vs_4_0 -O 3";
		private const String FSFlags = "--platform windows --profile ps_4_0 -O 3";
#elif BF_PLATFORM_MACOS
		private const String VSFlags = "--platform osx -p metal -O 3";
		private const String FSFlags = "--platform osx -p metal -O 3";
#elif BF_PLATFORM_LINUX
		private const String VSFlags = "--platform linux";
		private const String FSFlags = "--platform linux";
#endif

		public override String Extension => "shader";
		public override Type ResourceType => typeof(Shader);

		public override bool OnCheckBuild(StringView path, StringView hash)
		{
			var vsBinaryPath = scope String()..AppendF("{}{}.vsbin", ResourceManager.runtimeResourcesPath, hash);
			var fsBinaryPath = scope String()..AppendF("{}{}.fsbin", ResourceManager.runtimeResourcesPath, hash);
			var sourceDateTime = Utils.GetLatestTimestamp(path);
			var destinationDateTime = Utils.GetLatestTimestamp(vsBinaryPath, fsBinaryPath);
			return sourceDateTime > destinationDateTime;
		}

		public override bool OnBuild(StringView path, StringView hash)
		{
			while (true)
			{
				var text = scope String();
				switch (File.ReadAllText(path, text)) {
				case .Ok(let val):
					break;
				case .Err(let err):
					return false;
				}
				var vertexShaderIndex = text.IndexOf("[VS]");
				var varyingIndex = text.IndexOf("[VAR]");
				var fragmentShaderIndex = text.IndexOf("[FS]");
				if (vertexShaderIndex == -1)
				{
					var temp = scope String();
					temp.AppendF("{0} [VS] vertex shader not found!", path);
					if (Utils.ShowMessageBoxOKCancel("Shader Compile", temp) == 1)
					{
						System.Environment.Exit(1);
					}
					continue;
				}
				if (varyingIndex == -1)
				{
					var temp = scope String();
					temp.AppendF("{0} [VAR] varying not found!", path);
					if (Utils.ShowMessageBoxOKCancel("Shader Compile", temp) == 1)
					{
						System.Environment.Exit(1);
					}
					continue;
				}
				if (fragmentShaderIndex == -1)
				{
					var temp = scope String();
					temp.AppendF("{0} [FS] fragment shader not found!", path);
					if (Utils.ShowMessageBoxOKCancel("Shader Compile", temp) == 1)
					{
						System.Environment.Exit(1);
					}
					continue;
				}
				var vsPath = scope String()..AppendF("{}{}.vs", ResourceManager.runtimeResourcesPath, hash);
				var vsTextPart = scope String(text, vertexShaderIndex + 4, varyingIndex - (vertexShaderIndex + 4));
				File.WriteAllText(vsPath, vsTextPart);
				var varPath = scope String()..AppendF("{}{}.var", ResourceManager.runtimeResourcesPath, hash);
				var varTextPart = scope String(text, varyingIndex + 5, fragmentShaderIndex - (varyingIndex + 5));
				File.WriteAllText(varPath, varTextPart);
				var fsPath = scope String()..AppendF("{}{}.fs", ResourceManager.runtimeResourcesPath, hash);
				var fsTextPart = scope String(text, fragmentShaderIndex + 4, text.Length - (fragmentShaderIndex + 4));
				File.WriteAllText(fsPath, fsTextPart);
				// Build
				var vsBinaryPath = scope String()..AppendF("{}{}.vsbin", ResourceManager.runtimeResourcesPath, hash);
				var fsBinaryPath = scope String()..AppendF("{}{}.fsbin", ResourceManager.runtimeResourcesPath, hash);
				var toolPath = scope String();
				toolPath.Set(ResourceManager.buildtimeToolsPath);
				toolPath.Append("shadercrelease");
				Utils.NormalizePath(toolPath);
				var includePath = scope String();
				includePath.Set(ResourceManager.buildtimeShaderIncludePath);
				var commandLine = scope String();
				commandLine.Clear();
				commandLine.AppendF("-f \"{0}\" -o \"{1}\" --type Vertex --varyingdef \"{2}\" -i \"{3}\" {4}", vsPath, vsBinaryPath, varPath, includePath, VSFlags);
				// Build vertex shader
				if (Utils.ExecuteProcess(toolPath, commandLine) != 0)
				{
					var temp = scope String();
					temp.AppendF("{0} vertex shader compile failed!", path);
					if (Utils.ShowMessageBoxOKCancel("Shader Compile", temp) == 1)
					{
						System.Environment.Exit(1);
					}
					continue;
				}
				commandLine.Clear();
				commandLine.AppendF("-f \"{0}\" -o \"{1}\" --type Fragment --varyingdef \"{2}\" -i \"{3}\" {4}", fsPath, fsBinaryPath, varPath, includePath, FSFlags);
				// Build fragment shader
				if (Utils.ExecuteProcess(toolPath, commandLine) != 0)
				{
					var temp = scope String();
					temp.AppendF("{0} fragment shader compile failed!", path);
					if (Utils.ShowMessageBoxOKCancel("Shader Compile", temp) == 1)
					{
						System.Environment.Exit(1);
					}
					continue;
				}
				File.Delete(vsPath);
				File.Delete(varPath);
				File.Delete(fsPath);
				break;
			}
			return true;
		}
	}
}
