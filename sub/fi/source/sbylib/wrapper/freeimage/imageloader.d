module sbylib.wrapper.freeimage.imageloader;

public import sbylib.wrapper.freeimage.image;
public import sbylib.wrapper.freeimage.constants;

import derelict.freeimage.freeimage;
import sbylib.wrapper.freeimage.freeimage;

import std.format : format;
import std.file : exists;

/** 
  Class for load image.
  This class cannot be instantiated.
*/
class ImageLoader {

    @disable this();

    /**
    Load image.

    The file type is automatically selected.

    Params:
        path = image file path
        loadNoPixels = When this flag is supported by a plugin, load only header data and possibly metadata (including embedded thumbnail). When the flag is not supported, pixels are loaded. 

    Returns: loaded image
    */
    static Image load(string path, bool loadNoPixels = false) {
        const format = getFormat(path);
        assert(format != ImageFormat.Unknown, path ~ " was not found.");

        int option = 0;
        if (loadNoPixels) option |= FIF_LOAD_NOPIXELS;

        auto bitmap = load(format, path, option);
        return new Image(bitmap);
    }

    /**
    Load image as gif.

    When an image which has another file type, assertion error is thrown.

    Params:
        path = image file path
        loadNoPixels = When this flag is supported by a plugin, load only header data and possibly metadata (including embedded thumbnail). When the flag is not supported, pixels are loaded. 
        load256Color = Load the image as a 256 color image with unused palette entries, if it's 16 or 2 color
        playBack = 'Play' the GIF to generate each frame (as 32bpp) instead of returning raw frame data when loading

    Returns: loaded gif image
    */
    static Image loadAsGif(string path, bool loadNoPixels = false, bool load256Color = false, bool playBack = false) {
        return new Image(load(ImageFormat.Gif, path,
                      (loadNoPixels & FIF_LOAD_NOPIXELS) 
                    | (load256Color & GIF_LOAD256)
                    | (playBack     & GIF_PLAYBACK)));
    }

    /**
    Load image as ico.

    When an image which has another file type, assertion error is thrown.

    Params:
        path = image file path
        loadNoPixels = When this flag is supported by a plugin, load only header data and possibly metadata (including embedded thumbnail). When the flag is not supported, pixels are loaded. 
        makeAlpha = Convert to 32-bit and create an alpha channel from the AND-mask when loading

    Returns: loaded ico image
    */
    static Image loadAsIco(string path, bool loadNoPixels = false, bool makeAlpha = false) {
        int option = 0;
        if (loadNoPixels) option |= FIF_LOAD_NOPIXELS;
        if (makeAlpha) option |= ICO_MAKEALPHA;

        return new Image(load(ImageFormat.Ico, path,
                      (loadNoPixels & FIF_LOAD_NOPIXELS)
                    | (makeAlpha & ICO_MAKEALPHA)));
    }

    /**
    Load image as jpeg.

    When an image which has another file type, assertion error is thrown.

    Params:
        path = image file path
        loadNoPixels = When this flag is supported by a plugin, load only header data and possibly metadata (including embedded thumbnail). When the flag is not supported, pixels are loaded. 
        quality = When 'Fast' is selected, load the file as fast as possible, sacrificing some quality. When 'Accurate' is selected, load the file with the best quality, sacrificing some speed
        cmyk = This flag will load CMYK bitmaps as 32-bit separated CMYK
        grayScale = Load and convert to a 8-bit greyscale image (faster than loading as 24-bit and converting to 8-bit)
        scale = Load and resize the file such that size/X = max(width, height)/X will return an image scaled by 2, 4 or 8 (i.e. the most appropriate requested size).
        exifRotate = Load and rotate according to Exif 'Orientation' tag if available

    Returns: loaded jpeg image
    */
    static Image loadAsJpeg(string path, bool loadNoPixels = false, JpegLoadQuality quality = JpegLoadQuality.Fast,
            bool cmyk = false, bool grayScale = false, int scale = 1, bool exifRotate = false) {
        return new Image(load(ImageFormat.Jpeg, path,
                      (loadNoPixels & FIF_LOAD_NOPIXELS)
                    | (quality)
                    | (cmyk         & JPEG_CMYK)
                    | (grayScale    & JPEG_GRAYSCALE)
                    | (scale << 16)
                    | (exifRotate   & JPEG_EXIFROTATE)));
    }

    /**
    Load image as pcd.

    When an image which has another file type, assertion error is thrown.

    Params:
        path = image file path
        loadNoPixels = When this flag is supported by a plugin, load only header data and possibly metadata (including embedded thumbnail). When the flag is not supported, pixels are loaded. 
        option = A PhotoCD picture comes in many sizes. 'Base' will load the one sized 768 x 512

    Returns: loaded pcd image
    */
    static Image loadAsPcd(string path, bool loadNoPixels = false, PcdLoadOption option = PcdLoadOption.Base) {
        return new Image(load(ImageFormat.Pcd, path,
                      (loadNoPixels & FIF_LOAD_NOPIXELS)
                    | (option)));
    }

    /**
    Load image as png.

    When an image which has another file type, assertion error is thrown.

    Params:
        path = image file path
        loadNoPixels = When this flag is supported by a plugin, load only header data and possibly metadata (including embedded thumbnail). When the flag is not supported, pixels are loaded. 
        ignoreGamma = Avoid gamma correction on loading

    Returns: loaded png image
    */
    static Image loadAsPng(string path, bool loadNoPixels = false, bool ignoreGamma = false) {
        return new Image(load(ImageFormat.Png, path,
                      (loadNoPixels & FIF_LOAD_NOPIXELS)
                    | (ignoreGamma  & PNG_IGNOREGAMMA)));
    }

    /**
    Load image as raw.
    By default, load the file as linear RGB 48-bit

    When an image which has another file type, assertion error is thrown.

    Params:
        path = image file path
        loadNoPixels = When this flag is supported by a plugin, load only header data and possibly metadata (including embedded thumbnail). When the flag is not supported, pixels are loaded. 
        preview = Try to load the embedded JPEG preview with included Exif data or default to RGB 24-bit
        display = Load the file as RGB 24-bit
        halfSize = Output a half-size color image
        unprocessed = Output a FIT_UINT16 raw Bayer image

    Returns: loaded raw image
    */
    static Image loadAsRaw(string path, bool loadNoPixels = false,
            bool preview = false, bool display = false, bool halfSize = false, bool unprocessed = false) {
        return new Image(load(ImageFormat.Raw, path, 
                      (loadNoPixels & FIF_LOAD_NOPIXELS)
                    | (preview      & RAW_PREVIEW)
                    | (display      & RAW_DISPLAY)
                    | (halfSize     & RAW_HALFSIZE)
                    | (unprocessed  & RAW_UNPROCESSED)));
    }

    /**
    Load image as targa.

    When an image which has another file type, assertion error is thrown.

    Params:
        path = image file path
        loadNoPixels = When this flag is supported by a plugin, load only header data and possibly metadata (including embedded thumbnail). When the flag is not supported, pixels are loaded. 
        loadRGB888 = If set the loader converts RGB555 and ARGB8888 -> RGB888

    Returns: loaded targa image
    */
    static Image loadAsTarga(string path, bool loadNoPixels = false, bool loadRGB888 = false) {
        return new Image(load(ImageFormat.Targa, path,
                      (loadNoPixels & FIF_LOAD_NOPIXELS)
                    | (loadRGB888   & TARGA_LOAD_RGB888)));
    }

    /**
    Load image as tiff.

    When an image which has another file type, assertion error is thrown.

    Params:
        path = image file path
        loadNoPixels = When this flag is supported by a plugin, load only header data and possibly metadata (including embedded thumbnail). When the flag is not supported, pixels are loaded. 
        cmyk = This flag will load CMYK bitmaps as separated CMYK (default is conversion to RGB)

    Returns: loaded tiff image
    */
    static Image loadAsTiff(string path, bool loadNoPixels = false, bool cmyk = false) {
        return new Image(load(ImageFormat.Tiff, path,
                      (loadNoPixels & FIF_LOAD_NOPIXELS)
                    | (cmyk         & TIFF_CMYK)
                    ));
    }

    static ImageFormat getFormat(string path)
    in (exists(path), format!"'%s' does not exist."(path))
    {
        return FreeImage().getFileType(path);
    }

    private static FIBITMAP* load(ImageFormat format, string path, int option = 0)
    out(result; result, path ~ " exists, but cannot load.")
    {
        return FreeImage().load(format, path, option);
    }

    unittest {
        import std.exception : assertThrown, assertNotThrown;
        import core.exception : AssertError;

        assertThrown!(AssertError)(ImageLoader.loadAsGif("test/dman.png"));
        assertThrown!(AssertError)(ImageLoader.loadAsIco("test/dman.png"));
        assertThrown!(AssertError)(ImageLoader.loadAsJpeg("test/dman.png"));
        assertNotThrown!(AssertError)(ImageLoader.loadAsPcd("test/dman.png"));
        assertNotThrown!(AssertError)(ImageLoader.loadAsPng("test/dman.png"));
        assertThrown!(AssertError)(ImageLoader.loadAsRaw("test/dman.png"));
        assertThrown!(AssertError)(ImageLoader.loadAsTarga("test/dman.png"));
        assertThrown!(AssertError)(ImageLoader.loadAsTiff("test/dman.png"));
    }
}
