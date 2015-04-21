//
//  CSAudioPlotViewController.h
//  CommSync
//
//  Created by Ivan Lugo on 2/9/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "EZAudio.h"

#define kAudioFilePath @"EZAudioTest.m4a"

@interface CSAudioPlotViewController : UIViewController <AVAudioPlayerDelegate, EZMicrophoneDelegate, UIGestureRecognizerDelegate>

@property (nonatomic,weak) IBOutlet EZAudioPlotGL *audioPlot;
@property (nonatomic,assign) BOOL isRecording;

@property (nonatomic,strong) EZMicrophone *microphone;
@property (nonatomic,strong) EZRecorder *recorder;

@property (nonatomic,strong) NSString* fileNameSansExtension;
@property (nonatomic,strong) NSURL* fileOutputURL;

@property (strong, nonatomic) IBOutlet UIButton *playAudioButton;
@property (strong, nonatomic) IBOutlet UIImageView *micImage;


@property (nonatomic,strong) AVAudioPlayer *audioPlayer;

#pragma mark - Actions
-(IBAction)playFile:(id)sender;

/**
 Toggles the microphone on and off. When the microphone is on it will send its delegate (aka this view controller) the audio data in various ways (check out the EZMicrophoneDelegate documentation for more details);
 */
-(IBAction)toggleMicrophone:(id)sender;
-(void)stopRecording;
@end
