using SDL2;

namespace Example
{
	public static class Time
	{
		public static double Time
		{
			get; private set;
		}

		public static double DeltaTime
		{
			get; private set;
		}

		public static void Update()
		{
			let newTime = (double)SDL.GetPerformanceCounter() / (double)SDL.GetPerformanceFrequency();
			if (Time > 0.0)
			{
				DeltaTime = newTime - Time;
			}
			Time = newTime;
		}
	}
}
