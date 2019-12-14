module sbylib.math.quaternion;

import sbylib.math.vector;
import sbylib.math.matrix;
import sbylib.math.angle;
import std.traits;
import std.conv : to;
import std.format : format;
import std.range : isInputRange, RangeElementType = ElementType;

alias quat = Quaternion!float;

/**
Quaternion type
*/
struct Quaternion(T)
if (__traits(isArithmetic, T)) 
{
    /**
    Components of quaternion.

    q = ix + jy + kz + w
    */
    T x, y, z, w;

    /**
    Constructor from scalar components
    */
    this(T x, T y, T z, T w) {
        this.x = x;
        this.y = y;
        this.z = z;
        this.w = w;
    }

    /**
    Constructor from imaginary vector and real part
    */
    this(Vector!(T,3) v, T w) {
        this(v[0],v[1],v[2],w);
    }

    /**
    Constructor by InputRange.
    This quaternion's all elements are filled by given range.

    Params:
        elements = values which fills the quaternion
    */
    this(Range)(Range r)
    if (isInputRange!(Range) && is(RangeElementType!(Range) : T))
    {
        import std.range : front, popFront, empty;

        static foreach (i; 0..4) {
            this[i] = r.front;
            r.popFront;
        }
        assert(r.empty);
    }

    /**
    Get the x-axis basis vector of the transformation of this quaternion

    Returns: x basis vector
    */
    Vector!(T,3) baseX() const {
        return Vector!(T,3)
            (1-2*(y*y+z*z),
             2*(x*y+w*z),
             2*(x*z-w*y));
    }

    /**
    Get the y-axis basis vector of the transformation of this quaternion

    Returns: y basis vector
    */
    Vector!(T,3) baseY() const {
        return Vector!(T,3)
            (2*(x*y-z*w),
             1-2*(x*x+z*z),
             2*(y*z+w*x));
    }

    /**
    Get the z-axis basis vector of the transformation of this quaternion

    Returns: z basis vector
    */
    Vector!(T,3) baseZ() const {
        return Vector!(T,3)
            (2*(x*z+w*y),
             2*(y*z-w*x),
             1-2*(x*x+y*y));
    }

    unittest {
        import std.algorithm : map;
        import std.range : iota;
        import std.random : uniform;
        import sbylib.math.vector : approxEqual;
        foreach (i; 0..100) {
            const q = quat(iota(4).map!(_ => uniform(-1.0f, +1.0f))).normalize;
            assert(approxEqual(q.rotate(vec3(1,0,0)), q.baseX));
            assert(approxEqual(q.rotate(vec3(0,1,0)), q.baseY));
            assert(approxEqual(q.rotate(vec3(0,0,1)), q.baseZ));
        }
    }

    /**
    Unary operation for "+".

    this is identity function

    Returns: a quaternionly which is equal to this quaternion
    */
    Quaternion!T opUnary(string op)() const 
    if (op == "+")
    {
        return this;
    }

    unittest {
        import std.algorithm : map;
        import std.range : iota;
        import std.random : uniform;

        foreach (i; 0..100) {
            const q = quat(iota(4).map!(_ => uniform(-1.0f, +1.0f)));
            assert(approxEqual(q * +1, +q));
        }
    }

    /**
    Unary operation for "-".

    Returns: a quaternion whose sign is inverted
    */
    Quaternion!T opUnary(string op)() const 
    if (op == "-")
    {
        Quaternion!T result;
        static foreach (i; 0..4) {
            result[i] = -this[i];
        }
        return result;
    }

    unittest {
        import std.algorithm : map;
        import std.range : iota;
        import std.random : uniform;

        foreach (i; 0..100) {
            const q = quat(iota(4).map!(_ => uniform(-1.0f, +1.0f)));
            assert(approxEqual(q * -1, -q));
        }
    }

    /**
    Unary operation for "~".
    This means conjugation.

    Returns: a quaternion conjugate with this quaternion
    */
    Quaternion!T opUnary(string op)() const
    if (op == "~")
    {
        return Quaternion!T(-x,-y,-z,+w);
    }

    unittest {
        import std.algorithm : map;
        import std.range : iota;
        import std.random : uniform;

        foreach (i; 0..100) {
            const q = quat(iota(4).map!(_ => uniform(-1.0f, +1.0f)));

            assert(approxEqual(q * ~q, quat(vec3(0), lengthSq(q))));
        }
    }

    /**
    Binary operation between quaternion for "+" or "-"

    Params:
        q = target quaternion

    Returns: calculated quaternion
    */
    Quaternion!(CommonType!(T,S)) opBinary(string op,S)(Quaternion!S q) const 
    if (op == "+" || op == "-")
    {
        Quaternion!(CommonType!(T,S)) result;
        static foreach (i; 0..4) {
            result[i] = mixin(format!q{
                this[i] %s q[i]
            }(op));
        }
        return result;
    }

    unittest {
        import std.algorithm : map;
        import std.range : iota;
        import std.random : uniform;
        import std.math : approxEqual;

        foreach (k; 0..100) {
            const a = quat(iota(4).map!(_ => uniform(-1.0f, +1.0f)));
            const b = quat(iota(4).map!(_ => uniform(-1.0f, +1.0f)));

            const c = a + b;
            const d = a - b;

            static foreach (i; 0..4) {
                assert(approxEqual(a[i] + b[i], c[i]));
                assert(approxEqual(a[i] - b[i], d[i]));
            }
        }
    }

    /**
    Binary operation between quaternion for "*"

    Params:
        q = target quaternion

    Returns: calculated quaternion
    */
    Quaternion!(CommonType!(T,S)) opBinary(string op,S)(Quaternion!S q) const 
    if (op == "*")
    {
        Quaternion!(CommonType!(T,S)) result;
        result.w = w * q.w - x * q.x - y * q.y - z * q.z;
        result.x = w * q.x + x * q.w + y * q.z - z * q.y;
        result.y = w * q.y - x * q.z + y * q.w + z * q.x;
        result.z = w * q.z + x * q.y - y * q.x + z * q.w;
        return result;
    }

    unittest {
        import std.algorithm : map;
        import std.range : iota;
        import std.random : uniform;

        foreach (i; 0..100) {
            const a = quat(4.iota.map!(_ => uniform(-1.0f, +1.0f)));
            const b = quat(4.iota.map!(_ => uniform(-1.0f, +1.0f)));
            const c = quat(4.iota.map!(_ => uniform(-1.0f, +1.0f)));
            assert(approxEqual((a * b) * c, a * (b * c)));
        }
    }

    /**
    Binary operation between scalar type for "*" or "/".

    Params:
        e = target scalar value

    Returns: calculated quaternion
    */
    Quaternion!(CommonType!(T,S)) opBinary(string op, S)(S e) const
    if (__traits(isArithmetic, S) && (op == "*" || op == "/"))
    {
        Quaternion!(CommonType!(T,S)) result;
        static foreach (i; 0..4) {
            result[i] = mixin(format!q{
                this[i] %s e
            }(op));
        }
        return result;
    }

    unittest {
        import std.algorithm : map;
        import std.range : iota;
        import std.random : uniform;
        import std.math : approxEqual;

        foreach (k; 0..100) {
            const q = quat(4.iota.map!(_ => uniform(-1.0f, +1.0f)));
            const s = uniform(-1.0f, +1.0f);
            const q2 = q * s;
            const q3 = q / s;
            static foreach (i; 0..4) {
                assert(approxEqual(q[i] * s, q2[i]));
                assert(approxEqual(q[i] / s, q3[i]));
            }
        }
    }

    /**
    Binary operation between scalar type for "*".

    Params:
        e = target scalar value

    Returns: calculated quaternion
    */
    Quaternion!(CommonType!(T,S)) opBinaryRight(string op, S)(S e) const
    if (__traits(isArithmetic, S) && (op == "*"))
    {
        Quaternion!(CommonType!(T,S)) result;
        static foreach (i; 0..4) {
            result[i] = mixin(format!q{
                this[i] %s e
            }(op));
        }
        return result;
    }

    unittest {
        import std.algorithm : map;
        import std.range : iota;
        import std.random : uniform;
        import std.math : approxEqual;

        foreach (k; 0..100) {
            const q = quat(4.iota.map!(_ => uniform(-1.0f, +1.0f)));
            const s = uniform(-1.0f, +1.0f);
            const q2 = s * q;
            static foreach (i; 0..4) {
                assert(approxEqual(s * q[i], q2[i]));
            }
        }
    }

    /**
    Operator assign for quaternion.
    This function supports "+" or "-" operation.

    Params:
        q = target quaternion
    */
    Quaternion opOpAssign(string op,S)(Quaternion!S q) 
    if (op == "+" || op == "-")
    {
        static foreach (i; 0..4) {
            mixin(format!q{
                this[i] %s= q[i];
            }(op));
        }
        return this;
    }

    unittest {
        import std.algorithm : map;
        import std.range : iota;
        import std.random : uniform;

        foreach (i; 0..100) {
            auto q = quat(4.iota.map!(_ => uniform(-1.0f, +1.0f)));
            const q2 = quat(4.iota.map!(_ => uniform(-1.0f, +1.0f)));
            const q3 = q + q2;
            q += q2;

            assert(approxEqual(q, q3));
        }
    }

    /**
    Operator assign for quaternion.
    This function supports "*" operation.

    Params:
        q = target quaternion
    */
    Quaternion opOpAssign(string op,S)(Quaternion!(S) q)
    if (op == "*")
    {
        Quaternion result = this * q;
        static foreach (i; 0..4) {
            this[i] = result[i];
        }
        return this;
    }

    unittest {
        import std.algorithm : map;
        import std.range : iota;
        import std.random : uniform;
        foreach (i; 0..100) {
            auto q = quat(4.iota.map!(_ => uniform(-1.0f, +1.0f)));
            const s = uniform(-1.0f, +1.0f);
            const q2 = q * s;
            q *= s;

            assert(approxEqual(q, q2));
        }
    }

    /**
    Operator assign for scalar type.
    This function supports "*" or "/" operation.

    Params:
        q = target quaternion
    */
    Quaternion opOpAssign(string op, S)(S e) 
    if (__traits(isArithmetic, S) && (op == "*" || op == "/"))
    {
        static foreach (i; 0..4) {
            mixin(format!q{
                this[i] %s= e;
            }(op));
        }
        return this;
    }

    unittest {
        import std.algorithm : map;
        import std.range : iota;
        import std.random : uniform;

        foreach (i; 0..100) {
            auto q = quat(4.iota.map!(_ => uniform(-1.0f, +1.0f)));
            const s = uniform(-1.0f, +1.0f);
            const q2 = q * s;
            q *= s;

            assert(approxEqual(q, q2));
        }
    }

    /**
    Indexing operation.

    Returns: i-th element of this quaternion
    */
    T opIndex(size_t i)  const
    in (i < 4)
    {
        final switch (i) {
        case 0: return x;
        case 1: return y;
        case 2: return z;
        case 3: return w;
        }
    }

    unittest {
        import std.algorithm : map;
        import std.range : iota;
        import std.random : uniform;
        import std.array : array;

        foreach (k; 0..100) {
            float[4] v;
            static foreach (i; 0..4) {
                v[i] = uniform(-1.0f, +1.0f);
            }
            const q = quat(v.array);

            static foreach (i; 0..4) {
                assert(v[i] == q[i]);
            }
        }
    }

    /**
    Indexing operation.

    Returns: i-th element of this quaternion
    */
    ref T opIndex(size_t i) 
    in (i < 4)
    {
        final switch (i) {
        case 0: return x;
        case 1: return y;
        case 2: return z;
        case 3: return w;
        }
    }

    unittest {
        import std.algorithm : map;
        import std.range : iota;
        import std.random : uniform;

        foreach (k; 0..100) {
            quat q;

            static foreach (i; 0..4) {{
                const v = uniform(-1.0f, +1.0f);
                q[i] = v;
                assert(q[i] == v);
            }}
        }
    }

    string toString() const {
        return format!"q(%s, %s, %s, %s)"(x, y, z, w);
    }

    /**
    Get raw array data.

    Returns: raw array data
    */
    T[4] array() const {
        return [x,y,z,w];
    }

    unittest {
        import std.range : iota;
        const q = quat(iota(4));
        assert(q.array == [0,1,2,3]);
    }

    Vector!(T,3) axis() @property const {
        return Vector!(T,3)(x,y,z);
    }

    unittest {
        const q = quat(1,2,3,4);
        assert(q.axis == vec3(1,2,3));
    }

    void axis(const Vector!(T,3) axis) @property {
        this.x = axis[0];
        this.y = axis[1];
        this.z = axis[2];
    }

    unittest {
        quat q;
        q.axis = vec3(1,2,3);
        assert(q.axis == vec3(1,2,3));
    }

    /**
    Returns rotation quaternion decided by its rotation axis and angle.

    Params:
        axis = rotation axis vector, which must be normalized
        angle = rotation angle

    Returns: rotation quaternion
    */
    static Quaternion axisAngle(const Vector!(T,3) axis, const Angle rad) {
        return Quaternion(axis * sin(rad/2), cos(rad/2));
    }

    unittest {
        import std.algorithm : map;
        import std.random : uniform;
        import std.range : iota;
        import std.math : abs, approxEqual;
        import sbylib.math.vector : dot, normalize, ortho, length;

        foreach (i; 0..100) {
            const point = vec3(3.iota.map!(_ => uniform(-1.0f, +1.0f)));
            const axis = point.ortho.normalize;
            const angle = uniform(0,180.0f).deg;
            const r = mat3.axisAngle(axis, angle);
            const point2 = r * point;
            assert(approxEqual(dot(point, point2), length(point) * length(point2) * cos(angle)));
        }
    }

    /**
    Returns rotation quaternion which converts a vector to another vector.

    Params:
        from = before vector, which must be normalized
        to = after vector, which must be normalized

    Returns: rotation quaternion
    */
    static Quaternion!T rotFromTo(const Vector!(T,3) from, const Vector!(T,3) to) {
        import sbylib.math.vector : vnormalize = normalize;
        import std.math : sgn;

        const c = dot(from, to);
        const v = vnormalize(cross(from, to));
        if (v.hasNaN) {
            return Quaternion!T(0,0,0,sgn(dot(from,to)));
        }
        return axisAngle(v, c.acos);
    }

    unittest {
        import std.algorithm : map;
        import std.random : uniform;
        import std.range : iota;
        import sbylib.math.vector : approxEqual, normalize;

        foreach (i; 0..100) {
            const a = vec3(3.iota.map!(_ => uniform(-1.0f, +1.0f))).normalize;
            const b = vec3(3.iota.map!(_ => uniform(-1.0f, +1.0f))).normalize;
            const c = rotFromTo(a,b).rotate(a);
            assert(approxEqual(b,c));
        }
    }
}

/**
Returns length of a quaternion.

Params:
    q = target quaternion

Returns: length of the target quaternion
*/
T lengthSq(T)(const Quaternion!T q) {
    T sum = 0;
    static foreach (i; 0..4) {
        sum += q[i] * q[i];
    }
    return sum;
}

/**
Returns length of a quaternion.

Params:
    q = target quaternion

Returns: length of the target quaternion
*/
T length(T)(const Quaternion!T q) 
if (__traits(isFloating, T))
{
    import std.math : sqrt;
    return sqrt(lengthSq(q));
}

/**
Returns a quaternion whose length 1 from target quaternion.

Params:
    q = target quaternion

Returns: normalized target quaternion
*/
Quaternion!T normalize(T)(const Quaternion!T q) 
if (__traits(isFloating, T))
{
    return q / length(q);
}

/**
Returns a quaternion whose length 1 from target vector.
When the length is 0, returns zero quaternion.

Params:
    v = target quaternion

Returns: normalized target quaternion if the length is greater than 0, otherwise zero vector
*/
Quaternion!(T) safeNormalize(T)(const Quaternion!(T) q) 
if (__traits(isFloating, T))
{
    const l = length(q);
    if (l == 0) return q;
    return q / l;
}

unittest {
    import std.algorithm : map;
    import std.random : uniform;
    import std.range : iota;
    import std.math : approxEqual;

    foreach (i; 0..100) {
        const q = quat(4.iota.map!(_ => uniform(-1.0f, +1.0f)));
        assert(q == quat(0,0,0,0) || safeNormalize(q).length.approxEqual(1));
    }
}

/**
Rotate a vector by a quaternion.

Params:
    vec = rotation target vector
    q = rotation quaternion

Returns: rotated vector
*/
Vector!(T,3) rotate(T)(const Quaternion!(T) q, Vector!(T,3) vec) {
    return (q * Quaternion!T(vec, 0) * ~q).axis;
}

unittest {
    import std.algorithm : map;
    import std.random : uniform;
    import std.range : iota;
    import sbylib.math.vector : normalize, length;
    import std.math : approxEqual;

    foreach (i; 0..100) {
        const p = vec3(3.iota.map!(_ => uniform(-1.0f, +1.0f)));
        const axis = vec3(3.iota.map!(_ => uniform(-1.0f, +1.0f))).normalize;
        const angle = uniform(0,180.0f).deg;
        assert(approxEqual(p.length, quat.axisAngle(axis, angle).rotate(p).length));
    }
}

/**
Interpolate two quaternions spherically.

Params:
    q1 = target quaternion
    q2 = target quaternion
    t  = interpolation coefficient (0 <= t <= 1)

Returns: Interpolated quaternion
*/
Quaternion!(T) slerp(T)(const Quaternion!(T) q1, const Quaternion!(T) q2, T t) {
    import std.math : approxEqual;

    const c = q1.x * q2.x + q1.y * q2.y + q1.z * q2.z + q1.w * q2.w;
    if (c < 0) return slerp(q1, -q2, t);
    if (c.approxEqual(1, float.epsilon)) return q1;
    const angle = acos(c);
    const s = sin(angle);

    return sin((1-t)*angle) / s * q1 + sin(t*angle) / s * q2;
}

unittest {
    import std.algorithm : map;
    import std.random : uniform;
    import std.range : iota;
    import sbylib.math.vector : normalize, length;
    import std.math : approxEqual;

    foreach (i; 0..100) {
        const p = vec3(3.iota.map!(_ => uniform(-1.0f, +1.0f)));

        const axis1 = vec3(3.iota.map!(_ => uniform(-1.0f, +1.0f))).normalize;
        const angle1 = uniform(0,180.0f).deg;
        const q1 = quat.axisAngle(axis1, angle1);

        const axis2 = vec3(3.iota.map!(_ => uniform(-1.0f, +1.0f))).normalize;
        const angle2 = uniform(0,180.0f).deg;
        const q2 = quat.axisAngle(axis2, angle2);

        foreach (j; 0..100) {
            const t = j * 0.01;
            const q = slerp(q1, q2, t);
            assert(approxEqual(p.length, q.rotate(p).length));
        }

    }
}

/**
Converts a quaternion into matrix 3x3.

Params:
    q = target quaternion

Returns: converted matrix
*/
Matrix!(T,3,3) toMatrix3(T)(const Quaternion!T q) {
    with (q) {
        return Matrix!(T,3,3)(
                1-2*(y*y+z*z), 2*(x*y-z*w), 2*(x*z+w*y),
                2*(x*y+w*z), 1-2*(x*x+z*z), 2*(y*z-w*x),
                2*(x*z-w*y), 2*(y*z+w*x), 1-2*(x*x+y*y));
    }
}

unittest {
    import std.algorithm : map;
    import std.random : uniform;
    import std.range : iota;
    import sbylib.math.vector : approxEqual;

    foreach (i; 0..100) {
        const p = vec3(3.iota.map!(_ => uniform(-1.0f, +1.0f)));
        const q = quat(4.iota.map!(_ => uniform(-1.0f, +1.0f))).normalize;
        assert(approxEqual(q.toMatrix3() * p, q.rotate(p)));
    }
}

/**
Converts a quaternion into matrix 4x4.

Params:
    q = target quaternion

Returns: converted matrix
*/
Matrix!(T,4,4) toMatrix4(T)(const Quaternion!T q) {
    import sbylib.math.matrix : toMatrix4;
    return q.toMatrix3().toMatrix4();
}

unittest {
    import std.algorithm : map;
    import std.random : uniform;
    import std.range : iota;
    import sbylib.math.vector : approxEqual;

    foreach (i; 0..100) {
        const p = vec3(3.iota.map!(_ => uniform(-1.0f, +1.0f)));
        const q = quat(4.iota.map!(_ => uniform(-1.0f, +1.0f))).normalize;
        assert(approxEqual((q.toMatrix4() * vec4(p,1)).xyz, q.rotate(p)));
    }
}

/**
Returns true if the distance between the given two point is less than eps.

Params:
    a = target point
    b = target point
    eps = criteria of approximation

Returns: true if 2 vectors are approximately equal.
*/
bool approxEqual(T)(const Quaternion!(T) a, const Quaternion!(T) b, T eps = 1e-5) {
    return length(a-b) < eps;
}
