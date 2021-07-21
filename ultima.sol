// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.3;

//----- INTERFACES TO ENABLE INTERACTION -----//
  interface infinityPoolFunctions{
    function getInfinityPoolFingerprint() external pure returns(bytes32);
  }

contract Ultima {
  //----- ERC20 SETUP -----//

  //Rod Tidwell: You know some dudes might have the coin but they'll never have the Quan. 
  //Jerry Maguire: What? What is...?
  //Rod Tidwell: It means Love, Respect, Community, and the dollars too, the entire package: the Quan.
  //Jerry Maguire: *Whispers pensively* Great word!

  string  public constant name = "ULTIMA QUAN";
  string  public constant symbol = "ULTIMA"; 
  string  public constant version = "1";
  address public infinityPool;
  uint8   public constant decimals = 3;
  uint256 public constant maxSupply = 10000000000 * (10 ** uint256(decimals));
  uint256 public maxLaurelsSupply = 110000000 * (10 ** uint256(decimals));
  uint256 public maxSupremeSupply = 1000000000 * (10 ** uint256(decimals));
  uint256 public totalSupply;
  uint256 public totalLaurels;
  uint256 public totalExalted;  

  mapping(address => uint256)                      public nonces;
  mapping(address => uint256)                      public supremePoiseOf;
  mapping(address => uint256)                      public balanceOf;
  mapping(address => uint256)                      public laurelsOf;
  mapping(address => mapping(address => uint256))  public allowance;
  mapping(address => uint256[])                    public vesting_schedule;
  mapping(address => mapping( uint256 => uint256)) public vesting_balanceOf;

  mapping(bytes8  => uint16)                                          public gaia_rings; 
  mapping(address => mapping(bytes8 => uint256))                      public gaia_balanceOf;
  mapping(address => mapping(bytes8 => mapping(address => uint256)))  public gaia_allowance;
  mapping(bytes8  => mapping(address => uint256[]))                   public gaia_vesting_schedule;  
  mapping(address => mapping(bytes8 => mapping( uint256 => uint256))) public gaia_vesting_balanceOf;  

  event HodlerExalted(address indexed receiver, uint256 zenith);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed sender, address indexed receiver, uint256 value);
  event GeofencedTransfer(bytes8 indexed gaia_ring, address indexed sender, address indexed receiver, uint256 value);
  event GeofencedApproval(bytes8 indexed gaia_ring, address indexed owner, address indexed spender, uint256 value);


  //----- EIP1967 FORMALITIES -----//
  //bytes32 internal constant QUANTUMMINTER_SLOT = bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1));
  bytes32 internal constant QUANTUMMINTER_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
  address[] public quantumMinterVersions;
  bool public constant proxyCalling = true;


  function getQuantumMinterVersions() public view returns(uint256){
    return quantumMinterVersions.length;
  }

  function getQuantumMinterAddress(uint8 versionNumber) public view returns(address){
    return quantumMinterVersions[versionNumber];
  }

  function getLatestQuantumMinterAddress() public view returns(address latestQuantumMinter){
    assembly{
      latestQuantumMinter := sload(QUANTUMMINTER_SLOT)
    }
  }


  //----- ACCESS CONTROL -----//
  mapping(address => bool) internal flamekeepers;
  uint16 public flamekeepers_census = 0;
  bytes32 infinityPoolFingerprint;

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

  function setInfinityPoolFingerprint(string memory preImage)external onlyFlamekeepers{
    bytes32 _fingerprint = keccak256(abi.encodePacked(preImage));
    infinityPoolFingerprint = _fingerprint;
  }

  function setInfinityPoolAddress(address _infinityPool) internal onlyFlamekeepers{
    bytes32 fingerprint = infinityPoolFunctions(_infinityPool).getInfinityPoolFingerprint();
    require(fingerprint == infinityPoolFingerprint, "The destination contract could be not be validated");
    infinityPool = _infinityPool;
  }

  modifier onlyInfinity{
    require(msg.sender == infinityPool, "ULTIMA: This process can only be carried out by the Infinity Pool");
    _;
  }


  //----- INFINITYPOOL INCENTIVE PARAMETERS -----//
  uint16[5] public supremeTier = [5, 50, 500, 5000, 50000];
  uint8 private base_percentage = 3;
  mapping(address => uint256) public supremeHodlers;

  //Pass second parameter called approved, which shows the vote tally for the approval of the change of tiers
  function updateTiers(uint16[5] calldata new_tiers) external onlyFlamekeepers returns (bool){
    supremeTier = new_tiers;
    return true;
  }


  //----- EIP712 MAGIC -----//
  //bytes32 public immutable PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
  bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
  bytes32 public immutable DOMAIN_SEPARATOR;
  
  constructor(address quantumMinterAddress){
    flamekeepers[msg.sender] = true;
    // uint256 initialSupremeSupply = 1000000000 * (10 ** uint256(decimals));
    // uint256 initialSupply = 33000000 * (10 ** uint256(decimals));
    uint256 chainId = block.chainid;

    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256(bytes(name)),
        keccak256(bytes(version)),
        chainId,
        address(this)
      )
    );

    //check that quantumMinterAddress is indeed a contract address
    quantumMinterVersions.push(quantumMinterAddress);
    assembly {
      sstore(QUANTUMMINTER_SLOT, quantumMinterAddress)
    }
  }


  //----- QUANTUM MINTING -----//
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

  uint128[26] private  base = [ 
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

  mapping(address => MinterCharter) public certified_entities;
  

  receive() external payable {
    revert("Don't send your Ether wandering aimlessly in cyberspace kid!");
  }

  function _transfer(address sender, address receiver, uint256 value) private {
    require(sender != address(0), "ULTIMA: please provide an adequate origin address");
    require(receiver != address(0), "ULTIMA: please provide an adequate destination address.");
    require(balanceOf[sender] >= value, "The ULTIMA balance is insufficient."); //test what happens if you remove this line

    balanceOf[sender] -= value; 
    balanceOf[receiver] += value;
    emit Transfer(sender, receiver, value);
  }

  function transfer(address receiver, uint256 value) public returns (bool){
    _transfer(msg.sender, receiver, value);
    return true; 
  }

  function transferFrom(address owner, address spender, uint256 value) public returns (bool){
    require(allowance[owner][spender] >= value, "ULTIMA: This transaction exceeds allowance."); 
    allowance[owner][spender] -= value;
    _transfer(owner, spender, value);
    return true;
  }

  function _approve(address owner, address spender, uint256 value) private {
    require(owner != address(0), "ULTIMA: please provide an adequate origin address");
    require(spender != address(0), "ULTIMA: please provide an adequate destination address.");
    allowance[owner][spender] = value;
    emit Approval(owner, spender, value);
  }

  function approve(address spender, uint256 value) external returns (bool){
    _approve(msg.sender, spender, value);
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public returns(bool){
    _approve(msg.sender, spender, allowance[msg.sender][spender] + addedValue);
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public returns(bool){
    uint256 currentAllowance = allowance[msg.sender][spender];
    require(currentAllowance >= subtractedValue, "ULTIMA: yikes, you've reduced the allowance below zero.");
    _approve(msg.sender, spender, currentAllowance - subtractedValue);
    return true;
  }


  //----- SUPREME UTILITIES -----//
  function exalt(address receiver, uint256 zenith) external onlyInfinity{
    require(totalExalted + zenith <= maxSupremeSupply, "ULTIMA: This exaltation will exceed the cap if carried out.");
    totalExalted += zenith;
    supremePoiseOf[receiver] += zenith;
    emit HodlerExalted(receiver, zenith);
  }


  //----- GAIA UTILITIES -----//
  
  function _transferGeofenced(bytes8 geohash, address sender, address receiver, uint256 value) private {
    require(sender != address(0), "ULTIMA: please provide an adequate origin address");
    require(receiver != address(0), "ULTIMA: please provide an adequate destination address.");
    require(gaia_balanceOf[sender][geohash] >= value, "The ULTIMA balance in this Gaia Ring is insufficient."); //test what happens if you remove this line
    
    gaia_balanceOf[sender][geohash] -= value; 
    gaia_balanceOf[receiver][geohash] += value;
    emit GeofencedTransfer(geohash, sender, receiver, value);
  }

  function transferGeofenced(bytes8 geohash, address receiver, uint256 value) public returns (bool){
    _transferGeofenced(geohash, msg.sender, receiver, value);
    return true; 
  }

  function transferFromGeofenced(bytes8 geohash, address owner, address spender, uint256 value) public returns (bool){
    require(gaia_allowance[owner][geohash][spender] >= value, "ULTIMA: This transaction exceeds allowance."); 
    gaia_allowance[owner][geohash][spender] -= value;
    _transferGeofenced(geohash, owner, spender, value);
    return true;
  }

  function _approveGeofenced(bytes8 geohash, address owner, address spender, uint256 value) private {
    require(owner != address(0), "ULTIMA: please provide an adequate origin address");
    require(spender != address(0), "ULTIMA: please provide an adequate destination address.");
    gaia_allowance[owner][geohash][spender] = value;
    emit GeofencedApproval(geohash, owner, spender, value);
  }

  function approveGeofenced(bytes8 geohash, address spender, uint256 value) external returns (bool){
    _approveGeofenced(geohash, msg.sender, spender, value);
    return true;
  }

  function increaseAllowanceGeofenced(bytes8 geohash, address spender, uint256 addedValue) public returns(bool){
    _approveGeofenced(geohash, msg.sender, spender, allowance[msg.sender][spender] + addedValue);
    return true;
  }

  function decreaseAllowanceGeofenced(bytes8 geohash, address spender, uint256 subtractedValue) public returns(bool){
    uint256 currentGaiaAllowance = gaia_allowance[msg.sender][geohash][spender];
    require(currentGaiaAllowance >= subtractedValue, "ULTIMA: yikes, you've reduced the allowance below zero.");
    _approveGeofenced(geohash, msg.sender, spender, currentGaiaAllowance - subtractedValue);
    return true;
  }
  

  //----- VESTING UTILITIES -----//

  function vestingStatusSovereign() public view returns(uint256[] memory vested_balances) {
    vested_balances = new uint256[](0);
    uint256[] memory vesting_timeline = vesting_schedule[msg.sender];

    for(uint256 i = 0; i < vesting_timeline.length; i++){
      if(block.timestamp > vesting_timeline[i]){
        uint256 vested_indices = 0;
        vested_balances[vested_indices] = vesting_timeline[i];
        vested_indices++;
      }
    }
  }

  function vestingStatusGeofenced(bytes8 geohash) public view returns(uint256[] memory vested_gaia_balances) {
    vested_gaia_balances = new uint256[](0);
    uint256[] memory vesting_timeline = gaia_vesting_schedule[geohash][msg.sender];

    for(uint256 i = 0; i < vesting_timeline.length; i++){
      if(block.timestamp > vesting_timeline[i]){
        uint256 vested_indices = 0;
        vested_gaia_balances[vested_indices] = vesting_timeline[i];
        vested_indices++;
      }
    }
  }


  //----- EIP2612 AWESOMENESS -----//
  function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
    require(deadline >= block.timestamp, "ULTIMA: This Signature has already expired");
    bytes32 HASH_STRUCT = keccak256(abi.encode( PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline));

    bytes32 digest = keccak256(
      abi.encodePacked(
        '\x19\x01',
        DOMAIN_SEPARATOR,
        HASH_STRUCT
      )
    );

    address signer = ecrecover(digest, v, r, s);
    require(signer != address(0) && signer == owner, "ULTIMA: This Signature is invalid");
    _approve(signer, spender, value);
  }


  //----- QUANTUM MINTER GATEWAY -----//
  fallback() external {
    
    assembly {
      let quantumMinter := sload(QUANTUMMINTER_SLOT)
      calldatacopy(0x0, 0x0, calldatasize())
      let success := delegatecall(sub(gas(), 10000), quantumMinter, 0x0, calldatasize(), 0, 0)
      let retSz := returndatasize()
      returndatacopy(0, 0, retSz)

      switch success
      case 0 {
        revert(0, retSz)
      }
      default {
        return(0, retSz)
      }
    }
  }


}


