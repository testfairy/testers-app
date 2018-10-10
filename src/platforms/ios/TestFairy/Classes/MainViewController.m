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
#import "TFLogReader.h"
#import <Cordova/CDVUserAgentUtil.h>

#define kCookieURL @"https://my.testfairy.com/register-notification-cookie/?token="

@import GoogleSignIn;

@interface MainViewController() <NSURLConnectionDelegate, GIDSignInUIDelegate>

@end

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

- (id)init {
    if (self = [super init]) {
		token = @"";
		
		// callback when push notification token has been received
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tokenChanged:) name:CDVRemoteNotification object:nil];
		
		// callback when webview cookies changed (check cookie "l")
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cookiesChanged) name:NSHTTPCookieManagerCookiesChangedNotification object:nil];

		// update user-agent
		NSString *userAgent = [CDVUserAgentUtil originalUserAgent];
		NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
		self.baseUserAgent = [userAgent stringByAppendingString: [NSString stringWithFormat:@" TestersApp/%@", version]];
    }
	
    return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	[GIDSignIn sharedInstance].uiDelegate = self;
}

- (void)tokenChanged:(NSNotification *)tokenObject {
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

// gilm, open safari: urls in safari
- (BOOL) webView:(UIWebView*)theWebView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType
{
	NSString *url = [[request URL] absoluteString];
	NSLog(@"URL %@", url);
	NSRange range = [url rangeOfString: @"safari:"];
	if (range.location == 0) {
		url = [url substringFromIndex:range.length];
		[[UIApplication sharedApplication] openURL: [[NSURL alloc] initWithString: url]];
		return NO;
	}
	
	NSString *logUploadPrefix = @"testers-app://get-log";
	if ([url hasPrefix:logUploadPrefix]) {
		[self uploadLogs:[self extractSenders:url prefix:logUploadPrefix]];
		return NO;
	}
	
	if ([url containsString:@"/signup/google/"]) {
		[[GIDSignIn sharedInstance] signIn];
		return NO;
	}
	
	if ([url containsString:@"/logout/"]) {
		[[GIDSignIn sharedInstance] signOut];
	}
	
	return [super webView:theWebView shouldStartLoadWithRequest:request navigationType:navigationType];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	@try {
		NSError *error;
		NSString *jsonString = [[NSString alloc] initWithData:data  encoding:NSUTF8StringEncoding];
		NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
		NSDictionary *responseData = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
		NSString *redirect = [responseData objectForKey:@"redirect"];
		[self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:redirect]]];
	} @catch (NSException * exception) {
		NSLog(@"TestFairy: Exception when parsing response data");
	}
}

- (void) uploadLogs:(NSArray *)senders {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		NSArray *logs = [TFLogReader logs:senders];
		NSMutableString *log = [NSMutableString string];
		for (NSString *item in logs) {
			[log appendString:item];
			[log appendString:@"\r\n"];
		}

		NSDictionary *data = @{@"logs": log};
		NSURLRequest *request = [self createRequest:data];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[NSURLConnection connectionWithRequest:request delegate:self];
		});
	});
}

- (NSURLRequest *) createRequest:(NSDictionary *)requestData {
	NSString *url = [NSString stringWithFormat:@"%@/my/troubleshooting/logs-analysis", self.startPage];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
	[request setTimeoutInterval:30];
	[request setHTTPMethod:@"POST"];
	
	NSString *boundary = @"EZg2YAjpj1YPo2yp";
	NSMutableData *body = [NSMutableData data];
	
	NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
	[request setValue:contentType forHTTPHeaderField: @"Content-Type"];
	
	// add params (all params are strings)
	for (NSString *param in [requestData allKeys]) {
		[body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", param] dataUsingEncoding:NSUTF8StringEncoding]];
		
		NSObject *value = [requestData objectForKey:param];
		if ([value isKindOfClass:[NSData class]]) {
			// send as binary
			[body appendData:(NSData *)value];
			[body appendData:[@"%@\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
		} else {
			// use string encoding
			[body appendData:[[NSString stringWithFormat:@"%@\r\n", value] dataUsingEncoding:NSUTF8StringEncoding]];
		}
	}
	
	[body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	// setting the body of the post to the reqeust
	[request setHTTPBody:body];
	
	return request;
}

- (NSArray *)extractSenders:(NSString *)url prefix:(NSString *)prefix {
	NSString* senderString = [url substringWithRange:NSMakeRange(prefix.length, url.length - prefix.length)];
	NSArray *senders = [senderString componentsSeparatedByString:@"/"];
	NSMutableArray *all = nil;
	for (NSString *sender in senders) {
		if (sender == nil || [@"" isEqualToString:sender]) {
			continue;
		}
		
		if (all == nil) {
			all = [NSMutableArray array];
		}
		
		[all addObject:sender];
	}
	
	return all;
}

#pragma mark - GIDSignInUIDelegate

// Present a view that prompts the user to sign in with Google
- (void)signIn:(GIDSignIn *)signIn presentViewController:(UIViewController *)viewController {
	[self presentViewController:viewController animated:YES completion:nil];
}

// Dismiss the "Sign in with Google" view
- (void)signIn:(GIDSignIn *)signIn dismissViewController:(UIViewController *)viewController {
	[self dismissViewControllerAnimated:YES completion:nil];
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
