#import "XMPPIQ.h"

@implementation XMPPIQ
+ IQWithType: (OFString*)type_
	  ID: (OFString*)ID_
{
	return [[[self alloc] initWithType: type_
					ID: ID_] autorelease];
}

- initWithType: (OFString*)type_
	    ID: (OFString*)ID_
{
	if (!([type_ isEqual: @"get"] ||
	      [type_ isEqual: @"set"] ||
	      [type_ isEqual: @"result"] ||
	      [type_ isEqual: @"error"]))
		of_log(@"Invalid IQ type!");

	return [super initWithName: @"iq"
			     type: type_
			       ID: ID_];
}
@end
