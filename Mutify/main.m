//
//  main.m
//  Mutify
//
//  Created by Simon Knopp on 6/02/13.
//  Copyright (c) 2013 Simon Knopp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Spotify.h"


@interface SpotifyObserver : NSObject {
    SpotifyApplication *spotify;
    NSInteger volume;
    NSString *lastNotifiedTrack;
}

- (void)observeStateChange:(NSNotification *)note;
- (void)muteIfTrackChangedWithoutNotification;

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

- (void)muteIfTrackChangedWithoutNotification
{
    if (![spotify.currentTrack.id isEqualToString:lastNotifiedTrack]) {
        NSLog(@"Hah! Caught an ad.");
        volume = spotify.soundVolume;
        spotify.soundVolume = 0;
        usleep(100000);
        [spotify play];
    }
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
    
    NSLog(@"Track change: %@", note.userInfo);
    
    NSTimeInterval duration = [[note.userInfo valueForKey:@"Duration"] doubleValue];
    NSTimeInterval position = [[note.userInfo valueForKey:@"Playback Position"] doubleValue];
    NSTimeInterval remaining = duration - position;
    NSString *trackId = [note.userInfo valueForKey:@"Track ID"];
    
    if (spotify.soundVolume == 0) {
        NSLog(@"Restoring volume");
        spotify.soundVolume = volume;
    }

    if (spotify.playerState == SpotifyEPlSPlaying) {
        // These days Spotify doesn't emit notifications when ads start playing.
        // To find ads, we store the id of the latest track we've received a
        // notification for. This will be a legitimate track. We then schedule
        // a callback for just after that track is due to have finished. The
        // callback checks whether the (then) current track id is the same as
        // the last notified id. If it's not, we've found an ad.
        lastNotifiedTrack = [NSString stringWithString:trackId];
        [self performSelector:@selector(muteIfTrackChangedWithoutNotification)
                   withObject:nil
                   afterDelay:remaining + 0.5];
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
