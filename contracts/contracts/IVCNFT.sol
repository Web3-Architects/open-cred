// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

interface IVCNFT {
  function mint(address to_, bytes32 lessonId, string memory tokenURI_) external;
}