/*
 * tlv.h
 * Simple TLV implementation.
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
#ifndef __TLV_H
#define __TLV_H

#include <stdint.h>

struct tlv_buf {
	unsigned char* data;
	unsigned int length;
	unsigned int capacity;
};
typedef struct tlv_buf* tlv_buf_t;

tlv_buf_t tlv_buf_new();
void tlv_buf_free(tlv_buf_t tlv);

void tlv_buf_append(tlv_buf_t tlv, uint8_t tag, unsigned int length, void* data);
unsigned char* tlv_get_data_ptr(const void* tlv_data, void* tlv_end, uint8_t tag, uint8_t* length);
int tlv_data_get_uint(const void* tlv_data, unsigned int tlv_length, uint8_t tag, uint64_t* value);
int tlv_data_get_uint8(const void* tlv_data, unsigned int tlv_length, uint8_t tag, uint8_t* value);
int tlv_data_copy_data(const void* tlv_data, unsigned int tlv_length, uint8_t tag, void** out, unsigned int* out_len);

#endif /* __TLV_H */
