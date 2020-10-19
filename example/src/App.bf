using Bgfx;
using System;
using System.IO;
using System.Collections;

namespace Example
{
	class App : AppBase
	{
		public bgfx.VertexBufferHandle rainQuad;
		public bgfx.VertexBufferHandle blitQuad;
		public bgfx.UniformHandle scaleUniform;
		public bgfx.UniformHandle timeUniform;

		Texture rainDropTexture;
		List<Texture> cloudTextures = new List<Texture>() ~ delete _;
		Shader textureShader;
		Shader backgroundShader;
		Shader blitShader;

		public override void OnPreInit()
		{
			// Pixel art game!
			targetWidth = 640;
			targetHeight = 360;
		}

		public override void OnPostInit()
		{
			base.OnPostInit();
			textureShader = ResourceManager.GetResource<Shader>("shaders/generic_texture");
			blitShader = ResourceManager.GetResource<Shader>("shaders/blit");
			backgroundShader = ResourceManager.GetResource<Shader>("shaders/background");
			rainDropTexture = ResourceManager.GetResource<Texture>("textures/raindrop");
			for (int i = 0; i < 3; ++i)
			{
				var texture = ResourceManager.GetResource<Texture>(StackStringFormat!("textures/cloud_{0}", i + 1));
				cloudTextures.Add(texture);
			}

			rainQuad = ResourceManager.CreateQuad();
			blitQuad = ResourceManager.CreateQuad();

			scaleUniform = bgfx.create_uniform("scale", bgfx.UniformType.Vec4, 1);
			timeUniform = bgfx.create_uniform("time", bgfx.UniformType.Vec4, 1);
		}

		public void RenderQuad(uint16 viewId, ref Matrix4 model, Texture texture)
		{
			bgfx.set_transform(model.Ptr(), 1);
			uint64 state = (uint64)(bgfx.StateFlags.WriteRgb | bgfx.StateFlags.WriteA | bgfx.StateFlags.PtTristrip | bgfx.blend_function(bgfx.StateFlags.BlendSrcAlpha, bgfx.StateFlags.BlendInvSrcAlpha));
			bgfx.set_state(state, 0);
			if (texture != null)
			{
				var scale = Quaternion(texture.Width * 0.5f, texture.Height * 0.5f, 0.0f, 0.0f);
				bgfx.set_uniform(scaleUniform, &scale, 1);
				bgfx.set_texture(0, bgfx.create_uniform("s_texture", bgfx.UniformType.Sampler, 1), texture.Handle, (uint64)(bgfx.SamplerFlags.MinPoint | bgfx.SamplerFlags.MagPoint | bgfx.SamplerFlags.MipPoint | bgfx.SamplerFlags.UClamp | bgfx.SamplerFlags.VClamp));
			}
			bgfx.set_vertex_buffer(0, rainQuad, 0, 4);
			bgfx.submit(viewId, textureShader.Handle, 0, (uint8)bgfx.DiscardFlags.All);
		}

		public override void OnPostRender()
		{
			base.OnPostRender();
			// Fullscreen clear
			uint16 viewId = 0;
			{
				bgfx.set_view_clear(viewId, (uint)(bgfx.ClearFlags.Color | bgfx.ClearFlags.Depth), 0, 1.0f, 0);
				bgfx.set_view_rect(viewId, 0, 0, (uint16)mWidth, (uint16)mHeight);
				bgfx.touch(viewId);
				++viewId;
			}
			// Render somethings to texture
			{
				bgfx.set_view_clear(viewId, (uint)(bgfx.ClearFlags.Color | bgfx.ClearFlags.Depth), 0x4dadf5ff, 1.0f, 0);
				bgfx.set_view_frame_buffer(viewId, mFrameBufferHandle);
				bgfx.set_view_rect(viewId, 0, 0, (uint16)targetWidth, (uint16)targetHeight);
				bgfx.touch(viewId);

				var view = Matrix4();
				var projection = Matrix4.CreatePerspectiveOrtho(0, (float)targetWidth, 0, (float)targetHeight, 0.0f, 1.0f, 0.0f, false);
				bgfx.set_view_transform(viewId, view.Ptr(), projection.Ptr());

				var model = Matrix4();
				var rotation = Quaternion.CreateFromYawPitchRoll(0, 0, 0);
				model = rotation.ToMatrix();
				var random = scope Random(100);

				{
					var time = Quaternion((float)Time.Time, 0.0f, 0.0f, 0.0f);
					bgfx.set_uniform(timeUniform, &time, 1);
					var state = (uint64)(bgfx.StateFlags.WriteRgb | bgfx.StateFlags.WriteA | bgfx.StateFlags.PtTristrip);
					bgfx.set_state(state, 0);
					bgfx.set_vertex_buffer(0, blitQuad, 0, 4);
					bgfx.submit(viewId, backgroundShader.Handle, 0, (uint8)bgfx.DiscardFlags.All);
				}

				for (int i = 0; i < 100; ++i)
				{
					int index = random.Next(0, cloudTextures.Count - 1);
					var texture = cloudTextures[index];
					var x = (float)random.NextDouble() * (targetWidth * 1.5f);
					x += Math.Cos((float)(Time.Time * 0.001)) * 100.0f;
					model.Translation = Vector3(x, (float)random.NextDouble() * (float)targetHeight, 0.0f);
					RenderQuad(viewId, ref model, texture);
				}

				for (int i = 0; i < 100; ++i)
				{
					var x = (float)random.NextDouble() * (float)targetWidth;
					var y = (float)((Time.Time * Math.Lerp(5.0, 50.0, random.NextDouble())) % targetHeight);
					model.Translation = Vector3(x, y, 0.0f);
					RenderQuad(viewId, ref model, rainDropTexture);
				}
				++viewId;
			}
			// Render texture to screen
			{
				let aspectRatio = (float)targetWidth / (float)targetHeight;
				bgfx.set_view_clear(viewId, 0, 0, 1.0f, 0);
				if (mWidth > mHeight)
				{
					let newWidth = (uint16)(mHeight * aspectRatio);
					bgfx.set_view_rect(viewId, (uint16)mWidth / 2 - newWidth / 2, 0, newWidth, (uint16)mHeight);
				} else
				{
					let newHeight = (uint16)(mWidth / aspectRatio);
					bgfx.set_view_rect(viewId, 0, (uint16)mHeight / 2 - newHeight / 2, (uint16)mWidth, newHeight);
				}
				bgfx.touch(viewId);
				var state = (uint64)(bgfx.StateFlags.WriteRgb | bgfx.StateFlags.WriteA | bgfx.StateFlags.PtTristrip);
				bgfx.set_state(state, 0);
				bgfx.set_vertex_buffer(0, blitQuad, 0, 4);
				bgfx.set_texture(0, bgfx.create_uniform("s_texture", bgfx.UniformType.Sampler, 1), mRenderTextureHandle, (uint64)(bgfx.SamplerFlags.MinPoint | bgfx.SamplerFlags.MagPoint | bgfx.SamplerFlags.MipPoint | bgfx.SamplerFlags.UClamp | bgfx.SamplerFlags.VClamp));
				bgfx.submit(viewId, blitShader.Handle, 0, (uint8)bgfx.DiscardFlags.All);
				++viewId;
			}
		}

	}
}
