module sbylib.math.matrix;

import sbylib.math;
import std.traits;
import std.range : isInputRange, RangeElementType = ElementType;
import std.format : format;

alias mat1x1 = Matrix!(float, 1, 1);
alias mat1x2 = Matrix!(float, 1, 2);
alias mat1x3 = Matrix!(float, 1, 3);
alias mat1x4 = Matrix!(float, 1, 4);
alias mat2x1 = Matrix!(float, 2, 1);
alias mat2x2 = Matrix!(float, 2, 2);
alias mat2x3 = Matrix!(float, 2, 3);
alias mat2x4 = Matrix!(float, 2, 4);
alias mat3x1 = Matrix!(float, 3, 1);
alias mat3x2 = Matrix!(float, 3, 2);
alias mat3x3 = Matrix!(float, 3, 3);
alias mat3x4 = Matrix!(float, 3, 4);
alias mat4x1 = Matrix!(float, 4, 1);
alias mat4x2 = Matrix!(float, 4, 2);
alias mat4x3 = Matrix!(float, 4, 3);
alias mat4x4 = Matrix!(float, 4, 4);

alias mat2 = mat2x2;
alias mat3 = mat3x3;
alias mat4 = mat4x4;

enum isMatrix(T) = isInstanceOf!(Matrix, T);

/**
Matrix type
*/
struct Matrix(T, uint U, uint V)
if (__traits(isArithmetic, T)) 
{
    private T[U*V] element;

    /**
    Row number of this matrix type
    */
    enum Row = U;

    /**
    Column number of this matrix type
    */
    enum Column = V;

    /**
    Element type of this matrix type
    */
    alias ElementType = T;

    alias array this;

    /**
    Constructor by element type.
    This matrix's each element is filled by given value.

    Params:
        e = a value which fills the matrix
    */
    this(T e) {
        foreach (ref el; this.element) el = e;
    }

    unittest {
        import std.random : uniform;

        foreach (k; 0..100) {
            const e = uniform(-1.0f, +1.0f);
            const m = mat3(e);
            static foreach (i; 0..3) {
                static foreach (j; 0..3) {
                    assert(m[i,j] == e);
                }
            }
        }
    }

    /**
    Constructor by array.
    This matrix's all elements are filled by given array.

    Params:
        elements = values which fills the matrix
    */
    this(T[U*V] elements...) {
        static foreach (i; 0..U*V) {
            this[i/V,i%V] = elements[i];
        }
    }

    /**
    Constructor by InputRange.
    This matrix's all elements are filled by given range.

    Params:
        elements = values which fills the matrix
    */
    this(Range)(Range r)
    if (isInputRange!(Range) && is(RangeElementType!(Range) : T))
    {
        import std.range : front, popFront, empty;

        static foreach (i; 0..U*V) {
            this.element[i] = r.front;
            r.popFront;
        }
        assert(r.empty);
    }

    unittest {
        import std.range : iota;
        const a = mat2(iota(4));
        assert(a[0,0] == 0);
        assert(a[1,0] == 1);
        assert(a[0,1] == 2);
        assert(a[1,1] == 3);
    }


    /**
    Constructor by array of array.
    This matrix's all elements are filled by given array.

    Params:
        elements = values which fills the matrix
    */
    this(T[U][V] elements...) {
        static foreach (i; 0..U) {
            static foreach (j; 0..V) {
                this[i,j] = elements[j][i];
            }
        }
    }

    unittest {
        const a = mat2([1,3],[2,4]);
        assert(a[0,0] == 1);
        assert(a[0,1] == 2);
        assert(a[1,0] == 3);
        assert(a[1,1] == 4);
    }

    static if (V > 1) {
        /**
        Constructor by array of vector.
        This matrix's all elements are filled by given
        Each vectors are dealed as column.

        Params:
        vectors = values which fills the matrix
        */
        this(Vector!(T, U)[V] vectors...) {
            static foreach (i; 0..U) {
                static foreach (j; 0..V) {
                    this[i,j] = vectors[j][i];
                }
            }
        }

        unittest {
            const a = mat2(vec2(1,3),vec2(2,4));
            assert(a[0,0] == 1);
            assert(a[0,1] == 2);
            assert(a[1,0] == 3);
            assert(a[1,1] == 4);
        }
    }

    /**
    Unary operation for "+".

    this is identity function

    Returns: a matrix which is equal to this matrix
    */
    Matrix!(T,U,V) opUnary(string op)() const 
    if (op == "+")
    {
        return this;
    }

    unittest {
        import std.algorithm : map;
        import std.range : iota;
        import std.random : uniform;

        foreach (i; 0..100) {
            const m = mat4(iota(16).map!(_ => uniform(-1.0f, +1.0f)));
            assert(approxEqual(m * +1, +m));
        }
    }

    /**
    Unary operation for "-".

    Returns: a matrix whose sign is inverted
    */
    Matrix!(T,U,V) opUnary(string op)() const 
    if (op == "-")
    {
        Matrix!(T,U,V) result;
        static foreach (i; 0..U) {
            static foreach (j; 0..V) {
                result[i,j] = -this[i,j];
            }
        }
        return result;
    }

    unittest {
        import std.algorithm : map;
        import std.range : iota;
        import std.random : uniform;

        foreach (i; 0..100) {
            const m = mat4(iota(16).map!(_ => uniform(-1.0f, +1.0f)));
            assert(approxEqual(m * -1, -m));
        }
    }

    /**
    Binary operator between the same size matrix ("+" or "-").
    Another type matrix is allowed.

    Params: 
        m = target matrix

    Returns: calculated matrix
    */
    Matrix!(CommonType!(T,S), U,V) opBinary(string op, S)(Matrix!(S,U,V) m) const
    if (op == "+" || op == "-")
    {
        Matrix!(CommonType!(T,S),U,V) result;
        static foreach (i; 0..U) {
            static foreach (j; 0..V) {
                mixin(format!q{
                    result[i,j] = this[i,j] %s m[i,j];
                }(op));
            }
        }
        return result;
    }

    unittest {
        import std.algorithm : map;
        import std.range : iota;
        import std.random : uniform;
        import std.math : approxEqual;

        foreach (k; 0..100) {
            const a = mat4(iota(16).map!(_ => uniform(-1.0f, +1.0f)));
            const b = mat4(iota(16).map!(_ => uniform(-1.0f, +1.0f)));

            const c = a + b;
            const d = a - b;

            static foreach (i; 0..4) {
                static foreach (j; 0..4) {
                    assert(approxEqual(a[i,j] + b[i,j], c[i,j]));
                    assert(approxEqual(a[i,j] - b[i,j], d[i,j]));
                }
            }
        }
    }

    /**
    Multiply operator between matrix.
    Another type matrix is allowed.

    Params: 
        m = target matrix

    Returns: calculated matrix
    */
    Matrix!(CommonType!(T,S),U,P) opBinary(string op, S, uint P)(Matrix!(S,V,P) m) const
    if (op == "*") 
    {
        Matrix!(CommonType!(T,S),U,P) result;
        static foreach (i; 0..U) {
            static foreach (j; 0..P) {
                result[i,j] = 0;
                static foreach (k; 0..V) {
                    result[i,j] += this[i,k] * m[k,j];
                }
            }
        }
        return result;
    }

    unittest {
        import std.algorithm : map;
        import std.range : iota;
        import std.random : uniform;

        foreach (i; 0..100) {
            const a = mat3(9.iota.map!(_ => uniform(-1.0f, +1.0f)));
            const b = mat3(9.iota.map!(_ => uniform(-1.0f, +1.0f)));
            const c = mat3(9.iota.map!(_ => uniform(-1.0f, +1.0f)));
            assert(approxEqual((a * b) * c, a * (b * c)));
        }
    }

    /**
    Binary operation between scalar type ("*" or "/").

    Params: 
        e = target scalar value

    Returns: calculated matrix
    */
    Matrix!(CommonType!(T,S),U,V) opBinary(string op, S)(S e) const 
    if (__traits(isArithmetic, S) && (op == "*" || op == "/"))
    {
        Matrix!(CommonType!(T,S),U,V) result;
        static foreach (i; 0..U) {
            static foreach (j; 0..V) {
                result[i,j] = mixin(format!q{
                    this[i,j] %s e
                }(op));
            }
        }
        return result;
    }

    unittest {
        import std.algorithm : map;
        import std.range : iota;
        import std.random : uniform;
        import std.math : approxEqual;

        foreach (k; 0..100) {
            const m = mat4(16.iota.map!(_ => uniform(-1.0f, +1.0f)));
            const s = uniform(-1.0f, +1.0f);
            const m2 = m * s;
            const m3 = m / s;
            static foreach (i; 0..4) {
                static foreach (j; 0..4) {
                    assert(approxEqual(m[i,j] * s, m2[i,j]));
                    assert(approxEqual(m[i,j] / s, m3[i,j]));
                }
            }
        }
    }

    /**
    Binary operation between vector type ("*" only).

    Params: 
        e = target scalar value

    Returns: calculated vector
    */
    Vector!(CommonType!(T,S),U) opBinary(string op, S)(Vector!(S,V) v) const 
    if (op == "*")
    {
        Vector!(CommonType!(T,S),U) result;
        static foreach (i; 0..U) {
            result[i] = 0;
            static foreach (j; 0..V) {
                result[i] += this[i,j] * v[j];
            }
        }
        return result;
    }

    unittest {
        import std.algorithm : map;
        import std.range : iota;
        import std.random : uniform;
        import sbylib.math.vector : dot, approxEqual;
        foreach (i; 0..100) {
            const m = mat3(9.iota.map!(_ => uniform(-1.0f, +1.0f)));
            const v = vec3(3.iota.map!(_ => uniform(-1.0f, +1.0f)));
            const v2 = m * v;

            assert(approxEqual(vec3(dot(m.row[0], v), dot(m.row[1], v), dot(m.row[2], v)), v2));
        }
    }

    /**
    operator assign between matrix type ("+" or "-")

    Params: 
        m = target matrix

    Returns: calculated this matrix
    */
    Matrix opOpAssign(string op, S)(Matrix!(S,U,V) m) 
    if (op == "+" || op == "-")
    {
        static foreach (i; 0..U) {
            static foreach (j; 0..V) {
                mixin(format!q{
                    this[i,j] %s= m[i,j];
                }(op));
            }
        }
        return this;
    }

    unittest {
        import std.algorithm : map;
        import std.range : iota;
        import std.random : uniform;

        foreach (i; 0..100) {
            auto m = mat3(9.iota.map!(_ => uniform(-1.0f, +1.0f)));
            const m2 = mat3(9.iota.map!(_ => uniform(-1.0f, +1.0f)));
            const m3 = m + m2;
            m += m2;

            assert(approxEqual(m, m3));
        }
    }

    /**
    operator assign between matrix type (only "*")

    Params: 
        m = target matrix

    Returns: calculated this matrix
    */
    Matrix opOpAssign(string op, S)(Matrix!(S,U,V) m) 
    if (op == "*")
    {
        Matrix result = this * m;
        static foreach (i; 0..U) {
            static foreach (j; 0..V) {
                this[i,j] = result[i,j];
            }
        }
        return this;
    }

    unittest {
        import std.algorithm : map;
        import std.range : iota;
        import std.random : uniform;
        foreach (i; 0..100) {
            auto m = mat3(9.iota.map!(_ => uniform(-1.0f, +1.0f)));
            const m2 = mat3(9.iota.map!(_ => uniform(-1.0f, +1.0f)));
            const m3 = m * m2;
            m *= m2;

            assert(approxEqual(m, m3));
        }
    }

    /**
    operator assign between scalar type ("*" or "/")

    Params: 
        e = target scalar value

    Returns: calculated this matrix
    */
    Matrix opOpAssign(string op, S)(S e) 
    if (__traits(isArithmetic, S) && (op == "*" || op == "/"))
    {
        static foreach (i; 0..U) {
            static foreach (j; 0..V) {
                mixin(format!q{
                    this[i,j] %s= e;
                }(op));
            }
        }
        return this;
    }

    unittest {
        import std.algorithm : map;
        import std.range : iota;
        import std.random : uniform;

        foreach (i; 0..100) {
            auto m = mat3(9.iota.map!(_ => uniform(-1.0f, +1.0f)));
            const s = uniform(-1.0f, +1.0f);
            const m2 = m * s;
            m *= s;

            assert(approxEqual(m, m2));
        }
    }

    /**
    indexing operation

    Params: 
        i = column index
        j = row index

    Returns: selected value
    */
    T opIndex(size_t i, size_t j) const 
    in (i < U && j < V)
    {
        return element[i+j*U];
    }

    unittest {
        import std.algorithm : map;
        import std.range : iota;
        import std.random : uniform;

        foreach (k; 0..100) {
            vec3[3] v;
            static foreach (i; 0..3) {
                v[i] = vec3(3.iota.map!(_ => uniform(-1.0f, +1.0f)));
            }
            const m = mat3(v);

            static foreach (i; 0..3) {
                static foreach (j; 0..3) {
                    assert(m[i,j] == v[j][i]);
                }
            }
        }
    }

    /**
    indexing operation

    Params: 
        i = column index
        j = row index

    Returns: selected value
    */
    ref T opIndex(size_t i, size_t j) 
    in(i < U && j < V)
    {
        return element[i+j*U];
    }

    unittest {
        import std.algorithm : map;
        import std.range : iota;
        import std.random : uniform;

        foreach (k; 0..100) {
            mat3 m;

            static foreach (i; 0..3) {{
                static foreach (j; 0..3) {{
                    const v = uniform(-1.0f, +1.0f);
                    m[i,j] = v;
                    assert(m[i,j] == v);
                }}
            }}
        }
    }

    /**
    Get raw array data.

    Returns: raw array data
    */
    T[U*V] array() inout {
        return element;
    }

    unittest {
        import std.range : iota;
        const a = mat2(iota(4));
        assert(a.array == [0,1,2,3]);
    }

    /**
    Get column array as array of vector

    Returns: column array
    */
    Vector!(T,U)[V] column() const {
        Vector!(T,U)[V] result;
        static foreach (j; 0..V) {
            static foreach (i; 0..U) {
                result[j][i] = this[i,j];
            }
        }
        return result;
    }

    unittest {
        import std.range : iota;
        const a = mat2(iota(4));
        assert(a.column[0] == vec2(0,1));
        assert(a.column[1] == vec2(2,3));
    }

    /**
    Get row array as array of vector

    Returns: row array
    */
    Vector!(T,V)[U] row() const {
        Vector!(T,V)[U] result;
        static foreach (i; 0..U) {
            static foreach (j; 0..V) {
                result[i][j] = this[i,j];
            }
        }
        return result;
    }

    unittest {
        import std.range : iota;
        const a = mat2(iota(4));
        assert(a.row[0] == vec2(0,2));
        assert(a.row[1] == vec2(1,3));
    }

    /**
    Converts to string

    Returns: string representation of this matrix
    */
    string toString() const {
        string res;
        static foreach (i; 0..U) {
            res ~= "\n\t";
            static foreach (j; 0..V) {
                static if (__traits(isFloating, T))
                    res ~= format!"%10f,"(this[i,j]);
                else
                    res ~= format!"%d,"(this[i,j]);
            }
        }
        return res;
    }

    static if (U == V) {
        /**
        Returns identity matrix.

        Returns: identity matrix
        */
        static Matrix identity() {
            Matrix result;
            static foreach (i; 0..U) {
                static foreach (j; 0..U) {
                    static if (i == j)
                        result[i,j] = 1;
                    else
                        result[i,j] = 0;
                }
            }
            return result;
        }

        unittest {
            import std.algorithm : map;
            import std.range : iota;
            import std.random : uniform;
            import sbylib.math.vector : approxEqual;

            foreach (i; 0..100) {
                const v2 = vec2(2.iota.map!(_ => uniform(-1.0f, +1.0f)));
                assert(approxEqual(v2, mat2.identity * v2));

                const v3 = vec3(3.iota.map!(_ => uniform(-1.0f, +1.0f)));
                assert(approxEqual(v3, mat3.identity * v3));

                const v4 = vec4(4.iota.map!(_ => uniform(-1.0f, +1.0f)));
                assert(approxEqual(v4, mat4.identity * v4));
            }
        }

        /**
        Returns scale matrix.

        Params:
            vec = scale vector

        Returns: scale matrix
        */
        static Matrix scale(const Vector!(T,U) vec) {
            Matrix result;
            static foreach (i; 0..U) {
                static foreach (j; 0..U) {
                    static if (i == j)
                        result[i,j] = vec[i];
                    else
                        result[i,j] = 0;
                }
            }
            return result;
        }

        unittest {
            import std.algorithm : map;
            import std.range : iota;
            import std.random : uniform;
            import sbylib.math.vector : approxEqual;

            foreach (i; 0..100) {
                const v2 = vec2(2.iota.map!(_ => uniform(-1.0f, +1.0f)));
                const s2 = vec2(2.iota.map!(_ => uniform(-1.0f, +1.0f)));
                assert(approxEqual(v2 * s2, mat2.scale(s2) * v2));

                const v3 = vec3(3.iota.map!(_ => uniform(-1.0f, +1.0f)));
                const s3 = vec3(3.iota.map!(_ => uniform(-1.0f, +1.0f)));
                assert(approxEqual(v3 * s3, mat3.scale(s3) * v3));
            }
        }
        static if (U == 3 || U == 4) {
            /**
            Returns translation matrix.

            Params:
                vec = translation vector

            Returns: translation matrix
            */
            static Matrix translate(Vector!(T,U-1) vec) {
                Matrix result;
                static foreach (i; 0..U) {
                    static foreach (j; 0..U) {
                        static if (i == j) {
                            result[i,j] = 1;
                        } else static if (j == U-1) {
                            static if (i < U-1) {
                                result[i,j] = vec[i];
                            } else {
                                result[i,j] = 1;
                            }
                        } else {
                            result[i,j] = 0;
                        }
                    }
                }
                return result;
            }

            unittest {
                import std.algorithm : map;
                import std.range : iota;
                import std.random : uniform;
                import sbylib.math.vector : approxEqual;

                foreach (i; 0..100) {
                    const p2 = vec2(2.iota.map!(_ => uniform(-1.0f, +1.0f)));
                    const t2 = vec2(2.iota.map!(_ => uniform(-1.0f, +1.0f)));
                    assert(approxEqual(p2 + t2, (mat3.translate(t2) * vec3(p2,1)).xy));

                    const p3 = vec3(3.iota.map!(_ => uniform(-1.0f, +1.0f)));
                    const t3 = vec3(3.iota.map!(_ => uniform(-1.0f, +1.0f)));
                    assert(approxEqual(p3 + t3, (mat4.translate(t3) * vec4(p3,1)).xyz));
                }
            }

        }
        static if (U == 3) {
            /**
            Returns rotation matrix decided by its rotation axis and angle.

            Params:
                axis = rotation axis vector, which must be normalized
                angle = rotation angle

            Returns: rotation matrix
            */
            static Matrix axisAngle(const Vector!(T,3) axis, const Angle angle) {
                const c = cos(angle);
                const s = sin(angle);
                Matrix result;
                static foreach (i; 0..3) {
                    static foreach (j; 0..3) {
                        static if (i == j) {
                            result[i,j] = axis[i]*axis[j]*(1-c)+c;
                        } else static if (j == (i+1)%3) {
                            result[i,j] = axis[i]*axis[j]*(1-c)+axis[(i+2)%3]*s;
                        } else {
                            result[i,j] = axis[i]*axis[j]*(1-c)-axis[(i+1)%3]*s;
                        }
                    }
                }
                return result;
            }

            unittest {
                import std.algorithm : map;
                import std.random : uniform;
                import std.range : iota;
                import std.math : abs;
                import sbylib.math.vector : dot;

                foreach (i; 0..100) {
                    const axis = vec3(3.iota.map!(_ => uniform(-1.0f, +1.0f))).normalize;
                    auto point = vec3(3.iota.map!(_ => uniform(-1.0f, +1.0f)));
                    point = normalize(point - dot(point, axis) * axis);
                    const r = mat3.axisAngle(axis, 90.deg);
                    const point2 = r * point;
                    assert(abs(dot(point, point2)) < 1e-5);
                }
            }

            /**
            Returns rotation matrix which converts a vector to another vector.

            Params:
                from = before vector, which must be normalized
                to = after vector, which must be normalized

            Returns: rotation matrix
            */
            static Matrix rotFromTo(const Vector!(T,3) from, const Vector!(T,3) to) {
                import std.algorithm : clamp;

                const v = cross(from, to).normalize;
                const c = dot(from, to);

                if (v.hasNaN) {
                    if (c > 0) return Matrix.identity;
                    else return Matrix.scale(vec3(-1));
                }
                const angle = -acos(clamp(c, -1, +1));
                return axisAngle(v, angle);
            }

            unittest {
                import std.algorithm : map;
                import std.random : uniform;
                import std.range : iota;
                import sbylib.math.vector : approxEqual;

                foreach (i; 0..100) {
                    const a = vec3(3.iota.map!(_ => uniform(-1.0f, +1.0f))).normalize;
                    const b = vec3(3.iota.map!(_ => uniform(-1.0f, +1.0f))).normalize;
                    const c = rotFromTo(a,b) * a;
                    assert(approxEqual(b,c), format!"b = %s, b' = %s"(b,c));
                }
            }

            /**
            Returns view transform matrix.

            Params:
                vec = backward vector
                up = up vector

            Returns: view transformation matrix
            */
            static Matrix lookAt(const Vector!(T,3) vec, const Vector!(T,3) up) {
                const side = normalize(cross(up, vec));
                const up2 = normalize(cross(vec, side));
                return Matrix(side, up2, vec);
            }

        } else static if (U == 4) {

            /**
            Returns rotation matrix decided by its rotation axis and angle.

            Params:
                axis = rotation axis vector, which must be normalized
                angle = rotation angle

            Returns: rotation matrix
            */
            static Matrix axisAngle(const Vector!(T,3) v, const Angle angle) {
                return Matrix!(T,3,3).axisAngle(v, angle).toMatrix4();
            }

            unittest {
                import std.algorithm : map;
                import std.random : uniform;
                import std.range : iota;
                import std.math : abs;
                import sbylib.math.vector : dot;
                foreach (i; 0..100) {
                    const axis = vec3(3.iota.map!(_ => uniform(-1.0f, +1.0f))).normalize;
                    auto point = vec3(3.iota.map!(_ => uniform(-1.0f, +1.0f)));
                    point = normalize(point - dot(point, axis) * axis);
                    const r = mat4.axisAngle(axis, 90.deg);
                    const point2 = (r * vec4(point, 1)).xyz;
                    assert(abs(dot(point, point2)) < 1e-5);
                }
            }

            /**
            Returns rotation matrix which converts a vector to another vector.

            Params:
                from = before vector, which must be normalized
                to = after vector, which must be normalized

            Returns: rotation matrix
            */
            static Matrix rotFromTo(const Vector!(T,3) from, const Vector!(T,3) to) {
                return Matrix!(T,3,3).rotFromTo(from, to).toMatrix4();
            }

            unittest {
                import std.algorithm : map;
                import std.random : uniform;
                import std.range : iota;
                import sbylib.math.vector : approxEqual;

                foreach (i; 0..100) {
                    const a = vec3(3.iota.map!(_ => uniform(-1.0f, +1.0f))).normalize;
                    const b = vec3(3.iota.map!(_ => uniform(-1.0f, +1.0f))).normalize;
                    const c = (mat4.rotFromTo(a,b) * vec4(a,1)).xyz;
                    assert(approxEqual(b,c), format!"b = %s, b' = %s"(b,c));
                }
            }

            /**
            Returns view transform matrix.

            Params:
                eye = point of view
                vec = backward vector
                up = up vector

            Returns: view transformation matrix
            */
            static Matrix lookAt(const Vector!(T,3) eye, const Vector!(T,3) vec, const Vector!(T,3) up) {
                const side = normalize(cross(up, vec));
                const up2 = normalize(cross(vec, side));
                return Matrix(Vector!(T,4)(side, 0), Vector!(T,4)(up2, 0), Vector!(T,4)(vec, 0),
                        Vector!(T,4)(-dot(eye,side),-dot(eye,up2),-dot(eye,vec),1));
            }

            /**
            Returns orthographic projection transform matrix.

            Params:
                width = width of orthographic view area
                height = height of orthographic view area
                nearZ = near side z value of orthographic view area
                farZ = far side z value of orthographic view area

            Returns: orthographic projection transformation matrix
            */
            static Matrix ortho(T width, T height, T nearZ, T farZ) {
                return Matrix(
                        2 / width, 0,          0,                  0,
                        0,         2 / height, 0,                  0,
                        0,         0,          1 / (nearZ - farZ), nearZ / (nearZ - farZ),
                        0,         0,          0,                  1
                        );
            }

            /**
            Returns perspective projection transform matrix.

            Params:
                aspectWperH = bottom side aspect retio
                fovy = FOV of y direction
                nearZ = near side z value of orthographic view area
                farZ = far side z value of orthographic view area

            Returns: perspective projection transform matrix
            */
            static Matrix perspective(T aspectWperH, Angle fovy, T nearZ, T farZ) {
                return Matrix(
                        1 / (aspectWperH * tan(fovy/2)), 0, 0, 0,
                        0, 1 / (tan(fovy/2)), 0, 0,
                        0, 0, (nearZ+farZ)/(nearZ-farZ), 2 * nearZ * farZ / (nearZ - farZ),
                        0, 0, -1, 0);
            }

            /**
            Returns TRS transform matrix.

            Params:
                pos = translation vector, which represents T
                rot = rotation matrix, which represents R
                scale = scale vector, which represents S

            Returns: perspective projection transform matrix
            */
            static Matrix makeTRS(const Vector!(T,3) trans, const Matrix!(T,3,3) rot, const Vector!(T,3) scale) {
                return Matrix(
                        vec4(scale[0] * rot.column[0],0), 
                        vec4(scale[1] * rot.column[1],0), 
                        vec4(scale[2] * rot.column[2],0), 
                        vec4(trans,1));
            }

            unittest {
                import std.algorithm : map;
                import std.random : uniform;
                import std.range : iota;
                import sbylib.math.vector : approxEqual;

                foreach (i; 0..100) {
                    const p = vec3(3.iota.map!(_ => uniform(-1.0f, +1.0f)));
                    const t = vec3(3.iota.map!(_ => uniform(-1.0f, +1.0f)));
                    const r = mat3.axisAngle(vec3(3.iota.map!(_ => uniform(-1.0f, +1.0f))).normalize,
                            uniform(0,180.0).deg);
                    const s = vec3(3.iota.map!(_ => uniform(-1.0f, +1.0f)));

                    assert(approxEqual((mat4.makeTRS(t,r,s) * vec4(p,1)).xyz, r * (s * p) + t));
                }
            }
            
            /**
            Returns inverse TRS transform matrix.

            Params:
                pos = translation vector, which represents T
                rot = rotation matrix, which represents R
                scale = scale vector, which represents S

            Returns: perspective projection transform matrix
            */
            static Matrix makeInvertTRS(const Vector!(T,3) pos, const Matrix!(T,3,3) rot, const Vector!(T, 3) scale) {
                return Matrix(
                        rot[0,0] / scale[0], rot[1,0] / scale[0], rot[2,0] / scale[0], -dot(rot.column[0], pos) / scale[0],
                        rot[0,1] / scale[1], rot[1,1] / scale[1], rot[2,1] / scale[1], -dot(rot.column[1], pos) / scale[1],
                        rot[0,2] / scale[2], rot[1,2] / scale[2], rot[2,2] / scale[2], -dot(rot.column[2], pos) / scale[2],
                        0,0,0, 1);
            }

            unittest {
                import std.algorithm : map;
                import std.random : uniform;
                import std.range : iota;

                foreach (i; 0..100) {
                    const t = vec3(3.iota.map!(_ => uniform(-1.0f, +1.0f)));
                    const r = mat3.axisAngle(vec3(3.iota.map!(_ => uniform(-1.0f, +1.0f))).normalize, uniform(0,180.0).deg);
                    const s = vec3(3.iota.map!(_ => uniform(-1.0f, +1.0f)));

                    assert(approxEqual(mat4.makeTRS(t,r,s) * mat4.makeInvertTRS(t,r,s), mat4.identity));
                }
            }
        }
    }
}

/**
Returns transposed matrix.

Params:
    m = target matrix

Returns: transposed matrix
*/
Matrix!(T,V,U) transpose(T, uint U, uint V)(const Matrix!(T,U,V) m) {
    Matrix!(T,V,U) r;
    static foreach (i;0..V) {
        static foreach (j;0..U) {
            r[i,j] = m[j,i];
        }
    }
    return r;
}

unittest {
    assert(approxEqual(transpose(mat2x3(1,2,3, 4,5,6)), mat3x2(1,4, 2,5, 3,6)));
}

/**
Returns shrinked 3x3 matrix
The last row and column of the target are removed.

Params:
    m = target matrix

Returns: 3x3 matrix
*/
Matrix!(T,3,3) toMatrix3(T)(const Matrix!(T,4,4) m) {
    return Matrix!(T,3,3)(m.column[0].xyz, m.column[1].xyz, m.column[2].xyz);
}

unittest {
    import std.algorithm : map;
    import std.random : uniform;
    import std.range : iota;
    import sbylib.math.vector : approxEqual;

    foreach (i; 0..100) {
        const p = vec3(3.iota.map!(_ => uniform(-1.0f, +1.0f)));
        const m = mat4(16.iota.map!(_ => uniform(-1.0f, +1.0f)));

        assert(approxEqual((m * vec4(p,0)).xyz, m.toMatrix3() * p));
    }
}

/**
Returns expanded 4x4 matrix
The last row and column of the result matrix are almost 0, but 3,3 element is 1.

Params:
    m = target matrix

Returns: 4x4 matrix
*/
Matrix!(T,4,4) toMatrix4(T)(const Matrix!(T,3,3) m) {
    Matrix!(T,4,4) result;
    static foreach (i; 0..3) {
        static foreach (j; 0..3) {
            result[i,j] = m[i,j];
        }
    }
    static foreach (i; 0..3) {
        result[i,3] = 0;
        result[3,i] = 0;
    }
    result[3,3] = 1;
    return result;
}

unittest {
    import std.algorithm : map;
    import std.random : uniform;
    import std.range : iota;
    import sbylib.math.vector : approxEqual;

    foreach (i; 0..100) {
        const p = vec3(3.iota.map!(_ => uniform(-1.0f, +1.0f)));
        const m = mat3(9.iota.map!(_ => uniform(-1.0f, +1.0f)));

        assert(approxEqual(m * p, (m.toMatrix4() * vec4(p,1)).xyz));
    }
}

/**
Converts to quaternion.

Returns: converted quaternion
*/
Quaternion!T toQuaternion(T)(const Matrix!(T,3,3) m) {
    import std.math : sqrt, sgn;

    auto q0 = ( m[0,0] + m[1,1] + m[2,2] + 1.0f) / 4.0f;
    auto q1 = ( m[0,0] - m[1,1] - m[2,2] + 1.0f) / 4.0f;
    auto q2 = (-m[0,0] + m[1,1] - m[2,2] + 1.0f) / 4.0f;
    auto q3 = (-m[0,0] - m[1,1] + m[2,2] + 1.0f) / 4.0f;
    if(q0 < 0.0f) q0 = 0.0f;
    if(q1 < 0.0f) q1 = 0.0f;
    if(q2 < 0.0f) q2 = 0.0f;
    if(q3 < 0.0f) q3 = 0.0f;
    q0 = sqrt(q0);
    q1 = sqrt(q1);
    q2 = sqrt(q2);
    q3 = sqrt(q3);
    if(q0 >= q1 && q0 >= q2 && q0 >= q3) {
        q1 *= sgn(m[2,1] - m[1,2]);
        q2 *= sgn(m[0,2] - m[2,0]);
        q3 *= sgn(m[1,0] - m[0,1]);
    } else if(q1 >= q0 && q1 >= q2 && q1 >= q3) {
        q0 *= sgn(m[2,1] - m[1,2]);
        q2 *= sgn(m[1,0] + m[0,1]);
        q3 *= sgn(m[0,2] + m[2,0]);
    } else if(q2 >= q0 && q2 >= q1 && q2 >= q3) {
        q0 *= sgn(m[0,2] - m[2,0]);
        q1 *= sgn(m[1,0] + m[0,1]);
        q3 *= sgn(m[2,1] + m[1,2]);
    } else if(q3 >= q0 && q3 >= q1 && q3 >= q2) {
        q0 *= sgn(m[1,0] - m[0,1]);
        q1 *= sgn(m[2,0] + m[0,2]);
        q2 *= sgn(m[2,1] + m[1,2]);
    } else {
        assert(false);
    }

    auto result = Quaternion!T(q1, q2, q3, q0);
    return result.normalize;
}

unittest {
    import std.algorithm : map;
    import std.random : uniform;
    import std.range : iota;
    import sbylib.math.vector : approxEqual;
    import sbylib.math.quaternion : rotate;

    foreach (i; 0..100) {
        const p = vec3(3.iota.map!(_ => uniform(-1.0f, +1.0f)));
        const r = mat3.axisAngle(vec3(3.iota.map!(_ => uniform(-1.0f, +1.0f))).normalize,
                uniform(0,180.0).deg);

        assert(approxEqual(r * p, rotate(r.toQuaternion(), p), 1e-3));
    }
}

/**
Get diagonal component from matrix

Returns: diagonal vector of the matrix
*/
Vector!(T,U) diagonal(T,uint U)(const Matrix!(T,U,U) m) {
    Vector!(T,U) result;
    static foreach (i; 0..U) {
        result[i] = m[i,i];
    }
    return result;
}

unittest {
    import std.range : iota;
    import sbylib.math.vector : approxEqual;

    assert(approxEqual(diagonal(mat3(iota(9))), vec3(0,4,8)));
}

/**
Get translation information from matrix

Returns: translation vector for the matrix
*/
Vector!(T,U-1) getTranslation(T,uint U)(const Matrix!(T,U,U) m) 
if (U > 0)
{
    Vector!(T,U-1) result;
    static foreach (i; 0..U-1) {
        result[i] = m[i,U-1];
    }
    return result;
}

unittest {
    import std.algorithm : map;
    import std.random : uniform;
    import std.range : iota;
    import sbylib.math.vector : approxEqual;

    foreach (i; 0..100) {
        const t = vec3(3.iota.map!(_ => uniform(-1.0f, +1.0f)));
        const r = mat3.identity();
        const s = vec3(3.iota.map!(_ => uniform(-1.0f, +1.0f)));

        const m = mat4.makeTRS(t,r,s);

        assert(approxEqual(diagonal(m).xyz, s));
        assert(approxEqual(getTranslation(m), t));
    }
}

/**
Get the determinant value of 2x2 matrix

Params:
    m = target matrix

Returns: determinant value of the target matrix
*/
T determinant(T)(const Matrix!(T,2,2) m) {
    return m[0,0]*m[1,1] - m[0,1]*m[1,0];
}

/**
Get the determinant value of 3x3 matrix

Params:
    m = target matrix

Returns: determinant value of the target matrix
*/
T determinant(T)(const Matrix!(T,3,3) m) {
    return
        + m[0,0]*m[1,1]*m[2,2]
        + m[0,1]*m[1,2]*m[2,0]
        + m[0,2]*m[1,0]*m[2,1]
        - m[0,0]*m[1,2]*m[2,1]
        - m[0,1]*m[1,0]*m[2,2]
        - m[0,2]*m[1,1]*m[2,0];
}

/**
Get the determinant value of 4x4 matrix

Params:
    m = target matrix

Returns: determinant value of the target matrix
*/
T determinant(T)(const Matrix!(T,4,4) m) {
    const e2233_2332 = m[2,2] * m[3,3] - m[2,3] * m[3,2];
    const e2133_2331 = m[2,1] * m[3,3] - m[2,3] * m[3,1];
    const e2132_2231 = m[2,1] * m[3,2] - m[2,2] * m[3,1];
    const e2033_2330 = m[2,0] * m[3,3] - m[2,3] * m[3,0];
    const e2032_2230 = m[2,0] * m[3,2] - m[2,2] * m[3,0];
    const e2031_2130 = m[2,0] * m[3,1] - m[2,1] * m[3,0];
    return
        m[0,0] * (m[1,1] * e2233_2332 - m[1,2] * e2133_2331 + m[1,3] * e2132_2231) -
        m[0,1] * (m[1,0] * e2233_2332 - m[1,2] * e2033_2330 + m[1,3] * e2032_2230) +
        m[0,2] * (m[1,0] * e2133_2331 - m[1,1] * e2033_2330 + m[1,3] * e2031_2130) -
        m[0,3] * (m[1,0] * e2132_2231 - m[1,1] * e2032_2230 + m[1,2] * e2031_2130)
    ;
}

/**
Get 2x2 inverse matrix

Params:
    m = target matrix

Returns: inverse matrix of the target matrix
*/
Matrix!(T,2,2) invert(T)(const Matrix!(T,2,2) m) {
    auto det = determinant(m);
    if (det != 0) det = 1 / det;
    Matrix!(T,2,2) r;
    r[0,0] = +m[1,1] * det;
    r[0,1] = -m[0,1] * det;
    r[1,0] = -m[1,0] * det;
    r[1,1] = +m[0,0] * det;
    return r;
}

unittest {
    import std.algorithm : map;
    import std.range : iota;
    import std.random : uniform;
    foreach (i; 0..100) {
        const m = mat2(4.iota.map!(_ => uniform(-1.0f, +1.0f)));
        assert(determinant(m) == 0 || approxEqual(m * invert(m), mat2.identity, 1e-3));
    }
}

/**
Get 3x3 inverse matrix

Params:
    m = target matrix

Returns: inverse matrix of the target matrix
*/
Matrix!(T,3,3) invert(T)(const Matrix!(T,3,3) m) {
    auto det = determinant(m);
    if (det != 0) det = 1 / det;
    Matrix!(T,3,3) r;
    r[0,0] = (m[1,1]*m[2,2] - m[1,2]*m[2,1]) * det;
    r[0,1] = (m[0,2]*m[2,1] - m[0,1]*m[2,2]) * det;
    r[0,2] = (m[0,1]*m[1,2] - m[0,2]*m[1,1]) * det;
    r[1,0] = (m[1,2]*m[2,0] - m[1,0]*m[2,2]) * det;
    r[1,1] = (m[0,0]*m[2,2] - m[0,2]*m[2,0]) * det;
    r[1,2] = (m[0,2]*m[1,0] - m[0,0]*m[1,2]) * det;
    r[2,0] = (m[1,0]*m[2,1] - m[1,1]*m[2,0]) * det;
    r[2,1] = (m[0,1]*m[2,0] - m[0,0]*m[2,1]) * det;
    r[2,2] = (m[0,0]*m[1,1] - m[0,1]*m[1,0]) * det;
    return r;
}

unittest {
    import std.algorithm : map;
    import std.range : iota;
    import std.random : uniform;
    foreach (i; 0..100) {
        const m = mat3(9.iota.map!(_ => uniform(-1.0f, +1.0f)));
        assert(determinant(m) == 0 || approxEqual(m * invert(m), mat3.identity, 1e-3));
    }
}

/**
Get 4x4 inverse matrix

Params:
    m = target matrix

Returns: inverse matrix of the target matrix
*/
Matrix!(T,4,4) invert(T)(const Matrix!(T,4,4) m) {
    auto det = determinant(m);
    if (det != 0) det = 1 / det;
    const e2233_2332 = m[2,2] * m[3,3] - m[2,3] * m[3,2];
    const e2133_2331 = m[2,1] * m[3,3] - m[2,3] * m[3,1];
    const e2132_2231 = m[2,1] * m[3,2] - m[2,2] * m[3,1];
    const e1233_1332 = m[1,2] * m[3,3] - m[1,3] * m[3,2];
    const e1133_1331 = m[1,1] * m[3,3] - m[1,3] * m[3,1];
    const e1132_1231 = m[1,1] * m[3,2] - m[1,2] * m[3,1];
    const e1322_1223 = m[1,3] * m[2,2] - m[1,2] * m[2,3];
    const e1123_1321 = m[1,1] * m[2,3] - m[1,3] * m[2,1];
    const e1122_1221 = m[1,1] * m[2,2] - m[1,2] * m[2,1];
    const e2033_2330 = m[2,0] * m[3,3] - m[2,3] * m[3,0];
    const e2032_2230 = m[2,0] * m[3,2] - m[2,2] * m[3,0];
    const e1033_1330 = m[1,0] * m[3,3] - m[1,3] * m[3,0];
    const e1032_1230 = m[1,0] * m[3,2] - m[1,2] * m[3,0];
    const e1023_1320 = m[1,0] * m[2,3] - m[1,3] * m[2,0];
    const e1022_1220 = m[1,0] * m[2,2] - m[1,2] * m[2,0];
    const e2031_2130 = m[2,0] * m[3,1] - m[2,1] * m[3,0];
    const e1031_1130 = m[1,0] * m[3,1] - m[1,1] * m[3,0];
    const e1021_1120 = m[1,0] * m[2,1] - m[1,1] * m[2,0];
    const t00 =  m[1,1] * e2233_2332 - m[1,2] * e2133_2331 + m[1,3] * e2132_2231;
    const t01 = -m[0,1] * e2233_2332 + m[0,2] * e2133_2331 - m[0,3] * e2132_2231;
    const t02 =  m[0,1] * e1233_1332 - m[0,2] * e1133_1331 + m[0,3] * e1132_1231;
    const t03 =  m[0,1] * e1322_1223 + m[0,2] * e1123_1321 - m[0,3] * e1122_1221;
    const t10 = -m[1,0] * e2233_2332 + m[1,2] * e2033_2330 - m[1,3] * e2032_2230;
    const t11 =  m[0,0] * e2233_2332 - m[0,2] * e2033_2330 + m[0,3] * e2032_2230;
    const t12 = -m[0,0] * e1233_1332 + m[0,2] * e1033_1330 - m[0,3] * e1032_1230;
    const t13 = -m[0,0] * e1322_1223 - m[0,2] * e1023_1320 + m[0,3] * e1022_1220;
    const t20 =  m[1,0] * e2133_2331 - m[1,1] * e2033_2330 + m[1,3] * e2031_2130;
    const t21 = -m[0,0] * e2133_2331 + m[0,1] * e2033_2330 - m[0,3] * e2031_2130;
    const t22 =  m[0,0] * e1133_1331 - m[0,1] * e1033_1330 + m[0,3] * e1031_1130;
    const t23 = -m[0,0] * e1123_1321 + m[0,1] * e1023_1320 - m[0,3] * e1021_1120;
    const t30 = -m[1,0] * e2132_2231 + m[1,1] * e2032_2230 - m[1,2] * e2031_2130;
    const t31 =  m[0,0] * e2132_2231 - m[0,1] * e2032_2230 + m[0,2] * e2031_2130;
    const t32 = -m[0,0] * e1132_1231 + m[0,1] * e1032_1230 - m[0,2] * e1031_1130;
    const t33 =  m[0,0] * e1122_1221 - m[0,1] * e1022_1220 + m[0,2] * e1021_1120;
    Matrix!(T,4,4) r;
    r[0,0] =  det * t00;
    r[0,1] =  det * t01;
    r[0,2] =  det * t02;
    r[0,3] =  det * t03;
    r[1,0] =  det * t10;
    r[1,1] =  det * t11;
    r[1,2] =  det * t12;
    r[1,3] =  det * t13;
    r[2,0] =  det * t20;
    r[2,1] =  det * t21;
    r[2,2] =  det * t22;
    r[2,3] =  det * t23;
    r[3,0] =  det * t30;
    r[3,1] =  det * t31;
    r[3,2] =  det * t32;
    r[3,3] =  det * t33;
    return r;
}

unittest {
    import std.algorithm : map;
    import std.range : iota;
    import std.random : uniform;
    foreach (i; 0..100) {
        const m = mat4(16.iota.map!(_ => uniform(-1.0f, +1.0f)));
        assert(determinant(m) == 0 || approxEqual(m * invert(m), mat4.identity, 1e-3));
    }
}

/**
Calculate the diagonalize matrix of the target matrix.

Params:
    m = target matrix, which must be real symmetric

Returns: the diagonalize matrix
*/
Matrix!(T,U,U) diagonalizeForRealSym(T, uint U)(Matrix!(T,U,U) m, T eps = 1e-5) 
if (__traits(isFloating, T))
{
    import std.math : abs, sqrt;

    T getMaxValue(ref Matrix!(T,U,U) m, out uint p, out uint q) {
        T max = 0;
        foreach (i; 0..U) {
            foreach (j; 0..U) {
                if (i == j) continue;
                if (m[i,j].abs > max) {
                    max = m[i,j].abs;
                    p = i;
                    q = j;
                }
            }
        }
        return max;
    }

    auto result = Matrix!(T,U,U).identity;
    T max;
    uint p, q;
    uint bp = 114514, bq = 114514;
    while (true) {
        if ((max = getMaxValue(m, p, q)) < eps) break;
        if (p == bp && q == bq) break;
        const pp = m[p,p];
        const pq = m[p,q];
        const qq = m[q,q];
        T alpha = (pp - qq) / 2.0;
        T beta = -pq;
        T gamma = abs(alpha) / sqrt(alpha*alpha+beta*beta);
        T s = sqrt((1.0-gamma) / 2.0);
        const c = sqrt((1.0+gamma) / 2.0);
        if (alpha * beta < 0) s = -s;
        static foreach (i; 0..U) {{
            const tmp = c * m[p, i] - s * m[q, i];
            m[q, i] = s * m[p, i] + c * m[q, i];
            m[p, i] = tmp;
        }}
        static foreach (i; 0..U) {
            m[i,p] = m[p,i];
            m[i,q] = m[q,i];
        }
        m[p,p] = c*c*pp + s*s*qq - 2*s*c*pq;
        m[p,q] = s*c*(pp-qq) + (c*c-s*s) * pq;
        m[q,p] = m[p,q];
        m[q,q] = s*s*pp + c*c*qq + 2*s*c*pq;
        static foreach (i; 0..U) {{
            const tmp = c*result[i,p]-s*result[i,q];
            result[i,q] = s*result[i,p] + c*result[i,q];
            result[i,p] = tmp;
        }}
        bp = p;
        bq = q;
    }
    return result;
}

unittest {
    import std.algorithm : map;
    import std.array : array;
    import std.range : iota;
    import std.random : uniform;
    import sbylib.math.vector : vapproxEqual = approxEqual;
    foreach (k; 0..100) {
        // m is real symmetric matrix
        auto m = mat4(16.iota.map!(_ => uniform(-1.0f, +1.0f)));
        static foreach (i; 0..4) {
            static foreach (j; 0..4) {
                m[i,j] = m[j,i];
            }
        }
        assert(m.isSymmetric);

        // p is diagonalize matrix of m
        const p = diagonalizeForRealSym(m);

        // a is diagonalized matrix
        const a = transpose(p) * m * p;

        // successfully diagonalized
        assert(approxEqual(a, mat4.scale(diagonal(a)), 1e-3));

        // if m is real symmetric, p is orthognal matrix
        assert(p.isOrthogonal);

        static foreach (i; 0..4) {{
            const eigenVector = p.column[i];
            const eigenValue = a[i,i];

            assert(vapproxEqual(m * eigenVector, eigenVector * eigenValue, 1e-3));
        }}
    }
}

/**
Returns true if the given matrix is symmetric.

Params:
    m = target matrix
    eps = criteria of approximation

Returns: true if the given matrix is symmetric
*/
bool isSymmetric(T, uint U)(const Matrix!(T,U,U) m, T eps = 1e-5) {
    return approxEqual(m, transpose(m), eps);
}

/**
Returns true if the given matrix is orthogonal.

Params:
    m = target matrix
    eps = criteria of approximation

Returns: true if the given matrix is orthogonal
*/
bool isOrthogonal(T, uint U)(const Matrix!(T,U,U) m, T eps = 1e-5) {
    return approxEqual(invert(m), transpose(m), eps);
}

/**
Returns true if the distance of each element is less than eps.

Params:
    a = target point
    b = target point
    eps = criteria of approximation

Returns: true if 2 vectors are approximately equal.
*/
bool approxEqual(T,uint U,uint V)(const Matrix!(T,U,V) a, const Matrix!(T,U,V) b, T eps = 1e-5) {
    import std.math : abs;

    static foreach (i; 0..U) {
        static foreach (j; 0..V) {
            if (abs(a[i,j] - b[i,j]) > eps) return false;
        }
    }
    return true;
}
