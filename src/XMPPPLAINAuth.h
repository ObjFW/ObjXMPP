/*
 * Copyright (c) 2011, Florian Zeitz <florob@babelmonkeys.de>
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

#import <ObjFW/ObjFW.h>
#import "XMPPAuthenticator.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * \brief A class to authenticate using SASL PLAIN
 */
@interface XMPPPLAINAuth: XMPPAuthenticator
/**
 * \brief Creates a new autoreleased XMPPPLAINAuth with an authcid and password.
 *
 * \param authcid The authcid to authenticate with
 * \param password The password to authenticate with
 * \return A new autoreleased XMPPPLAINAuth
 */
+ (instancetype)PLAINAuthWithAuthcid: (nullable OFString *)authcid
			    password: (nullable OFString *)password;

/**
 * \brief Creates a new autoreleased XMPPPLAINAuth with an authzid, authcid and
 *	  password.
 *
 * \param authzid The authzid to get authorization for
 * \param authcid The authcid to authenticate with
 * \param password The password to authenticate with
 * \return A new autoreleased XMPPPLAINAuth
 */
+ (instancetype)PLAINAuthWithAuthzid: (nullable OFString *)authzid
			     authcid: (nullable OFString *)authcid
			    password: (nullable OFString *)password;
@end

OF_ASSUME_NONNULL_END
