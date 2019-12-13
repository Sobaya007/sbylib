module sbylib.math.angle;

import std.format : format;

/**
This struct is like (Degree | Radian)
*/
struct Angle {
    private float deg;

    package this(float deg) {
        this.deg = deg;
    }

    /**
    unary operator for '-' 

    Returns: negated angle struct
    */
    Angle opUnary(string op)() const
    if (op == "-")
    {
        return Angle(mixin(op ~ "this.deg"));
    }

    /**
    binary operator between float ("*" and "/" only)

    Params:
        v = operation target value

    Returns: calculated angle struct
    */
    Angle opBinary(string op)(float v) const
    if (op == "*" || op == "/") 
    {
        return Angle(mixin("this.deg " ~ op ~ " v"));
    }

    /**
    binary operator between float ("*" and "/" only)

    Params:
        v = operation target value

    Returns: calculated angle struct
    */
    Angle opBinaryRight(string op)(float v) const
    if (op == "*" || op == "/") 
    {
        return Angle(mixin("v" ~ op ~ "this.deg"));
    }

    /**
    binary operator between Angle ("*" and "/" only)

    Params:
        a = operation target

    Returns: calculated angle struct
    */
    Angle opBinary(string op)(Angle a) const {
        return Angle(mixin("this.deg " ~ op ~ " a.deg"));
    }

    /**
    operator assign between Angle ("*" and "/" only)

    Params:
        a = operation target
    */
    void opOpAssign(string op)(float v)
    if (op == "*" || op == "/") 
    {
        mixin("this.deg" ~ op ~ "= v;");
    }

    /**
    operator assign between Angle ("*" and "/" only)

    Params:
        a = operation target
    */
    void opOpAssign(string op)(Angle a) {
        mixin("this.deg" ~ op ~ "= a.deg;");
    }

    /**
    compare operation between Angle

    Params:
        a = comparison target

    Returns: comparison result
    */
    int opCmp(Angle a) const {
        import std.math : sgn;

        return cast(int)sgn(this.deg - a.deg);
    }

    /**
    equal operation between Angle

    Params:
        a = comparison target

    Returns: comparison result
    */
    bool opEquals(Angle a) const {
        return this.deg == a.deg;
    }

    /**
    Calculate the hash value for this instance.
    It is equals to the floating degree expression's hash value.

    Returns: hash value
    */
    int toHash() const {
        return this.deg.deg.toHash();
    }

    /**
    convers to String

    Returns: String expression
    */
    string toString() const {
        return format!"%f [deg.]"(deg);
    }

    /**
    Get the floating value as radians.

    Returns: radian value
    */
    float asRadian() const {
        import std.math : PI;
        return deg * PI / 180;
    }

    /**
    Get the floating value as degrees.

    Returns: degree value
    */
    float asDegree() const {
        return deg;
    }
}

private mixin template RadianInputFunction(string func) {
    import std.format;
    mixin(format!q{

auto %s(const Angle angle) {
    import std.math : %s;
    return %s(angle.asRadian());
}

    }(func, func, func));
}

private mixin template RadianOutputFunction(string func) {
    import std.format;
    mixin(format!q{

auto %s(float angle) {
    import std.math : %s;
    return %s(angle).rad;
}

    }(func, func, func));
}

private mixin template AngleInputFunction(string func) {
    import std.format;
    mixin(format!q{

auto %s(const Angle angle) {
    import std.math : %s;
    return %s(angle.asDegree()).deg;
}

    }(func, func, func));
}

mixin RadianInputFunction!("sin");
mixin RadianInputFunction!("cos");
mixin RadianInputFunction!("tan");
mixin RadianOutputFunction!("asin");
mixin RadianOutputFunction!("acos");
mixin RadianOutputFunction!("atan");
mixin AngleInputFunction!("abs");

/**
Get Angle struct from degree value.

Returns: Angle struct that equals to the degree value.
*/
Angle deg(float d) {
    return Angle(d);
}

/**
Get Angle struct from radian value.

Returns: Angle struct that equals to the radian value.
*/
Angle rad(float r) {
    import std.math : PI;
    return Angle(r * 180 / PI);
}
