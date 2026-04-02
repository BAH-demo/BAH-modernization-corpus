# Assembly to C Modernization - Build System

CC = gcc
CFLAGS = -Wall -Wextra -std=c11 -O2
LDFLAGS = -lm

SRC_DIR = src
TEST_DIR = tests
BUILD_DIR = build

# Source files
SRCS = $(SRC_DIR)/fixed_point.c $(SRC_DIR)/guidance.c $(SRC_DIR)/navigation.c
HEADERS = $(SRC_DIR)/agc_types.h $(SRC_DIR)/fixed_point.h $(SRC_DIR)/guidance.h $(SRC_DIR)/navigation.h

# Test executables
TEST_FP = $(BUILD_DIR)/test_fixed_point
TEST_GUIDANCE = $(BUILD_DIR)/test_guidance

.PHONY: all test clean help

help:
	@echo "Assembly to C Modernization - Build Targets:"
	@echo "  make all     - Build all tests"
	@echo "  make test    - Build and run all tests"
	@echo "  make clean   - Remove build artifacts"

all: $(TEST_FP) $(TEST_GUIDANCE)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(TEST_FP): $(TEST_DIR)/test_fixed_point.c $(SRC_DIR)/fixed_point.c $(HEADERS) | $(BUILD_DIR)
	$(CC) $(CFLAGS) -o $@ $(TEST_DIR)/test_fixed_point.c $(SRC_DIR)/fixed_point.c $(LDFLAGS)

$(TEST_GUIDANCE): $(TEST_DIR)/test_guidance.c $(SRCS) $(HEADERS) | $(BUILD_DIR)
	$(CC) $(CFLAGS) -o $@ $(TEST_DIR)/test_guidance.c $(SRCS) $(LDFLAGS)

test: all
	@echo ""
	@echo "Running fixed-point arithmetic tests..."
	@echo "======================================="
	@$(TEST_FP)
	@echo ""
	@echo "Running guidance & navigation tests..."
	@echo "======================================="
	@$(TEST_GUIDANCE)
	@echo ""
	@echo "All test suites completed."

clean:
	rm -rf $(BUILD_DIR)
