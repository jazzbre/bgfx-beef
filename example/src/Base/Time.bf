using SDL2;

namespace Example
{
	public static class Time
	{
		private static double startTime = -1.0;

		public static double Time
		{
			get; private set;
		}

		public static float DeltaTime
		{
			get; private set;
		}

		public static void Update()
		{
			var newTime = (double)SDL.GetPerformanceCounter() / (double)SDL.GetPerformanceFrequency();
			if(startTime < 0.0) {
				startTime = newTime;
			}
			newTime -= startTime;
			if (Time > 0.0)
			{
				DeltaTime = (float)(newTime - Time);
			}
			Time = newTime;
		}
	}
}
