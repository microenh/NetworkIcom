//
//  CARingBufferWrapper.h
//  CallCPPFromSwift
//
//  Created by Mark Erbaugh on 3/23/22.
//

// based on https://github.com/derekli66/Learning-Core-Audio-Swift-SampleCode

#ifndef CARingBufferWrapper_h
#define CARingBufferWrapper_h

#include <stdio.h>
#import <AudioToolbox/AudioToolbox.h>

typedef SInt64 SampleTime;
typedef SInt32 CARingBufferError;

#if __cplusplus
extern "C" {
#endif
typedef struct RingBufferWrapper {
    void *ringBufferPtr;
}RingBufferWrapper;

RingBufferWrapper CreateRingBuffer();

void DestroyBuffer(RingBufferWrapper wrapper);
    
void AllocateBuffer(RingBufferWrapper wrapper, int nChannels, UInt32 bytesPerFrame, UInt32 capacityFrames);
    
void DeallocateBuffer(RingBufferWrapper wrapper);
    
CARingBufferError StoreBuffer(RingBufferWrapper wrapper, const AudioBufferList *abl, UInt32 nFrames, SampleTime frameNumber);
    
CARingBufferError FetchBuffer(RingBufferWrapper wrapper, AudioBufferList *abl, UInt32 nFrames, SampleTime frameNumber);
    
CARingBufferError GetTimeBoundsFromBuffer(RingBufferWrapper wrapper, SampleTime *startTime, SampleTime *endTime);
#if __cplusplus
}
#endif

#endif /* CARingBufferWrapper_h */
