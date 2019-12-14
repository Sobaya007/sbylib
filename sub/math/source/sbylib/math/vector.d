module sbylib.math.vector;

import std.traits;
import std.algorithm;
import std.range : isInputRange, RangeElementType = ElementType;

alias vec2  = Vector!(float, 2);
alias vec3  = Vector!(float, 3);
alias vec4  = Vector!(float, 4);
alias ivec2 = Vector!(int,   2);
alias ivec3 = Vector!(int,   3);
alias ivec4 = Vector!(int,   4);

enum isVector(T) = isInstanceOf!(Vector, T);

/**
Vector type
*/
struct Vector(T, uint S) 
if (__traits(isArithmetic, T)) 
{

    private T[S] elements;

    /**
    Dimension of this vector type
    */
    enum Dimension = S;

    /**
    Element type of this vector type
    */
    alias ElementType = T;

    alias array this;

    /**
    Constructor by element type.
    This vector's each element is filled by given value.

    Params:
        e = a value which fills the vector
    */
    this(T e) {
        assignSingle(e);
    }

    unittest {
        import std.random : uniform;

        foreach (k; 0..100) {
            const e = uniform(-1.0f, +1.0f);
            const v = vec3(e);
            static foreach (i; 0..3) {
                assert(v[i] == e);
            }
        }
    }

    /**
    Constructor by InputRange.
    This vector's all elements are filled by given range.

    Params:
        elements = values which fills the vector
    */
    this(Range)(Range r)
    if (isInputRange!(Range) && is(RangeElementType!(Range) : T))
    {
        import std.range : front, popFront, empty;

        static foreach (i; 0..S) {
            this.elements[i] = r.front;
            r.popFront;
        }
        assert(r.empty);
    }

    unittest {
        import std.range : iota;
        assert(vec3(iota(3)) == vec3(0,1,2));
    }

    /**
    Constructor by combination of scalar, array, or vector.

    Params:
        args = combination of values, whose total element count must be the same as S
    */
    this(Args...)(Args args) {
        assignAll(args);
    }

    unittest {
        const v = Vector!(float,5)(1,2,3, vec2(4,5));
        assert(v == Vector!(float,5)(1,2,3,4,5));
    }

    /**
    Unary operation for "+".
    This function is identity.

    Returns: a vector equals to this vector.
    */
    Vector opUnary(string op)() const 
    if (op == "+")
    {
        return this;
    }

    unittest {
        import std.algorithm : map;
        import std.range : iota;
        import std.random : uniform;

        foreach (i; 0..100) {
            const v = vec4(iota(4).map!(_ => uniform(-1.0f, +1.0f)));
            assert(approxEqual(v * +1, +v));
        }
    }

    /**
    Unary operation for "-".

    Returns: an inverted vector
    */
    Vector opUnary(string op)() const 
    if (op == "-")
    {
        return makeVector!(op ~ "elements[]");
    }

    unittest {
        import std.algorithm : map;
        import std.range : iota;
        import std.random : uniform;

        foreach (i; 0..100) {
            const v = vec4(iota(4).map!(_ => uniform(-1.0f, +1.0f)));
            assert(approxEqual(v * -1, -v));
        }
    }

    /**
    Binary operation between scalar, array or vector type.

    Params:
        value = operation target

    Returns: calculated vector
    */
    Vector opBinary(string op, AnotherType)(auto ref AnotherType value) const 
    { 
        return makeVector!("elements[]" ~ op ~ Expression!(AnotherType))(value);
    }

    unittest {
        import std.algorithm : map;
        import std.range : iota;
        import std.array : array;
        import std.random : uniform;
        import std.math : approxEqual;

        foreach (k; 0..100) {
            const a = vec4(iota(4).map!(_ => uniform(-1.0f, +1.0f)));
            const b = vec4(iota(4).map!(_ => uniform(-1.0f, +1.0f)));

            const s = uniform(-1.0f, +1.0f);
            const r = iota(4).map!(_ => uniform(-1.0f, +1.0f)).array;

            static foreach (i; 0..4) {
                assert(approxEqual(a[i] + b[i], (a + b)[i]));
                assert(approxEqual(a[i] - b[i], (a - b)[i]));
                assert(approxEqual(a[i] * b[i], (a * b)[i]));
                assert(approxEqual(a[i] / b[i], (a / b)[i]));

                assert(approxEqual(a[i] + s, (a + s)[i]));
                assert(approxEqual(a[i] - s, (a - s)[i]));
                assert(approxEqual(a[i] * s, (a * s)[i]));
                assert(approxEqual(a[i] / s, (a / s)[i]));

                assert(approxEqual(a[i] + r[i], (a + r)[i]));
                assert(approxEqual(a[i] - r[i], (a - r)[i]));
                assert(approxEqual(a[i] * r[i], (a * r)[i]));
                assert(approxEqual(a[i] / r[i], (a / r)[i]));
            }
        }
    }

    /**
    Binary operation between matrix, scalar, array or vector type.

    Params:
        value = operation target

    Returns: calculated vector
    */
    Vector opBinaryRight(string op, AnotherType)(auto ref AnotherType value) const 
    {
        import sbylib.math.matrix : isMatrix;

        static if (isPotentially!(AnotherType, isMatrix)) {
            return mixin("value"~PotentialExpression!(AnotherType, isMatrix) ~ ".opBinary!(\""~op~"\")(this)");
        } else {
            return makeVector!(Expression!(AnotherType) ~ op ~ "elements[]")(value);
        }
    }

    unittest {
        import std.algorithm : map;
        import std.range : iota;
        import std.array : array;
        import std.random : uniform;
        import std.math : approxEqual;

        foreach (k; 0..100) {
            const a = vec4(iota(4).map!(_ => uniform(-1.0f, +1.0f)));

            const s = uniform(-1.0f, +1.0f);
            const r = iota(4).map!(_ => uniform(-1.0f, +1.0f)).array;

            static foreach (i; 0..4) {

                assert(approxEqual(s + a[i], (s + a)[i]));
                assert(approxEqual(s - a[i], (s - a)[i]));
                assert(approxEqual(s * a[i], (s * a)[i]));
                assert(approxEqual(s / a[i], (s / a)[i]));

                assert(approxEqual(r[i] + a[i], (r + a)[i]));
                assert(approxEqual(r[i] - a[i], (r - a)[i]));
                assert(approxEqual(r[i] * a[i], (r * a)[i]));
                assert(approxEqual(r[i] / a[i], (r / a)[i]));
            }
        }
    }

    /**
    Assign operation for vector or array.

    Params:
        value = assigned value

    Returns: this vector after assigned.
    */
    Vector opAssign(AnotherType)(const AnotherType value) 
        if (isVector!(AnotherType) || isArray!(AnotherType))
    {
        this.assignAll(value);
        return this;
    }

    /**
    Assign operation for scalar.
    The value fills each element of this vector.

    Params:
        value = assigned value

    Returns: this vector after assigned.
    */
    Vector opAssign(AnotherType)(const AnotherType value) 
        if (!isVector!(AnotherType) && !isArray!(AnotherType) && is(typeof({ T v; v = AnotherType.init; })))
    {
        this.assignSingle(value);
        return this;
    }

    unittest {
        vec3 v;

        v = 3;
        assert(approxEqual(v, vec3(3)));

        int[3] v2 = [1,2,3];
        v = v2;
        assert(approxEqual(v, vec3(1,2,3)));

        v = vec3(3,2,1);
        assert(approxEqual(v, vec3(3,2,1)));
    }

    /**
    Operator assign for vector, array, or scalar type.
    If the argument type is scalar, the value affects each element of this vector.

    Params:
        value = assigned value

    Returns: this vector after assigned.
    */
    Vector opOpAssign(string op, AnotherType)(AnotherType value)
    {
        mixin("elements[] " ~ op ~ "=" ~ Expression!(AnotherType) ~ ";");
        return this;
    }

    unittest {
        import std.algorithm : map;
        import std.range : iota;
        import std.random : uniform;

        foreach (i; 0..100) {
            auto v = vec4(4.iota.map!(_ => uniform(-1.0f, +1.0f)));
            const v2 = vec4(4.iota.map!(_ => uniform(-1.0f, +1.0f)));
            const v3 = v + v2;
            v += v2;

            assert(approxEqual(v, v3));
        }
    }

    /**
    Cast operation.

    Returns: a vector whose elements are indivisually casted.
    */
    V2 opCast(V2)() const if (isVector!V2 && Dimension == V2.Dimension) {
        import std : to;

        return V2(this.elements[].map!(to!(V2.ElementType)));
    }

    unittest {
        import std.algorithm : map;
        import std.range : iota;
        import std.random : uniform;
        import std.array : array;

        foreach (k; 0..100) {
            float[4] e;
            static foreach (i; 0..4) {
                e[i] = uniform(-1.0f, +1.0f);
            }
            const v = vec4(e.array);

            const v2 = cast(ivec4)v;

            static foreach (i; 0..4) {
                assert(cast(int)v[i] == v2[i]);
            }
        }
    }

    /**
    Indexing operation.
    
    Params:
        idx = index

    Returns: i-th element of this vector.
    */
    T opIndex(size_t i) const 
    in (i < S)
    {
        return this.elements[i];
    }

    unittest {
        import std.algorithm : map;
        import std.range : iota;
        import std.random : uniform;
        import std.array : array;

        foreach (k; 0..100) {
            float[4] e;
            static foreach (i; 0..4) {
                e[i] = uniform(-1.0f, +1.0f);
            }
            const v = vec4(e.array);

            static foreach (i; 0..4) {
                assert(v[i] == e[i]);
            }
        }
    }

    /**
    Indexing operation.
    
    Params:
        idx = index

    Returns: i-th element of this vector.
    */
    ref T opIndex(size_t i) 
    in (i < S)
    {
        return this.elements[i];
    }

    unittest {
        import std.algorithm : map;
        import std.range : iota;
        import std.random : uniform;

        foreach (k; 0..100) {
            vec4 v;

            static foreach (i; 0..4) {{
                const e = uniform(-1.0f, +1.0f);
                v[i] = e;
                assert(v[i] == e);
            }}
        }
    }

    /**
    Get raw array of this vector.

    Returns: raw array of this vector.
    */
    auto array() inout {
        return elements;
    }

    private enum XYZW = "xyzw";
    private enum RGBA = "rgba";

    private static size_t[] createIndex(string propertyString, string s) {
        size_t[] index = new size_t[s.length];
        foreach (i; 0..s.length) {
            index[i] = propertyString.countUntil(s[i]);
        }
        return index;
    }

    private mixin template Gen(string s) {
        enum isXYZW = s.all!(a => XYZW.canFind(a));
        enum isRGBA = s.all!(a => RGBA.canFind(a));
        static assert(isXYZW || isRGBA);
        enum propertyString = isXYZW ? XYZW : isRGBA ? RGBA : "";
        enum index = createIndex(propertyString, s);
    }

    /**
    Single element access by name.
    The property is 'x', 'y', 'z', 'w', 'r', 'g', 'b' or 'a'.

    Returns: selected element
    */
    auto ref opDispatch(string s)() inout
    if (s.length == 1)
    {
        mixin Gen!(s);
        return elements[index[0]];
    }

    /**
    Multiple element access by name.
    The property is combination of 'x', 'y', 'z', 'w', 'r', 'g', 'b' or 'a'.

    Returns: a vector made by selected elements
    */
    const(Vector!(T,s.length)) opDispatch(string s)() inout
    if (s.length > 1)
    {
        mixin Gen!(s);
        Vector!(T, s.length) result;
        static foreach (i,idx; index) {
            result[i] = elements[idx];
        }
        return result;
    }

    /**
    Property assign for scalar value.
    This function supports both single and multiple property reference.

    Params:
        value = assigned scalar value

    Returns: assigned value
    */
    T opDispatch(string s)(T value)
    if (s.all!(a =>XYZW.canFind(a)) || s.all!(a => RGBA.canFind(a)))
    {
        mixin Gen!(s);
        static if(s.length == 1) {
            return this[index[0]] = value;
        } else {
            static foreach (i,idx; index) {
                this[idx] = value;
            }
            return value;
        }
    }

    /**
    Property assign for vector value.
    This function supports both single and multiple property reference.

    Params:
        value = assigned vector value

    Returns: assigned value
    */
    const(Vector!(T,s.length)) opDispatch(string s)(Vector!(T,s.length) value)
    if (s.all!(a =>XYZW.canFind(a)) || s.all!(a => RGBA.canFind(a)))
    {
        mixin Gen!(s);
        static foreach (i,idx; index) {
            this[idx] = value[i];
        }
        return value;
    }

    string toString() const {
        import std.format : format;
        import std.array : array, join;
        import std.algorithm : map;
        import std.conv : to;

        return format!"(%s)"(this.elements.array.map!(to!string).join(","));
    }

    static if (isFloatingPoint!T) {
        /**
        Returns whether this vector contains NaN.

        Returns: true if this vector contains NaN
        */
        bool hasNaN() const {
            import std.algorithm : any;
            import std.array : array;
            import std.math : isNaN;

            return this.elements.array.any!(isNaN);
        }

        unittest {
            assert(vec3().hasNaN);
            assert(!vec3(0).hasNaN);
        }
    }

    private void assignAll(Args...)(Args args) {
        assignAll!(0)(args);
    }

    private void assignAll(size_t offset, Args...)(Args args) 
        if (Args.length > 0 && offset + Count!(Args) == Dimension)
    {
        assign!(offset)(args[0]);
        assignAll!(offset + Count!(Args[0]))(args[1..$]);
    }

    private void assignAll(size_t offset)() {
        static assert(offset == Dimension);
    }

    private void assign(size_t offset, AnotherType)(AnotherType value) 
        if (isVector!(AnotherType) && offset + Count!(AnotherType) <= Dimension)
    {
        assign!(offset)(value.elements);
    }

    private void assign(size_t offset, AnotherType)(AnotherType value) 
        if (isStaticArray!(AnotherType) && offset + Count!(AnotherType) <= Dimension)
    {
        static foreach (i; 0..Count!(AnotherType)) {
            assign!(offset+i)(value[i]);
        }
    }

    private void assign(size_t index, AnotherType : T)(AnotherType value) {
        this[index] = value;
    }

    private void assignSingle(AnotherType)(AnotherType value) {
        this.elements[] = value;
    }

    private template Count(Types...) 
        if (Types.length > 1)
    {
        enum Count = Count!(Types[0]) + Count!(Types[1..$]);
    }

    private template Count(Type) {
        static if (isVector!(Type)) {
            enum Count = Count!(typeof(Type.elements));
        } else static if (isStaticArray!(Type)) {
            enum Count = Type.length * Count!(ForeachType!(Type));
        } else static if (is(Unqual!Type : T)) {
            enum Count = 1;
        } else {
            static assert(false, "Invalid type: " ~ Type.stringof);
        }
    }

    private template Expression(AnotherType) {
        static if (isPotentially!(AnotherType, isArray)) 
            enum Expression = "value" ~ PotentialExpression!(AnotherType, isArray) ~ "[]";
        else 
            enum Expression = "value";
    }

    private Vector makeVector(string expr, AnotherType...)(auto ref AnotherType values) const {
        static if (AnotherType.length > 0) alias value = values[0];
        else alias value = values;

        Vector result;
        result.elements[] = mixin(expr);
        return result;
    }
}


/**
Get a vector whose each element is minimum value of the same indexed element of two vectors.

Params:
    v = left hand value of calculation
    v2 = right hand value of calculation

Returns: minimum vector of two vectors
*/
Vector!(CommonType!(T,S),U) min(T,S,uint U)(const Vector!(T,U) v, const Vector!(S,U) v2) {
    import std.algorithm : fmin = min;
    return reduceV!(fmin)(v, v2);
}

unittest {
    import std.algorithm : map, fmin = min;
    import std.range : iota;
    import std.random : uniform;

    foreach (k; 0..100) {
        const a = vec4(iota(4).map!(_ => uniform(-1.0f, +1.0f)));
        const b = vec4(iota(4).map!(_ => uniform(-1.0f, +1.0f)));
        static foreach (i; 0..4) {
            assert(fmin(a[i], b[i]) == min(a,b)[i]);
        }
    }
}

/**
Get a vector whose each element is maximum value of the same indexed element of two vectors.

Params:
    v = left hand value of calculation
    v2 = right hand value of calculation

Returns: maximum vector of two vectors
*/
Vector!(CommonType!(T,S),U) max(T,S,uint U)(const Vector!(T,U) v, const Vector!(S,U) v2) {
    import std.algorithm : fmax = max;
    return reduceV!(fmax)(v, v2);
}

unittest {
    import std.algorithm : map, fmax = max;
    import std.range : iota;
    import std.random : uniform;

    foreach (k; 0..100) {
        const a = vec4(iota(4).map!(_ => uniform(-1.0f, +1.0f)));
        const b = vec4(iota(4).map!(_ => uniform(-1.0f, +1.0f)));
        static foreach (i; 0..4) {
            assert(fmax(a[i], b[i]) == max(a,b)[i]);
        }
    }
}

/**
Calculates dot product.

Params:
    v = left hand value of dot product
    v2 = right hand value of dot product

Returns: dot product of two vectors
*/
CommonType!(T,S) dot(T,S,uint U)(const Vector!(T,U) v, const Vector!(S,U) v2) {
    CommonType!(T,S) result = 0;
    static foreach (i; 0..U) {
        result += v[i] * v2[i];
    }
    return result;
}

unittest {
    import std.algorithm : map;
    import std.random : uniform;
    import std.range : iota;
    import std.math : abs, approxEqual;
    import sbylib.math.angle : deg, cos;
    import sbylib.math.matrix : mat3;

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
Calclates cross product of two vectors in 2D.
Returned value is |v||v2| sin a

Params:
    v = left hand value of calculation
    v2 = right hand value of calculation

Returns: cross product of two vectors
*/
CommonType!(T,S) cross(T,S)(const Vector!(T,2) v, const Vector!(S,2) v2) {
    return v.x * v2.y - v.y * v2.x;
}

unittest {
    import std.algorithm : map;
    import std.random : uniform;
    import std.range : iota;
    import std.math : approxEqual, abs;
    import sbylib.math.angle : deg, acos, sin;

    foreach (i; 0..100) {
        const a = vec2(2.iota.map!(_ => uniform(-1.0f, +1.0f)));
        const b = vec2(2.iota.map!(_ => uniform(-1.0f, +1.0f)));

        const la = length(a);
        const lb = length(b);

        const angle = acos(dot(a,b) / (la * lb));

        const c = cross(a,b);

        assert(approxEqual(abs(c), la * lb * sin(angle), 1e-3));
    }
}

/**
Calclates cross product of two vectors in 3D.

Params:
    v = left hand value of calculation
    v2 = right hand value of calculation

Returns: cross product of two vectors
*/
Vector!(CommonType!(T,S),3) cross(T,S)(const Vector!(T,3) v, const Vector!(S,3) v2) {
    Vector!(CommonType!(T,S),3) result;
    static foreach (i; 0..3) {
        result[i] = v[(i+1)%3] * v2[(i+2)%3] - v[(i+2)%3] * v2[(i+1)%3];
    }
    return result;
}

unittest {
    import std.algorithm : map;
    import std.random : uniform;
    import std.range : iota;
    import std.math : approxEqual;
    import sbylib.math.angle : deg, acos, sin;

    foreach (i; 0..100) {
        const a = vec3(3.iota.map!(_ => uniform(-1.0f, +1.0f)));
        const b = vec3(3.iota.map!(_ => uniform(-1.0f, +1.0f)));

        const la = length(a);
        const lb = length(b);

        const angle = acos(dot(a,b) / (la * lb));

        const c = cross(a,b);

        assert(approxEqual(dot(a,c), 0));
        assert(approxEqual(dot(b,c), 0));
        assert(approxEqual(c.length, la * lb * sin(angle)));
    }
}

/**
Returns a vector which is orthognal to the given vector.

Params:
    v = target vector

Returns: orthognal vector
*/
Vector!(T,2) ortho(T)(const Vector!(T,2) v) {
    return Vector!(T,2)(-v.y, v.x);
}

unittest {
    import std.algorithm : map;
    import std.random : uniform;
    import std.range : iota;
    import std.math : approxEqual;

    foreach (i; 0..100) {
        const a = vec2(2.iota.map!(_ => uniform(-1.0f, +1.0f)));
        assert(approxEqual(dot(a, a.ortho), 0));
    }
}

/**
Returns a vector which is orthognal to the given vector.

Params:
    v = target vector

Returns: orthognal vector
*/
Vector!(T,3) ortho(T)(const Vector!(T,3) v) 
if (__traits(isFloating, T))
{
    if (v.x == 0 && v.z == 0) {
        return normalize(cross(v, Vector!(T,3)(1,0,0)));
    } else {
        return normalize(cross(v, Vector!(T,3)(0,1,0)));
    }
}

unittest {
    import std.algorithm : map;
    import std.random : uniform;
    import std.range : iota;
    import std.math : approxEqual;

    foreach (i; 0..100) {
        const a = vec3(3.iota.map!(_ => uniform(-1.0f, +1.0f)));
        assert(approxEqual(dot(a, a.ortho), 0));
    }
}

/**
Returns squared length of the given vector.

Params:
    v = target vector

Returns: squared length of the given vector
*/
T lengthSq(T,uint U)(const Vector!(T,U) v) {
    T result = 0;
    static foreach (i; 0..U) {
        result += v[i] * v[i];
    }
    return result;
}

/**
Returns length of the given vector.

Params:
    v = target vector

Returns: length of the given vector
*/
T length(T,uint U)(const Vector!(T,U) v) 
if (__traits(isFloating, T))
{
    import std.math : sqrt;
    return sqrt(lengthSq(v));
}

/**
Returns a vector whose length 1 from target vector.

Params:
    v = target vector

Returns: normalized target vector
*/
Vector!(T,U) normalize(T,uint U)(const Vector!(T,U) v) 
if (__traits(isFloating, T))
{
    return v / length(v);
}

/**
Returns a vector whose length 1 from target vector.
When the length is 0, returns zero vector.

Params:
    v = target vector

Returns: normalized target vector if the length is greater than 0, otherwise zero vector
*/
Vector!(T,U) safeNormalize(T,uint U)(const Vector!(T,U) v) 
if (__traits(isFloating, T))
{
    const l = length(v);
    if (l == 0) return v;
    return v / l;
}

unittest {
    import std.algorithm : map;
    import std.random : uniform;
    import std.range : iota;
    import std.math : approxEqual;

    foreach (i; 0..100) {
        const v = vec4(4.iota.map!(_ => uniform(-1.0f, +1.0f)));
        assert(v == vec4(0) || safeNormalize(v).length.approxEqual(1));
    }
}

/**
Returns a linear interpolated vector

Params:
    v1 = target vector
    v2 = target vector
    t  = interpolation coefficient

Returns: interpolated vector
*/
Vector!(T,U) mix(T,uint U)(const Vector!(T,U) v1, const Vector!(T,U) v2, T t) {
    return (1-t) * v1 + t * v2;
}

unittest {
    import std.algorithm : map;
    import std.random : uniform;
    import std.range : iota;
    import std.math : approxEqual;

    foreach (i; 0..100) {
        const v1 = vec4(4.iota.map!(_ => uniform(-1.0f, +1.0f)));
        const v2 = vec4(4.iota.map!(_ => uniform(-1.0f, +1.0f)));
        foreach (j; 1..100) {
            const t = j * 0.01;
            const v = mix(v1, v2, t);
            assert(dot(normalize(v1-v), normalize(v2-v)).approxEqual(-1));
        }
    }
}

/**
Reduces an array of vector by the given function.

Params:
    v = array of vector reduced

Returns: reduced vector
*/
Vector!(T,U) reduceV(alias pred, T, int U)(const Vector!(T,U)[] v...) {
    Vector!(T,U) result = v[0];
    static foreach (i; 0..U) {
        foreach (j; 1..v.length) {
            result[i] = pred(result[i], v[j][i]);
        }
    }
    return result;
}

/**
Calculates an unsigned area of a triangle which is composed of the given points.

Params:
    positions = array of position vectors which compose a triangle

Returns: unsigned area of triangle
*/
T computeUnSignedArea(T)(const Vector!(T,3)[3] positions...) {
    return length(cross(positions[2] - positions[0], positions[1] - positions[0])) / 2;
}

unittest {
    import std.algorithm : map;
    import std.random : uniform;
    import std.range : iota;
    import std.math : approxEqual;

    foreach (i; 0..100) {
        const a = vec3(3.iota.map!(_ => uniform(-1.0f, +1.0f)));
        const b = vec3(3.iota.map!(_ => uniform(-1.0f, +1.0f)));

        const area = computeUnSignedArea(a,b,vec3(0));

        const base = length(a);
        const height = length(b-normalize(a) * dot(normalize(a),b));

        assert(approxEqual(area, base * height / 2));
    }
}

/**
Calculates a signed volume of a tetrahedron which is composed of the given points.

Params:
    positions = array of position vectors which compose a tetrahedron

Returns: signed volume of tetrahedron
*/
T computeSignedVolume(T)(const Vector!(T,3)[4] positions...) {
    Vector!(T,3)[3] v;
    static foreach (i; 0..3) {
        v[i] = positions[i+1] - positions[0];
    }
    T result = 0;
    static foreach (i; 0..3) {
        result += v[i].x * v[(i+1)%3].y * v[(i+2)%3].z;
        result -= v[i].x * v[(i+2)%3].y * v[(i+1)%3].z;
    }
    return result / 6;
}

unittest {
    import std.algorithm : map;
    import std.random : uniform;
    import std.range : iota;
    import std.math : approxEqual, abs;

    foreach (i; 0..100) {
        const a = vec3(3.iota.map!(_ => uniform(-1.0f, +1.0f)));
        const b = vec3(3.iota.map!(_ => uniform(-1.0f, +1.0f)));
        const c = vec3(3.iota.map!(_ => uniform(-1.0f, +1.0f)));

        const volume = computeSignedVolume(a,b,c,vec3(0));

        const area = computeUnSignedArea(a,b,vec3(0));
        const height = dot(normalize(cross(a,b)), c);

        assert(approxEqual(abs(volume), abs(area * height / 3)));
    }
}

//与えられた点列に対し、分散が最大化するベクトルを含む正規直交基底を返す
/**
Returns normalized orthognal basis which maximize the dispersion of the given points

Params:
    vertices = array of points

Returns: 3 normalized orthognal basis
*/
Vector!(T,3)[3] mostDispersionBasis(T)(const Vector!(T,3)[] vertices...)
    in(vertices.length > 0)
{
    import std.algorithm : sum;
    import sbylib.math.matrix : mat3, Matrix, diagonalizeForRealSym;

    const c = vertices.sum / vertices.length;
    mat3 vcm = mat3(0);
    foreach (ref v; vertices) {
        const r = v - c;
        vcm += Matrix!(float,3,1)(r.array) * Matrix!(float,1,3)(r.array);
    }
    vcm /= vertices.length;
    const diagonal = diagonalizeForRealSym(vcm);
    Vector!(T,3)[3] result;
    static foreach (i; 0..3) {
        result[i] = diagonal.column[i].normalize;
    }
    return result;
}

unittest {
    import std.algorithm : map, sum, max;
    import std.random : uniform;
    import std.range : iota;
    import std.math : abs, approxEqual;
    import sbylib.math.angle : deg, cos;
    import sbylib.math.matrix : mat3;

    vec3[] points;
    foreach (i; 0..100) {
        points ~= vec3(3.iota.map!(_ => uniform(-1.0f, +1.0f)));
    }
    const center = points.sum / 100;
    foreach (i; 0..100) {
        points[i] -= center;
    }

    float maxDispersion = 0;

    foreach (i; 0..10) {
        const axis = vec3(3.iota.map!(_ => uniform(-1.0f, +1.0f))).normalize;
        const angle = uniform(0,180.0f).deg;
        const r = mat3.axisAngle(axis, angle);
        static foreach (j; 0..3) {
            maxDispersion = max(maxDispersion, points.map!(p => (r * p)[j]^^2).sum);
        }
    }

    const basis = mostDispersionBasis(points);
    float idealMaxDispersion = 0;
    static foreach (j; 0..3) {
        idealMaxDispersion = max(idealMaxDispersion, points.map!(p => dot(basis[j],p)^^2).sum);
    }

    assert(idealMaxDispersion >= maxDispersion);
}

/**
Returns true if the distance between the given two point is less than eps.

Params:
    a = target point
    b = target point
    eps = criteria of approximation

Returns: true if 2 vectors are approximately equal.
*/
bool approxEqual(T,uint N)(const Vector!(T,N) a, const Vector!(T,N) b, T eps = 1e-5) {
    return length(a-b) < eps;
}

private template PotentialExpression(T, alias pred) {
    static if (pred!(T)) {
        enum PotentialExpression = "";
    } else static if (isAggregateType!(T)) {
        enum AliasThis = __traits(getAliasThis, T);
        static assert(AliasThis.length > 0);
        enum Expr = "T."~AliasThis[0];
        static if (isFunction!(mixin(Expr))) {
            alias Type = ReturnType!(mixin(Expr));
        } else {
            alias Type = typeof(mixin(Expr));
        }
        enum PotentialExpression = "." ~ AliasThis[0] ~ PotentialExpression!(Type, pred);
    }
}

private template isPotentially(T, alias pred) {
    static if (pred!(T)) {
        enum isPotentially = true;
    } else static if (isAggregateType!(T)) {
        enum AliasThis = __traits(getAliasThis, T);
        static if (AliasThis.length == 0) {
            enum isPotentially = false;
        } else {
            enum Expr = "T."~AliasThis[0];
            static if (isFunction!(mixin(Expr))) {
                alias Type = ReturnType!(mixin(Expr));
            } else {
                alias Type = typeof(mixin(Expr));
            }
            enum isPotentially = isPotentially!(Type, pred);
        }
    } else {
        enum isPotentially = false;
    }
}
