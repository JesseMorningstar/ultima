// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.3;

contract Ultima {

  //----- ACCESS CONTROL -----//
  mapping(address => bool) internal flamekeepers;
  uint16 public flamekeepers_census = 0;

  function induct(address candidate) external only_flamekeepers{
    flamekeepers[candidate] = true;
    flamekeepers_census++;
  }

  function retire(address incumbent) external only_flamekeepers{
    flamekeepers[incumbent] = false;
    flamekeepers_census--;
  }

  modifier only_flamekeepers{
    require(flamekeepers[msg.sender] == true, "ULTIMA: Performing this magic requires a special calling.");
    _;
  }



  //----- ERC20 SETUP -----//

  string  public constant name = "ULTIMA QUAN";
  string  public constant symbol = "ULTIMA"; 
  string  public constant version = "1";
  uint8   public constant decimals = 3;
  uint256 public constant maxSupply = 3333333333 * (10 ** uint256(decimals));
  uint256 public constant initialSupply = 33000000 * (10 ** uint256(decimals));
  uint256 public totalSupply;

  mapping(address => uint256)                      public nonces;
  mapping(address => uint256)                      public balanceOf;
  mapping(address => uint256)                      public meritOf;
  mapping(address => mapping(address => uint256))  public allowance;
  mapping(address => uint256[])                    public vesting_schedule;
  mapping(address => mapping( uint256 => uint256)) public vesting_balanceOf;

  mapping(bytes8  => uint16)                                          public gaia_rings; 
  mapping(address => mapping(bytes8 => uint256))                      public gaia_balanceOf;
  mapping(address => mapping(bytes8 => mapping(address => uint256)))  public gaia_allowance;
  mapping(bytes8  => mapping(address => uint256[]))                   public gaia_vesting_schedule;  
  mapping(address => mapping(bytes8 => mapping( uint256 => uint256))) public gaia_vesting_balanceOf;  

  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed sender, address indexed receiver, uint256 value);
  event GeofencedTransfer(bytes8 indexed gaia_ring, address indexed sender, address indexed receiver, uint256 value);
  event GeofencedApproval(bytes8 indexed gaia_ring, address indexed owner, address indexed spender, uint256 value);


  //----- INFINITYPOOL INCENTIVE PARAMETERS -----//
  mapping(address => uint256) public supremeHodlers;
  uint256[5] public supremeTier = [5, 50, 500, 5000, 50000];
  uint8 base_percentage = 3;

  //Pass second parameter called approved, which shows the vote tally for the approval of the change of tiers
  function updateTiers(uint256[5] calldata new_tiers) external only_flamekeepers returns (bool){
    supremeTier = new_tiers;
    return true;
  }


  // function whichTier(address hodler) internal view returns(uint8 tier) {
  //   uint256 supremeStatus = supremeHodlers[hodler];
  //   if(supremeStatus > 0 && supremeStatus <= supremeTier[0]){
  //     tier = 1;
  //   }else if(supremeStatus > supremeTier[0] && supremeStatus <= supremeTier[1]){
  //     tier = 2;
  //   }else if(supremeStatus > supremeTier[1] && supremeStatus <= supremeTier[2]){
  //     tier = 3;
  //   }else if(supremeStatus > supremeTier[2] && supremeStatus <= supremeTier[3]){
  //     tier = 4;
  //   }else if(supremeStatus > supremeTier[3] && supremeStatus <= supremeTier[4]){
  //     tier = 5;
  //   }
  // }


  //----- EIP712 MAGIC -----//
  //bytes32 public immutable PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
  bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
  bytes32 public immutable DOMAIN_SEPARATOR;
  
  constructor(address quantumMinter){
    flamekeepers[msg.sender] = true;

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

    assembly {
      sstore(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7, quantumMinter)
    }
  }




  //----- QUANTUM MINTING -----//
  // 1000 Nyota == 1 Ultima
  // gf: means geofenced not girlfriend, v: vesting, v_gf: vesting-geofenced

  struct MinterPrivileges {
    bool nyota_certified;
    bool gf_nyota_certified;

    bool nyota10_certified;
    bool gf_nyota10_certified;

    bool nyota100_certified;
    bool gf_nyota100_certified;
    bool v_nyota100_certified;
    bool v_gf_nyota100_certified;

    bool ultima_certified;
    bool gf_ultima_certified;
    bool v_ultima_certified;
    bool v_gf_ultima_certified;

    bool ultima10_certified;
    bool gf_ultima10_certified;
    bool v_ultima10_certified;
    bool v_gf_ultima10_certified;

    bool ultima100_certified;
    bool gf_ultima100_certified;
    bool v_ultima100_certified;
    bool v_gf_ultima100_certified;

    bool ultima1000_certified;
    bool gf_ultima1000_certified;
    bool v_ultima1000_certified;
    bool v_gf_ultima1000_certified;

    uint256 minterMax;
    uint256 totalSovereignMinted;
    uint256 totalGeofencedMinted;
    uint256 totalVestingMinted;
    uint256 totalVestingGeofencedMinted;

  }

  mapping(address => MinterPrivileges) public certified_entities;
  

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
      let quantumMinter := sload(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7)
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


