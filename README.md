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
