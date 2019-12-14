module sbylib.wrapper.freeimage.image;

import derelict.freeimage.freeimage;
import sbylib.wrapper.freeimage.freeimage;

public import sbylib.wrapper.freeimage.constants;

import std.format : format;

/** 
  Class represented FIBITMAP.
*/
class Image {

    private FIBITMAP* bitmap;

    /**
    Constructor by image size and image type.

    Params:
        width = image width
        height = image height
        type = flag used to specify the bitmap type 
    */
    this(int width, int height, ImageType type) {
        this(FreeImage().allocate(width, height, type));
    }

    /**
    Constructor by image size and bpp.
    
    Params:
        width = image width
        height = image height
        bpp = number to specify the bit depth of the image
    */
    this(int width, int height, int bpp) {
        this(FreeImage().allocate(width, height, bpp));
    }

    package this(FIBITMAP* bitmap)
        in(bitmap !is null)
    {
        this.bitmap = bitmap;
    }

    ~this() {
        FreeImage().unload(this.bitmap);
    }

    /**
    Load image.
    This function is same as ImageLoader.load.

    Params:
        path = image file path

    Returns: loaded image

    See_Also: ImageLoader.load
    */
    static Image load(string path) {
        import sbylib.wrapper.freeimage.imageloader : ImageLoader;

        return ImageLoader.load(path);
    }

    /**
    Converts a bitmap to 32 bits. A clone of the input bitmap is returned for 32-bit bitmaps.
    For 48-bit RGB images, conversion is done by dividing each 16-bit channel by 256 and by setting the alpha channel to an opaque value (0xFF). For 64-bit RGBA images, conversion is done by dividing each 16-bit channel by 256. A NULL value is returned for other nonstandard bitmap types.

    Returns: conveted image
    */
    Image to32bit() {
        return new Image(FreeImage().convertTo32Bits(bitmap));
    }

    /**
    Returns the width of the bitmap in pixel units.

    Returns: the width of the bitmap in pixel units
    */
    int width() {
        return FreeImage().getWidth(bitmap);
    }

    /**
    Returns the height of the bitmap in pixel units.

    Returns: the height of the bitmap in pixel units
    */
    int height() {
        return FreeImage().getHeight(bitmap);
    }

    /**
    Returns the size of one pixel in the bitmap in bits. For example when each pixel takes 32-bits of space in the bitmap, this function returns 32. Possible bit depths are 1, 4, 8, 16, 24, 32 for standard bitmaps and 16-, 32-, 48-, 64-, 96- and 128-bit for non standard bitmaps. 

    Returns: the bit depth of the bitmap
    */
    uint bpp() {
        return FreeImage().getBPP(bitmap);
    }

    /**
    Returns how many channels the image has.
    This is calculated by (bpp) / (1 channel bits).
    1 channel bits is estimated by image type.

    Returns: the channels of the image
    */
    uint channels() {
        return bpp / getTypeBits(imageType);
    }

    /**
    Returns the raw pointer to the image data for low level API.

    Returns: the pointer to the raw image data.
    */
    void* rawPointer() {
        return FreeImage().getBits(bitmap);
    }

    RGBQUAD* palette() {
        return FreeImage().getPalette(bitmap);
    }

    /**
    Returns the raw image data as T[].

    Returns: an array pointing to the raw data.
    */
    T[] dataArray(T=ubyte)() {
        return (cast(T*)rawPointer)[0..width * height * bpp / (8*T.sizeof)];
    }

    /**
    Returns the type of the image.

    Returns: the type of the image
    */
    ImageType imageType() {
        import std.conv : to;
        return FreeImage_GetImageType(bitmap).to!ImageType;
    }

    /**
    Save the image.
    The extension is estimated by the output path.

    Params:
        path = where the image is saved
    */
    void save(string path) {
        import std.path : extension;

        switch(path.extension) {
            case ".bmp":
                saveAsBmp(path);
                break;
            case ".exr":
                saveAsExr(path);
                break;
            case ".jpeg":
            case ".jpg":
                saveAsJpeg(path);
                break;
            case ".png":
                saveAsPng(path);
                break;
            case ".tiff":
                saveAsTiff(path);
                break;
            default:
                assert(false, "Unrecognized format '" ~ path.extension ~ "'");
        }
    }

    /**
    Save the image as bmp.

    Params:
        path = where the image is saved
        rle = compress the bitmap using RLE when saving
    */
    void saveAsBmp(string path, bool rle = false) {
        save(ImageFormat.Bmp, path, (rle ? BMP_SAVE_RLE : BMP_DEFAULT));
    }

    /**
    Save the image as exr.

    Params:
        path = where the image is saved
        saveAs32Bit = save data as float instead of as half (not recommended)
        compress = compression method

    See_Also: ExrCompressOption
    */
    void saveAsExr(string path, bool saveAs32Bit = false, ExrCompressOption compress = ExrCompressOption.None) {
        save(ImageFormat.Exr, path,
                  (saveAs32Bit ? EXR_FLOAT : EXR_DEFAULT)
                | (compress));
    }

    /**
    Save the image as j2k.

    Params:
        path = where the image is saved
        rate = Save with a rate:1
    */
    void saveAsJ2k(string path, int rate = J2K_DEFAULT)
    in(1 <= rate && rate <= 512)
    {
        save(ImageFormat.J2k, path, rate);
    }

    /**
    Save the image as jp2.

    Params:
        path = where the image is saved
        rate = Save with a rate:1
    */
    void saveAsJp2(string path, int rate = JP2_DEFAULT)
    in(1 <= rate && rate <= 512)
    {
        save(ImageFormat.Jp2, path, rate);
    }

    /**
    Save the image as jpeg.

    Params:
        path = where the image is saved
        quality = save quality(%)
        progressive = save as a progressive JPEG file 
        subsampling = for SubSampling4ab, save with 4:a:b
        optimize = On saving, compute optimal Huffman coding tables (can reduce a few percent of file size)
        baseline = Save basic JPEG, without metadata or any markers 
    */
    void saveAsJpeg(string path, int quality = 75, bool progressive = false, 
            JpegSaveSubsamplingOption subsampling = JpegSaveSubsamplingOption.Subsampling420,
            bool optimize = false, bool baseline = false)
    in(0 <= quality && quality <= 100)
    {
        save(ImageFormat.Jpeg, path, 
                quality
                | (progressive & JPEG_PROGRESSIVE)
                | (subsampling)
                | (optimize & JPEG_OPTIMIZE)
                | (baseline & JPEG_BASELINE));
    }

    /**
    Save the image as png.

    Params:
        path = where the image is saved
        compress = compression level
        interlace = Save using Adam7 interlacing 
    */
    void saveAsPng(string path,
            PngCompressOption compress = PngCompressOption.DefaultCompression, bool interlace = false) {
        save(ImageFormat.Png, path,
                  (compress)
                | (interlace & PNG_INTERLACED));
    }

    /**
    Save the image as pbm.

    Params:
        path = where the image is saved
        option = Saves the bitmap as a binary file or an ascii file
    */
    void saveAsPbm(string path, PnmSaveOption option = PnmSaveOption.Raw) {
        save(ImageFormat.Pbm, path, option);
    }

    /**
    Save the image as pgm.

    Params:
        path = where the image is saved
        option = Saves the bitmap as a binary file or an ascii file
    */
    void saveAsPgm(string path, PnmSaveOption option = PnmSaveOption.Raw) {
        save(ImageFormat.Pgm, path, option);
    }

    /**
    Save the image as ppm.

    Params:
        path = where the image is saved
        option = Saves the bitmap as a binary file or an ascii file
    */
    void saveAsPpm(string path, PnmSaveOption option = PnmSaveOption.Raw) {
        save(ImageFormat.Ppm, path, option);
    }

    /**
    Save the image as tiff.

    Params:
        path = where the image is saved
        cmyk = Stores tags for separated CMYK (use | to combine with
TIFF compression flags)
        compress = compression level
    */
    void saveAsTiff(string path, bool cmyk = false, TiffCompressOption compress = TiffCompressOption.LZW) {
        save(ImageFormat.Tiff, path,
                  (cmyk & TIFF_CMYK)
                | (compress));
    }

    private void save(ImageFormat fmt, string path, int option = 0) {
        import std.string : toStringz;

        const saveResult = FreeImage_Save(fmt, bitmap, path.toStringz, option);

        assert(saveResult, format!"Failed to Save '%s'"(path));
    }

    private static int getTypeBits(ImageType type) {
        final switch(type) {
            case ImageType.Unknown: assert(false, format!"Invalid Enum: %s"(type));
            case ImageType.Bitmap: return 8;
            case ImageType.Rgb16: return 16;
            case ImageType.Rgba16: return 16;
            case ImageType.Rgbf: return 32;
            case ImageType.Rgbaf: return 32;
            case ImageType.Uint16: return 16;
            case ImageType.Int16: return 16;
            case ImageType.Uint32: return 32;
            case ImageType.Int32: return 32;
            case ImageType.Float: return 32;
            case ImageType.Double: return 64;
            case ImageType.Complex: return 128;
        }
    }
}
