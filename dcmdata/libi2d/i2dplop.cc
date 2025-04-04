/*
 *
 *  Copyright (C) 2001-2025, OFFIS e.V.
 *  All rights reserved.  See COPYRIGHT file for details.
 *
 *  This software and supporting documentation were developed by
 *
 *    OFFIS e.V.
 *    R&D Division Health
 *    Escherweg 2
 *    D-26121 Oldenburg, Germany
 *
 *
 *  Module:  dcmdata
 *
 *  Author:  Michael Onken
 *
 *  Purpose: Implements conversion from image into Ophthalmic Photography IODs
 *
 */

#include "dcmtk/config/osconfig.h"    /* make sure OS specific configuration is included first */

#include "dcmtk/dcmdata/libi2d/i2dplop.h"
#include "dcmtk/dcmdata/dcdeftag.h"        /* for DCM_ defines */
#include "dcmtk/dcmdata/dcuid.h"           /* for UID_ defines */
#include "dcmtk/ofstd/ofdatime.h"          /* for OFDateTime */
#include "dcmtk/dcmdata/dcdatset.h"


I2DOutputPlugOphthalmicPhotography::I2DOutputPlugOphthalmicPhotography()
{
  DCMDATA_LIBI2D_DEBUG("I2DOutputPlugOphthalmicPhotography: Output plugin for Ophthalmic Photography IODs initialized");
}


I2DOutputPlugOphthalmicPhotography::~I2DOutputPlugOphthalmicPhotography()
{
}


OFString I2DOutputPlugOphthalmicPhotography::ident()
{
  return "Ophthalmic Photography SOP Classes";
}


void I2DOutputPlugOphthalmicPhotography::supportedSOPClassUIDs(OFList<OFString>& suppSOPs)
{
  suppSOPs.push_back(UID_OphthalmicPhotography8BitImageStorage);
  suppSOPs.push_back(UID_OphthalmicPhotography16BitImageStorage);
}


OFCondition I2DOutputPlugOphthalmicPhotography::convert(DcmDataset &dataset) const
{
  DCMDATA_LIBI2D_DEBUG("I2DOutputPlugOphthalmicPhotography: Inserting Ophthalmic Photography specific attributes");

  // Find out which of the Ophthalmic Photography SOP Classes to use
  Uint16 bitsAllocated;
  OFCondition cond = dataset.findAndGetUint16(DCM_BitsAllocated, bitsAllocated);
  if (cond.bad())
    return makeOFCondition(OFM_dcmdata, 18, OF_error, "I2DOutputPlugOphthalmicPhotography: Unable to determine correct SOP class due to missing Image Pixel module information");

  if (bitsAllocated == 8)
    cond = handle8BitImage(&dataset);
  else if (bitsAllocated == 16)
    cond = handle16BitImage(&dataset);
  else
    cond = makeOFCondition(OFM_dcmdata, 18, OF_error, "I2DOutputPlugOphthalmicPhotography: Bits Allocated needs a value of 8 or 16 for conversion");

  return cond;
}


OFString I2DOutputPlugOphthalmicPhotography::isValid(DcmDataset& dataset) const
{
  OFString err;
  // Just return if checking was disabled
  if (!m_doAttribChecking)
    return err;

  DCMDATA_LIBI2D_DEBUG("I2DOutputPlugOphthalmicPhotography: Checking Ophthalmic Photography specific attributes");

  // compute defaults for some type 1 attributes
  char newUID[70];
  dcmGenerateUniqueIdentifier(newUID);
  OFDateTime now = OFDateTime::getCurrentDateTime();
  OFString contentDate;
  OFString contentTime;
  OFString acquisitionDateTime;
  now.getDate().getISOFormattedDate(contentDate, OFFalse);
  now.getTime().getISOFormattedTime(contentTime, OFFalse, OFFalse, OFFalse, OFFalse);
  now.getISOFormattedDateTime(acquisitionDateTime, OFFalse, OFFalse, OFFalse, OFFalse);

  // check and, if necessary, "invent" type 1 attributes
  err += checkAndInventType1Attrib(DCM_Modality, &dataset, "OP");
  err += checkAndInventType1Attrib(DCM_SynchronizationTrigger, &dataset, "NO TRIGGER");
  err += checkAndInventType1Attrib(DCM_AcquisitionTimeSynchronized, &dataset, "N");
  err += checkAndInventType1Attrib(DCM_InstanceNumber, &dataset, "1");
  err += checkAndInventType1Attrib(DCM_ImageType, &dataset, "ORIGINAL\\PRIMARY");
  err += checkAndInventType1Attrib(DCM_SynchronizationFrameOfReferenceUID, &dataset, newUID);
  err += checkAndInventType1Attrib(DCM_ContentDate, &dataset, contentDate.c_str());
  err += checkAndInventType1Attrib(DCM_ContentTime, &dataset, contentTime.c_str());
  err += checkAndInventType1Attrib(DCM_AcquisitionDateTime, &dataset, acquisitionDateTime.c_str());
  err += checkAndInventType1Attrib(DCM_BurnedInAnnotation, &dataset, "NO");
  err += checkAndInventType1CodeSQ(DCM_AnatomicRegionSequence, &dataset, "Eye", "81745001", "SCT");

  // check type 1 attributes that we cannot "invent"
  err += checkType1Attrib(DCM_ImageLaterality, &dataset);
  err += checkType1Attrib(DCM_AcquisitionDeviceTypeCodeSequence, &dataset);

  // check and, if necessary, add type 2 attributes
  err += checkAndInventType2Attrib(DCM_Manufacturer, &dataset);
  err += checkAndInventType2Attrib(DCM_PatientEyeMovementCommanded, &dataset);
  err += checkAndInventType2Attrib(DCM_HorizontalFieldOfView, &dataset);
  err += checkAndInventType2Attrib(DCM_RefractiveStateSequence, &dataset);
  err += checkAndInventType2Attrib(DCM_EmmetropicMagnification, &dataset);
  err += checkAndInventType2Attrib(DCM_IntraOcularPressure, &dataset);
  err += checkAndInventType2Attrib(DCM_PupilDilated, &dataset);
  err += checkAndInventType2Attrib(DCM_IlluminationTypeCodeSequence, &dataset);
  err += checkAndInventType2Attrib(DCM_LightPathFilterTypeStackCodeSequence, &dataset);
  err += checkAndInventType2Attrib(DCM_ImagePathFilterTypeStackCodeSequence, &dataset);
  err += checkAndInventType2Attrib(DCM_LensesCodeSequence, &dataset);
  err += checkAndInventType2Attrib(DCM_DetectorType, &dataset);

  return err;
}


OFCondition I2DOutputPlugOphthalmicPhotography::handle8BitImage(DcmDataset *dataset) const
{
  if (!dataset)
    return EC_IllegalParameter;

  OFCondition cond; Uint16 u16 = 0; OFString str;
  cond = dataset->findAndGetOFStringArray(DCM_PhotometricInterpretation, str);
  if (cond.bad())
    return makeOFCondition(OFM_dcmdata, 18, OF_error, "I2DOutputPlugOphthalmicPhotography: Photometric Interpretation not set for Pixel Data");

  if (str == "MONOCHROME2")
  {
    cond = dataset->findAndGetUint16(DCM_SamplesPerPixel, u16);
    if (cond.bad() || (u16 != 1))
      return makeOFCondition(OFM_dcmdata, 18, OF_error, "I2DOutputPlugOphthalmicPhotography: Samples Per Pixel does not fit SOP class");

    cond = dataset->findAndGetUint16(DCM_BitsStored, u16);
    if (cond.bad() || (u16 != 8))
      return makeOFCondition(OFM_dcmdata, 18, OF_error, "I2DOutputPlugOphthalmicPhotography: Bits Stored does not fit SOP class");

    cond = dataset->findAndGetUint16(DCM_HighBit, u16);
    if (cond.bad() || (u16 != 7))
      return makeOFCondition(OFM_dcmdata, 18, OF_error, "I2DOutputPlugOphthalmicPhotography: High Bit does not fit SOP class");

    cond = dataset->findAndGetUint16(DCM_PixelRepresentation, u16);
    if (cond.bad() || (u16 != 0))
      return makeOFCondition(OFM_dcmdata, 18, OF_error, "I2DOutputPlugOphthalmicPhotography: Pixel Representation does not fit SOP class");

    // Insert Presentation LUT Shape
    if (cond.good())
      cond = dataset->putAndInsertString(DCM_PresentationLUTShape, "IDENTITY");

  }
  else if ((str == "YBR_FULL_422") || (str == "RGB"))
  {
    cond = dataset->findAndGetUint16(DCM_SamplesPerPixel, u16);
    if (cond.bad() || (u16 != 3))
      return makeOFCondition(OFM_dcmdata, 18, OF_error, "I2DOutputPlugOphthalmicPhotography: Samples Per Pixel does not fit SOP class");

    cond = dataset->findAndGetUint16(DCM_BitsStored, u16);
    if (cond.bad() || (u16 != 8))
      return makeOFCondition(OFM_dcmdata, 18, OF_error, "I2DOutputPlugOphthalmicPhotography: Bits Stored does not fit SOP class");

    cond = dataset->findAndGetUint16(DCM_HighBit, u16);
    if (cond.bad() || (u16 != 7))
      return makeOFCondition(OFM_dcmdata, 18, OF_error, "I2DOutputPlugOphthalmicPhotography: High Bit does not fit SOP class");

    cond = dataset->findAndGetUint16(DCM_PixelRepresentation, u16);
    if (cond.bad() || (u16 != 0))
      return makeOFCondition(OFM_dcmdata, 18, OF_error, "I2DOutputPlugOphthalmicPhotography: Pixel Representation does not fit SOP class");

    cond = dataset->findAndGetUint16(DCM_PlanarConfiguration, u16);
    if (cond.bad() || (u16 != 0))
      return makeOFCondition(OFM_dcmdata, 18, OF_error, "I2DOutputPlugOphthalmicPhotography: Planar Configuration does not fit SOP class");
  }
  else
    return makeOFCondition(OFM_dcmdata, 18, OF_error, "I2DOutputPlugOphthalmicPhotography: Photometric Interpretation does not fit SOP class");

  // Insert SOP Class UID
  if (cond.good())
    cond = dataset->putAndInsertString(DCM_SOPClassUID, UID_OphthalmicPhotography8BitImageStorage);

  // Lossy Image Compression is Type 1 for this SOP Class. If it is not yet present (i.e. the image was
  // not converted from a lossy input format such as JPEG), mark it as not lossy compressed.
  if (cond.good() && (! dataset->tagExists(DCM_LossyImageCompression)))
  {
    cond = dataset->putAndInsertString(DCM_LossyImageCompression, "00");
  }

  return cond;
}


OFCondition I2DOutputPlugOphthalmicPhotography::handle16BitImage(DcmDataset *dataset) const
{
  if (!dataset)
    return EC_IllegalParameter;

  OFCondition cond; Uint16 u16 = 0; OFString str;
  cond = dataset->findAndGetOFStringArray(DCM_PhotometricInterpretation, str);
  if (cond.bad())
    return makeOFCondition(OFM_dcmdata, 18, OF_error, "I2DOutputPlugOphthalmicPhotography: Photometric Interpretation not set for Pixel Data");
  if (str == "MONOCHROME2")
  {
    cond = dataset->findAndGetUint16(DCM_SamplesPerPixel, u16);
    if (cond.bad() || (u16 != 1))
      return makeOFCondition(OFM_dcmdata, 18, OF_error, "I2DOutputPlugOphthalmicPhotography: Samples Per Pixel does not fit SOP class");

    cond = dataset->findAndGetUint16(DCM_BitsStored, u16);
    if (cond.bad() || (u16 != 16))
      return makeOFCondition(OFM_dcmdata, 18, OF_error, "I2DOutputPlugOphthalmicPhotography: Bits Stored does not fit SOP class");

    cond = dataset->findAndGetUint16(DCM_HighBit, u16);
    if (cond.bad() || (u16 != 15))
      return makeOFCondition(OFM_dcmdata, 18, OF_error, "I2DOutputPlugOphthalmicPhotography: High Bit does not fit SOP class");

    cond = dataset->findAndGetUint16(DCM_PixelRepresentation, u16);
    if (cond.bad() || (u16 != 0))
      return makeOFCondition(OFM_dcmdata, 18, OF_error, "I2DOutputPlugOphthalmicPhotography: Pixel Representation does not fit SOP class");

    // Insert Presentation LUT Shape
    if (cond.good())
      cond = dataset->putAndInsertString(DCM_PresentationLUTShape, "IDENTITY");
  }
  else if ((str == "YBR_FULL_422") || (str == "RGB"))
  {
    cond = dataset->findAndGetUint16(DCM_SamplesPerPixel, u16);
    if (cond.bad() || (u16 != 3))
      return makeOFCondition(OFM_dcmdata, 18, OF_error, "I2DOutputPlugOphthalmicPhotography: Samples Per Pixel does not fit SOP class");

    cond = dataset->findAndGetUint16(DCM_BitsStored, u16);
    if (cond.bad() || (u16 != 16))
      return makeOFCondition(OFM_dcmdata, 18, OF_error, "I2DOutputPlugOphthalmicPhotography: Bits Stored does not fit SOP class");

    cond = dataset->findAndGetUint16(DCM_HighBit, u16);
    if (cond.bad() || (u16 != 15))
      return makeOFCondition(OFM_dcmdata, 18, OF_error, "I2DOutputPlugOphthalmicPhotography: High Bit does not fit SOP class");

    cond = dataset->findAndGetUint16(DCM_PixelRepresentation, u16);
    if (cond.bad() || (u16 != 0))
      return makeOFCondition(OFM_dcmdata, 18, OF_error, "I2DOutputPlugOphthalmicPhotography: Pixel Representation does not fit SOP class");

    cond = dataset->findAndGetUint16(DCM_PlanarConfiguration, u16);
    if (cond.bad() || (u16 != 0))
      return makeOFCondition(OFM_dcmdata, 18, OF_error, "I2DOutputPlugOphthalmicPhotography: Planar Configuration does not fit SOP class");
  }
  else
    return makeOFCondition(OFM_dcmdata, 18, OF_error, "I2DOutputPlugOphthalmicPhotography: Photometric Interpretation does not fit SOP class");

  // Insert SOP Class UID
  if (cond.good())
    cond = dataset->putAndInsertString(DCM_SOPClassUID, UID_OphthalmicPhotography16BitImageStorage);

  // Lossy Image Compression is Type 1 for this SOP Class. If it is not yet present (i.e. the image was
  // not converted from a lossy input format such as JPEG), mark it as not lossy compressed.
  if (cond.good() && (! dataset->tagExists(DCM_LossyImageCompression)))
  {
    cond = dataset->putAndInsertString(DCM_LossyImageCompression, "00");
  }

  return cond;
}


OFBool I2DOutputPlugOphthalmicPhotography::supportsMultiframe() const
{
  return OFTrue;
}


OFBool I2DOutputPlugOphthalmicPhotography::colorModelPermitted(const OFString& photometricInterpretation, E_TransferSyntax outputTS) const
{
    if (photometricInterpretation == "MONOCHROME2") return OFTrue;

    // DICOM part 3, C.8.17.2.1.3:
    // When Samples per Pixel (0028,0002) is greater than 1,
    // Photometric Interpretation (0028,0004) shall be RGB for uncompressed or lossless compressed Transfer Syntaxes that do not have defined color space transformations,
    // YBR_ICT for irreversible JPEG 2000 Transfer Syntaxes,
    // YBR_RCT for reversible JPEG 2000 Transfer Syntaxes,
    // YBR_PARTIAL_420 for MPEG2, MPEG-4 AVC/H.264, HEVC/H.265 Transfer Syntaxes and
    // YBR_FULL_422 for JPEG lossy compressed Transfer Syntaxes.
    // Note that YBR_FULL is explicitly not permitted for RLE in this SOP class.
    switch(outputTS)
    {
        case EXS_JPEG2000:
        case EXS_JPEG2000Multicomponent:
        case EXS_HighThroughputJPEG2000:
            return (photometricInterpretation == "YBR_ICT");
            /* break; */
        case EXS_JPEG2000LosslessOnly:
        case EXS_JPEG2000MulticomponentLosslessOnly:
        case EXS_HighThroughputJPEG2000LosslessOnly:
        case EXS_HighThroughputJPEG2000withRPCLOptionsLosslessOnly:
            return (photometricInterpretation == "YBR_RCT");
            /* break; */
        case EXS_MPEG2MainProfileAtMainLevel:
        case EXS_FragmentableMPEG2MainProfileMainLevel:
        case EXS_MPEG2MainProfileAtHighLevel:
        case EXS_FragmentableMPEG2MainProfileHighLevel:
        case EXS_MPEG4HighProfileLevel4_1:
        case EXS_FragmentableMPEG4HighProfileLevel4_1:
        case EXS_MPEG4BDcompatibleHighProfileLevel4_1:
        case EXS_FragmentableMPEG4BDcompatibleHighProfileLevel4_1:
        case EXS_MPEG4HighProfileLevel4_2_For2DVideo:
        case EXS_FragmentableMPEG4HighProfileLevel4_2_For2DVideo:
        case EXS_MPEG4HighProfileLevel4_2_For3DVideo:
        case EXS_FragmentableMPEG4HighProfileLevel4_2_For3DVideo:
        case EXS_MPEG4StereoHighProfileLevel4_2:
        case EXS_FragmentableMPEG4StereoHighProfileLevel4_2:
        case EXS_HEVCMainProfileLevel5_1:
        case EXS_HEVCMain10ProfileLevel5_1:
            return (photometricInterpretation == "YBR_PARTIAL_420");
            /* break; */
        case EXS_JPEGProcess1:
        case EXS_JPEGProcess2_4:
        case EXS_JPEGProcess3_5:
        case EXS_JPEGProcess6_8:
        case EXS_JPEGProcess7_9:
        case EXS_JPEGProcess10_12:
        case EXS_JPEGProcess11_13:
        case EXS_JPEGProcess16_18:
        case EXS_JPEGProcess17_19:
        case EXS_JPEGProcess20_22:
        case EXS_JPEGProcess21_23:
        case EXS_JPEGProcess24_26:
        case EXS_JPEGProcess25_27:
            return (photometricInterpretation == "YBR_FULL_422");
            /* break; */
        case EXS_JPEGXLLossless:
        case EXS_JPEGXLJPEGRecompression:
        case EXS_JPEGXL:
            // DICOM part 3 does not (yet) specify any requirements for this IOD and JPEG-XL.
            return OFTrue;
            /* break; */
        default:
            return (photometricInterpretation == "RGB");
            /* break; */
    }
}


OFCondition I2DOutputPlugOphthalmicPhotography::updateColorModel(OFString& photometricInterpretation, E_TransferSyntax outputTS) const
{
    if (photometricInterpretation == "MONOCHROME2") return EC_Normal;
    switch(outputTS)
    {
        case EXS_JPEG2000:
        case EXS_JPEG2000Multicomponent:
        case EXS_HighThroughputJPEG2000:
            if (photometricInterpretation == "YBR_ICT") return EC_Normal; else return makeOFCondition(OFM_dcmdata, 18, OF_error, "Unsupported color model");
            /* break; */
        case EXS_JPEG2000LosslessOnly:
        case EXS_JPEG2000MulticomponentLosslessOnly:
        case EXS_HighThroughputJPEG2000LosslessOnly:
        case EXS_HighThroughputJPEG2000withRPCLOptionsLosslessOnly:
            if (photometricInterpretation == "YBR_RCT") return EC_Normal; else return makeOFCondition(OFM_dcmdata, 18, OF_error, "Unsupported color model");
            /* break; */
        case EXS_MPEG2MainProfileAtMainLevel:
        case EXS_FragmentableMPEG2MainProfileMainLevel:
        case EXS_MPEG2MainProfileAtHighLevel:
        case EXS_FragmentableMPEG2MainProfileHighLevel:
        case EXS_MPEG4HighProfileLevel4_1:
        case EXS_FragmentableMPEG4HighProfileLevel4_1:
        case EXS_MPEG4BDcompatibleHighProfileLevel4_1:
        case EXS_FragmentableMPEG4BDcompatibleHighProfileLevel4_1:
        case EXS_MPEG4HighProfileLevel4_2_For2DVideo:
        case EXS_FragmentableMPEG4HighProfileLevel4_2_For2DVideo:
        case EXS_MPEG4HighProfileLevel4_2_For3DVideo:
        case EXS_FragmentableMPEG4HighProfileLevel4_2_For3DVideo:
        case EXS_MPEG4StereoHighProfileLevel4_2:
        case EXS_FragmentableMPEG4StereoHighProfileLevel4_2:
        case EXS_HEVCMainProfileLevel5_1:
        case EXS_HEVCMain10ProfileLevel5_1:
            if (photometricInterpretation == "YBR_PARTIAL_420") return EC_Normal; else return makeOFCondition(OFM_dcmdata, 18, OF_error, "Unsupported color model");
            /* break; */
        case EXS_JPEGProcess1:
        case EXS_JPEGProcess2_4:
        case EXS_JPEGProcess3_5:
        case EXS_JPEGProcess6_8:
        case EXS_JPEGProcess7_9:
        case EXS_JPEGProcess10_12:
        case EXS_JPEGProcess11_13:
        case EXS_JPEGProcess16_18:
        case EXS_JPEGProcess17_19:
        case EXS_JPEGProcess20_22:
        case EXS_JPEGProcess21_23:
        case EXS_JPEGProcess24_26:
        case EXS_JPEGProcess25_27:
            // silently replace "YBR_FULL" by "YBR_FULL_422". Most JPEG codecs won't mind.
            if (photometricInterpretation == "YBR_FULL")
            {
                photometricInterpretation = "YBR_FULL_422";
                return EC_Normal;
            }
            else if (photometricInterpretation == "YBR_FULL_422") return EC_Normal;
            else return makeOFCondition(OFM_dcmdata, 18, OF_error, "Unsupported color model");
            /* break; */
        case EXS_JPEGXLLossless:
        case EXS_JPEGXLJPEGRecompression:
        case EXS_JPEGXL:
            // DICOM part 3 does not (yet) specify any requirements for this IOD and JPEG-XL.
            return EC_Normal;
            /* break; */
        default:
            if (photometricInterpretation == "RGB") return EC_Normal; else return makeOFCondition(OFM_dcmdata, 18, OF_error, "Unsupported color model");
            /* break; */
    }
}


OFCondition I2DOutputPlugOphthalmicPhotography::insertMultiFrameAttributes(
  DcmDataset* targetDataset,
  size_t numberOfFrames) const
{
  if ((!targetDataset) || (numberOfFrames == 0))
    return EC_IllegalParameter;

  char numFrames[30];
  char frameTime[30];
  size_t fTime = (numberOfFrames > 1) ? DCMTK_I2D_Default_Frame_Time : 0;
  OFStandard::snprintf(numFrames, 30, "%lu", numberOfFrames);
  OFStandard::snprintf(frameTime, 30, "%lu", fTime);
  OFCondition cond = targetDataset->putAndInsertOFStringArray(DCM_NumberOfFrames, numFrames);
  if (cond.good()) cond = targetDataset->putAndInsertOFStringArray(DCM_FrameTime, frameTime);
  if (cond.good()) cond = targetDataset->putAndInsertTagKey(DCM_FrameIncrementPointer, DCM_FrameTime);
  return cond;
}
