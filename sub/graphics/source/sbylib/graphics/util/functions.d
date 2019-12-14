module sbylib.graphics.util.functions;

import sbylib.math;

// public import sbylib.math;
// public import sbylib.wrapper.freeimage : Image;
// 
// // import sbylib.graphics.canvas : Canvas;
// import sbylib.wrapper.gl : Texture;
// 
// import std.traits : isAggregateType, FieldTypeTuple, FieldNameTuple;
// 
mixin template DefineCachedValue(Type, string attribute, string name, string expression, string[] keys) 
    if (keys.length > 0)
{

    import std : format, replace;

    static foreach (key; keys) {
        mixin(format!"%s _%sSavedValue;"(VariableType!(typeof(mixin(key))).stringof, key.replace(".", "_")));
    }
    mixin(format!"%s _%sSavedValue;"(Type.stringof, name));

    mixin(format!q{
        %s %s %s() {
            bool _shouldUpdate = false;
            static foreach (key; keys) {
                if (mixin(format!"_%sSavedValue != %s"(key.replace(".", "_"), key))) {
                    _shouldUpdate = true;
                    mixin(format!"_%sSavedValue = %s;"(key.replace(".", "_"), key));
                }
            }
            if (_shouldUpdate)
                _%sSavedValue = %s;
            return _%sSavedValue;
        }
    }(attribute, Type.stringof, name, "%s", "%s", "%s", "%s", name, expression, name));

    template VariableType(Type) {
        import std : isSomeFunction, ReturnType;
    
        static if (isSomeFunction!(Type)) {
            alias VariableType = ReturnType!(Type);
        } else {
            alias VariableType = Type;
        }
    }
} 

mixin template ImplPos() {
    import sbylib.math : vec3;
    // import sbylib.graphics.util : Pixel, pixel, ImplPixelX, ImplPixelY;
    import sbylib.wrapper.glfw : Window;

    vec3 pos = vec3(0);

    /*

    Pixel[2] pixelPos() {
        import sbylib.wrapper.gl : GlUtils;

        const viewport = GlUtils().getViewport();
        return [
            pixel(cast(int)(pos.x * viewport[2]) / 2),
            pixel(cast(int)(pos.y * viewport[3]) / 2),
        ];
    }

    Pixel[2] pixelPos(Pixel[2] pixel) {
        import sbylib.wrapper.gl : GlUtils;

        const viewport = GlUtils().getViewport();

        this.pos.xy = 2 * vec2(pixel) / vec2(viewport[2..$]);

        return pixel;
    }

    mixin ImplPixelX;
    mixin ImplPixelY;
    */
}

/*
mixin template ImplPixelX() {
    Pixel pixelX() {
        return this.pixelPos[0];
    }

    Pixel pixelX(Pixel pixel) {
        this.pixelPos = [pixel, this.pixelPos[1]];
        return pixel;
    }
}

mixin template ImplPixelY() {
    Pixel pixelY() {
        return this.pixelPos[1];
    }

    Pixel pixelY(Pixel pixel) {
        this.pixelPos = [this.pixelPos[0], pixel];
        return pixel;
    }
}
*/

mixin template ImplRot() {
    import sbylib.math : mat3, Angle;

    mat3 rot = mat3.identity;

    auto rotate(Angle angle) {
        this.rot *= mat3.axisAngle(vec3(0,0,1), angle);
        return this;
    }
}
 
 mixin template ImplScale() {
     import sbylib.math : vec3;
     // import sbylib.graphics.util : Pixel, ImplPixelX, ImplPixelY;
 
     vec3 scale = vec3(1);
 
     /*
     Pixel[2] pixelSize(Pixel[2] pixel) {
         import sbylib.wrapper.gl : GlUtils;
 
         this.scale.xy = 2 * vec2(pixel) / vec2(GlUtils().getViewport()[2..$]);
 
         return pixel;
     }
 
     Pixel[2] pixelSize() {
         import sbylib.wrapper.gl : GlUtils;
 
         const viewport = GlUtils().getViewport();
         return [
             pixel(cast(int)(this.scale.x * viewport[2]) / 2),
             pixel(cast(int)(this.scale.y * viewport[3]) / 2),
         ];
     }
 
     mixin ImplPixelWidth;
     mixin ImplPixelHeight;
     */
 }
 
// mixin template ImplPixelWidth() {
//     Pixel pixelWidth() {
//         return this.pixelSize[0];
//     }
// 
//     Pixel pixelWidth(Pixel pixel) {
//         this.pixelSize = [pixel, this.pixelSize[1]];
//         return pixel;
//     }
// }
// 
// mixin template ImplPixelHeight() {
//     Pixel pixelHeight() {
//         return this.pixelSize[1];
//     }
// 
//     Pixel pixelHeight(Pixel pixel) {
//         this.pixelSize = [this.pixelSize[0], pixel];
//         return pixel;
//     }
// }
// 
mixin template ImplWorldMatrix(string name = "worldMatrix") {
    import sbylib.graphics.util : DefineCachedValue;
    import std : hasMember, format;

    private enum hasPos = hasMember!(typeof(this), "pos");
    private enum hasRot = hasMember!(typeof(this), "rot");
    private enum hasScale = hasMember!(typeof(this), "scale");
    private enum expression = format!q{mat4.makeTRS(%s, %s, %s)}
        (hasPos   ? "pos"   : "vec3(0)",
         hasRot   ? "rot"   : "mat3.identity",
         hasScale ? "scale" : "vec3(1)");
    enum key = 
          (hasPos   ? ["pos"]   : [])
        ~ (hasRot   ? ["rot"]   : [])
        ~ (hasScale ? ["scale"] : []);

    static if (key.length > 0) {
        mixin DefineCachedValue!(mat4, "", name, expression, key);
    } else {
        mixin(format!q{mat4 %s() { return mat4.identity; }}(name));
    }
}
// 
// mixin template ImplParentalWorldMatrix(alias parent) {
//     mixin ImplWorldMatrix!("_worldMatrix") W;
// 
//     private enum expression = "parent.worldMatrix * W._worldMatrix";
//     private enum key = [parent.stringof] ~ "parent.worldMatrix" ~ W.key;
// 
//     mixin DefineCachedValue!(mat4, "@uniform", "worldMatrix", expression, key);
// }
// 
mixin template ImplViewMatrix() {
    import sbylib.graphics.util : DefineCachedValue;
    import std : hasMember, format;

    private enum hasPos = hasMember!(typeof(this), "pos");
    private enum hasRot = hasMember!(typeof(this), "rot");
    private enum hasScale = hasMember!(typeof(this), "scale");
    private enum expression = format!q{mat4.makeInvertTRS(%s, %s, %s)}
        (hasPos   ? "pos"   : "vec3(0)",
         hasRot   ? "rot"   : "mat3.identity",
         hasScale ? "scale" : "vec3(1)");
    private enum key = 
          (hasPos   ? ["pos"]   : [])
        ~ (hasRot   ? ["rot"]   : [])
        ~ (hasScale ? ["scale"] : []);

    static if (key.length > 0) {
        mixin DefineCachedValue!(mat4, "", "viewMatrix", expression, key);
    } else {
        mat4 getViewMatrix() { return mat4.identity; }
    }
}
// 
// /*
// void render(Canvas dstCanvas, Texture tex, ivec2 p, ivec2 s) {
//     import sbylib.graphics.canvas : CanvasBuilder;
//     import sbylib.wrapper.gl : TextureFilter, BufferBit;
// 
//     static Canvas canvas;
//     if (canvas is null) {
//         with (CanvasBuilder()) {
//             color.enable = true;
//             canvas = build();
//         }
//     }
//     canvas.color.attach(tex);
// 
//     dstCanvas.render(canvas,
//         0, 0, tex.width, tex.height,
//         p.x, p.y, p.x + s.x, p.y + s.y,
//         TextureFilter.Linear, BufferBit.Color);
// }
// */
// 
void lookAt(T)(T entity, vec3 target, vec3 up = vec3(0,1,0)) {
    entity.rot = mat3.lookAt(normalize(entity.pos - target), up);
}
// 
// Texture convert(Image image) {
//     import sbylib.wrapper.gl : TextureBuilder;
//     with (TextureBuilder()) {
//         width = image.width;
//         height = image.height;
//         return build(image.dataArray());
//     }
// }

mixin template ImplResourceStack() {
    private void delegate()[] deconstructionStack;

    private void destroyStack() {
        while (deconstructionStack.empty is false) {
            deconstructionStack.back()();
            deconstructionStack.popBack();
        }
    }

    public T pushResource(T)(T t) {
        pushReleaseCallback({ t.destroy(); });
        return t;
    }

    public void pushReleaseCallback(void delegate() cb) {
        deconstructionStack ~= cb;
    }
}
