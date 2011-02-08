#include <ObjFW/ObjFW.h>
#import "XMPPConnection.h"

@interface AppDelegate: OFObject
{
	XMPPConnection *conn;
}
@end

OF_APPLICATION_DELEGATE(AppDelegate)

@implementation AppDelegate
- (void)applicationDidFinishLaunching
{
	OFArray *arguments = [OFApplication arguments];

	conn = [[XMPPConnection alloc] init];

	if (arguments.count != 3) {
		of_log(@"Invalid count of command line arguments!");
		[OFApplication terminateWithStatus: 1];
	}

	[conn setServer: [arguments objectAtIndex: 0]];
	[conn setUsername: [arguments objectAtIndex: 1]];
	[conn setPassword: [arguments objectAtIndex: 2]];
	[conn setResource: @"ObjXMPP"];
	[conn setUseTLS: NO];

	[conn connect];
	[conn handleConnection];
}
@end
