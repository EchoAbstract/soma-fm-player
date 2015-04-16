//
//  AppDelegate.m
//  SomaFM
//
//  Created by Brian Wilson on 4/13/15.
//  Copyright (c) 2015 Polytopes. All rights reserved.
//

#import "AppDelegate.h"
#import "AppleMediaKeyController.h"
@import AVFoundation;
@import AVKit;

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@property (nonatomic, retain) AVPlayer *mp3Player;
@property (nonatomic, retain) AppleMediaKeyController *mediaKeyController;

@property (nonatomic, retain) AVPlayerView *playbackView;
@property (nonatomic, retain) NSDictionary *stationMap;

@property (nonatomic, retain) NSMenu *stations;
@end

@interface StationInfo : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *shortKey;
@property (nonatomic, copy) NSString *playlistLocation;
@property (nonatomic, retain) NSImage *icon;
@property (nonatomic, readwrite) int sortKey;

+ (instancetype)stationInfoForStationNamed: (NSString *)stationName;

+ (instancetype)stationInfoForStationNamed: (NSString *)stationName
                      withPlaylistLocation: (NSString *)playlistLocation
                              withShortKey: (NSString *)shortKey
                               atSortOrder: (int)sortKey;

+ (instancetype)stationInfoForStationNamed: (NSString *)stationName
                      withPlaylistLocation: (NSString *)playlistLocation
                              withShortKey: (NSString *)shortKey
                             withIconNamed: (NSString *)iconName
                               atSortOrder: (int)sortKey;


@end

@implementation StationInfo

+ (instancetype)stationInfoForStationNamed:(NSString *)stationName {
    return [StationInfo stationInfoForStationNamed:stationName withPlaylistLocation:nil withShortKey:@"" atSortOrder:0];
}

+ (instancetype)stationInfoForStationNamed: (NSString *)stationName
                      withPlaylistLocation: (NSString *)playlistLocation
                              withShortKey: (NSString *)shortKey
                               atSortOrder: (int)sortKey {

    
    StationInfo *stationInfo = [[StationInfo alloc] init];
    stationInfo.name = stationName;
    stationInfo.playlistLocation = playlistLocation;
    stationInfo.shortKey = shortKey;
    stationInfo.sortKey = sortKey;
    stationInfo.icon = nil;
    
    return stationInfo;
    
}

+ (instancetype)stationInfoForStationNamed: (NSString *)stationName
                      withPlaylistLocation: (NSString *)playlistLocation
                              withShortKey: (NSString *)shortKey
                             withIconNamed: (NSString *)iconName
                               atSortOrder: (int)sortKey {
    
    StationInfo *stationInfo = [StationInfo stationInfoForStationNamed:stationName
                                                  withPlaylistLocation:playlistLocation
                                                          withShortKey:shortKey
                                                           atSortOrder:sortKey];
    
    NSImage *icon = [NSImage imageNamed:iconName];
    stationInfo.icon = icon;

    return stationInfo;
}


@end

@implementation AppDelegate

@synthesize window;
@synthesize mp3Player;
@synthesize mediaKeyController;
@synthesize stationMap;
@synthesize playbackView;
@synthesize stations;

#pragma mark - Constants

const NSString *kSortKey = @"sortKey";
const NSString *kShortKey = @"shortKey";
const NSString *kPlaylistLocation = @"playlistLocation";
const NSString *kDefaultStationKey = @"Drone Zone";
const NSString *kIconKey = @"iconKey";


#pragma mark - Menu Stuff
- (void)buildStationMap {
    stationMap = @{
                   @"Drone Zone":       @{kSortKey: @1, kShortKey: @"1", kPlaylistLocation: @"http://somafm.com/dronezone130.pls", kIconKey: @"test"},
                   @"Lush":             @{kSortKey: @6, kShortKey: @"6", kPlaylistLocation: @"http://somafm.com/lush130.pls"},
                   @"Underground 80's": @{kSortKey: @3, kShortKey: @"3", kPlaylistLocation: @"http://somafm.com/u80s130.pls"},
                   @"PopTron":          @{kSortKey: @2, kShortKey: @"2", kPlaylistLocation: @"http://somafm.com/poptron64.pls"},
                   @"Seven Inch Soul":  @{kSortKey: @9, kShortKey: @"",  kPlaylistLocation: @"http://somafm.com/7soul130.pls"},
                   @"Suburbs of Goa":   @{kSortKey: @8, kShortKey: @"",  kPlaylistLocation: @"http://somafm.com/suburbsofgoa130.pls"},
                   @"Deep Space One":   @{kSortKey: @7, kShortKey: @"",  kPlaylistLocation: @"http://somafm.com/deepspaceone130.pls"},
                   @"DEF CON Radio":    @{kSortKey: @4, kShortKey: @"4", kPlaylistLocation: @"http://somafm.com/defcon64.pls"},
                   @"SF 10-33":         @{kSortKey: @5, kShortKey: @"5", kPlaylistLocation: @"http://somafm.com/sf103364.pls"},
                   };
}


- (NSMenuItem *)buildStationMenu{
    NSMenuItem *stationMenuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Stations" action:NULL keyEquivalent:@""];
    NSMenu *stationMenu = [[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@"Stations"];
    stationMenuItem.submenu = stationMenu;

    NSArray *stations = [[stationMap allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSString *s1 = (NSString *)obj1;
        NSString *s2 = (NSString *)obj2;
        NSDictionary *d1 = stationMap[s1];
        NSDictionary *d2 = stationMap[s2];

        NSNumber *n1 = d1[kSortKey];
        NSNumber *n2 = d2[kSortKey];
        
        return [n1 compare:n2];
    }];
    
    int key = 1;
    for (NSString *station in stations){
        NSDictionary *info = stationMap[station];
        [stationMenu addItemWithTitle:station action:@selector(setStation:) keyEquivalent:info[kShortKey]];
        key++;
    }
    
    
    return stationMenuItem;
}


NSInteger GetStationMenuPlacementIndex(){
    NSMenu *mainMenu = [NSApp mainMenu];
    for (int i = 0; i < mainMenu.itemArray.count; i++){
        NSMenuItem *item = (NSMenuItem *)mainMenu.itemArray[i];
        if ([item.title isEqualToString:@"File"]){
            return i+1;
        }
    }
    
    return 0;
}

-(void)setStation: (id)sender {
    NSLog(@"Got command to change the station: %@\n", sender);
    NSMenuItem *station = (NSMenuItem *)sender;
    NSDictionary *stationInfo = stationMap[station.title];
    
    [self tuneStation: station.title withPlaylistURL:[NSURL URLWithString:stationInfo[kPlaylistLocation]]];
}


#pragma mark - Playback Methods

- (void)togglePlayPause: (NSNotification *)notification {
    if (mp3Player.rate > 0 && !mp3Player.error){
        [mp3Player pause];
        NSLog(@"Paused playing...");
    } else if (!mp3Player.error) {
        [mp3Player play];
        NSLog(@"Started playing...");
    }
}

- (void)tuneStation: (NSString *)station withPlaylistURL: (NSURL *)playlistURL {
    NSLog(@"Tuning %@", playlistURL);
    AVURLAsset *playlistAsset = [AVURLAsset assetWithURL:playlistURL];
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:playlistAsset];
    mp3Player = [AVPlayer playerWithPlayerItem:playerItem];
    
    // Update view
    playbackView.player = mp3Player;
    
    // Update window
    window.title = station;
    
    // Update the icon (if available)
    NSImage *stationIcon = [NSImage imageNamed:]
    

    [mp3Player play];
}

#pragma mark - NSNotificationCenter delegate methods

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context{
    if ([keyPath isEqualToString:@"accessLog"]){
        AVPlayerItem *item = (AVPlayerItem *)object;
        AVPlayerItemAccessLog *accessLog = item.accessLog;
        NSLog(@"AL: %@", [accessLog.events objectAtIndex:accessLog.events.count - 1]);
    }
}

#pragma mark - NSApplicationDelegate Methods

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    [self buildStationMap];
    
    NSMenuItem *stationMenu = [self buildStationMenu];
    NSInteger index = GetStationMenuPlacementIndex(window);
    
    NSMenu *mainMenu = [NSApp mainMenu];
    [mainMenu insertItem:stationMenu atIndex:index];
    
    CGRect windowFrame = window.frame;
    CGSize windowSize = CGSizeMake(200, 50);
    [window setMinSize:windowSize];
    [window setMaxSize:windowSize];
    windowFrame.size = windowSize;
    [window setFrame:windowFrame display:NO];
    
    mediaKeyController = [AppleMediaKeyController sharedController];
    
    CGRect playerFrame = CGRectMake(0, 0, 0, 0);
    playerFrame.size = windowSize;
    playbackView = [[AVPlayerView alloc] initWithFrame:playerFrame];
    
    playbackView.controlsStyle = AVPlayerViewControlsStyleDefault;
    playbackView.actionPopUpButtonMenu = stationMenu.submenu;
    
    stations = stationMenu.submenu;
    
    
    [window.contentView addSubview:playbackView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(togglePlayPause:)
                                                 name:MediaKeyPlayPauseNotification
                                               object:self.mediaKeyController];
    
    
    // Start a station playing
    NSDictionary *defaultStationInfo = stationMap[kDefaultStationKey];
    [self tuneStation: kDefaultStationKey withPlaylistURL:[NSURL URLWithString:defaultStationInfo[kPlaylistLocation]]];
    
    
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

- (NSMenu *)applicationDockMenu:(NSApplication *)sender {
    return stations;
}

@end
