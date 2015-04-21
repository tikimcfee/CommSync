//
//  CSAudioPlotViewController.m
//  CommSync
//
//  Created by Ivan Lugo on 2/9/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "CSAudioPlotViewController.h"
#import "UIColor+FlatColors.h"
#import "IonIcons.h"

@interface CSAudioPlotViewController ()


@property (strong, nonatomic) IBOutlet NSLayoutConstraint *buttonCenterYConstraint;


@end

@implementation CSAudioPlotViewController

-(id)init {
    self = [super init];
    if(self){
        [self initializeViewController];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if(self){
        [self initializeViewController];
    }
    return self;
}

- (IBAction)saveNewRecording:(id)sender {
    [self.saveDelegate saveAudio];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)closeWithoutSaving:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}


-(void)initializeViewController {
    // Create an instance of the microphone and tell it to use this view controller instance as the delegate
    self.microphone = [EZMicrophone microphoneWithDelegate:self];
}

-(void)dealloc {
    
    if( self.audioPlayer ){
        if( self.audioPlayer.playing ) [self.audioPlayer stop];
        self.audioPlayer = nil;
    }
    
    [self.microphone stopFetchingAudio];
    self.microphone.microphoneDelegate = nil;
    self.microphone = nil;
    
    if (self.recorder) {
        [self.recorder closeAudioFile];
        self.recorder = nil;
    }
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.audioPlot.backgroundColor = [UIColor flatWetAsphaltColor];
    self.audioPlot.color           = [UIColor flatCloudsColor];
    self.audioPlot.plotType        = EZPlotTypeBuffer;
    self.audioPlot.shouldFill      = YES;
    self.audioPlot.shouldMirror    = YES;
    self.audioPlot.gain            = 1.5f;
    
    self.playAudioButton.userInteractionEnabled = NO;
    self.playAudioButton.alpha = 0;
    
    self.micImage.image = [IonIcons imageWithIcon:ion_ios_mic iconColor:[UIColor flatCloudsColor] iconSize:30.0f imageSize:CGSizeMake(45.0f, 40.f)];
    
    if (self.showShowSaveAndClose) {
        //
        _saveImageView.image = [IonIcons imageWithIcon:ion_plus_circled size:40 color:[UIColor flatEmeraldColor]];
        _closeImageView.image = [IonIcons imageWithIcon:ion_ios_close size:40 color:[UIColor flatAlizarinColor]];
        _saveImageView.userInteractionEnabled = YES;
        _closeImageView.userInteractionEnabled = YES;
        _saveImageView.alpha = 0;
        _buttonCenterYConstraint.constant = -64.0f;
    } else {
        _saveImageView.userInteractionEnabled = NO;
        _closeImageView.userInteractionEnabled = NO;
        _saveImageView.hidden = YES;
        _closeImageView.hidden = YES;
    }
}

-(void)playFile:(id)sender
{
    
    // Update microphone state
    [self.microphone stopFetchingAudio];
    
    // Update recording state
    self.isRecording = NO;
    
    // Create Audio Player
    if( self.audioPlayer )
    {
        if( self.audioPlayer.playing )
        {
            [self.audioPlayer stop];
        }
        self.audioPlayer = nil;
    }
    
    // Close the audio file
    if( self.recorder )
    {
        [self.recorder closeAudioFile];
    }
    
    NSError *err;
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[self testFilePathURL]
                                                              error:&err];
    [self.audioPlayer play];
    self.audioPlayer.delegate = self;
    
}

-(void)stopRecording
{
    // Update microphone state
    [self.microphone stopFetchingAudio];
    
    // Update recording state
    self.isRecording = NO;
    
    // Create Audio Player
    if( self.audioPlayer )
    {
        if( self.audioPlayer.playing )
        {
            [self.audioPlayer stop];
        }
        self.audioPlayer = nil;
    }
    
    // Close the audio file
    if( self.recorder )
    {
        [self.recorder closeAudioFile];
    }
    
    NSError *err;
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[self testFilePathURL]
                                                              error:&err];
}

-(void)toggleMicrophone:(id)sender {
    
    if( self.audioPlayer ){
        if( self.audioPlayer.playing ) [self.audioPlayer stop];
        self.audioPlayer = nil;
    }
    
    if( _isRecording )
    {
        _isRecording = NO;
        [self.microphone stopFetchingAudio];
        [self.recorder closeAudioFile];
        self.recorder = nil;
        self.playAudioButton.userInteractionEnabled = YES;
        self.saveImageView.userInteractionEnabled = YES;
        self.closeImageView.userInteractionEnabled = YES;
        [UIView animateWithDuration:0.2 animations:^{
            self.playAudioButton.alpha = 1;
            self.saveImageView.alpha = 1;
            self.closeImageView.alpha = 1;
        }];
    }
    else {
        _isRecording = YES;
        self.playAudioButton.userInteractionEnabled = NO;
        self.saveImageView.userInteractionEnabled = NO;
        self.closeImageView.userInteractionEnabled = NO;
        [UIView animateWithDuration:0.2 animations:^{
            self.playAudioButton.alpha = 0;
            self.saveImageView.alpha = 0;
            self.closeImageView.alpha = 0;
        }];
        [self.microphone startFetchingAudio];
        self.recorder = [EZRecorder recorderWithDestinationURL:[self testFilePathURL]
                                                  sourceFormat:self.microphone.audioStreamBasicDescription
                                           destinationFileType:EZRecorderFileTypeM4A];
        
    }
}

#pragma mark - EZMicrophoneDelegate
-(void)microphone:(EZMicrophone *)microphone
 hasAudioReceived:(float **)buffer
   withBufferSize:(UInt32)bufferSize
withNumberOfChannels:(UInt32)numberOfChannels {
    
    // Note that any callback that provides streamed audio data (like streaming microphone input) happens on a separate audio thread that should not be blocked. When we feed audio data into any of the UI components we need to explicity create a GCD block on the main thread to properly get the UI to work.
    dispatch_async(dispatch_get_main_queue(),^{
        [self.audioPlot updateBuffer:buffer[0] withBufferSize:bufferSize];
    });
}

-(void)microphone:(EZMicrophone *)microphone
    hasBufferList:(AudioBufferList *)bufferList
   withBufferSize:(UInt32)bufferSize
withNumberOfChannels:(UInt32)numberOfChannels {
    
    // Getting audio data as a buffer list that can be directly fed into the EZRecorder. This is happening on the audio thread - any UI updating needs a GCD main queue block. This will keep appending data to the tail of the audio file.
    if( self.isRecording ){
        [self.recorder appendDataFromBufferList:bufferList
                                 withBufferSize:bufferSize];
    }
    
}

#pragma mark - AVAudioPlayerDelegate
/*
 Occurs when the audio player instance completes playback
 */
-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    self.audioPlayer = nil;
}

#pragma mark - Utility
-(NSArray*)applicationDocuments {
    return NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
}

-(NSString*)applicationDocumentsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

-(NSURL*)testFilePathURL {
    NSString* append = _fileNameSansExtension ? _fileNameSansExtension : kAudioFilePath;
    NSURL* toReturn = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@.m4a",
                                              [self applicationDocumentsDirectory],
                                              append]];
    self.fileOutputURL = toReturn;
    return toReturn;
}

@end
