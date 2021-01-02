using SDL2;
using Bgfx;
using System;
using System.IO;
using System.Diagnostics;
using System.Threading;
using Example;

namespace Example
{
	public abstract class AppBase
	{
		public SDL.Window* mWindow;
		public int32 mUpdateCnt;
		public String mTitle = new .("Bgfx-Beef PixelArt game example") ~ delete _;
		public int32 mWidth = 640;
		public int32 mHeight = 360;
		public bool* mKeyboardState;
		public bool isFullscreen = false;

		public int32 targetWidth = 320;
		public int32 targetHeight = 180;

		public bgfx.TextureHandle mRenderTextureHandle;
		public bgfx.FrameBufferHandle mFrameBufferHandle;

		public delegate void OnPauseDelegate(bool paused);
		public Event<OnPauseDelegate> OnPause ~ _.Dispose();

		public int[3] mouseButton;
		public Vector2 mouseDelta = .sZero;

		public this()
		{
			gApp = this;
		}

		public ~this()
		{
			ResourceManager.Finalize();

			bgfx.destroy_frame_buffer(mFrameBufferHandle);
			bgfx.shutdown();

			if (mWindow != null)
				SDL.DestroyWindow(mWindow);
		}

		private bool InitializeSDL()
		{
			SDL.Init(.Video | .Events | .Audio);

			mWindow = SDL.CreateWindow(mTitle, .Undefined, .Undefined, mWidth, mHeight, .Shown | .Resizable);
			SDL.MaximizeWindow(mWindow);
			return true;
		}

		private bool InitializeBgfx()
		{
			var info = SDL.SDL_SysWMinfo();
			SDL.GetWindowWMInfo(mWindow, ref info);

			var platformData = bgfx.PlatformData();
			platformData.ndt = null;
#if BF_PLATFORM_WINDOWS
			platformData.nwh = (void*)(int)info.info.win.window;
#elif BF_PLATFORM_MACOS
                        platformData.nwh = (void*)(int)info.info.cocoa.window;
#elif BF_PLATFORM_LINUX
                        platformData.nwh = (void*)(int)info.info.x11.window;
#endif
			bgfx.render_frame(0);

			var init = bgfx.Init();
			init.platformData = platformData;
			init.type = .Direct3D11;
			init.resolution.format = .RGBA8;
			init.resolution.width = (uint32)mWidth;
			init.resolution.height = (uint32)mHeight;
			init.resolution.reset = (uint32)bgfx.ResetFlags.Vsync;
			init.resolution.numBackBuffers = 2;
			init.limits.maxEncoders = 8;
			init.limits.minResourceCbSize = 65536;
			init.limits.transientVbSize = 6291456;
			init.limits.transientIbSize = 2097152;
			bgfx.init(&init);

			return true;
		}

		public virtual void OnPreInit()
		{
		}

		public virtual void OnPostInit()
		{
		}

		public void Init()
		{
			String currentDirectory = scope .();
			System.IO.Directory.GetCurrentDirectory(currentDirectory);

			OnPreInit();
			InitializeSDL();
			InitializeBgfx();

			ResourceManager.SetRootPath(currentDirectory);

			mRenderTextureHandle = bgfx.create_texture_2d((uint16)targetWidth, (uint16)targetHeight, false, 1, .RGBA8, (uint64)bgfx.TextureFlags.Rt, null);

			bgfx.TextureHandle[1] handles;
			handles[0] = mRenderTextureHandle;
			mFrameBufferHandle = bgfx.create_frame_buffer_from_handles(1, &handles, true);

			OnPostInit();
		}

		public bool IsKeyDown(SDL.Scancode scancode)
		{
			if (mKeyboardState == null)
				return false;
			return mKeyboardState[(int)scancode];
		}

		public virtual void OnUpdate() {
		}

		public virtual void Update()
		{
			Time.Update();
			OnUpdate();
		}

		public virtual void Draw()
		{
		}

		public bool KeyDownInternal(SDL.KeyboardEvent evt)
		{
			return false;
		}

		public virtual void KeyDown(SDL.KeyboardEvent evt)
		{
			if (evt.keysym.scancode == .Grave)
			{
				GC.Report();
			}
			if ((evt.keysym.mod & .ALT) !=0 && evt.keysym.scancode == .Return)
			{
				isFullscreen = !isFullscreen;
				if(isFullscreen) {
					var rect = SDL.Rect();
					SDL.GetDisplayBounds(0, out rect);
					SDL.RestoreWindow(mWindow);
					SDL.SetWindowSize(mWindow, rect.w, rect.h);
					SDL.SetWindowPosition(mWindow, (int32)SDL.WindowPos.Centered, (int32)SDL.WindowPos.Centered);
				} else {
					SDL.RestoreWindow(mWindow);
					SDL.MaximizeWindow(mWindow);
				}
			}
		}

		public virtual void KeyUp(SDL.KeyboardEvent evt)
		{
		}

		public virtual void MouseDown(SDL.MouseButtonEvent evt)
		{
			mouseButton[evt.button - 1] = 1;
		}

		public virtual void MouseUp(SDL.MouseButtonEvent evt)
		{
			mouseButton[evt.button - 1] = 0;
		}

		public virtual void HandleEvent(SDL.Event evt)
		{
			switch (evt.type) {
			case .WindowEvent:
				switch (evt.window.windowEvent) {
				case .Focus_lost:
					Log.Info("Pause!");
					OnPause(true);
				case .FocusGained:
					Log.Info("Resume!");
					OnPause(false);
				default:
				}
			default:
			}
		}

		public virtual void OnPreRender()
		{
		}

		public virtual void OnPostRender()
		{
		}

		public void Render()
		{
			OnPreRender();
			bgfx.frame(false);
			OnPostRender();
		}

		public void Run()
		{
			var quitting = false;
			while (!quitting)
			{
				mouseDelta = .sZero;
				SDL.Event event;
				while (SDL.PollEvent(out event) != 0)
				{
					switch (event.type)
					{
					case .Quit:
						quitting = true;
					case .KeyDown:
						KeyDown(event.key);
					case .KeyUp:
						KeyUp(event.key);
					case .MouseButtonDown:
						MouseDown(event.button);
					case .MouseButtonUp:
						MouseUp(event.button);
					case .MouseMotion:
						mouseDelta.mX += event.motion.xrel;
						mouseDelta.mY += event.motion.yrel;
					case .WindowEvent:
						switch (event.window.windowEvent) {
						case .SizeChanged:
							mWidth = event.window.data1;
							mHeight = event.window.data2;
							bgfx.reset((uint32)mWidth, (uint32)mHeight, (uint32)bgfx.ResetFlags.Vsync, bgfx.TextureFormat.Count);
							Log.Debug("Window resized to {0}x{1}!", mWidth, mHeight);
						default:
						}
					default:
					}
					HandleEvent(event);
				}

				mKeyboardState = SDL.GetKeyboardState(null);

				Update();
				Render();
			}
		}
	}

	static
	{
		public static AppBase gApp;
	}
}

