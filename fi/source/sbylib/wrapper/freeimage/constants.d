module sbylib.wrapper.freeimage.constants;

import derelict.freeimage.freeimage;

/**
Type which is returned by Image.getImageType
*/
enum ImageType {
    Unknown = FIT_UNKNOWN,
    Bitmap = FIT_BITMAP,
    Uint16 = FIT_UINT16,
    Int16 = FIT_INT16,
    Uint32 = FIT_UINT32,
    Int32 = FIT_INT32,
    Float = FIT_FLOAT,
    Double = FIT_DOUBLE,
    Complex = FIT_COMPLEX,
    Rgb16 = FIT_RGB16,
    Rgba16 = FIT_RGBA16,
    Rgbf = FIT_RGBF,
    Rgbaf = FIT_RGBAF
}

package enum ImageFormat {
    Unknown = FIF_UNKNOWN,
    Bmp = FIF_BMP,
    Cut = FIF_CUT,
    Dds = FIF_DDS,
    Exr = FIF_EXR,
    FaxG3 = FIF_FAXG3,
    Gif = FIF_GIF,
    Hdr = FIF_HDR,
    Ico = FIF_ICO,
    Iff = FIF_IFF,
    J2k = FIF_J2K,
    Jng = FIF_JNG,
    Jp2 = FIF_JP2,
    Jpeg = FIF_JPEG,
    Koala = FIF_KOALA,
    Mng = FIF_MNG,
    Pbm = FIF_PBM,
    PbmRaw = FIF_PBMRAW,
    Pcd = FIF_PCD,
    Pcx = FIF_PCX,
    Pfm = FIF_PFM,
    Pgm = FIF_PGM,
    PgmRaw = FIF_PGMRAW,
    Pict = FIF_PICT,
    Png = FIF_PNG,
    Ppm = FIF_PPM,
    PpmRaw = FIF_PPMRAW,
    Psd = FIF_PSD,
    Ras = FIF_RAS,
    Raw = FIF_RAW,
    Sgi = FIF_SGI,
    Targa = FIF_TARGA,
    Tiff = FIF_TIFF,
    Wbmp = FIF_WBMP,
    Xbm = FIF_XBM,
    Xpm = FIF_XPM
}

/**
Flag type used in ImageLoader.loadAsJpeg
*/
enum JpegLoadQuality {
    Fast = JPEG_FAST,
    Accurate = JPEG_ACCURATE,
}

/**
Flag type used in ImageLoader.loadAsPcd
*/
enum PcdLoadOption {
    Base = PCD_BASE,
    BaseDiv4 = PCD_BASEDIV4,
    BaseDiv16 = PCD_BASEDIV16,
}

/**
Flag type used in Image.saveAsExr
*/
enum ExrCompressOption {
    None = EXR_NONE,
    Zip = EXR_ZIP,
    Piz = EXR_PIZ,
    Pxr24 = EXR_PXR24,
    B44 = EXR_B44,
    LC = EXR_LC,
}

/**
Flag type used in Image.saveAsJpeg
*/
enum JpegSaveQualityOption {
    Default = JPEG_DEFAULT,
    Superb = JPEG_QUALITYSUPERB,
    Good = JPEG_QUALITYGOOD,
    Normal = JPEG_QUALITYNORMAL,
    Average = JPEG_QUALITYAVERAGE,
    Bad = JPEG_QUALITYBAD,
}

/**
Flag type used in Image.saveAsJpeg
*/
enum JpegSaveSubsamplingOption {
    Subsampling411 = JPEG_SUBSAMPLING_411,
    Subsampling420 = JPEG_SUBSAMPLING_420,
    Subsampling422 = JPEG_SUBSAMPLING_422,
    Subsampling444 = JPEG_SUBSAMPLING_444,
}

/**
Flag type used in Image.saveAsPng
*/
enum PngCompressOption {
    BestSpeed = PNG_Z_BEST_SPEED,
    DefaultCompression = PNG_Z_DEFAULT_COMPRESSION,
    BestCompression = PNG_Z_BEST_COMPRESSION,
    NoCompression = PNG_Z_NO_COMPRESSION,
}

/**
Flag type used in Image.saveAsPbm, Image.saveAsPgm, Image.saveAsPpm
*/
enum PnmSaveOption {
    Raw = PNM_SAVE_RAW,
    Ascii = PNM_SAVE_ASCII
}

/**
Flag type used in Image.saveAsTiff
*/
enum TiffCompressOption {
    PackBits = TIFF_PACKBITS,
    Deflate = TIFF_DEFLATE,
    AdobeDeflate = TIFF_ADOBE_DEFLATE,
    None = TIFF_NONE,
    CCITT_Fax3 = TIFF_CCITTFAX3,
    CCITT_Fax4 = TIFF_CCITTFAX4,
    LZW = TIFF_LZW,
    Jpeg = TIFF_JPEG,
}
