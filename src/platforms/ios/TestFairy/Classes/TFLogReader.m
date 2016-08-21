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

+ (NSArray *)logs {
	aslmsg m;
	const char *val;
	char logId[128];
	strcpy(logId, "0");

	NSMutableArray *logs = [NSMutableArray array];
	
	aslmsg q = asl_new(ASL_TYPE_QUERY);
	asl_set_query(q, ASL_KEY_MSG_ID, logId, ASL_QUERY_OP_GREATER);
	aslresponse r = asl_search(NULL, q);
	
	while ((m = aslresponse_next(r)) != NULL) {
		NSString *msg = @"";
		val = asl_get(m, ASL_KEY_MSG);
		
		if (val) {
			msg = [NSString stringWithUTF8String:val];
			[logs addObject:msg];
		}
	}
	
	aslresponse_free(r);
	
	return logs;
}

@end
