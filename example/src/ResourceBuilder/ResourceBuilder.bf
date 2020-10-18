using System;
using System.IO;

namespace Example
{
	public abstract class ResourceBuilder
	{
		public virtual String Extension => "";

		public abstract Type ResourceType => null;

		public bool CheckBuild(StringView path, StringView hash)
		{
			return OnCheckBuild(path, hash);
		}

		public bool Build(StringView path, StringView hash)
		{
			return OnBuild(path, hash);
		}

		public abstract bool OnCheckBuild(StringView path, StringView hash);
		public abstract bool OnBuild(StringView path, StringView hash);
	}
}
