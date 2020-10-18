using System;
using System.Collections;
using System.Text;

namespace Example
{
	[CRepr]
	public struct Point
	{
		public float x;
		public float y;

		public this(float x, float y)
		{
			this.x = x;
			this.y = y;
		}
	}
}
