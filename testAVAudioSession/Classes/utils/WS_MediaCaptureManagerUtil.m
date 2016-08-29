//
//  WS_MediaCaptureManagerUtil.m
//  testAVAudioSession
//
//  Created by wsliang on 16/8/29.
//  Copyright © 2016年 wsliang. All rights reserved.
//

#import "WS_MediaCaptureManagerUtil.h"

@implementation WS_MediaCaptureManagerUtil



#if SUPPORT_AAC_ENCODER


//-(BOOL)setupAssetWriterAudioInput:(CMFormatDescriptionRef)currentFormatDescription
//{
//  const AudioStreamBasicDescription *currentASBD = CMAudioFormatDescriptionGetStreamBasicDescription(currentFormatDescription);
//
//  size_t aclSize = 0;
//  const AudioChannelLayout *currentChannelLayout = CMAudioFormatDescriptionGetChannelLayout(currentFormatDescription, &aclSize);
//  NSData *currentChannelLayoutData = nil;
//
//  // AVChannelLayoutKey must be specified, but if we don't know any better give an empty data and let AVAssetWriter decide.
//  if ( currentChannelLayout && aclSize > 0 )
//    currentChannelLayoutData = [NSData dataWithBytes:currentChannelLayout length:aclSize];
//  else
//    currentChannelLayoutData = [NSData data];
//
//  NSDictionary *audioCompressionSettings = [NSDictionary dictionaryWithObjectsAndKeys:
//                                            [NSNumber numberWithInteger:kAudioFormatMPEG4AAC], AVFormatIDKey,
//                                            [NSNumber numberWithFloat:currentASBD->mSampleRate], AVSampleRateKey,
//                                            [NSNumber numberWithInt:44100], AVEncoderBitRatePerChannelKey,
//                                            [NSNumber numberWithInteger:currentASBD->mChannelsPerFrame], AVNumberOfChannelsKey,
//                                            currentChannelLayoutData, AVChannelLayoutKey,
//                                            nil];
//
//  if ([assetWriter canApplyOutputSettings:audioCompressionSettings forMediaType:AVMediaTypeAudio]) {
//
//    assetWriterAudioIn = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio outputSettings:audioCompressionSettings];
//    assetWriterAudioIn.expectsMediaDataInRealTime = YES;
//    if ([assetWriter canAddInput:assetWriterAudioIn]) {
//      [assetWriter addInput:assetWriterAudioIn];
//      NSLog(@"add asset writer audio input.");
//    } else {
//      NSLog(@"Couldn't add asset writer audio input.");
//      return NO;
//    }
//  }
//  else {
//    NSLog(@"Couldn't apply audio output settings.");
//    return NO;
//  }
//
//  return YES;
//}
//
//
//-(BOOL)createAudioConvert:(CMSampleBufferRef)sampleBuffer { //根据输入样本初始化一个编码转换器
//  if (m_converter != NULL) { return TRUE; }
//
//  AudioStreamBasicDescription inputFormat = *(CMAudioFormatDescriptionGetStreamBasicDescription(CMSampleBufferGetFormatDescription(sampleBuffer))); // 输入音频格式
//  AudioStreamBasicDescription outputFormat; // 这里开始是输出音频格式
//  memset(&outputFormat, 0, sizeof(outputFormat));
//  outputFormat.mSampleRate       = inputFormat.mSampleRate; // 采样率保持一致
//  outputFormat.mFormatID         = kAudioFormatMPEG4AAC;    // AAC编码
//  outputFormat.mChannelsPerFrame = 2;
//  outputFormat.mFramesPerPacket  = 1024;                    // AAC一帧是1024个字节
//
//  AudioClassDescription *desc = [self getAudioClassDescriptionWithType:kAudioFormatMPEG4AAC fromManufacturer:kAppleSoftwareAudioCodecManufacturer];
//  if (AudioConverterNewSpecific(&inputFormat, &outputFormat, 1, desc, &m_converter) != noErr)
//  {
//    NSLog(@"AudioConverterNewSpecific failed");
//    return NO;
//  }
//  return YES;
//}
//
//-(BOOL)encoderAAC:(CMSampleBufferRef)sampleBuffer aacData:(char*)aacData aacLen:(int*)aacLen { // 编码PCM成AAC
//  if ([self createAudioConvert:sampleBuffer] != YES)
//  {
//    return NO;
//  }
//
//  CMBlockBufferRef blockBuffer = nil;
//  AudioBufferList  inBufferList;
//  if (CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer, NULL, &inBufferList, sizeof(inBufferList), NULL, NULL, 0, &blockBuffer) != noErr)
//  {
//    CKPrint(@"CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer failed");
//    return NO;
//  }
//  // 初始化一个输出缓冲列表
//  AudioBufferList outBufferList;
//  outBufferList.mNumberBuffers              = 1;
//  outBufferList.mBuffers[0].mNumberChannels = 2;
//  outBufferList.mBuffers[0].mDataByteSize   = *aacLen; // 设置缓冲区大小
//  outBufferList.mBuffers[0].mData           = aacData; // 设置AAC缓冲区
//  UInt32 outputDataPacketSize               = 1;
//  if (AudioConverterFillComplexBuffer(m_converter, inputDataProc, &inBufferList, &outputDataPacketSize, &outBufferList, NULL) != noErr)
//  {
//    CKPrint(@"AudioConverterFillComplexBuffer failed");
//    return NO;
//  }
//
//  *aacLen = outBufferList.mBuffers[0].mDataByteSize; //设置编码后的AAC大小
//  CFRelease(blockBuffer);
//  return YES;
//}
//
//-(AudioClassDescription*)getAudioClassDescriptionWithType:(UInt32)type fromManufacturer:(UInt32)manufacturer { // 获得相应的编码器
//  static AudioClassDescription audioDesc;
//
//  UInt32 encoderSpecifier = type, size = 0;
//  OSStatus status;
//
//  memset(&audioDesc, 0, sizeof(audioDesc));
//  status = AudioFormatGetPropertyInfo(kAudioFormatProperty_Encoders, sizeof(encoderSpecifier), &encoderSpecifier, &size);
//  if (status)
//  {
//    return nil;
//  }
//
//  uint32_t count = size / sizeof(AudioClassDescription);
//  AudioClassDescription descs[count];
//  status = AudioFormatGetProperty(kAudioFormatProperty_Encoders, sizeof(encoderSpecifier), &encoderSpecifier, &size, descs);
//  for (uint32_t i = 0; i < count; i++)
//  {
//    if ((type == descs[i].mSubType) && (manufacturer == descs[i].mManufacturer))
//    {
//      memcpy(&audioDesc, &descs[i], sizeof(audioDesc));
//      break;
//    }
//  }
//  return &audioDesc;
//}
//
////<span style="font-family: Arial, Helvetica, sans-serif;">AudioConverterFillComplexBuffer 编码过程中，会要求这个函数来填充输入数据，也就是原始PCM数据</span>
//OSStatus inputDataProc(AudioConverterRef inConverter, UInt32 *ioNumberDataPackets, AudioBufferList *ioData,AudioStreamPacketDescription **outDataPacketDescription, void *inUserData) {
//  AudioBufferList bufferList = *(AudioBufferList*)inUserData;
//  ioData->mBuffers[0].mNumberChannels = 1;
//  ioData->mBuffers[0].mData           = bufferList.mBuffers[0].mData;
//  ioData->mBuffers[0].mDataByteSize   = bufferList.mBuffers[0].mDataByteSize;
//  return noErr;
//}

#endif



@end
