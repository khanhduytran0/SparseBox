/*
 * opack.h
 * "opack" format encoder/decoder implementation.
 *
 * Copyright (c) 2021 Nikias Bassen, All Rights Reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 */
#ifndef __OPACK_H
#define __OPACK_H

#include <plist/plist.h>

void opack_encode_from_plist(plist_t plist, unsigned char** out, unsigned int* out_len);
int opack_decode_to_plist(unsigned char* buf, unsigned int buf_len, plist_t* plist_out);

#endif /* __OPACK_H */
