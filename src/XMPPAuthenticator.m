/*
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

#ifdef HAVE_CONFIG_H
# include "config.h"
#endif

#import "XMPPAuthenticator.h"

@implementation XMPPAuthenticator
- initWithAuthcid: (OFString*)authcid_
	 password: (OFString*)password_
{
	return [self initWithAuthzid: nil
			     authcid: authcid_
			    password: password_];
}

- initWithAuthzid: (OFString*)authzid_
	  authcid: (OFString*)authcid_
	 password: (OFString*)password_
{
	self = [super init];

	[self setAuthzid: authzid_];
	[self setAuthcid: authcid_];
	[self setPassword: password_];

	return self;
}

- (void)dealloc
{
	[authzid release];
	[authcid release];
	[password release];

	[super dealloc];
}

- (void)setAuthzid: (OFString*)authzid_
{
	OFString *old = authzid;
	authzid = [authzid_ copy];
	[old release];
}

- (OFString*)authzid
{
	return [[authzid copy] autorelease];
}

- (void)setAuthcid: (OFString*)authcid_
{
	OFString *old = authcid;
	authcid = [authcid_ copy];
	[old release];
}

- (OFString*)authcid
{
	return [[authcid copy] autorelease];
}

- (void)setPassword: (OFString*)password_
{
	OFString *old = password;
	password = [password_ copy];
	[old release];
}

- (OFString*)password
{
	return [[password copy] autorelease];
}

- (OFDataArray*)initialMessage
{
	return nil;
}

- (OFDataArray*)continueWithData: (OFDataArray*)challenge
{
	return nil;
}
@end
