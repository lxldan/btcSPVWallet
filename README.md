# Bitcoin SPV Wallet

A lightweight Bitcoin SPV (Simplified Payment Verification) wallet implementation that connects directly to the Bitcoin P2P network using BIP-157 and BIP-158 protocols.

## Overview

This project implements a Bitcoin SPV wallet that utilizes the Neutrino protocol as specified in BIP-157 and BIP-158. Instead of relying on third-party services, this wallet connects directly to the Bitcoin peer-to-peer network for enhanced privacy and security.

> **Note**: This project is currently under active development and is intended for research purposes only. It should not be used for managing real funds on mainnet.

## What is SPV?

SPV (Simplified Payment Verification) allows lightweight clients to verify Bitcoin transactions without downloading the entire blockchain. This implementation uses the following BIPs:

- **BIP-157**: Client Side Block Filtering - defines how light clients can request compact filters from full nodes
- **BIP-158**: Compact Block Filters - specifies the structure of compact filters that enable efficient verification

## Features

- Direct connection to Bitcoin P2P network
- Lightweight verification using Neutrino filters (BIP-157/158)
- No reliance on centralized servers
- Enhanced privacy compared to traditional API-based wallets
- Cross-platform support

## Current Status

🚧 **Work in Progress** 🚧

This project is still in early development stages. Many features are experimental and the codebase is subject to significant changes.

## Getting Started

### Prerequisites

- Dart SDK
- [Additional prerequisites]

### Installation

[Installation instructions to be added]

## Usage

[Basic usage examples to be added]

## Roadmap

- [x] Initial P2P network connection
- [ ] Complete BIP-157/158 implementation
- [ ] Wallet key management
- [ ] Transaction creation and signing
- [ ] UI implementation

## Disclaimer

This project is provided for **research and educational purposes only**. The codebase has not been audited for security vulnerabilities and should be considered experimental.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

[License information]
