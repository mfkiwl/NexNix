# Makefile - contains build system for host utilities
# SPDX-License-Identifier: ISC

all: ../utilsbin/confgen ../utilsbin/mbrwrap ../utilsbin/mbrwrite

../utilsbin/%:  %.c
	@echo "Compiling $@"
	@$(CC) -std=gnu11 -o $@ $<

.PHONY: all
