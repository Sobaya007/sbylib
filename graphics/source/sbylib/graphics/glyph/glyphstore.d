module sbylib.graphics.glyph.glyphstore;

import std;
import erupted;
import sbylib.graphics.glyph.glyph;
import sbylib.graphics.glyph.glyphtexture;
import sbylib.wrapper.freetype;
import sbylib.wrapper.vulkan;

class GlyphStore {
 
     private Font font;
     private GlyphTexture _texture;
     private int[] currentX;
     private Glyph[dchar] glyph;
 
     this(string font, int height) {
         this.font = FontLoader().load(font, height);
         this._texture = new GlyphTexture(256, 256);
         this.currentX = [0];
     }

     ~this() {
         this._texture.destroy();
     }
 
     GlyphTexture texture() {
         return _texture;
     }
 
     Glyph getGlyph(dchar c) {
         if (auto r = c in glyph) return *r;
 
         auto info = font.getLetterInfo(c);

         auto result = glyph[c] = 
             new Glyph(info.character,
                     info.offsetX, info.offsetY,
                     info.width, info.height,
                     info.advance,
                     info.maxHeight);

         write(info);
         return result;
     }
 
     private void write(Character c) {
         auto g = getGlyph(c.character);
         auto idx = currentX.countUntil!(x => x + g.advance < this.texture.width);
 
         if (idx == -1) {
             if ((currentX.length + 1) * g.maxHeight < this.texture.height) {
                 idx = cast(int)currentX.length;
                 currentX ~= 0;
             } else {
                 this.texture.resize(this.texture.width * 2, this.texture.height * 2);
                 idx = 0;
             }
         }

         const x = currentX[idx];
         const y = idx * g.maxHeight;
         VkOffset3D dstOffset = {
            x: cast(int)(x+g.offsetX),
            y: cast(int)(y+g.offsetY),
            z: 0
         };
         VkExtent3D dstExtent = {
            width: cast(uint)g.width,
            height: cast(uint)g.height,
            depth: 1
         };

         texture.write(c.bitmap, dstOffset, dstExtent);
 
         g.x = x;
         g.y = y;
         currentX[idx] += g.advance;
     }
 }
