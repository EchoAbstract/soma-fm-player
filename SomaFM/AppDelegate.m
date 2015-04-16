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
@property (nonatomic, retain) NSArray *stationMap;

@property (nonatomic, retain) NSMenu *stations;
@end

@interface StationInfo : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *shortKey;
@property (nonatomic, copy) NSString *playlistLocation;
@property (nonatomic, retain) NSImage *icon;
@property (nonatomic, readwrite) int sortOrder;

+ (instancetype)stationInfoForStationNamed: (NSString *)stationName;

+ (instancetype)stationInfoForStationNamed: (NSString *)stationName
                      withPlaylistLocation: (NSString *)playlistLocation
                              withShortKey: (NSString *)shortKey
                               atSortOrder: (int)sortOrder;

+ (instancetype)stationInfoForStationNamed: (NSString *)stationName
                      withPlaylistLocation: (NSString *)playlistLocation
                              withShortKey: (NSString *)shortKey
                             withIconNamed: (NSString *)iconName
                               atSortOrder: (int)sortOrder;


@end

@implementation StationInfo

+ (instancetype)stationInfoForStationNamed:(NSString *)stationName {
    return [StationInfo stationInfoForStationNamed:stationName withPlaylistLocation:nil withShortKey:@"" atSortOrder:0];
}

+ (instancetype)stationInfoForStationNamed: (NSString *)stationName
                      withPlaylistLocation: (NSString *)playlistLocation
                              withShortKey: (NSString *)shortKey
                               atSortOrder: (int)sortOrder {

    
    StationInfo *stationInfo = [[StationInfo alloc] init];
    stationInfo.name = stationName;
    stationInfo.playlistLocation = playlistLocation;
    stationInfo.shortKey = shortKey;
    stationInfo.sortOrder = sortOrder;
    stationInfo.icon = nil;
    
    return stationInfo;
    
}

+ (instancetype)stationInfoForStationNamed: (NSString *)stationName
                      withPlaylistLocation: (NSString *)playlistLocation
                              withShortKey: (NSString *)shortKey
                             withIconNamed: (NSString *)iconName
                               atSortOrder: (int)sortOrder {
    
    StationInfo *stationInfo = [StationInfo stationInfoForStationNamed:stationName
                                                  withPlaylistLocation:playlistLocation
                                                          withShortKey:shortKey
                                                           atSortOrder:sortOrder];
    
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

const NSString *kDefaultStationKey = @"Drone Zone";

#pragma mark - Menu Stuff
- (void)buildStationMap {
    stationMap = @[
                   [StationInfo stationInfoForStationNamed:@"Drone Zone"       withPlaylistLocation:@"http://somafm.com/dronezone130.pls"    withShortKey:@"1" withIconNamed:@"test" atSortOrder:1],
                   [StationInfo stationInfoForStationNamed:@"Lush"             withPlaylistLocation:@"http://somafm.com/lush130.pls"         withShortKey:@"6" withIconNamed:nil atSortOrder:6],
                   [StationInfo stationInfoForStationNamed:@"Underground 80's" withPlaylistLocation:@"http://somafm.com/u80s130.pls"         withShortKey:@"3" withIconNamed:nil atSortOrder:3],
                   [StationInfo stationInfoForStationNamed:@"PopTron"          withPlaylistLocation:@"http://somafm.com/poptron64.pls"       withShortKey:@"2" withIconNamed:@"test" atSortOrder:2],
                   [StationInfo stationInfoForStationNamed:@"Seven Inch Soul"  withPlaylistLocation:@"http://somafm.com/7soul130.pls"        withShortKey:@"" withIconNamed:nil atSortOrder:9],
                   [StationInfo stationInfoForStationNamed:@"Suburbs of Goa"   withPlaylistLocation:@"http://somafm.com/suburbsofgoa130.pls" withShortKey:@"" withIconNamed:nil atSortOrder:8],
                   [StationInfo stationInfoForStationNamed:@"Deep Space One"   withPlaylistLocation:@"http://somafm.com/deepspaceone130.pls" withShortKey:@"" withIconNamed:nil atSortOrder:7],
                   [StationInfo stationInfoForStationNamed:@"DEF CON Radio"    withPlaylistLocation:@"http://somafm.com/defcon64.pls"        withShortKey:@"4" withIconNamed:nil atSortOrder:4],
                   [StationInfo stationInfoForStationNamed:@"SF 10-33"         withPlaylistLocation:@"http://somafm.com/sf103364.pls"        withShortKey:@"5" withIconNamed:nil atSortOrder:5]
                   ];
}

- (StationInfo *)stationInfoForStationNamed: (NSString *)name {
  for (StationInfo *info in stationMap){
    if ([info.name isEqualToString: name]){
      return info;
    }
  }
  return nil;
}

- (NSArray *)sortedStations {
    NSArray *sortedStations = [stationMap sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        StationInfo *station1 = (StationInfo *)obj1;
        StationInfo *station2 = (StationInfo *)obj2;
        
        return station1.sortOrder > station2.sortOrder;
    }];
    
    return sortedStations;
}


- (NSMenuItem *)buildStationMenu{
    NSMenuItem *stationMenuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Stations" action:NULL keyEquivalent:@""];
    NSMenu *stationMenu = [[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@"Stations"];
    stationMenuItem.submenu = stationMenu;

    NSArray *sortedStations = [self sortedStations];
    
    for (StationInfo *station in sortedStations){
        NSLog(@"Adding station %@ to menu with key %@", station.name, station.shortKey);
        [stationMenu addItemWithTitle:station.name action:@selector(setStation:) keyEquivalent:station.shortKey];
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
    StationInfo *info = [self stationInfoForStationNamed:station.title];

    [self tuneStation:info];
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

- (void)tuneStation: (StationInfo *)station {
    NSLog(@"Tuning %@ @ %@", station.name, station.playlistLocation);
    NSURL *playlistURL = [NSURL URLWithString:station.playlistLocation];
    
    AVURLAsset *playlistAsset = [AVURLAsset assetWithURL:playlistURL];
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:playlistAsset];
    mp3Player = [AVPlayer playerWithPlayerItem:playerItem];
    
    // Update view
    playbackView.player = mp3Player;
    
    // Update window
    window.title = station.name;
    
    // Update the icon (if available)
    [NSApp setApplicationIconImage:station.icon];

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
    StationInfo *defaultStationInfo = [self stationInfoForStationNamed:kDefaultStationKey];
    [self tuneStation: defaultStationInfo];
    
    
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
