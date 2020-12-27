using System;
using System.IO;
using System.Diagnostics;
using System.Collections;
using System.Security.Cryptography;
using SDL2;

namespace Example
{
	public static class Utils
	{
		public static int32 ShowMessageBoxOK(String title, String message)
		{
			var messageBoxData = SDL.MessageBoxData();
			SDL.MessageBoxButtonData[1] buttons;
			buttons[0].buttonid = 0;
			buttons[0].text = "OK";
			messageBoxData.buttons = &buttons[0];
			messageBoxData.window = null;
			messageBoxData.numbuttons = 1;
			messageBoxData.message = message;
			messageBoxData.title = title;
			int32 buttonId = 0;
			SDL.ShowMessageBox(ref messageBoxData, out buttonId);
			return buttonId;
		}

		public static int32 ShowMessageBoxOKCancel(StringView title, StringView message)
		{
			var messageBoxData = SDL.MessageBoxData();
			SDL.MessageBoxButtonData[2] buttons;
			buttons[0].buttonid = 0;
			buttons[0].text = "OK";
			buttons[1].buttonid = 1;
			buttons[1].text = "Cancel";
			messageBoxData.buttons = &buttons[0];
			messageBoxData.window = null;
			messageBoxData.numbuttons = 1;
			messageBoxData.message = message.Ptr;
			messageBoxData.title = title.Ptr;
			int32 buttonId = 0;
			SDL.ShowMessageBox(ref messageBoxData, out buttonId);
			return buttonId;
		}

		public static int ExecuteProcess(StringView executable, StringView commandLine)
		{
			Log.Info("Executing: {0} {1}", executable, commandLine);
			var process = scope SpawnedProcess();
			var processStartInfo = scope ProcessStartInfo();
			processStartInfo.SetFileName(executable);
			processStartInfo.SetArguments(commandLine);
			switch (process.Start(processStartInfo)) {
			case .Ok:
				break;
			case .Err:
				return -1;
			}
			process.WaitFor();
			return process.ExitCode;
		}

		public static bool ReadBinaryFile(StringView filename, out uint8[] data)
		{
			data = null;
			var file = scope FileStream();
			switch (file.Open(filename, FileAccess.Read)) {
			case .Ok:
				break;
			case .Err:
				return false;
			}
			data = new uint8[file.Length];
			file.TryRead(Span<uint8>(data));
			file.Close();
			return true;
		}

		public static DateTime GetLatestTimestamp(params StringView[] args)
		{
			var bestDateTime = DateTime();
			var failed = false;
			for (var arg in args)
			{
				if (File.Exists(arg))
				{
					switch (File.GetLastWriteTimeUtc(arg)) {
					case .Ok(let dt):
						if (dt > bestDateTime)
						{
							bestDateTime = dt;
						}
						break;
					default:
					}
				} else
				{
					failed = true;
				}
			}
			return failed ? DateTime() : bestDateTime;
		}

		public static void NormalizePath(String path)
		{
			path.Replace("\\", "/");
			path.Replace("//", "/");
		}

		public static void FindFiles(StringView path, StringView what, ref List<String> foundFiles)
		{
			var searchPath = scope String();
			var fileName = scope String();
			searchPath.AppendF("{}/{}", path, what);
			var files = Directory.Enumerate(searchPath, .Directories | .Files);
			for (var file in files)
			{
				fileName.Clear();
				file.GetFilePath(fileName);
				// if (file.IsDirectory) doesn't work on macOS so the hack bellow is used
				if (!fileName.Contains("."))
				{
					Log.Info(scope $"Dir '{fileName}'...");
					FindFiles(fileName, what, ref foundFiles);
				} else
				{
					var foundFileName = new String(fileName);
					Utils.NormalizePath(foundFileName);
					foundFiles.Add(foundFileName);
				}
			}
		}

		public static void SHA256ToString(SHA256Hash hash, String s)
		{
			for (var h in hash.mHash)
			{
				s.AppendF("{0:X}", h);
			}
		}

	}
}
