# Contracts Technical Assessment

Thank you for your interest in Tokemak and for taking the time to perform the technical assessment. Please privately fork the repo and grant access to the designated contact upon your completion. The assessment comes in two parts:

1.  Find the Bugs
2.  Implement a Spot Price Oracle

## Find the Bugs - Transmuter

Review the `src/Transmuter.sol` contract in the `transmuter` branch. Open a PR to `main` and perform your review. Your review should focus on bugs and security/attack issues.

## Spot Price Oracle Implementation

Provide an implementation of the `src/interfaces/ISpotPriceOracle.sol` interface for a Curve StableSwap pool (V1):

- Must work on 2+ coin pools
- Is not required to work on meta pools
- You can assume the requested token, and quote token, are constituents of the pool provided.
- Please list any assumptions you've made in the contract
