/*
 * Copyright (c) 2012, Florian Zeitz <florob@babelmonkeys.de>
 * Copyright (c) 2019, 2021, Jonathan Schleifer <js@nil.im>
 *
 * https://heap.zone/objxmpp/
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

#include "config.h"

#import "XMPPEXTERNALAuth.h"

@implementation XMPPEXTERNALAuth: XMPPAuthenticator
+ (instancetype)EXTERNALAuth
{
	return [[[self alloc] initWithAuthcid: nil password: nil] autorelease];
}

+ (instancetype)EXTERNALAuthWithAuthzid: (OFString *)authzid
{
	return [[[self alloc] initWithAuthzid: authzid
				      authcid: nil
				     password: nil] autorelease];
}

- (OFData *)initialMessage
{
	OFMutableData *message = [OFMutableData data];

	/* authzid */
	if (_authzid != nil)
		[message addItems: _authzid.UTF8String
			    count: _authzid.UTF8StringLength];

	[message makeImmutable];

	return message;
}
@end
