/*
 * termcolors.h
 *
 * Copyright (c) 2020-2021 Nikias Bassen, All Rights Reserved.
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
#ifndef TERMCOLORS_H
#define TERMCOLORS_H

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include <stdarg.h>
#include <stdio.h>

#define COLOR_RESET           "\e[m"
#define STYLE_NORMAL          "\e[0m"
#define STYLE_BRIGHT          "\e[1m"
#define STYLE_DARK            "\e[2m"
#define FG_BLACK              "\e[0;30m"
#define FG_DARK_GRAY          "\e[1;30m"
#define FG_RED                "\e[0;31m"
#define FG_BRIGHT_RED         "\e[1;31m"
#define FG_DARK_RED           "\e[2;31m"
#define FG_GREEN              "\e[0;32m"
#define FG_BRIGHT_GREEN       "\e[1;32m"
#define FG_DARK_GREEN         "\e[2;32m"
#define FG_YELLOW             "\e[0;33m"
#define FG_BRIGHT_YELLOW      "\e[1;33m"
#define FG_DARK_YELLOW        "\e[2;33m"
#define FG_BLUE               "\e[0;34m"
#define FG_BRIGHT_BLUE        "\e[1;34m"
#define FG_DARK_BLUE          "\e[2;34m"
#define FG_MAGENTA            "\e[0;35m"
#define FG_BRIGHT_MAGENTA     "\e[1;35m"
#define FG_DARK_MAGENTA       "\e[2;35m"
#define FG_CYAN               "\e[0;36m"
#define FG_BRIGHT_CYAN        "\e[1;36m"
#define FG_DARK_CYAN          "\e[2;36m"
#define FG_LIGHT_GRAY         "\e[0;37m"
#define FG_WHITE              "\e[1;37m"
#define FG_GRAY               "\e[2;37m"
#define FG_DEFAULT            "\e[39m"
#define BG_BLACK              "\e[40m"
#define BG_GRAY               "\e[100m"
#define BG_RED                "\e[41m"
#define BG_BRIGHT_RED         "\e[101m"
#define BG_GREEN              "\e[42m"
#define BG_BRIGHT_GREEN       "\e[102m"
#define BG_YELLOW             "\e[43m"
#define BG_BRIGHT_YELLOW      "\e[103m"
#define BG_BLUE               "\e[44m"
#define BG_BRIGHT_BLUE        "\e[104m"
#define BG_MAGENTA            "\e[45m"
#define BG_BRIGHT_MAGENTA     "\e[105m"
#define BG_CYAN               "\e[46m"
#define BG_BRIGHT_CYAN        "\e[106m"
#define BG_LIGHT_GRAY         "\e[47m"
#define BG_WHITE              "\e[107m"
#define BG_DEFAULT            "\e[49m"

/* automatically called by library constructor */
void term_colors_init();

/* enable / disable terminal colors */
void term_colors_set_enabled(int en);

/* color-aware *printf variants */
int cprintf(const char* fmt, ...);
int cfprintf(FILE* stream, const char* fmt, ...);
int cvfprintf(FILE* stream, const char* fmt, va_list vargs);

#endif
