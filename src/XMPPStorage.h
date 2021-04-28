/*
 * Copyright (c) 2012, 2021, Jonathan Schleifer <js@nil.im>
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

#import <ObjFW/OFObject.h>

OF_ASSUME_NONNULL_BEGIN

@class OFString;
@class OFArray;
@class OFDictionary;

@protocol XMPPStorage <OFObject>
- (void)save;
- (void)setStringValue: (nullable OFString *)string
	       forPath: (OFString *)path;
- (nullable OFString *)stringValueForPath: (OFString *)path;
- (void)setBooleanValue: (bool)boolean
		forPath: (OFString *)path;
- (bool)booleanValueForPath: (OFString *)path;
- (void)setIntegerValue: (long long)integer
		forPath: (OFString *)path;
- (long long)integerValueForPath: (OFString *)path;
- (void)setArray: (nullable OFArray *)array
	 forPath: (OFString *)path;
- (nullable OFArray *)arrayForPath: (OFString *)path;
- (void)setDictionary: (nullable OFDictionary *)dictionary
	      forPath: (OFString *)path;
- (nullable OFDictionary *)dictionaryForPath: (OFString *)path;
@end

OF_ASSUME_NONNULL_END
