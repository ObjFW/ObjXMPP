/*
 * Copyright (c) 2012, Florian Zeitz <florob@babelmonkeys.de>
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

#import <ObjFW/ObjFW.h>
#import "XMPPAuthenticator.h"

OF_ASSUME_NONNULL_BEGIN

/*!
 * @brief A class to authenticate using SASL EXTERNAL
 */
@interface XMPPEXTERNALAuth: XMPPAuthenticator
/*!
 * @brief Creates a new autoreleased XMPPEXTERNALAuth.
 *
 * @return A new autoreleased XMPPEXTERNALAuth
 */
+ (instancetype)EXTERNALAuth;

/*!
 * @brief Creates a new autoreleased XMPPEXTERNALAuth with an authzid.
 *
 * @param authzid The authzid to get authorization for
 * @return A new autoreleased XMPPEXTERNALAuth
 */
+ (instancetype)EXTERNALAuthWithAuthzid: (nullable OFString *)authzid;
@end

OF_ASSUME_NONNULL_END
