//
//  TFLogReader.m
//  TestFairy
//
//  Copyright © 2016 TestFairy. All rights reserved.
//

#import "TFLogReader.h"
#import <asl.h>
#import <stdlib.h>

@implementation TFLogReader

+ (NSArray *)logs:(NSArray *)filter {
	aslmsg m;
	const char *val;
	char logId[128];
	strcpy(logId, "0");

	NSMutableArray *logs = [NSMutableArray array];
	
	aslmsg q = asl_new(ASL_TYPE_QUERY);
	asl_set_query(q, ASL_KEY_MSG_ID, logId, ASL_QUERY_OP_GREATER);
	aslresponse r = asl_search(NULL, q);
	
	NSString *msg = @"";
	NSString *sender = nil;
	
	while ((m = aslresponse_next(r)) != NULL) {
		BOOL sendMessage = YES;
		
		val = asl_get(m, ASL_KEY_SENDER);
		if (val) {
			// message sender
			sender = [NSString stringWithUTF8String:val];
			if (filter == nil) {
				sendMessage = YES;
			} else {
				sendMessage = [filter containsObject:sender];
			}
		}

		val = asl_get(m, ASL_KEY_MSG);
		if (val && sendMessage) {
			msg = [NSString stringWithUTF8String:val];
			[logs addObject:msg];
		}
	}
	
	aslresponse_free(r);
	
	return logs;
}

@end
