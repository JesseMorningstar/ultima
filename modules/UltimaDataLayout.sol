// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

contract UltimaDataLayout {
  //----- SHADOW VARIABLES FOR ULTIMA ERC20 CONTRACT - NEEDED DUE TO UUPS PATTERN IMPLEMENTATION -----//
  bool public constant proxyCalling = false;
  uint8   public constant decimals = 3;
  uint256 public constant maxSupply = 3333333333 * (10 ** uint256(decimals));
  uint256 public totalSupply;
  uint256 public totalLaurels;
  uint256 public maxLaurelsSupply = 21000000 * (10 ** uint256(decimals));
  address[] public quantumMinterVersions;
  mapping(address => uint256) public balanceOf;
  mapping(address => uint256)                      public laurelsOf;
  mapping(address => mapping( uint256 => uint256)) public vesting_balanceOf;
  mapping(address => mapping(bytes8 => uint256)) public gaia_balanceOf;
  mapping(address => mapping(bytes8 => mapping( uint256 => uint256))) public gaia_vesting_balanceOf;

  mapping(address => bool) internal flamekeepers;
  uint16 public flamekeepers_census = 0;

  function induct(address candidate) external onlyFlamekeepers{
    flamekeepers[candidate] = true;
    flamekeepers_census++;
  }

  function retire(address incumbent) external onlyFlamekeepers{
    flamekeepers[incumbent] = false;
    flamekeepers_census--;
  }

  modifier onlyFlamekeepers{
    require(flamekeepers[msg.sender] == true, "ULTIMA: Performing this magic requires a special calling.");
    _;
  }

  modifier onlyProxy{
    require(proxyCalling == true, "ULTIMA: No direct calls allowed for this function");
    _;
  }

  // 1000 Nyota == 1 Ultima
  // gf: means geofenced not girlfriend, v: vesting, v_gf: vesting-geofenced
  enum Quanta {
    nyota,
    nyota10,
    nyota100,
    ultima,
    ultima10,
    ultima100,
    ultima1000,

    v_nyota100,
    v_ultima,
    v_ultima10,
    v_ultima100,
    v_ultima1000,

    gf_nyota,
    gf_nyota10,
    gf_nyota100,
    gf_ultima,
    gf_ultima10,
    gf_ultima100,
    gf_ultima1000,
    
    v_gf_nyota100,
    v_gf_ultima,
    v_gf_ultima10,
    v_gf_ultima100,
    v_gf_ultima1000,

    lowMerit,
    highMerit
  }

  uint32[26] internal  base = [ 
    1, 10, 100, 1000, 10000, 100000, 1000000, 
    100, 1000, 10000, 100000, 1000000, 
    1, 10, 100, 1000, 10000, 100000, 1000000,
    100, 1000, 10000, 100000, 1000000,
    1, 10
  ];

  struct MinterCharter {
    bool[26] minterPermit;
    uint128 minterMax;
    uint128 totalSovereignMinted;
    uint128 totalGeofencedMinted;
    uint128 totalVestingMinted;
    uint128 totalVestingGeofencedMinted;
    uint128 totalLaurelsGranted;
  }

  uint16[5] public supremeTier = [5, 50, 500, 5000, 50000];
  uint8 internal base_percentage = 3;
  mapping(address => uint256) public supremeHodlers;
  mapping(address => MinterCharter) public certified_entities;
}