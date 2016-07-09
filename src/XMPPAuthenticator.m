/*
 * Copyright (c) 2011, Florian Zeitz <florob@babelmonkeys.de>
 * Copyright (c) 2016, Jonathan Schleifer <js@heap.zone>
 *
 * https://heap.zone/git/?p=objxmpp.git
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
@synthesize authzid = _authzid, authcid = _authcid, password = _password;

- initWithAuthcid: (OFString*)authcid
	 password: (OFString*)password
{
	return [self initWithAuthzid: nil
			     authcid: authcid
			    password: password];
}

- initWithAuthzid: (OFString*)authzid
	  authcid: (OFString*)authcid
	 password: (OFString*)password
{
	self = [super init];

	@try {
		_authzid = [authzid copy];
		_authcid = [authcid copy];
		_password = [password copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_authzid release];
	[_authcid release];
	[_password release];

	[super dealloc];
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
