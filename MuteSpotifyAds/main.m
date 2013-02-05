//
//  main.m
//  MuteSpotifyAds
//
//  Created by Simon Knopp on 6/02/13.
//  Copyright (c) 2013 Simon Knopp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Spotify.h"


@interface SpotifyObserver : NSObject {
    SpotifyApplication *spotify;
    NSInteger volume;
}

- (void)observeStateChange:(NSNotification *)note;

@end


@implementation SpotifyObserver

- (id)init
{
    if (self = [super init]) {
        NSNotificationCenter* nc = [NSDistributedNotificationCenter defaultCenter];
        [nc addObserver:self
               selector:@selector(observeStateChange:)
                   name:@"com.spotify.client.PlaybackStateChanged"
                 object:nil];
        
        spotify = [SBApplication applicationWithBundleIdentifier:@"com.spotify.client"];
        volume = (spotify.isRunning) ? spotify.soundVolume : -1;
    }
    return self;
}

- (void)dealloc
{
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void)observeStateChange:(NSNotification *)note
{
    if ([[note.userInfo valueForKey:@"Player State"] isEqualToString:@"Stopped"]) {
        // This notification occurs when Spotify is launched or quit.
        // Use it to get the initial volume in case Spotify wasn't running when
        // this program was launched.
        volume = spotify.soundVolume;
        return;
    }
    
    NSString *album  =  [note.userInfo valueForKey:@"Album"];
    int discNum  = (int)[note.userInfo valueForKey:@"Disc Number"];
    int trackNum = (int)[note.userInfo valueForKey:@"Track Number"];
    
    NSLog(@"Got notification: %@", note.userInfo);
    
    bool isAd = NO;
    if ([album hasPrefix:@"http"]) {
        isAd = YES;
        NSLog(@"Album prefix = http (%@)", album);
    }
    if ([album hasPrefix:@"spotify"]) {
        isAd = YES;
        NSLog(@"Album prefix = spotify (%@)", album);
    }
    if (trackNum == 0 && discNum == 0) {
        isAd = YES;
        NSLog(@"Track and disc numbers = 0");
    }
    
    if (isAd) {
        NSLog(@"Hah! Caught an ad.");
        // Mute Spotify if it isn't already muted
        if (spotify.soundVolume > 0) {
            volume = spotify.soundVolume;
            spotify.soundVolume = 0;
        }
    } else {
        spotify.soundVolume = volume;
    }
}

@end


int main(int argc, const char * argv[])
{
    @autoreleasepool {
        [SpotifyObserver new];
        CFRunLoopRun();
    }
    return 0;
}
