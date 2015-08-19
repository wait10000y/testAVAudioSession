//
//  RemoteIOPlayer.m
//  RemoteIOTest
//
//  Created by aran Mulholland on 3/03/09.
//  Copyright 2009 Aran Mulholland. All rights reserved.
//

#import "RemoteIOPlayer.h"
#include <AudioUnit/AudioUnit.h>
#include "TPCircularBuffer.h"

#define kOutputBus 0
#define kInputBus 1

@implementation RemoteIOPlayer
{
  TPCircularBuffer buffer;
}

AudioComponentInstance audioUnit;
AudioStreamBasicDescription audioFormat;

-(OSStatus)start{
	
	OSStatus status = AudioOutputUnitStart(audioUnit);
	return status;
}

-(OSStatus)stop{
	OSStatus status = AudioOutputUnitStop(audioUnit);
	return status;
}

-(void)cleanUp{
	AudioUnitUninitialize(audioUnit);
}

// ------------------------------



static OSStatus audioOutputCallback(void *inRefCon,
                                    AudioUnitRenderActionFlags *ioActionFlags,
                                    const AudioTimeStamp *inTimeStamp,
                                    UInt32 inBusNumber,
                                    UInt32 inNumberFrames,
                                    AudioBufferList *ioData) {
  RemoteIOPlayer *THIS = (__bridge RemoteIOPlayer *)inRefCon;
  
  int bytesToCopy = ioData->mBuffers[0].mDataByteSize;
  SInt16 *targetBuffer = (SInt16*)ioData->mBuffers[0].mData;
  
  // Pull audio from playthrough buffer
  int32_t availableBytes;
  int32_t sampleCount = MIN(bytesToCopy, availableBytes);
  SInt16 *buffer = TPCircularBufferTail(&THIS->buffer, &availableBytes);
  memcpy(targetBuffer, buffer, sampleCount);
  TPCircularBufferConsume(&THIS->buffer, sampleCount);
  
  return noErr;
}


/* Parameters on entry to this function are :-
 
 *inRefCon - used to store whatever you want, can use it to pass in a reference to an objectiveC class
			 i do this below to get at the InMemoryAudioFile object, the line below :
				callbackStruct.inputProcRefCon = self;
			 in the initialiseAudio method sets this to "self" (i.e. this instantiation of RemoteIOPlayer).
			 This is a way to bridge between objectiveC and the straight C callback mechanism, another way
			 would be to use an "evil" global variable by just specifying one in theis file and setting it
			 to point to inMemoryAudiofile whenever it is set.
 
 *inTimeStamp - the sample time stamp, can use it to find out sample time (the sound card time), or the host time
 
 inBusnumber - the audio bus number, we are only using 1 so it is always 0 
 
 inNumberFrames - the number of frames we need to fill. In this example, because of the way audioformat is
				  initialised below, a frame is a 32 bit number, comprised of two signed 16 bit samples.
 
 *ioData - holds information about the number of audio buffers we need to fill as well as the audio buffers themselves */
static OSStatus playbackCallback(void *inRefCon, 
								 AudioUnitRenderActionFlags *ioActionFlags, 
								 const AudioTimeStamp *inTimeStamp, 
								 UInt32 inBusNumber, 
								 UInt32 inNumberFrames, 
								 AudioBufferList *ioData) {  
	

	
	//get a copy of the objectiveC class "self" we need this to get the next sample to fill the buffer
	RemoteIOPlayer *remoteIOplayer = (__bridge RemoteIOPlayer *)inRefCon;
	
	//loop through all the buffers that need to be filled
	for (int i = 0 ; i < ioData->mNumberBuffers; i++){
		//get the buffer to be filled
		AudioBuffer buffer = ioData->mBuffers[i];
		
		//if needed we can get the number of bytes that will fill the buffer using
		// int numberOfSamples = ioData->mBuffers[i].mDataByteSize;
		
		//get the buffer and point to it as an UInt32 (as we will be filling it with 32 bit samples)
		//if we wanted we could grab it as a 16 bit and put in the samples for left and right seperately
		//but the loop below would be for(j = 0; j < inNumberFrames * 2; j++) as each frame is a 32 bit number
		UInt32 *frameBuffer = buffer.mData;
		
		//loop through the buffer and fill the frames
		for (int j = 0; j < inNumberFrames; j++){
			// get NextPacket returns a 32 bit value, one frame.
      if ([remoteIOplayer.sourceDelegate respondsToSelector:@selector(needNextPacket)]) {
        
      }
			frameBuffer[j] = [[remoteIOplayer sourceDelegate] needNextPacket];
		}
	}
	//dodgy return :)
    return noErr;
}


// Below code is a cut down version (for output only) of the code written by
// Micheal "Code Fighter" Tyson (punch on Mike)
// See http://michael.tyson.id.au/2008/11/04/using-remoteio-audio-unit/ for details
-(void)intialiseAudio{
	OSStatus status;

  if (TPCircularBufferInit(&buffer, 1024*10)) {
    NSLog(@"--- init circularBuffer ok ---");
  }else{
    NSLog(@"--- init circularBuffer error ---");
  }
	
	// Describe audio component
	AudioComponentDescription desc;
	desc.componentType = kAudioUnitType_Output;
	desc.componentSubType = kAudioUnitSubType_RemoteIO;
	desc.componentFlags = 0;
	desc.componentFlagsMask = 0;
	desc.componentManufacturer = kAudioUnitManufacturer_Apple;
	
	// Get component
	AudioComponent inputComponent = AudioComponentFindNext(NULL, &desc);
	
	// Get audio units
	status = AudioComponentInstanceNew(inputComponent, &audioUnit);
	
	UInt32 flag = 1;
	// Enable IO for playback
	status = AudioUnitSetProperty(audioUnit, 
								  kAudioOutputUnitProperty_EnableIO, 
								  kAudioUnitScope_Output, 
								  kOutputBus,
								  &flag, 
								  sizeof(flag));
	
	// Describe format
	audioFormat.mSampleRate			= 44100.00;
	audioFormat.mFormatID			= kAudioFormatLinearPCM;
	audioFormat.mFormatFlags		= kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
	audioFormat.mFramesPerPacket	= 1;
	audioFormat.mChannelsPerFrame	= 2;
	audioFormat.mBitsPerChannel		= 16;
	audioFormat.mBytesPerPacket		= 4;
	audioFormat.mBytesPerFrame		= 4;
	
	//Apply format
	status = AudioUnitSetProperty(audioUnit, 
								  kAudioUnitProperty_StreamFormat, 
								  kAudioUnitScope_Input, 
								  kOutputBus, 
								  &audioFormat, 
								  sizeof(audioFormat));
	 
	// Set up the playback  callback
	AURenderCallbackStruct callbackStruct;
	callbackStruct.inputProc = playbackCallback;
	//set the reference to "self" this becomes *inRefCon in the playback callback
	callbackStruct.inputProcRefCon = (__bridge void *)(self);
	
	status = AudioUnitSetProperty(audioUnit, 
								  kAudioUnitProperty_SetRenderCallback, 
								  kAudioUnitScope_Global, 
								  kOutputBus,
								  &callbackStruct, 
								  sizeof(callbackStruct));
	
	// Initialise
	status = AudioUnitInitialize(audioUnit);
	
	//notice i do nothing with status, i should error check.
}



@end
