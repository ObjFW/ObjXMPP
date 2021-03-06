/*
 * Copyright (c) 2011, 2012, 2013, 2019, 2021, Jonathan Schleifer <js@nil.im>
 * Copyright (c) 2011, Florian Zeitz <florob@babelmonkeys.de>
 *
 * https://nil.im/objxmpp/
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

#import "XMPPMessage.h"
#import "namespaces.h"

@implementation XMPPMessage
+ (instancetype)message
{
	return [[[self alloc] init] autorelease];
}

+ (instancetype)messageWithID: (OFString *)ID
{
	return [[[self alloc] initWithID: ID] autorelease];
}

+ (instancetype)messageWithType: (OFString *)type
{
	return [[[self alloc] initWithType: type] autorelease];
}

+ (instancetype)messageWithType: (OFString *)type ID: (OFString *)ID
{
	return [[[self alloc] initWithType: type ID: ID] autorelease];
}

- (instancetype)init
{
	return [self initWithType: nil ID: nil];
}

- (instancetype)initWithID: (OFString *)ID
{
	return [self initWithType: nil ID: ID];
}

- (instancetype)initWithType: (OFString *)type
{
	return [self initWithType: type ID: nil];
}

- (instancetype)initWithType: (OFString *)type ID: (OFString *)ID
{
	return [super initWithName: @"message" type: type ID: ID];
}

- (void)setBody: (OFString *)body
{
	OFXMLElement *oldBody = [self elementForName: @"body"
					   namespace: XMPPClientNS];

	if (oldBody != nil)
		[self removeChild: oldBody];

	if (body != nil)
		[self addChild: [OFXMLElement elementWithName: @"body"
						    namespace: XMPPClientNS
						  stringValue: body]];
}

- (OFString *)body
{
	return [self elementForName: @"body"
			  namespace: XMPPClientNS].stringValue;
}
@end
