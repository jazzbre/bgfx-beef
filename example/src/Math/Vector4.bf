using System;
using System.Collections;
using System.Text;
using System.Threading.Tasks;

namespace Example
{
	[CRepr]
	public struct Vector4 : IHashable, IEquatable<Vector4>
	{
		[Reflect]
		public float mX;
		[Reflect]
		public float mY;
		[Reflect]
		public float mZ;
		[Reflect]
		public float mW;

		private static Vector4 sZero = Vector4(0f, 0f, 0f, 0.0f);
		private static Vector4 sOne = Vector4(1f, 1f, 1f, 1.0f);
		private static Vector4 sUnitX = Vector4(1f, 0f, 0f, 0.0f);
		private static Vector4 sUnitY = Vector4(0f, 1f, 0f, 0.0f);
		private static Vector4 sUnitZ = Vector4(0f, 0f, 1f, 0.0f);
		private static Vector4 sUp = Vector4(0f, 1f, 0f, 0.0f);
		private static Vector4 sDown = Vector4(0f, -1f, 0f, 0.0f);
		private static Vector4 sRight = Vector4(1f, 0f, 0f, 0.0f);
		private static Vector4 sLeft = Vector4(-1f, 0f, 0f, 0.0f);
		private static Vector4 sForward = Vector4(0f, 0f, -1f, 0.0f);
		private static Vector4 sBackward = Vector4(0f, 0f, 1f, 0.0f);

		public static Vector4 Zero
		{
			get { return sZero; }
		}

		public static Vector4 One
		{
			get { return sOne; }
		}

		public static Vector4 UnitX
		{
			get { return sUnitX; }
		}

		public static Vector4 UnitY
		{
			get { return sUnitY; }
		}

		public static Vector4 UnitZ
		{
			get { return sUnitZ; }
		}

		public static Vector4 Up
		{
			get { return sUp; }
		}

		public static Vector4 Down
		{
			get { return sDown; }
		}

		public static Vector4 Right
		{
			get { return sRight; }
		}

		public static Vector4 Left
		{
			get { return sLeft; }
		}

		public static Vector4 Forward
		{
			get { return sForward; }
		}

		public static Vector4 Backward
		{
			get { return sBackward; }
		}

		public float Length
		{
			get
			{
				return (float)Math.Sqrt(mX * mX + mY * mY + mZ * mZ + mW * mW);
			}
		}

		public float LengthSquared
		{
			get
			{
				return mX * mX + mY * mY + mZ * mZ + mW * mW;
			}
		}

		public this(float x, float y, float z, float w)
		{
			mX = x;
			mY = y;
			mZ = z;
			mW = w;
		}

		public bool Equals(Vector4 other)
		{
			return this == other;
		}

		public int GetHashCode()
		{
			return (int)(this.mX + this.mY + this.mZ + this.mW);
		}

		public static Vector4 Normalize(Vector4 vector)
		{
			Vector4 newVec;
			Normalize(vector, out newVec);
			return vector;
		}

		public static void Normalize(Vector4 value, out Vector4 result)
		{
			float factor = Distance(value, sZero);
			factor = 1f / factor;
			result.mX = value.mX * factor;
			result.mY = value.mY * factor;
			result.mZ = value.mZ * factor;
			result.mW = value.mW * factor;
		}

		public static float Dot(Vector4 vec1, Vector4 vec2)
		{
			return vec1.mX * vec2.mX + vec1.mY * vec2.mY + vec1.mZ * vec2.mZ + vec1.mW * vec2.mW;
		}

		public static float DistanceSquared(Vector4 value1, Vector4 value2)
		{
			return (value1.mX - value2.mX) * (value1.mX - value2.mX) +
				(value1.mY - value2.mY) * (value1.mY - value2.mY) +
				(value1.mZ - value2.mZ) * (value1.mZ - value2.mZ) +
				(value1.mW - value2.mW) * (value1.mW - value2.mW);
		}

		public static float Distance(Vector4 vector1, Vector4 vector2)
		{
			float result = DistanceSquared(vector1, vector2);
			return (float)Math.Sqrt(result);
		}

		public static Vector4 Transform(Vector4 vec, Matrix4 matrix)
		{
			Vector4 result;
			float fInvW = 1.0f / (matrix.m30 * vec.mX + matrix.m31 * vec.mY + matrix.m32 * vec.mZ + matrix.m33);

			result.mX = (matrix.m00 * vec.mX + matrix.m01 * vec.mY + matrix.m02 * vec.mZ + matrix.m03) * fInvW;
			result.mY = (matrix.m10 * vec.mX + matrix.m11 * vec.mY + matrix.m12 * vec.mZ + matrix.m13) * fInvW;
			result.mZ = (matrix.m20 * vec.mX + matrix.m21 * vec.mY + matrix.m22 * vec.mZ + matrix.m23) * fInvW;
			result.mW = 1.0f;
			return result;
		}

		public static Vector4 Transform(Vector4 vec, Quaternion quat)
		{
			Matrix4 matrix = quat.ToMatrix();
			return Transform(vec, matrix);
		}

		public static Vector4 TransformNormal(Vector4 normal, Matrix4 matrix)
		{
			return Vector4((normal.mX * matrix.m11) + (normal.mY * matrix.m21) + (normal.mZ * matrix.m31),
				(normal.mX * matrix.m12) + (normal.mY * matrix.m22) + (normal.mZ * matrix.m32),
				(normal.mX * matrix.m13) + (normal.mY * matrix.m23) + (normal.mZ * matrix.m33), 1.0f);
		}

		public static bool operator==(Vector4 value1, Vector4 value2)
		{
			return (value1.mX == value2.mX) &&
				(value1.mY == value2.mY) &&
				(value1.mZ == value2.mZ) &&
				(value1.mW == value2.mW);
		}

		public static bool operator!=(Vector4 value1, Vector4 value2)
		{
			return !(value1 == value2);
		}

		public static Vector4 operator+(Vector4 vec1, Vector4 vec2)
		{
			return Vector4(vec1.mX + vec2.mX, vec1.mY + vec2.mY, vec1.mZ + vec2.mZ, vec1.mW + vec2.mW);
		}

		public static Vector4 operator-(Vector4 vec1, Vector4 vec2)
		{
			return Vector4(vec1.mX - vec2.mX, vec1.mY - vec2.mY, vec1.mZ - vec2.mZ, vec1.mW - vec2.mW);
		}

		public static Vector4 operator*(Vector4 vec, float scale)
		{
			return Vector4(vec.mX * scale, vec.mY * scale, vec.mZ * scale, vec.mW * scale);
		}

		public override void ToString(String str)
		{
			str.AppendF("{0:0.0#}, {1:0.0#}, {2:0.0#}, {3:0.0#}", mX, mY, mZ, mW);
		}
	}
}
