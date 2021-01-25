#
# MIT License
#
# Copyright (c) 2021 Zakhary Kaplan
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

# --------------------------------
#          Configuration
# --------------------------------

# Root directory
ROOT  := ~/ece344


# --------------------------------
#            Variables
# --------------------------------

# Directories
REPO   := $(ROOT)/os161
BUILD  := $(ROOT)/build
MARKER := $(ROOT)/marker

# Commands
MAKE  += -j1
MKDIR  = mkdir -p
RM     = rm -rf

# State
KERNEL := $(shell readlink $(BUILD)/kernel)
ASSTNO := $(KERNEL:kernel-ASST%=%)


# --------------------------------
#           Build Rules
# --------------------------------

# Explicitly set default goal
.DEFAULT_GOAL := all

# Build the current kernel
.PHONY: all
all: assert-build asst$(ASSTNO)

# Clean build directories
.PHONY:
clean:
	@$(MAKE) -C $(REPO) clean
	@$(RM) $(BUILD)


# --------------------------------
#          Primary Rules
# --------------------------------

# Assert an assignment kernel is built
.PHONY: assert-build
assert-build: $(BUILD)/kernel

$(BUILD)/kernel:
	$(error please build an assignment and try again)

# Compile an assignment kernel build
asst%: $(BUILD) $(BUILD)/kernel-ASST% FORCE
	@cd $(BUILD)
	# Copy the assignment simulator configuration file into the build directory
	@ln -sf /cad2/ece344s/tester/sysconfig/sys161-$@.conf sys161.conf

$(BUILD)/kernel-%: $(REPO)/kern/compile/% FORCE
	@cd $<
	# Build and install the kernel
	@$(MAKE) depend
	@$(MAKE)
	@$(MAKE) install

$(REPO)/kern/compile/%: KERN = $(@F)
$(REPO)/kern/compile/%:
	@cd $(REPO)/kern/conf
	# Configure a kernel named $(KERN)
	@./config $(KERN)

# Run preliminary setup
.PHONY: setup
setup: $(BUILD)

$(BUILD):
	@cd $(REPO)
	# Configure your tree for the machine on which you are working
	@./configure --werror --ostree=$$HOME/ece344/build
	# Build and install the user level utilities
	@$(MAKE)


# --------------------------------
#         Secondary Rules
# --------------------------------

# Run kernel with debug flag
.PHONY: debug
debug: assert-build
	@cd $(BUILD)
	@sys161 -w kernel

# Run cs161-gdb
.PHONY: gdb
gdb: assert-build $(BUILD)/.gdbinit
	@cd $(BUILD)
	@cs161-gdb kernel

$(BUILD)/.gdbinit:
	@echo 'target remote unix:.sockets/gdb' >| $@

# Run the marker
.PHONY: mark
mark: mark$(ASSTNO)

mark%: assert-build FORCE
	@$(MKDIR) $(MARKER)
	@cd $(MARKER)
	@os161-tester -m $*

# Run the compiled kernel
.PHONY: run
run: assert-build
	@cd $(BUILD)
	@sys161 kernel

# Run the tester
.PHONY: test
test: test$(ASSTNO)

test%: assert-build FORCE
	@cd $(BUILD)
	@os161-tester $*


# --------------------------------
#              Extras
# --------------------------------

# Special targets
.PHONY: FORCE
FORCE: # force implicit pattern rules

.NOTPARALLEL: # do not run in parallel

.ONESHELL: # run rules in a single shell

.SECONDARY: # do not remove secondary files
