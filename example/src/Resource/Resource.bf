using System;
using System.Collections;
using System.IO;
using System.Diagnostics;
using System.Security.Cryptography;
using Bgfx;

namespace Example
{
	public abstract class Resource
	{
		public String Name
		{
			get; private set;
		}

		public String Hash
		{
			get; private set;
		}

		public bool IsLoaded
		{
			get; private set;
		}

		public ~this()
		{
			delete Name;
			delete Hash;
		}

		public virtual void Initialize(String name, String hash)
		{
			Name = name;
			Hash = hash;
		}

		public void Load()
		{
			if (IsLoaded)
			{
				return;
			}
			OnLoad();
			IsLoaded = true;
		}

		public void Unload()
		{
			if (!IsLoaded)
			{
				return;
			}
			OnUnload();
			IsLoaded = false;
		}

		public abstract void OnLoad();
		public abstract void OnUnload();

	}

	public static class ResourceManager
	{
		public static String runtimeResourcesPath ~ delete _;
		public static String buildtimeResourcesPath ~ delete _;
		public static String buildtimeToolsPath ~ delete _;
		public static String buildtimeShaderIncludePath ~ delete _;
		private static bool canBuild = true;

		private static List<bgfx.VertexBufferHandle> vertexBufferHandles = new List<bgfx.VertexBufferHandle>();

		private static FileSystemWatcher buildResourcesWatched = null ~ delete _;
		private static Dictionary<String, Resource> resourceMap = new Dictionary<String, Resource>() ~ DestroyResources();
		private static List<ResourceBuilder> resourceBuilders = new List<ResourceBuilder>() ~ DestroyResourceBuilders();
		private static HashSet<String> queueResourceFiles = new HashSet<String>() ~ delete _;
		private static bool buildResourceFiles = true;

		private static void DestroyResourceBuilders()
		{
			foreach (var builder in resourceBuilders)
			{
				delete builder;
			}
			delete resourceBuilders;
		}

		private static void DestroyResources()
		{
			foreach (var pair in resourceMap)
			{
				delete pair.value;
			}
			delete resourceMap;
		}

		public static void Finalize()
		{
			foreach (var vertexBufferHandle in vertexBufferHandles)
			{
				bgfx.destroy_vertex_buffer(vertexBufferHandle);
			}
			delete vertexBufferHandles;
		}

		private struct Vertex
		{
			public float x = 0.0f;
			public float y = 0.0f;
			public float u = 0.0f;
			public float v = 0.0f;
		};

		public static bgfx.VertexBufferHandle CreateQuad(float min = -1.0f, float max = 1.0f)
		{
			var layout = bgfx.VertexLayout();
			bgfx.vertex_layout_begin(&layout, bgfx.get_renderer_type());
			bgfx.vertex_layout_add(&layout, bgfx.Attrib.Position, 2, bgfx.AttribType.Float, false, false);
			bgfx.vertex_layout_add(&layout, bgfx.Attrib.TexCoord0, 2, bgfx.AttribType.Float, false, false);
			bgfx.vertex_layout_end(&layout);

			Vertex[] vertices = new Vertex[4];
			vertices[0].x = min;
			vertices[0].y = min;
			vertices[0].u = 0.0f;
			vertices[0].v = 0.0f;
			vertices[1].x = max;
			vertices[1].y = min;
			vertices[1].u = 1.0f;
			vertices[1].v = 0.0f;
			vertices[3].x = max;
			vertices[3].y = max;
			vertices[3].u = 1.0f;
			vertices[3].v = 1.0f;
			vertices[2].x = min;
			vertices[2].y = max;
			vertices[2].u = 0.0f;
			vertices[2].v = 1.0f;

			var memory = bgfx.copy(vertices.CArray(), (uint32)vertices.Count * sizeof(Vertex));
			var handle = bgfx.create_vertex_buffer(memory, &layout, 0);

			delete vertices;

			vertexBufferHandles.Add(handle);
			return handle;
		}

		private static void OnFileChange(StringView _fileName)
		{
			var fileName = scope String(buildtimeResourcesPath);
			fileName.Append(_fileName);
			if (buildResourceFiles)
			{
				BuildResource(fileName, true);
			} else
			{
				var newFileName = new String(fileName);
				if (!queueResourceFiles.Contains(newFileName))
				{
					queueResourceFiles.Add(newFileName);
				} else
				{
					delete newFileName;
				}
			}
		}

		private static void AddResourceBuild(ResourceBuilder builder)
		{
			resourceBuilders.Add(builder);
		}

		private static void GetPathHash(StringView path, String hashString)
		{
			var hash = SHA256.Hash(Span<uint8>((uint8*)path.Ptr, path.Length));
			Utils.SHA256ToString(hash, hashString);
		}

		private static void GetRelativePathHash(String relativePath, String hashString)
		{
			var path = scope String();
			Path.GetDirectoryPath(relativePath, path);
			var fileName = scope String();
			Path.GetFileNameWithoutExtension(relativePath, fileName);
			path.AppendF("/{}", fileName);
			GetPathHash(path, hashString);
			relativePath.Set(path);
		}

		private static bool BuildResource(StringView filename, bool force = false)
		{
			var relativePath = scope String(filename);
			relativePath.Remove(0, buildtimeResourcesPath.Length);
			relativePath.ToLower();
			Utils.NormalizePath(relativePath);
			for (var builder in resourceBuilders)
			{
				if (!relativePath.EndsWith(builder.Extension))
				{
					continue;
				}
				var hashString = scope String();
				GetRelativePathHash(relativePath, hashString);
				Resource resource = null;
				var wasLoaded = false;
				if (resourceMap.TryGetValue(hashString, out resource))
				{
					wasLoaded = resource.IsLoaded;
					resource.Unload();
				} else
				{
					switch (builder.ResourceType.CreateObject()) {
					case .Ok(let val):
						Log.Info("Resource {} added!", relativePath);
						resource = val as Resource;
						var hash = new String(hashString);
						resource.Initialize(new String(relativePath), hash);
						resourceMap.Add(hash, resource);
						break;
					case .Err(let err):
						Log.Info("Resource {} failed!", relativePath);
						continue;
					}
				}
				if (!force && !builder.CheckBuild(filename, hashString))
				{
					continue;
				}
				Log.Info("Building {}...", filename);
				builder.Build(filename, hashString);
				if (wasLoaded)
				{
					resource.Load();
				}
			}
			return false;
		}

		private static void InitializeRuntimeBuild(String path)
		{
			canBuild = System.IO.Directory.Exists(buildtimeResourcesPath);
			// Find tools (either VS2019 or VS2017)
			if (canBuild)
			{
				buildtimeToolsPath.Append("/../submodules/bgfx/.build/win64_vs2019/bin/");
				if (!System.IO.Directory.Exists(buildtimeToolsPath))
				{
					canBuild = false;
				}
				if (!canBuild)
				{
					buildtimeToolsPath.Append("/../submodules/bgfx/.build/win64_vs2017/bin/");
					if (!System.IO.Directory.Exists(buildtimeToolsPath))
					{
						canBuild = false;
					}
				}
				if (canBuild)
				{
					String.NewOrSet!(buildtimeShaderIncludePath, path);
					buildtimeShaderIncludePath.Append("/../submodules/bgfx/src/");
					if (!System.IO.Directory.Exists(buildtimeShaderIncludePath))
					{
						canBuild = false;
					}
				}
			}
			if (canBuild)
			{
				Log.Info("NOTE: Running in build mode!");
				Log.Info("NOTE: You can change existing assets (textures, shaders, etc) and they will get rebuilt and reloaded!");
				Directory.CreateDirectory(runtimeResourcesPath);
				// Create resource builders
				for (let type in Type.Types)
				{
					if (!type.IsSubtypeOf(typeof(ResourceBuilder)))
					{
						continue;
					}
					switch (type.CreateObject()) {
					case .Ok(let val):
						AddResourceBuild(val as ResourceBuilder);
						break;
					case .Err(let err):
						continue;
					}
				}
				// Update buildtime folder
				var files = scope List<String>();
				Utils.FindFiles(buildtimeResourcesPath, "*.*", ref files);
				// Update resource
				foreach (var fileName in files)
				{
					BuildResource(fileName);
					delete fileName;
				}
				// Watch buildtime folder
				buildResourcesWatched = new FileSystemWatcher(buildtimeResourcesPath);
				buildResourcesWatched.IncludeSubdirectories = true;
				buildResourcesWatched.StartRaisingEvents();
				buildResourcesWatched.OnCreated.Add(new (fileName) => OnFileChange(fileName));
				buildResourcesWatched.OnChanged.Add(new (fileName) => OnFileChange(fileName));
				gApp.OnPause.Add(new (paused) =>
					{
						if (paused)
						{
							buildResourceFiles = false;
						} else
						{
							buildResourceFiles = true;
							for (var fileName in queueResourceFiles)
							{
								BuildResource(fileName, true);
								delete fileName;
							}
							queueResourceFiles.Clear();
						}
					});
			}
		}

		public static void SetRootPath(String _path)
		{
			var path = scope String();
			Path.GetActualPathName(_path, path);
			String.NewOrSet!(runtimeResourcesPath, path);
			runtimeResourcesPath.Append("/runtime/resources/");
			String.NewOrSet!(buildtimeResourcesPath, path);
			buildtimeResourcesPath.Append("/buildtime/resources/");
			String.NewOrSet!(buildtimeToolsPath, path);
			InitializeRuntimeBuild(path);
			if (!System.IO.Directory.Exists(runtimeResourcesPath))
			{
				Utils.ShowMessageBoxOK("ERROR", "Runtime folder missing!");
				System.Environment.Exit(1);
			}
		}

		public static T GetResource<T>(StringView path, bool load = true) where T : Resource
		{
			var hashString = scope String();
			GetPathHash(path, hashString);
			if (resourceMap.TryGetValue(hashString, var resource))
			{
				if (!(resource is T))
				{
					return null;
				}
				resource.Load();
				return resource as T;
			}
			return null;
		}

	}
}
