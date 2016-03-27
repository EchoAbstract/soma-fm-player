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

NSString * const kDefaultStationKey = @"Fluid";

#pragma mark - Menu Stuff
- (void)buildStationMap {
    stationMap = @[
                   [StationInfo stationInfoForStationNamed:@"Fluid" withPlaylistLocation:@"https://somafm.com/fluid130.pls" withShortKey:@"1" withIconNamed:@"rounded_fluid120" atSortOrder:0],
                   [StationInfo stationInfoForStationNamed:@"DEF CON Radio" withPlaylistLocation:@"https://somafm.com/defcon64.pls" withShortKey:@"2" withIconNamed:@"rounded_defcon120" atSortOrder:1],
                   [StationInfo stationInfoForStationNamed:@"ThistleRadio" withPlaylistLocation:@"https://somafm.com/thistle64.pls" withShortKey:@"3" withIconNamed:@"rounded_thistle120" atSortOrder:2],
                   [StationInfo stationInfoForStationNamed:@"PopTron" withPlaylistLocation:@"https://somafm.com/poptron64.pls" withShortKey:@"4" withIconNamed:@"rounded_poptron120" atSortOrder:3],
                   [StationInfo stationInfoForStationNamed:@"Lush" withPlaylistLocation:@"https://somafm.com/lush130.pls" withShortKey:@"5" withIconNamed:@"rounded_lush-x120" atSortOrder:4],
                   [StationInfo stationInfoForStationNamed:@"The Trip" withPlaylistLocation:@"https://somafm.com/thetrip64.pls" withShortKey:@"6" withIconNamed:@"rounded_thetrip120" atSortOrder:5],
                   [StationInfo stationInfoForStationNamed:@"Drone Zone" withPlaylistLocation:@"https://somafm.com/dronezone130.pls" withShortKey:@"7" withIconNamed:@"rounded_dronezone120" atSortOrder:6],
                   [StationInfo stationInfoForStationNamed:@"Deep Space One" withPlaylistLocation:@"https://somafm.com/deepspaceone130.pls" withShortKey:@"8" withIconNamed:@"rounded_deepspaceone120" atSortOrder:7],
                   [StationInfo stationInfoForStationNamed:@"Suburbs of Goa" withPlaylistLocation:@"https://somafm.com/suburbsofgoa130.pls" withShortKey:@"9" withIconNamed:@"rounded_sog120" atSortOrder:8],
                   [StationInfo stationInfoForStationNamed:@"Groove Salad" withPlaylistLocation:@"https://somafm.com/groovesalad130.pls" withShortKey:@"0" withIconNamed:@"rounded_groovesalad120" atSortOrder:9],
                   [StationInfo stationInfoForStationNamed:@"Indie Pop Rocks!" withPlaylistLocation:@"https://somafm.com/indiepop130.pls" withShortKey:@"" withIconNamed:@"rounded_indychick" atSortOrder:50],
                   [StationInfo stationInfoForStationNamed:@"Space Station Soma" withPlaylistLocation:@"https://somafm.com/spacestation130.pls" withShortKey:@"" withIconNamed:@"rounded_sss" atSortOrder:50],
                   [StationInfo stationInfoForStationNamed:@"Secret Agent" withPlaylistLocation:@"https://somafm.com/secretagent130.pls" withShortKey:@"" withIconNamed:@"rounded_secretagent120" atSortOrder:50],
                   [StationInfo stationInfoForStationNamed:@"Underground 80s" withPlaylistLocation:@"https://somafm.com/u80s130.pls" withShortKey:@"" withIconNamed:@"rounded_u80s-120" atSortOrder:50],
                   [StationInfo stationInfoForStationNamed:@"Beat Blender" withPlaylistLocation:@"https://somafm.com/beatblender64.pls" withShortKey:@"" withIconNamed:@"rounded_blender120" atSortOrder:50],
                   [StationInfo stationInfoForStationNamed:@"Boot Liquor" withPlaylistLocation:@"https://somafm.com/bootliquor130.pls" withShortKey:@"" withIconNamed:@"rounded_bootliquor120" atSortOrder:50],
                   [StationInfo stationInfoForStationNamed:@"Folk Forward" withPlaylistLocation:@"https://somafm.com/folkfwd64.pls" withShortKey:@"" withIconNamed:@"rounded_folkfwd120" atSortOrder:50],
                   [StationInfo stationInfoForStationNamed:@"Left Coast 70s" withPlaylistLocation:@"https://somafm.com/seventies64.pls" withShortKey:@"" withIconNamed:@"rounded_seventies120" atSortOrder:50],
                   [StationInfo stationInfoForStationNamed:@"Sonic Universe" withPlaylistLocation:@"https://somafm.com/sonicuniverse64.pls" withShortKey:@"" withIconNamed:@"rounded_sonicuniverse120" atSortOrder:50],
                   [StationInfo stationInfoForStationNamed:@"Illinois Street Lounge" withPlaylistLocation:@"https://somafm.com/illstreet130.pls" withShortKey:@"" withIconNamed:@"rounded_illstreet" atSortOrder:50],
                   [StationInfo stationInfoForStationNamed:@"BAGeL Radio" withPlaylistLocation:@"https://somafm.com/bagel64.pls" withShortKey:@"" withIconNamed:@"rounded_bagel120" atSortOrder:50],
                   [StationInfo stationInfoForStationNamed:@"Digitalis" withPlaylistLocation:@"https://somafm.com/digitalis130.pls" withShortKey:@"" withIconNamed:@"rounded_digitalis120" atSortOrder:50],
                   [StationInfo stationInfoForStationNamed:@"Seven Inch Soul" withPlaylistLocation:@"https://somafm.com/7soul130.pls" withShortKey:@"" withIconNamed:@"rounded_7soul120" atSortOrder:50],
                   [StationInfo stationInfoForStationNamed:@"Dub Step Beyond" withPlaylistLocation:@"https://somafm.com/dubstep64.pls" withShortKey:@"" withIconNamed:@"rounded_dubstep120" atSortOrder:50],
                   [StationInfo stationInfoForStationNamed:@"cliqhop idm" withPlaylistLocation:@"https://somafm.com/cliqhop64.pls" withShortKey:@"" withIconNamed:@"rounded_cliqhop120" atSortOrder:50],
                   [StationInfo stationInfoForStationNamed:@"Mission Control" withPlaylistLocation:@"https://somafm.com/missioncontrol64.pls" withShortKey:@"" withIconNamed:@"rounded_missioncontrol120" atSortOrder:50],
                   [StationInfo stationInfoForStationNamed:@"Black Rock FM" withPlaylistLocation:@"https://somafm.com/brfm130.pls" withShortKey:@"" withIconNamed:@"rounded_1023brc" atSortOrder:50],
                   [StationInfo stationInfoForStationNamed:@"Covers" withPlaylistLocation:@"https://somafm.com/covers64.pls" withShortKey:@"" withIconNamed:@"rounded_covers120" atSortOrder:50],
                   [StationInfo stationInfoForStationNamed:@"Earwaves" withPlaylistLocation:@"https://somafm.com/earwaves130.pls" withShortKey:@"" withIconNamed:@"rounded_earwaves120" atSortOrder:50],
                   [StationInfo stationInfoForStationNamed:@"Doomed" withPlaylistLocation:@"https://somafm.com/doomed64.pls" withShortKey:@"" withIconNamed:@"rounded_doomed120" atSortOrder:50],
                   [StationInfo stationInfoForStationNamed:@"SF 10-33" withPlaylistLocation:@"https://somafm.com/sf103364.pls" withShortKey:@"" withIconNamed:@"rounded_sf1033120" atSortOrder:50],
                   [StationInfo stationInfoForStationNamed:@"Metal Detector" withPlaylistLocation:@"https://somafm.com/metal130.pls" withShortKey:@"" withIconNamed:@"rounded_metal-200" atSortOrder:50],
                   [StationInfo stationInfoForStationNamed:@"South by Soma" withPlaylistLocation:@"https://somafm.com/sxfm64.pls" withShortKey:@"" withIconNamed:@"rounded_sxfm120" atSortOrder:50]
                   ];
}

- (StationInfo *)stationInfoForStationNamed: (NSString * const)name {
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

#pragma mark - NSApplicationDelegate Methods

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    [self buildStationMap];
    
    NSMenuItem *stationMenu = [self buildStationMenu];
    NSInteger index = GetStationMenuPlacementIndex(window);
    
    stations = [stationMenu.submenu copyWithZone:[NSMenu menuZone]];
    
    NSMenu *mainMenu = [NSApp mainMenu];
    [mainMenu insertItem:stationMenu atIndex:index];
    
    CGRect windowFrame = window.frame;
    CGSize windowSize = CGSizeMake(250, 46);
    [window setMinSize:windowSize];
    [window setMaxSize:windowSize];
    windowFrame.size = windowSize;
    [window setFrame:windowFrame display:NO];
    
    mediaKeyController = [AppleMediaKeyController sharedController];
    
    CGRect playerFrame = CGRectMake(0, 0, 0, 0);
    playerFrame.size = windowSize;
    playbackView = [[AVPlayerView alloc] initWithFrame:playerFrame];
    
    playbackView.controlsStyle = AVPlayerViewControlsStyleDefault;
    playbackView.actionPopUpButtonMenu = stations;
    
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
