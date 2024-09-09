/*
 * cbuf.h
 * Simple char buffer implementation.
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

#ifndef __CBUF_H
#define __CBUF_H

struct char_buf {
	unsigned char* data;
	unsigned int length;
	unsigned int capacity;
};

struct char_buf* char_buf_new();
void char_buf_free(struct char_buf* cbuf);
void char_buf_append(struct char_buf* cbuf, unsigned int length, unsigned char* data);

#endif /* __CBUF_H */
