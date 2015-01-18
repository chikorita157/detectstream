//
//  main.m
//  detectstream
//
//  Created by 高町なのは on 2014/10/21.
//  Copyright (c) 2014, Atelier Shiori and James M.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
// Do not want to output timestamp for the output

#define NSLog(FORMAT, ...) printf("%s\n", [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);

#import <Foundation/Foundation.h>
#import <ScriptingBridge/SBApplication.h>
#import "Safari.h"
#import "Google Chrome.h"
#import "OmniWeb.h"

@import ScriptingBridge;
@interface browsercheck : NSObject
-(BOOL)checkIdentifier:(NSString*)identifier;
-(NSString *)checkURL:(NSString *)url;
@end

@implementation browsercheck
-(BOOL)checkIdentifier:(NSString*)identifier{
    NSWorkspace * ws = [NSWorkspace sharedWorkspace];
    NSArray *runningApps = [ws runningApplications];
    NSRunningApplication *a;
    for (a in runningApps) {
        if ([[a bundleIdentifier] isEqualToString:identifier]) {
            return true;
        }
    }
    return false;
}
-(NSString *)checkURL:(NSString *)url{
    NSError *errRegex = NULL;
    NSRegularExpression *regex = [NSRegularExpression
                                  regularExpressionWithPattern:@"(crunchyroll|daisuki|animelab|animenewsnetwork|viz|netflix)" //Supported Streaming Sites
                                  options:NSRegularExpressionCaseInsensitive
                                  error:&errRegex];
    NSString * teststring = url;
    NSRange  searchrange = NSMakeRange(0, [teststring length]);
        NSTextCheckingResult *match = [regex firstMatchInString:teststring options:0 range: searchrange];
        NSRange matchRange = [regex rangeOfFirstMatchInString:teststring options:NSMatchingReportProgress range:searchrange];
    NSString * result;
        if (matchRange.location != NSNotFound) {
            result = [teststring substringWithRange:[match rangeAtIndex:1]];
            return result;
        }
        else{
            return result;
        }
    
}
@end
//
// This class is used to simplify regex
//
@interface ezregex : NSObject
-(BOOL)checkMatch:(NSString *)string pattern:(NSString *)pattern;
-(NSString *)searchreplace:(NSString *)string pattern:(NSString *)pattern;
-(NSString *)findMatch:(NSString *)string pattern:(NSString *)pattern rangeatindex:(int)ri;
-(NSArray *)findMatches:(NSString *)string pattern:(NSString *)pattern;
@end

@implementation ezregex

-(BOOL)checkMatch:(NSString *)string pattern:(NSString *)pattern{
    NSError *errRegex = NULL;
    NSRegularExpression *regex = [NSRegularExpression
                                  regularExpressionWithPattern:pattern
                                  options:NSRegularExpressionCaseInsensitive
                                  error:&errRegex];
    NSRange  searchrange = NSMakeRange(0, [string length]);
    NSRange matchRange = [regex rangeOfFirstMatchInString:string options:NSMatchingReportProgress range:searchrange];
    if (matchRange.location != NSNotFound)
        return true;
        else
        return false;
}
-(NSString *)searchreplace:(NSString *)string pattern:(NSString *)pattern{
    NSError *errRegex = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&errRegex];
    NSString * newString = [regex stringByReplacingMatchesInString:string options:0 range:NSMakeRange(0, [string length]) withTemplate:@""];
    return newString;
}
-(NSString *)findMatch:(NSString *)string pattern:(NSString *)pattern rangeatindex:(int)ri{
    NSError *errRegex = NULL;
    NSRegularExpression *regex = [NSRegularExpression
                                  regularExpressionWithPattern:pattern
                                  options:NSRegularExpressionCaseInsensitive
                                  error:&errRegex];
    NSRange  searchrange = NSMakeRange(0, [string length]);
    NSTextCheckingResult *match = [regex firstMatchInString:string options:0 range: searchrange];
    NSRange matchRange = [regex rangeOfFirstMatchInString:string options:NSMatchingReportProgress range:searchrange];
    if (matchRange.location != NSNotFound){
        return [string substringWithRange:[match rangeAtIndex:ri]];
    }
    return @"";
}
-(NSArray *)findMatches:(NSString *)string pattern:(NSString *)pattern {
    NSError *errRegex = NULL;
    NSRegularExpression *regex = [NSRegularExpression
                                  regularExpressionWithPattern:pattern
                                  options:NSRegularExpressionCaseInsensitive
                                  error:&errRegex];
    NSRange  searchrange = NSMakeRange(0, [string length]);
    NSArray * a = [regex matchesInString:string options:kNilOptions range:searchrange];
    NSMutableArray * results = [[NSMutableArray alloc] init];
    for (NSTextCheckingResult * result in a ) {
        [results addObject:[string substringWithRange:[result rangeAtIndex:0]]];
    }
    return results;
}
@end

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        //Initalize Browser Check Object
        browsercheck * browser = [[browsercheck alloc] init];
        NSMutableArray* pages = [[NSMutableArray alloc]init];
/* 
 Browser Detection
 */
        // Check to see Safari is running. If so, add tab's title and url to the array
            for (int s = 0; s <2; s++) {
                SafariApplication* safari;
                NSString * browserstring;
                switch (s) {
                    case 0:
                        if (![browser checkIdentifier:@"com.apple.Safari"]) {
                            continue;
                        }
                        safari = [SBApplication applicationWithBundleIdentifier:@"com.apple.Safari"];
                        browserstring = @"Safari";
                        break;
                    case 1:
                        if (![browser checkIdentifier:@"org.webkit.nightly.WebKit"]) {
                            continue;
                        }
                        safari  = [SBApplication applicationWithBundleIdentifier:@"org.webkit.nightly.WebKit"];
                        browserstring = @"Webkit";
                        break;
                    default:
                        break;
                }

                SBElementArray * windows = [safari windows];
                for (int i = 0; i < [windows count]; i++) {
                    SafariWindow * window = [windows objectAtIndex:i];
                    SBElementArray * tabs = [window tabs];
                    for (int i = 0 ; i < [tabs count]; i++) {
                        SafariTab * tab = [tabs objectAtIndex:i];
                        NSString * site = [browser checkURL:[tab URL]];
                        if (site.length > 0) {
                            NSString * DOM;
                            if ([[[ezregex alloc] init] checkMatch:[tab URL] pattern:@"(netflix)"]){
                                //Include DOM
                                DOM = [tab source];
                            }
                            else{
                                DOM = nil;
                            }
                            NSDictionary * page = [[NSDictionary alloc] initWithObjectsAndKeys:[tab name],@"title",[tab URL], @"url",  browserstring, @"browser", site, @"site", DOM, @"DOM",  nil];
                            [pages addObject:page];
                        }
                        else{
                            continue;
                        }
						
                    }
                }
            }
        // Check to see Chrome is running. If so, add tab's title and url to the array
        if ([browser checkIdentifier:@"com.google.Chrome"]) {
            GoogleChromeApplication * chrome = [SBApplication applicationWithBundleIdentifier:@"com.google.Chrome"];
            SBElementArray * windows = [chrome windows];
            for (int i = 0; i < [windows count]; i++) {
                GoogleChromeWindow * window = [windows objectAtIndex:i];
                SBElementArray * tabs = [window tabs];
                for (int i = 0 ; i < [tabs count]; i++) {
                    GoogleChromeTab * tab = [tabs objectAtIndex:i];
                    NSString * site  = [browser checkURL:[tab URL]];
                    if (site.length > 0) {
					if ([[[ezregex alloc] init] checkMatch:[tab URL] pattern:@"(netflix)"]){
						// Chrome does not provide DOM, exclude
						continue;
					}
                    NSDictionary * page = [[NSDictionary alloc] initWithObjectsAndKeys:[tab title],@"title",[tab URL], @"url", @"Chrome", @"browser",  site, @"site", nil, @"DOM", nil];
                    [pages addObject:page];
                    }
                    else{
                        continue;
                    }
                }
            }
        }
        // Check to see Omniweb is running. If so, add tab's title and url to the array
        if ([browser checkIdentifier:@"com.omnigroup.OmniWeb5"]||[browser checkIdentifier:@"com.omnigroup.OmniWeb6"]) {
            OmniWebApplication * omniweb;
            if ([browser checkIdentifier:@"com.omnigroup.OmniWeb5"]) {
                // For version 5
                omniweb = [SBApplication applicationWithBundleIdentifier:@"com.omnigroup.OmniWeb5"];
            }
            else{
                // For version 6
                omniweb = [SBApplication applicationWithBundleIdentifier:@"com.omnigroup.OmniWeb6"];
            }
            SBElementArray * browsers = [omniweb browsers];
            for (int i = 0; i < [browsers count]; i++) {
                OmniWebBrowser * obrowser = [browsers objectAtIndex:i];
                SBElementArray * tabs = [obrowser tabs];
                for (int i = 0 ; i < [tabs count]; i++) {
                    OmniWebTab * tab = [tabs objectAtIndex:i];
                    NSString * site  = [browser checkURL:[tab address]];
                    if (site.length > 0) {
                    NSString * DOM;
                    if ([[[ezregex alloc] init] checkMatch:[tab address] pattern:@"(netflix)"]){
                        // Chrome does not provide DOM, exclude
                        DOM = [tab source];
                    }
                    else{
                        DOM = nil;
                    }
                    NSDictionary * page = [[NSDictionary alloc] initWithObjectsAndKeys:[tab title],@"title",[tab address], @"url", @"OmniWeb", @"browser", site, @"site", DOM, @"DOM", nil];
                    [pages addObject:page];
                    }
                    else{
                        continue;
                    }
                }
            }
        }
        NSMutableArray * final = [[NSMutableArray alloc] init];
        ezregex * ez = [[ezregex alloc] init];
        //Perform Regex and sanitize
        if (pages.count > 0) {
            for (NSDictionary *m in pages) {
                NSString * regextitle = [NSString stringWithFormat:@"%@",[m objectForKey:@"title"]];
                NSString * url = [NSString stringWithFormat:@"%@", [m objectForKey:@"url"]];
                NSString * site = [NSString stringWithFormat:@"%@", [m objectForKey:@"site"]];
                NSString * title;
                NSString * tmpepisode;
                NSString * tmpseason;
                if ([site isEqualToString:@"crunchyroll"]) {
                    //Add Regex Arguments Here
                    if ([ez checkMatch:url pattern:@"\\b[^/]+\\/episode-[0-9]+.*-[0-9]+$"]||[ez checkMatch:url pattern:@"\\b[^/]+\\/.*-movie-[0-9]+$"]) {
                        //Perform Sanitation
                        regextitle = [ez searchreplace:regextitle pattern:@"\\bCrunchyroll - Watch\\s"];
                        regextitle = [ez searchreplace:regextitle pattern:@"\\b\\s-\\sMovie\\s-\\sMovie"];
                        regextitle = [ez searchreplace:regextitle pattern:@"\\b\\sEpisode"];
                        regextitle = [ez searchreplace:regextitle pattern:@"\\D-\\s*.*$"];
                        tmpepisode = [ez findMatch:regextitle pattern:@"(\\d\\d\\d|\\d\\d|\\d)" rangeatindex:0];
                        title = [ez findMatch:regextitle pattern:@"\\b.*\\D" rangeatindex:0];
                        title = [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                        tmpepisode = [tmpepisode stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                        tmpseason = @"0"; //not supported
                    }
                    else
                    continue;
                }
                else if ([site isEqualToString:@"daisuki"]) {
                    //Add Regex Arguments for daisuki.net
                    if ([ez checkMatch:url pattern:@"^(?=.*\\banime\\b)(?=.*\\bwatch\\b).*"]) {
                        //Perform Sanitation
                        regextitle = [ez searchreplace:regextitle pattern:@"\\s-\\sDAISUKI\\b"];
                        regextitle = [ez searchreplace:regextitle pattern:@"\\D\\D\\s*.*\\s-"];
                        tmpepisode = [ez findMatch:regextitle pattern:@"(\\d\\d\\d|\\d\\d)" rangeatindex:0];
                        title = [ez findMatch:regextitle pattern:@"\\b\\D([^\\n\\r]*)$" rangeatindex:0];
                        title = [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                        tmpepisode = [tmpepisode stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                        tmpseason = @"0"; //not supported
                    }
                    else
                        continue; // Invalid address
                }
                // Following came from Taiga - https://github.com/erengy/taiga/ //
                else if ([site isEqualToString:@"animelab"]) {
                    if ([ez checkMatch:url pattern:@"(\\/player\\/)"]) {
                        regextitle = [ez searchreplace:regextitle pattern:@"AnimeLab\\s-\\s"];
                        
                        regextitle = [ez searchreplace:regextitle pattern:@"-\\sEpisode\\s"];
                        regextitle = [ez searchreplace:regextitle pattern:@"\\s-\\s.*"];
                        tmpepisode = [ez findMatch:regextitle pattern:@"(\\d\\d\\d|\\d\\d|\\d)" rangeatindex:0];
                        title = [ez findMatch:regextitle pattern:@"\\b.*\\D" rangeatindex:0];
                        title = [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                        tmpepisode = [tmpepisode stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                        tmpseason = @"0"; //not supported
                    }
                    else
                        continue; // Invalid address
                }
                else if ([site isEqualToString:@"animenewsnetwork"]) {
                    if ([ez checkMatch:url pattern:@"video\\/[0-9]+"]) {
                        regextitle = [ez searchreplace:regextitle pattern:@"\\b\\s-\\sAnime News Network$"];
                        regextitle = [ez searchreplace:regextitle pattern:@"\\s\\((s|d)\\)\\s"];
                        regextitle = [ez searchreplace:regextitle pattern:@"ep\\."];
                        tmpepisode = [ez findMatch:regextitle pattern:@"(\\d\\d\\d|\\d\\d|\\d)" rangeatindex:0];
                        title = [ez findMatch:regextitle pattern:@"\\b.*\\D" rangeatindex:0];
                        title = [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                        tmpepisode = [tmpepisode stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                        tmpseason = @"0"; //not supported
                    }
                    else
                        continue; // Invalid address
                }
                else if ([site isEqualToString:@"viz"]) {
                    if ([ez checkMatch:url pattern:@"anime\\/streaming\\/[^/]+-episode-[0-9]+\\/"]||[ez checkMatch:url pattern:@"anime\\/streaming\\/[^/]+-movie\\/"]) {
                        regextitle = [ez searchreplace:regextitle pattern:@"\\bVIZ.com - NEON ALLEY -\\s"];
                        regextitle = [ez searchreplace:regextitle pattern:@"\\s\\((DUB|SUB)\\)"];
                        regextitle = [ez searchreplace:regextitle pattern:@"\\b\\sEpisode"];
                        tmpepisode = [ez findMatch:regextitle pattern:@"(\\d\\d\\d|\\d\\d|\\d)" rangeatindex:0];
                        title = [ez findMatch:regextitle pattern:@"\\b.*\\s" rangeatindex:0];
                        title = [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                        tmpepisode = [tmpepisode stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                        tmpseason = @"0"; //not supported
                    }
                    else
                        continue; // Invalid address
                }
				else if ([site isEqualToString:@"netflix"]){
					//Experimental
                    if([ez checkMatch:url pattern:@"WiPlayer"]){
						NSString * DOM = [NSString stringWithFormat:@"%@",[m objectForKey:@"DOM"]];
						DOM = [ez findMatch:DOM pattern:@"\"metadata\":\"*.*\",\"initParams\"" rangeatindex:0];
                        DOM = [DOM stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                        DOM = [DOM stringByReplacingOccurrencesOfString:@"metadata:" withString:@""];
                        DOM = [DOM stringByReplacingOccurrencesOfString:@",initParams" withString:@""];
						// Decode JSON Data
						NSData * jsonData = [[NSData alloc] initWithBase64Encoding:DOM];
					    NSError* error;
					    NSDictionary *metadata = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&error];
						NSDictionary *videodata = [metadata objectForKey:@"video"];
						title = [videodata objectForKey:@"title"];
                        NSString * videoid = [NSString stringWithFormat:@"%@", [[ez findMatches:url pattern:@"\\b(movieid|EpisodeMovieId)=\\d+"] lastObject]];
                        videoid = [ez searchreplace:videoid pattern:@"(movieid|EpisodeMovieId)="];
						NSArray * seasondata = [videodata objectForKey:@"seasons"];
                        for (int i = 0; i < [seasondata count]; i++) {
                            NSDictionary * season = [seasondata objectAtIndex:i];
                            NSArray *episodes = [season objectForKey:@"episodes"];
                            for (int e = 0; e < [episodes count]; e++) {
                                NSDictionary * episode = [episodes objectAtIndex:e];
                                if (![videoid isEqualTo:[NSString stringWithFormat:@"%@", [episode objectForKey:@"id"]]]) {
                                    continue;
                                }
                                else{
                                    tmpepisode = [NSString stringWithFormat:@"%@", [episode objectForKey:@"seq"]];
                                    break;
                                }
                            }
                        }
                        tmpseason = @"0"; //not supported
					}
					else
						continue;
				}
                else{
                    continue;
                }
                NSNumber * episode;
                NSNumber * season;
                // Final Checks
                if ([tmpepisode length] ==0){
                    episode = [NSNumber numberWithInt:0];
                }
                else{
                    episode = [[[NSNumberFormatter alloc] init] numberFromString:tmpepisode];
                }
                if (title.length == 0) {
                    continue;
                }
                season = [[[NSNumberFormatter alloc] init] numberFromString:tmpseason];
                // Add to Final Array
                NSDictionary * frecord = [[NSDictionary alloc] initWithObjectsAndKeys:title, @"title", episode, @"episode", season, @"season", [m objectForKey:@"browser"], @"browser", site, @"site", nil];
                [final addObject:frecord];
            }
        }
        // Generate JSON and output
        NSDictionary * result;
        if (final.count > 0 ) {
            result = [[NSDictionary alloc] initWithObjectsAndKeys:final,@"result", nil];
        }
        else {
            // Empty final array, send null
            result = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNull null], @"result", nil];
        }

        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:result options:0 error:&error];
        if (!jsonData) {}
        else{
            NSString *JSONString = [[NSString alloc] initWithBytes:[jsonData bytes] length:[jsonData length] encoding:NSUTF8StringEncoding];
            NSLog(@"%@", JSONString);
        }
    }
    return 0;
}


