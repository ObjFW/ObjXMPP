/*
 * Copyright (c) 2011, Jonathan Schleifer <js@webkeks.org>
 * Copyright (c) 2011, Florian Zeitz <florob@babelmonkeys.de>
 *
 * https://webkeks.org/hg/objxmpp/
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice is present in all copies.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#include <stringprep.h>

#import "XMPPJID.h"
#import "XMPPExceptions.h"

@implementation XMPPJID
@synthesize node;
@synthesize domain;
@synthesize resource;

+ JID
{
	return [[[self alloc] init] autorelease];
}

+ JIDWithString: (OFString*)str
{
	return [[[self alloc] initWithString: str] autorelease];
}

- initWithString: (OFString*)str
{
	self = [super init];

	size_t nodesep, resourcesep;
	nodesep = [str indexOfFirstOccurrenceOfString: @"@"];
	resourcesep = [str indexOfFirstOccurrenceOfString: @"/"];

	if (nodesep == SIZE_MAX)
		[self setNode: nil];
	else
		[self setNode: [str substringFromIndex: 0
					       toIndex: nodesep]];

	if (resourcesep == SIZE_MAX) {
		[self setResource: nil];
		resourcesep = [str length];
	} else
		[self setResource: [str substringFromIndex: resourcesep + 1
						 toIndex: [str length]]];

	[self setDomain: [str substringFromIndex: nodesep + 1
					 toIndex: resourcesep]];

	return self;
}

- copy
{
	XMPPJID *new = [[XMPPJID alloc] init];

	@try {
		new->node = [node copy];
		new->domain = [domain copy];
		new->resource = [resource copy];
	} @catch (id e) {
		[new release];
		@throw e;
	}

	return new;
}

- (void)setNode: (OFString*)node_
{
	OFString *old = node;
	char *nodepart;
	Stringprep_rc rc;

	if (node_ == nil) {
		[old release];
		node = nil;
		return;
	}

	if ((rc = stringprep_profile([node_ cString], &nodepart,
	    "Nodeprep", 0)) != STRINGPREP_OK)
		@throw [XMPPStringPrepFailedException newWithClass: isa
							connection: nil
							   profile: @"Nodeprep"
							    string: node_];

	@try {
		node = [[OFString alloc] initWithCString: nodepart];
	} @finally {
		free(nodepart);
	}

	[old release];
}

- (void)setDomain: (OFString*)domain_
{
	OFString *old = domain;
	char *srv;
	Stringprep_rc rc;

	if ((rc = stringprep_profile([domain_ cString], &srv,
	    "Nameprep", 0)) != STRINGPREP_OK)
		@throw [XMPPStringPrepFailedException newWithClass: isa
							connection: nil
							   profile: @"Nameprep"
							    string: domain_];

	@try {
		domain = [[OFString alloc] initWithCString: srv];
	} @finally {
		free(srv);
	}

	[old release];
}

- (void)setResource: (OFString*)resource_
{
	OFString *old = resource;
	char *res;
	Stringprep_rc rc;

	if (resource_ == nil) {
		[old release];
		resource = nil;
		return;
	}

	if ((rc = stringprep_profile([resource_ cString], &res,
	    "Resourceprep", 0)) != STRINGPREP_OK)
		@throw [XMPPStringPrepFailedException
		    newWithClass: isa
		      connection: nil
			 profile: @"Resourceprep"
			  string: resource_];

	@try {
		resource = [[OFString alloc] initWithCString: res];
	} @finally {
		free(res);
	}

	[old release];
}

- (OFString*)bareJID
{
	if (node != nil)
		return [OFString stringWithFormat: @"%@@%@", node, domain];
	else
		return [OFString stringWithFormat: @"%@", domain];
}

- (OFString*)fullJID
{
	/* If we don't have a resource, the full JID is equal to the bare JID */
	if (resource == nil)
		return [self bareJID];

	if (node != nil)
		return [OFString stringWithFormat: @"%@@%@/%@",
		       node, domain, resource];
	else
		return [OFString stringWithFormat: @"%@/%@",
		       domain, resource];
}
@end
