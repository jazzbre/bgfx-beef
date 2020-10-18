using System;

namespace Example
{
	public enum LogType
	{
		Debug,
		Info,
		Warning,
		Error,
	}

	public static class Log
	{
		private static void Log(LogType logType, StringView fmt, params Object[] args)
		{
			var log = scope String();
			var now = DateTime.Now;
			var type = scope String();
			logType.ToString(type);
			log.AppendF("{} {}-{}-{} {}:{}:{}.{} - ", type, now.Year, now.Month, now.Day, now.Hour, now.Minute, now.Second, now.Millisecond);
			log.AppendF(fmt, params args);
			Console.WriteLine(log);
		}

		public static void Debug(StringView fmt, params Object[] args)
		{
			Log(LogType.Debug, fmt, params args);
		}

		public static void Info(StringView fmt, params Object[] args)
		{
			Log(LogType.Info, fmt, params args);
		}

		public static void Warning(StringView fmt, params Object[] args)
		{
			Log(LogType.Warning, fmt, params args);
		}

		public static void Error(StringView fmt, params Object[] args)
		{
			Log(LogType.Error, fmt, params args);
		}

	}
}
