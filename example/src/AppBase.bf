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
		public bool mHasAudio;

		public int32 targetWidth = 320;
		public int32 targetHeight = 180;

		public bgfx.TextureHandle mRenderTextureHandle;
		public bgfx.FrameBufferHandle mFrameBufferHandle;

		public delegate void OnPauseDelegate(bool paused);
		public Event<OnPauseDelegate> OnPause ~ _.Dispose();

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
			SDL.Init(.Events | .Audio);
			SDL.EventState(.JoyAxisMotion, .Disable);
			SDL.EventState(.JoyBallMotion, .Disable);
			SDL.EventState(.JoyHatMotion, .Disable);
			SDL.EventState(.JoyButtonDown, .Disable);
			SDL.EventState(.JoyButtonUp, .Disable);
			SDL.EventState(.JoyDeviceAdded, .Disable);
			SDL.EventState(.JoyDeviceRemoved, .Disable);

			mWindow = SDL.CreateWindow(mTitle, .Undefined, .Undefined, mWidth, mHeight, .Shown | .AllowHighDPI);
			mHasAudio = SDLMixer.OpenAudio(44100, SDLMixer.MIX_DEFAULT_FORMAT, 2, 4096) >= 0;

			return true;
		}

		private bool InitializeBgfx()
		{
			var info = SDL.SDL_SysWMinfo();
			SDL.GetWindowWMInfo(mWindow, ref info);


			var platformData = bgfx.PlatformData();
			platformData.ndt = null;
			platformData.nwh = (void*)(int)info.info.win.window;

			bgfx.render_frame(0);

			var init = bgfx.Init();
			init.platformData = platformData;
			init.type = bgfx.RendererType.Direct3D11;
			init.resolution.format = bgfx.TextureFormat.RGBA8;
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

			mRenderTextureHandle = bgfx.create_texture_2d((uint16)targetWidth, (uint16)targetHeight, false, 1, bgfx.TextureFormat.RGBA8, (uint64)bgfx.TextureFlags.Rt, null);

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

		public virtual void Update()
		{
			Time.Update();
		}

		public virtual void Draw()
		{
		}

		public virtual void KeyDown(SDL.KeyboardEvent evt)
		{
			if (evt.keysym.scancode == .Grave)
			{
				GC.Report();
			}
		}

		public virtual void KeyUp(SDL.KeyboardEvent evt)
		{
		}

		public virtual void MouseDown(SDL.MouseButtonEvent evt)
		{
		}

		public virtual void MouseUp(SDL.MouseButtonEvent evt)
		{
		}

		public virtual void HandleEvent(SDL.Event evt)
		{
			switch (evt.type) {
			case .WindowEvent:
				switch (evt.window.windowEvent) {
				case .Focus_lost:
					Log.Info("Pause!");
					OnPause(true);
					break;
				case .FocusGained:
					Log.Info("Resume!");
					OnPause(false);
					break;
				default:
					break;
				}
				break;
			default:
				break;
			}
		}

		public void PlaySound(Sound sound, float volume = 1.0f, float pan = 0.5f)
		{
			if (sound == null)
				return;

			int32 channel = SDLMixer.PlayChannel(-1, sound.mChunk, 0);
			//SDLMixer.SetPanning()
			SDLMixer.Volume(channel, (int32)(volume * 128));
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
			while (true)
			{
				SDL.Event event;

				while (SDL.PollEvent(out event) != 0)
				{
					switch (event.type)
					{
					case .Quit:
						return;
					case .KeyDown:
						KeyDown(event.key);
					case .KeyUp:
						KeyUp(event.key);
					case .MouseButtonDown:
						MouseDown(event.button);
					case .MouseButtonUp:
						MouseUp(event.button);
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

