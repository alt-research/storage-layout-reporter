# Storage Layout Reporter

A utility script to generate storage layout reports for Solidity contracts using Foundry's `forge inspect` command.

## Overview

This script scans your Solidity contracts and generates storage layout reports showing their variable positioning and slot usage. These reports help developers understand the storage structure of their contracts, which is crucial for upgradeable contracts and gas optimization.

## Installation

```bash
# From your project root
git submodule add https://github.com/alt-research/storage-layout-reporter.git lib/storage-layout-reporter
git submodule update --init --recursive
```

## Requirements

- [Foundry](https://book.getfoundry.sh/getting-started/installation) must be installed
- POSIX-compliant shell (bash, sh, zsh)

## Usage

### Command-line Options

| Option            | Description                                           | Default                |
| ----------------- | ----------------------------------------------------- | ---------------------- |
| `--output=DIR`    | Set output directory                                  | `docs/storage`         |
| `--source=DIRS`   | Set source directories (space-separated)              | `src`                  |
| `--exclude=PATHS` | Set paths to exclude (space-separated, glob patterns) | `interfaces libraries` |
| `-h, --help`      | Display help message                                  | -                      |

### Direct Execution

```bash
./lib/storage-layout-reporter/report.sh --output=docs/storage --source="src" --exclude="interfaces libraries"
```

### Pattern-Based Exclusions

The exclude option uses glob pattern matching to exclude files and directories:

```bash
# Exclude all test files and mock implementations
./lib/storage-layout-reporter/report.sh --exclude="test mock"

# Exclude specific directories or file types
./lib/storage-layout-reporter/report.sh --exclude="interfaces libraries utils"
```

Any path that contains the specified pattern will be excluded.

### Makefile Integration (Recommended)

Add this target to your Makefile:

```makefile
.PHONY: storage-report

storage-report:
	@echo "📝 Generating storage layout report..."
	@./lib/storage-layout-reporter/report.sh --output=docs/storage --source="src" --exclude="interfaces libraries test"
	@echo "✅ Storage report generated in docs/storage directory"
```

Then run:

```bash
make storage-report
```

### CI Integration to Detect Storage Layout Changes

You can integrate storage layout verification into your CI/CD pipeline to detect unintended storage layout changes between branches:

```yaml
name: Storage Report

on:
  push:
  pull_request:
  workflow_dispatch:

env:
  FOUNDRY_PROFILE: ci

jobs:
  check:
    strategy:
      fail-fast: true

    name: Foundry project
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          submodules: recursive

      - name: Install Foundry
        uses: foundry-rs/foundry-toolchain@v1

      - name: Detect storage layout changes
        run: |
          # Set directories for reports
          PR_DIR="pr"
          TARGET_DIR="target"

          # Generate storage report for the current PR branch
          echo "Generating storage layout report for the PR branch..."
          ./lib/storage-layout-reporter/report.sh --output=$PR_DIR --source="src" --exclude="src/interfaces"

          # Fetch and check out the target branch
          echo "Fetching and checking out the target branch..."
          git fetch origin $TARGET
          git checkout $TARGET

          # Generate storage report for the target branch
          echo "Generating storage layout report for the target branch..."
          ./lib/storage-layout-reporter/report.sh --output=$TARGET_DIR --source="src" --exclude="src/interfaces"

          # Compare the storage layouts of the PR and target branches
          echo "Comparing storage layouts..."
          if diff --unified $PR_DIR $TARGET_DIR; then
            echo "No differences found in storage layouts."
          else
            echo "::error::Storage layout changes detected. Review changes carefully as they may impact contract upgrades."
            exit 1
          fi
        env:
          TARGET: ${{ github.event.pull_request.base.sha }}
```

This workflow automatically:

1. Generates storage layout reports for both the PR and target branches
2. Performs a differential analysis to identify any storage layout modifications
3. Fails the CI pipeline if incompatible storage changes are detected

This approach is critical for maintaining storage compatibility in upgradeable contract systems and preventing deployment failures due to incompatible storage layouts.

> **Note**: If storage layout changes are intentional (e.g., during initial development or when implementing a planned contract upgrade), you can modify the workflow to ignore specific changes.

## Output

The script creates one text file per contract:

```
docs/storage/
  ├── ContractA.txt
  ├── ContractB.txt
  └── ...
```

Each file contains the raw output from `forge inspect`, showing the storage layout of the contract in a tabular format:

```
╭-------------------+--------------------------------------------------------------+------+--------+-------+-----------------------------╮
| Name              | Type                                                         | Slot | Offset | Bytes | Contract                    |
+========================================================================================================================================+
| owner             | address                                                      | 0    | 0      | 20    | src/Example.sol:FooContract |
|-------------------+--------------------------------------------------------------+------+--------+-------+-----------------------------|
| initialized       | bool                                                         | 0    | 20     | 1     | src/Example.sol:FooContract |
|-------------------+--------------------------------------------------------------+------+--------+-------+-----------------------------|
| fooMapping        | mapping(uint256 => uint256)                                  | 1    | 0      | 32    | src/Example.sol:FooContract |
|-------------------+--------------------------------------------------------------+------+--------+-------+-----------------------------|
| barArray          | uint256[]                                                    | 2    | 0      | 32    | src/Example.sol:FooContract |
|-------------------+--------------------------------------------------------------+------+--------+-------+-----------------------------|
| fooBarStruct      | struct FooContract.BarData                                   | 3    | 0      | 32    | src/Example.sol:FooContract |
╰-------------------+--------------------------------------------------------------+------+--------+-------+-----------------------------╯
```
