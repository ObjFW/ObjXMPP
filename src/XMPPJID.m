/*
 * Copyright (c) 2011, Jonathan Schleifer <js@webkeks.org>
 * Copyright (c) 2011, Florian Zeitz <florob@babelmonkeys.de>
 *
 * https://webkeks.org/git/?p=objxmpp.git
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

#ifdef HAVE_CONFIG_H
# include "config.h"
#endif

#include <string.h>

#include <stringprep.h>

#import "XMPPJID.h"
#import "XMPPExceptions.h"

@implementation XMPPJID
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
	size_t nodesep, resourcesep;

	self = [super init];

	if (str == nil) {
		[self release];
		return nil;
	}

	nodesep = [str rangeOfString: @"@"].location;
	resourcesep = [str rangeOfString: @"/"].location;

	if (nodesep == SIZE_MAX)
		[self setNode: nil];
	else
		[self setNode: [str substringWithRange: of_range(0, nodesep)]];

	if (resourcesep == SIZE_MAX) {
		[self setResource: nil];
		resourcesep = [str length];
	} else
		[self setResource: [str substringWithRange:
		    of_range(resourcesep + 1, [str length] - resourcesep - 1)]];

	[self setDomain: [str substringWithRange:
	    of_range(nodesep + 1, resourcesep - nodesep - 1)]];

	return self;
}

- (void)dealloc
{
	[node release];
	[domain release];
	[resource release];

	[super dealloc];
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

	if (((rc = stringprep_profile([node_ UTF8String], &nodepart,
	    "Nodeprep", 0)) != STRINGPREP_OK) || (nodepart[0] == '\0') ||
	    (strlen(nodepart) > 1023))
		@throw [XMPPStringPrepFailedException
		    exceptionWithClass: [self class]
			    connection: nil
			       profile: @"Nodeprep"
				string: node_];

	@try {
		node = [[OFString alloc] initWithUTF8String: nodepart];
	} @finally {
		free(nodepart);
	}

	[old release];
}

- (OFString*)node
{
	return [[node copy] autorelease];
}

- (void)setDomain: (OFString*)domain_
{
	OFString *old = domain;
	char *srv;
	Stringprep_rc rc;

	if (((rc = stringprep_profile([domain_ UTF8String], &srv,
	    "Nameprep", 0)) != STRINGPREP_OK) || (srv[0] == '\0') ||
	    (strlen(srv) > 1023))
		@throw [XMPPStringPrepFailedException
		    exceptionWithClass: [self class]
			    connection: nil
			       profile: @"Nameprep"
				string: domain_];

	@try {
		domain = [[OFString alloc] initWithUTF8String: srv];
	} @finally {
		free(srv);
	}

	[old release];
}

- (OFString*)domain
{
	return [[domain copy] autorelease];
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

	if (((rc = stringprep_profile([resource_ UTF8String], &res,
	    "Resourceprep", 0)) != STRINGPREP_OK) || (res[0] == '\0') ||
	    (strlen(res) > 1023))
		@throw [XMPPStringPrepFailedException
		    exceptionWithClass: [self class]
			    connection: nil
			       profile: @"Resourceprep"
				string: resource_];

	@try {
		resource = [[OFString alloc] initWithUTF8String: res];
	} @finally {
		free(res);
	}

	[old release];
}

- (OFString*)resource
{
	return [[resource copy] autorelease];
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

- (OFString*)description
{
	return [self fullJID];
}

- (BOOL)isEqual: (id)object
{
	XMPPJID *otherJID;

	if (object == self)
		return YES;

	if (![object isKindOfClass: [XMPPJID class]])
		return NO;

	otherJID = object;

	if ([node isEqual: [otherJID node]] &&
	    [domain isEqual: [otherJID domain]] &&
	    [resource isEqual: [otherJID resource]])
		return YES;

	return NO;
}

- (uint32_t) hash
{
	return [[self fullJID] hash];
}
@end
