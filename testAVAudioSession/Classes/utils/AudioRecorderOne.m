//
//  AudioPlayer.m
//  testAVAudioSession
//
//  Created by wsliang on 15/7/6.
//  Copyright (c) 2015年 wsliang. All rights reserved.
//

#import "AudioRecorderOne.h"
#import <AVFoundation/AVFoundation.h>

typedef struct MyAUGraphStruct{
  AUGraph graph;
  AudioUnit remoteIOUnit;
  AUNode remoteIONode;
} MyAUGraphStruct;

#define BUFFER_COUNT 15

MyAUGraphStruct myStruct;

AudioBuffer recordedBuffers[BUFFER_COUNT];//Used to save audio data
int         currentBufferPointer;//Pointer to the current buffer
int         callbackCount;

static void CheckError(OSStatus error, const char *operation)
{
  if (error == noErr) return;
  char errorString[20];
  // See if it appears to be a 4-char-code
  *(UInt32 *)(errorString + 1) = CFSwapInt32HostToBig(error);
  if (isprint(errorString[1]) && isprint(errorString[2]) &&
      isprint(errorString[3]) && isprint(errorString[4])) {
    errorString[0] = errorString[5] = '\'';
    errorString[6] = '\0';
  } else
    // No, format it as an integer
    sprintf(errorString, "%d", (int)error);
  fprintf(stderr, "Error: %s (%s)\n", operation, errorString);
  exit(1);
}

OSStatus InputCallback(void *inRefCon,
                       AudioUnitRenderActionFlags *ioActionFlags,
                       const AudioTimeStamp *inTimeStamp,
                       UInt32 inBusNumber,
                       UInt32 inNumberFrames,
                       AudioBufferList *ioData){
  //TODO: implement this function
  MyAUGraphStruct* myStruct = (MyAUGraphStruct*)inRefCon;
  
  //Get samples from input bus(bus 1)
  OSStatus status = AudioUnitRender(myStruct->remoteIOUnit,
                                     ioActionFlags,
                                     inTimeStamp,
                                     1,
                                     inNumberFrames,
                                     ioData);
  if (noErr == status) {
    
    
    //save audio to ring buffer and load from ring buffer
//    AudioBuffer buffer = ioData->mBuffers[0];
//    recordedBuffers[currentBufferPointer].mNumberChannels = buffer.mNumberChannels;
//    recordedBuffers[currentBufferPointer].mDataByteSize = buffer.mDataByteSize;
//    free(recordedBuffers[currentBufferPointer].mData);
//    recordedBuffers[currentBufferPointer].mData = malloc(sizeof(SInt16)*buffer.mDataByteSize);
//    memcpy(recordedBuffers[currentBufferPointer].mData,buffer.mData,buffer.mDataByteSize);
//    currentBufferPointer = (currentBufferPointer+1)%BUFFER_COUNT;
//    
//    if (callbackCount>=BUFFER_COUNT) {
//      memcpy(buffer.mData,recordedBuffers[currentBufferPointer].mData,buffer.mDataByteSize);
//    }
//    callbackCount++;
    
    /*
     SInt16 sample = 0;
     int currentFrame = 0;
     UInt32 bytesPerChannel = controller.streamFormat.mBytesPerFrame/controller.streamFormat.mChannelsPerFrame;
     while (currentFrame<inNumberFrames) {
     for (int currentChannel=0; currentChannel<buffer.mNumberChannels; currentChannel++) {
     //Copy sample to buffer, across all channels
     memcpy(&sample,
     buffer.mData+(currentFrame*controller.streamFormat.mBytesPerFrame) + currentChannel*bytesPerChannel,
     sizeof(sample));
     
     memcpy(buffer.mData+(currentFrame*controller.streamFormat.mBytesPerFrame) + currentChannel*bytesPerChannel,
     &sample,
     sizeof(sample));
     }
     currentFrame++;
     }*/
    
    
  }else{
    // show error
    CheckError(status, "AudioUnitRender failed");
  }
  return status;
}



@interface AudioRecorderOne()

@property(nonatomic,assign)AudioStreamBasicDescription streamFormat;

@end

@implementation AudioRecorderOne

@synthesize streamFormat;

+(instancetype)defaultAudioRecord:(id)theProfile
{
  static AudioRecorderOne *staticObject;
  if (!staticObject) {
    staticObject = [AudioRecorderOne new];
  
  }
  return staticObject;
}

-(void)startAudioRecord
{
  //Initialize currentBufferPointer
  currentBufferPointer = 0;
  callbackCount = 0;
  
  [self setupSession];
  
  [self createAUGraph:&myStruct];
  
  [self setupRemoteIOUnit:&myStruct];
  
  [self startGraph:myStruct.graph];
  
//  [self addControlButton];
  
}

-(void)stopAudioRecord
{

  AudioOutputUnitStop(myStruct.remoteIOUnit);
  AUGraphRemoveNode(myStruct.graph, myStruct.remoteIONode);
    AUGraphStop(myStruct.graph);
    AUGraphClose(myStruct.graph);
    AUGraphUninitialize(myStruct.graph);
  
  AVAudioSession* session = [AVAudioSession sharedInstance];
  [session setCategory:AVAudioSessionCategoryPlayback error:nil];
  [session overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil];
  
}


-(void)openOrCloseEchoCancellation:(BOOL)theOpen
{
  UInt32 echoCancellation;
  UInt32 size = sizeof(echoCancellation);
  CheckError(AudioUnitGetProperty(myStruct.remoteIOUnit,kAUVoiceIOProperty_BypassVoiceProcessing,kAudioUnitScope_Global,0,&echoCancellation,&size),
             "AudioUnitGetProperty kAUVoiceIOProperty_BypassVoiceProcessing failed");
  if (echoCancellation==0 && theOpen) {
    return;
  }else{
    echoCancellation = theOpen?0:1; // 0:open;1:close;
  }
  
  CheckError(AudioUnitSetProperty(myStruct.remoteIOUnit,
                                  kAUVoiceIOProperty_BypassVoiceProcessing,
                                  kAudioUnitScope_Global,
                                  0,
                                  &echoCancellation,
                                  sizeof(echoCancellation)),
             "AudioUnitSetProperty kAUVoiceIOProperty_BypassVoiceProcessing failed");
  
}

-(void)startGraph:(AUGraph)graph{
  CheckError(AUGraphInitialize(graph),
             "AUGraphInitialize failed");
  
  CheckError(AUGraphStart(graph),
             "AUGraphStart failed");
}

-(void)setupRemoteIOUnit:(MyAUGraphStruct*)myStruct{
  //Open input of the bus 1(input mic)
  UInt32 enableFlag = 1;
  CheckError(AudioUnitSetProperty(myStruct->remoteIOUnit,
                                  kAudioOutputUnitProperty_EnableIO,
                                  kAudioUnitScope_Input,
                                  1,
                                  &enableFlag,
                                  sizeof(enableFlag)),
             "Open input of bus 1 failed");
  
  //Open output of bus 0(output speaker)
  CheckError(AudioUnitSetProperty(myStruct->remoteIOUnit,
                                  kAudioOutputUnitProperty_EnableIO,
                                  kAudioUnitScope_Output,
                                  0,
                                  &enableFlag,
                                  sizeof(enableFlag)),
             "Open output of bus 0 failed");
  
  //Set up stream format for input and output
  streamFormat.mFormatID = kAudioFormatLinearPCM;
  streamFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
  streamFormat.mSampleRate = 44100;
  streamFormat.mFramesPerPacket = 1;
  streamFormat.mBytesPerFrame = 2;
  streamFormat.mBytesPerPacket = 2;
  streamFormat.mBitsPerChannel = 16;
  streamFormat.mChannelsPerFrame = 1;
  
  CheckError(AudioUnitSetProperty(myStruct->remoteIOUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Input,
                                  0,
                                  &streamFormat,
                                  sizeof(streamFormat)),
             "kAudioUnitProperty_StreamFormat of bus 0 failed");
  
  CheckError(AudioUnitSetProperty(myStruct->remoteIOUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Output,
                                  1,
                                  &streamFormat,
                                  sizeof(streamFormat)),
             "kAudioUnitProperty_StreamFormat of bus 1 failed");
  
  //Set up input callback
  AURenderCallbackStruct input;
  input.inputProc = InputCallback;
  input.inputProcRefCon = myStruct;
  CheckError(AudioUnitSetProperty(myStruct->remoteIOUnit,
                                  kAudioUnitProperty_SetRenderCallback,
                                  kAudioUnitScope_Global,
                                  0,//input mic
                                  &input,
                                  sizeof(input)),
             "kAudioUnitProperty_SetRenderCallback failed");
}

-(void)createAUGraph:(MyAUGraphStruct*)myStruct{
  //Create graph
  CheckError(NewAUGraph(&myStruct->graph),"NewAUGraph failed");
  
  //Create nodes and add to the graph
  //Set up a RemoteIO for synchronously playback
  AudioComponentDescription inputcd = {0};
  inputcd.componentType = kAudioUnitType_Output;
  //inputcd.componentSubType = kAudioUnitSubType_RemoteIO;
  //we can access the system's echo cancellation by using kAudioUnitSubType_VoiceProcessingIO subtype
  inputcd.componentSubType = kAudioUnitSubType_VoiceProcessingIO;
  inputcd.componentManufacturer = kAudioUnitManufacturer_Apple;
  
  //Add node to the graph
  CheckError(AUGraphAddNode(myStruct->graph,
                            &inputcd,
                            &myStruct->remoteIONode),
             "AUGraphAddNode failed");
  
  //Open the graph
  CheckError(AUGraphOpen(myStruct->graph),
             "AUGraphOpen failed");
  
  //Get reference to the node
  CheckError(AUGraphNodeInfo(myStruct->graph,
                             myStruct->remoteIONode,
                             &inputcd,
                             &myStruct->remoteIOUnit),
             "AUGraphNodeInfo failed");
}

-(void)createRemoteIONodeToGraph:(AUGraph*)graph{
  
}

-(void)setupSession{
  AVAudioSession* session = [AVAudioSession sharedInstance];
  [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
  [session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
  [session setActive:YES error:nil];
}


-(void)inputAudioFrameList:(AudioBufferList *)thedata
{
  
}





@end



