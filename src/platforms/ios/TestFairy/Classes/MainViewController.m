/*
 Licensed to the Apache Software Foundation (ASF) under one
 or more contributor license agreements.  See the NOTICE file
 distributed with this work for additional information
 regarding copyright ownership.  The ASF licenses this file
 to you under the Apache License, Version 2.0 (the
 "License"); you may not use this file except in compliance
 with the License.  You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing,
 software distributed under the License is distributed on an
 "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 KIND, either express or implied.  See the License for the
 specific language governing permissions and limitations
 under the License.
 */

//
//  MainViewController.h
//  TestFairy
//
//  Created by ___FULLUSERNAME___ on ___DATE___.
//  Copyright ___ORGANIZATIONNAME___ ___YEAR___. All rights reserved.
//

#import "MainViewController.h"
#import <Cordova/CDVUserAgentUtil.h>

#define kCookieURL @"https://my.testfairy.com/register-notification-cookie/?token="

@implementation MainViewController

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Uncomment to override the CDVCommandDelegateImpl used
        // _commandDelegate = [[MainCommandDelegate alloc] initWithViewController:self];
        // Uncomment to override the CDVCommandQueue used
        // _commandQueue = [[MainCommandQueue alloc] initWithViewController:self];
    }
	
    return self;
}

- (id)init
{
    self = [super init];
    if (self) {
	token = @"";
	    
	// callback when push notification token has been received
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tokenChanged:) name:CDVRemoteNotification object:nil];
	    
	// callback when webview cookies changed (check cookie "l")
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cookiesChanged) name:NSHTTPCookieManagerCookiesChangedNotification object:nil];

	// update user-agent
	NSString *userAgent = [CDVUserAgentUtil originalUserAgent];
	NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
	self.baseUserAgent = [userAgent stringByAppendingString: [NSString stringWithFormat:@" TestersApp/%@", version]];
    }
	
    return self;
}

- (void)tokenChanged:(NSNotification *)tokenObject
{
	if ([[tokenObject object] isKindOfClass:[NSString class]]) {
		token = [tokenObject object];
	}
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];

    // Release any cached data, images, etc that aren't in use.
}

#pragma mark View lifecycle

- (void)viewWillAppear:(BOOL)animated
{
    // View defaults to full size.  If you want to customize the view's size, or its subviews (e.g. webView),
    // you can do so here.
	
    [super viewWillAppear:animated];
}

// testfairy
- (void)cookiesChanged
{
	NSHTTPCookie *cookie = nil;
	for (NSHTTPCookie *curCookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]) {
		// user has logged in and now has the "l" cookie
		if ([[[curCookie name] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] isEqualToString:@"l"]) {
			cookie = curCookie;
			break;
		}
	}
	
	if (cookie && token && [token isKindOfClass:[NSString class]]) {
		NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@", kCookieURL, [token stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]]];

		NSArray* cookies = [NSArray arrayWithObjects: cookie, nil];
	
		NSDictionary *headers = [NSHTTPCookie requestHeaderFieldsWithCookies:cookies];
	
		[request setAllHTTPHeaderFields:headers];
		[NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue currentQueue] completionHandler:^(NSURLResponse *response, NSData *responseData, NSError *error) {}];
	}
}

- (void)viewDidLoad
{
	// viewDidLoad creates self.webView
	[super viewDidLoad];

}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return [super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

/* Comment out the block below to over-ride */

/*
- (UIWebView*) newCordovaViewWithFrame:(CGRect)bounds
{
    return[super newCordovaViewWithFrame:bounds];
}
*/

#pragma mark UIWebDelegate implementation

- (void)webViewDidFinishLoad:(UIWebView*)theWebView
{
    // Black base color for background matches the native apps
    theWebView.backgroundColor = [UIColor blackColor];
	
	[self cookiesChanged];

    return [super webViewDidFinishLoad:theWebView];
}

/* Comment out the block below to over-ride */

/*

- (void) webViewDidStartLoad:(UIWebView*)theWebView
{
    return [super webViewDidStartLoad:theWebView];
}

- (void) webView:(UIWebView*)theWebView didFailLoadWithError:(NSError*)error
{
    return [super webView:theWebView didFailLoadWithError:error];
}

- (BOOL) webView:(UIWebView*)theWebView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType
{
    return [super webView:theWebView shouldStartLoadWithRequest:request navigationType:navigationType];
}
*/

// gilm, open testfairy:// urls in Safari
- (BOOL) webView:(UIWebView*)theWebView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType
{
	NSString *url = [[request URL] absoluteString];
	NSRange range = [url rangeOfString: @"safari:"];
	if (range.location == 0) {
		url = [url substringFromIndex:range.length];
		[[UIApplication sharedApplication] openURL: [[NSURL alloc] initWithString: url]];
		return NO;
	}
	
	return [super webView:theWebView shouldStartLoadWithRequest:request navigationType:navigationType];
}

@end

@implementation MainCommandDelegate

/* To override the methods, uncomment the line in the init function(s)
   in MainViewController.m
 */

#pragma mark CDVCommandDelegate implementation

- (id)getCommandInstance:(NSString*)className
{
    return [super getCommandInstance:className];
}

- (NSString*)pathForResource:(NSString*)resourcepath
{
    return [super pathForResource:resourcepath];
}

@end

@implementation MainCommandQueue

/* To override, uncomment the line in the init function(s)
   in MainViewController.m
 */
- (BOOL)execute:(CDVInvokedUrlCommand*)command
{
    return [super execute:command];
}

@end
