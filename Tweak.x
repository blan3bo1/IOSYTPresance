#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface YTPlayerViewController : UIViewController
@property (nonatomic, readonly) id playerResponse;
@property (nonatomic, readonly) double currentTime;
@property (nonatomic, readonly) BOOL isPlaying;
@end

@interface YTVideo : NSObject
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSString *channelTitle;
@property (nonatomic, readonly) double durationSeconds;
@end

static NSDictionary *currentVideoInfo = nil;
static NSTimer *presenceTimer = nil;

%hook YTPlayerViewController

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    [self startPresenceUpdates];
}

- (void)viewWillDisappear:(BOOL)animated {
    %orig;
    [self stopPresenceUpdates];
    [self clearDiscordPresence];
}

- (void)startPresenceUpdates {
    if (presenceTimer) {
        [presenceTimer invalidate];
        presenceTimer = nil;
    }
    
    presenceTimer = [NSTimer scheduledTimerWithTimeInterval:2.0
                                                    target:self
                                                  selector:@selector(updateDiscordPresence)
                                                  userInfo:nil
                                                   repeats:YES];
}

- (void)stopPresenceUpdates {
    if (presenceTimer) {
        [presenceTimer invalidate];
        presenceTimer = nil;
    }
}

- (void)updateDiscordPresence {
    YTVideo *video = [self valueForKeyPath:@"playerResponse.video"];
    
    if (video && [video respondsToSelector:@selector(title)]) {
        NSString *title = [video title];
        NSString *channel = [video channelTitle];
        double duration = [video durationSeconds];
        double currentTime = [self currentTime];
        BOOL isPlaying = [self isPlaying];
        
        if (title && channel) {
            NSDictionary *newVideoInfo = @{
                @"title": title,
                @"channel": channel,
                @"duration": @(duration),
                @"currentTime": @(currentTime),
                @"isPlaying": @(isPlaying)
            };
            
            if (![newVideoInfo isEqual:currentVideoInfo]) {
                currentVideoInfo = newVideoInfo;
                [self sendDiscordPresenceWithTitle:title channel:channel duration:duration currentTime:currentTime isPlaying:isPlaying];
            }
        }
    } else {
        [self clearDiscordPresence];
    }
}

- (void)sendDiscordPresenceWithTitle:(NSString *)title channel:(NSString *)channel duration:(double)duration currentTime:(double)currentTime isPlaying:(BOOL)isPlaying {
    NSMutableDictionary *activity = [@{
        @"details": title ?: @"Watching YouTube",
        @"assets": @{
            @"large_image": @"youtube",
            @"large_text": @"YouTube iOS",
            @"small_image": isPlaying ? @"play" : @"pause",
            @"small_text": isPlaying ? @"Playing" : @"Paused"
        }
    } mutableCopy];
    
    if (channel) {
        activity[@"state"] = [NSString stringWithFormat:@"By %@", channel];
    }
    
    if (duration > 0 && currentTime > 0) {
        long startTimestamp = (long)[[NSDate date] timeIntervalSince1970] - currentTime;
        activity[@"timestamps"] = @{
            @"start": @(startTimestamp)
        };
        
        if (isPlaying) {
            activity[@"timestamps"] = @{
                @"start": @(startTimestamp),
                @"end": @(startTimestamp + duration)
            };
        }
    }
    
    NSDictionary *rpcData = @{
        @"cmd": @"SET_ACTIVITY",
        @"args": @{
            @"pid": @(getpid()),
            @"activity": activity
        }
    };
    
    [self sendToDiscord:rpcData];
}

- (void)sendToDiscord:(NSDictionary *)data {
    for (int i = 0; i < 10; i++) {
        NSString *portName = [NSString stringWithFormat:@"discord-ipc-%d", i];
        CFMessagePortRef port = CFMessagePortCreateRemote(kCFAllocatorDefault, (__bridge CFStringRef)portName);
        
        if (port) {
            NSError *error = nil;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:0 error:&error];
            
            if (jsonData && !error) {
                CFDataRef cfData = CFDataCreate(kCFAllocatorDefault, [jsonData bytes], [jsonData length]);
                CFMessagePortSendRequest(port, 0, cfData, 1.0, 1.0, NULL, NULL);
                CFRelease(cfData);
            }
            
            CFRelease(port);
            break;
        }
    }
}

- (void)clearDiscordPresence {
    NSDictionary *clearData = @{
        @"cmd": @"SET_ACTIVITY",
        @"args": @{
            @"pid": @(getpid())
        }
    };
    [self sendToDiscord:clearData];
    currentVideoInfo = nil;
}

%end
