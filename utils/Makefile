# Makefile - contains build system for host utilities
# SPDX-License-Identifier: ISC

all: ../utilsbin/confgen ../utilsbin/mbrwrap ../utilsbin/mbrwrite

../utilsbin/%: %.c Makefile
	@echo "Compiling $@"
	@$(CC) -O3 -DNDEBUG -std=gnu11 -o $@ $<

.PHONY: all
