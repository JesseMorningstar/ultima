// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.3;


contract QuantumMinter {

  // 1000 Nyota == 1 Ultima
  // gf: means geofenced not girlfriend, v: vesting, v_gf: vesting-geofenced

  enum Quanta {
    nyota_certified,
    nyota10_certified,
    nyota100_certified,
    ultima_certified,
    ultima10_certified,
    ultima100_certified,
    ultima1000_certified,

    v_nyota100_certified,
    v_ultima_certified,
    v_ultima10_certified,
    v_ultima100_certified,
    v_ultima1000_certified,

    gf_nyota_certified,
    gf_nyota10_certified,
    gf_nyota100_certified,
    gf_ultima_certified,
    gf_ultima10_certified,
    gf_ultima100_certified,
    gf_ultima1000_certified,
    
    v_gf_nyota100_certified,
    v_gf_ultima_certified,
    v_gf_ultima10_certified,
    v_gf_ultima100_certified,
    v_gf_ultima1000_certified
  }

  uint32[24] private  base = [ 
    1, 10, 100, 1000, 10000, 100000, 1000000, 
    100, 1000, 10000, 100000, 1000000, 
    1, 10, 100, 1000, 10000, 100000, 1000000,
    100, 1000, 10000, 100000, 1000000
  ];

  struct MinterCharter {
    bool[24] minterPermit;
    uint256 minterMax;
    uint256 totalSovereignMinted;
    uint256 totalGeofencedMinted;
    uint256 totalVestingMinted;
    uint256 totalVestingGeofencedMinted;
  }

  mapping(address => uint256) public supremeHodlers;
  uint8 base_percentage = 3;

  function whichTier(address hodler) internal view returns(uint8 tier) {
    uint256 supremeStatus = supremeHodlers[hodler];
    if(supremeStatus > 0 && supremeStatus <= supremeTier[0]){
      tier = 1;
    }else if(supremeStatus > supremeTier[0] && supremeStatus <= supremeTier[1]){
      tier = 2;
    }else if(supremeStatus > supremeTier[1] && supremeStatus <= supremeTier[2]){
      tier = 3;
    }else if(supremeStatus > supremeTier[2] && supremeStatus <= supremeTier[3]){
      tier = 4;
    }else if(supremeStatus > supremeTier[3] && supremeStatus <= supremeTier[4]){
      tier = 5;
    }
  }


  function getMinterTotal(address minter) public view returns (uint256 minterTotal){
    uint256 _totalSovereignMinted = certified_entities[minter].totalSovereignMinted;
    uint256 _totalGeofencedMinted = certified_entities[minter].totalGeofencedMinted;
    uint256 _totalVestingMinted = certified_entities[minter].totalVestingMinted;
    uint256 _totalVestingGeoFerencedMinted = certified_entities[minter].totalVestingGeofencedMinted;

    minterTotal = _totalSovereignMinted + _totalGeofencedMinted + _totalVestingMinted + _totalVestingGeoFerencedMinted;
  }

  function getHodlerBonus(uint256 value, address hodler)internal view returns(uint256){
    uint8 percentage = base_percentage * whichTier(hodler);
    return (value * percentage) / 100;
  }

  function supremeReward(address receiver, uint256 quantum) public returns(uint256 _minted){
    if(supremeHodlers[receiver] > 0){
      _minted = quantum + getHodlerBonus(quantum, receiver);
    }else{
      _minted = quantum; 
    }
  }


  modifier rangeCheck(uint8 multiple) {
    require(multiple >= 1 && multiple < 10, "ULTIMA: The multiple provided falls outside the minting range.");
    _;
  }

  event Minted(address indexed minter, address indexed receiver, uint8 flavor, uint256 value);


  function mintSovereign(uint8 flavor, uint8 multiple, address minter, address receiver) rangeCheck(multiple) private returns(uint128 minted){
    require(flavor >= 0 && flavor <= 6, "ULTIMA: This process can only mint the Sovereign flavor.");
    MinterCharter _minter = certified_entities[msg.sender];
    require(_minter.minterPermit[flavor] == true, "ULTIMA: This minter is not allowed to mint this quantum.");
    uint128 quantum = base[flavor] * multiple;
    minted = supremeReward(receiver, quantum);
    uint128 _totalMinted = getMinterTotal(minter);
    require(_totalMinted + minted <= _minter.minterMax, "ULTIMA: Minting this amount will exceed the cap.");

    if( totalSupply + minted <= maxSupply){
      totalSupply += minted;
      balanceOf[receiver] += minted;
      _minter.totalSovereignMinted += minted;
      emit Minted(minter, receiver, flavor, minted);
    }
  }



  //----- MINTING SOVEREIGN FLAVORS -----//

  function mintNyota(address receiver, uint8 multiple) public returns(uint128 minted) {
    uint8 flavor = uint8(Quanta.nyota_certified);
    address minter = msg.sender;
    mintSovereign(flavor, multiple, minter, receiver);
  }


  function mintNyota10(address receiver, uint8 multiple) public rangeCheck(multiple) returns(uint256 minted){
    require(certified_entities[msg.sender].nyota10_certified == true, "ULTIMA: This entity is not certified to mint Nyota10."); 
    uint256 _minterMax = certified_entities[msg.sender].minterMax;
    uint256 _totalMinted = getMinterTotal(msg.sender);
    uint16 quantum = 10 * multiple;
    minted = mintTierWise(receiver, quantum);    
    require(_totalMinted + minted <= _minterMax, "ULTIMA: Minting this amount will exceed the cap."); 
    
    if( totalSupply + minted <= maxSupply){
      totalSupply += minted;
      balanceOf[receiver] += minted;
      certified_entities[msg.sender].totalSovereignMinted += minted;
      emit Transfer(address(0), receiver, minted);
    }
  }


  function mintNyota100(address receiver, uint8 multiple) public rangeCheck(multiple) returns(uint256 minted){
    require(certified_entities[msg.sender].nyota100_certified == true, "ULTIMA: This entity is not certified to mint Nyota100."); 

    uint256 _minterMax = certified_entities[msg.sender].minterMax;
    uint256 _totalMinted = getMinterTotal(msg.sender);
    uint16 quantum = 100 * multiple;
    minted = mintTierWise(receiver, quantum);
    require(_totalMinted + minted <= _minterMax, "ULTIMA: Minting this amount will exceed the cap."); 
    
    if( totalSupply + minted <= maxSupply){
      totalSupply += minted;
      balanceOf[receiver] += minted;
      certified_entities[msg.sender].totalSovereignMinted += minted;
      emit Transfer(address(0), receiver, minted);
    }
  }


  function mintUltima(address receiver, uint8 multiple) public rangeCheck(multiple) returns(uint256 minted){
    require(certified_entities[msg.sender].ultima_certified == true, "ULTIMA: This entity is not certified to mint Nyota100."); 

    uint256 _minterMax = certified_entities[msg.sender].minterMax;
    uint256 _totalMinted = getMinterTotal(msg.sender);
    uint16 quantum = 1000 * multiple;
    minted = mintTierWise(receiver, quantum);
    require(_totalMinted + minted <= _minterMax, "ULTIMA: Minting this amount will exceed the cap."); 
    
    if( totalSupply + minted <= maxSupply){
      totalSupply += minted;
      balanceOf[receiver] += minted;
      certified_entities[msg.sender].totalSovereignMinted += minted;
      emit Transfer(address(0), receiver, minted);
    }
  }


  function mintUltima10(address receiver, uint8 multiple) public rangeCheck(multiple) returns(uint256 minted) {
    require(certified_entities[msg.sender].ultima10_certified == true, "ULTIMA: This entity is not certified to mint Nyota100."); 

    uint256 _minterMax = certified_entities[msg.sender].minterMax;
    uint256 _totalMinted = getMinterTotal(msg.sender);
    uint16 quantum = 10000 * multiple;
    minted = mintTierWise(receiver, quantum);
    require(_totalMinted + minted <= _minterMax, "ULTIMA: Minting this amount will exceed the cap."); 
    
    if( totalSupply + minted <= maxSupply){
      totalSupply += minted;
      balanceOf[receiver] += minted;
      certified_entities[msg.sender].totalSovereignMinted += minted;
      emit Transfer(address(0), receiver, minted);
    }
  }


  function mintUltima100(address receiver, uint8 multiple) public rangeCheck(multiple) returns(uint256 minted){
    require(certified_entities[msg.sender].ultima100_certified == true, "ULTIMA: This entity is not certified to mint Nyota100."); 

    uint256 _minterMax = certified_entities[msg.sender].minterMax;
    uint256 _totalMinted = getMinterTotal(msg.sender);
    uint24 quantum = 100000 * multiple;
    minted = mintTierWise(receiver, quantum);
    require(_totalMinted + minted <= _minterMax, "ULTIMA: Minting this amount will exceed the cap."); 
    
    if( totalSupply + minted <= maxSupply){
      totalSupply += minted;
      balanceOf[receiver] += minted;
      certified_entities[msg.sender].totalSovereignMinted += minted;
      emit Transfer(address(0), receiver, minted);
    }
  }


  function mintUltima1000(address receiver, uint8 multiple) public rangeCheck(multiple) returns(uint256 minted){
    require(certified_entities[msg.sender].ultima1000_certified == true, "ULTIMA: This entity is not certified to mint Nyota100."); 

    uint256 _minterMax = certified_entities[msg.sender].minterMax;
    uint256 _totalMinted = getMinterTotal(msg.sender);
    uint24 quantum = 1000000 * multiple;
    minted = mintTierWise(receiver, quantum);
    require(_totalMinted + minted <= _minterMax, "ULTIMA: Minting this amount will exceed the cap."); 
    
    if( totalSupply + minted <= maxSupply){
      totalSupply += minted;
      balanceOf[receiver] += minted;
      certified_entities[msg.sender].totalSovereignMinted += minted;
      emit Transfer(address(0), receiver, minted);
    }
  }



  //----- MINTING GAIA FLAVORS -----//

  function mintNyotaGF(bytes8 geohash, address receiver, uint8 multiple) public rangeCheck(multiple) returns(uint256 minted){
    require(certified_entities[msg.sender].gf_nyota_certified == true, "ULTIMA: This entity is not certified to mint Nyota."); 

    uint256 _minterMax = certified_entities[msg.sender].minterMax;
    uint256 _totalMinted = getMinterTotal(msg.sender);
    uint16 quantum = 1 * multiple;
    minted = mintTierWise(receiver, quantum);
    require(_totalMinted + minted <= _minterMax, "ULTIMA: Minting this amount will exceed the cap."); 
    
    if( totalSupply + minted <= maxSupply){
      totalSupply += minted;
      gaia_balanceOf[receiver][geohash] += minted;
      certified_entities[msg.sender].totalGeofencedMinted += minted;
      emit Transfer(address(0), receiver, minted);
    }
  }


  function mintNyota10GF(bytes8 geohash, address receiver, uint8 multiple) public rangeCheck(multiple) returns(uint256 minted){
    require(certified_entities[msg.sender].gf_nyota10_certified == true, "ULTIMA: This entity is not certified to mint Nyota."); 

    uint256 _minterMax = certified_entities[msg.sender].minterMax;
    uint256 _totalMinted = getMinterTotal(msg.sender);
    uint16 quantum = 10 * multiple;
    minted = mintTierWise(receiver, quantum);
    require(_totalMinted + minted <= _minterMax, "ULTIMA: Minting this amount will exceed the cap."); 
    
    if( totalSupply + minted <= maxSupply){
      totalSupply += minted;
      gaia_balanceOf[receiver][geohash] += minted;
      certified_entities[msg.sender].totalGeofencedMinted += minted;
      emit Transfer(address(0), receiver, minted);
    }
  }


  function mintNyota100GF(bytes8 geohash, address receiver, uint8 multiple) public rangeCheck(multiple) returns(uint256 minted){
    require(certified_entities[msg.sender].gf_nyota100_certified == true, "ULTIMA: This entity is not certified to mint Nyota."); 

    uint256 _minterMax = certified_entities[msg.sender].minterMax;
    uint256 _totalMinted = getMinterTotal(msg.sender);
    uint16 quantum = 100 * multiple;
    minted = mintTierWise(receiver, quantum);
    require(_totalMinted + minted <= _minterMax, "ULTIMA: Minting this amount will exceed the cap."); 
    
    if( totalSupply + minted <= maxSupply){
      totalSupply += minted;
      gaia_balanceOf[receiver][geohash] += minted;
      certified_entities[msg.sender].totalGeofencedMinted += minted;
      emit Transfer(address(0), receiver, minted);
    }
  }


  function mintUltimaGF(bytes8 geohash, address receiver, uint8 multiple) public rangeCheck(multiple) returns(uint256 minted){
    require(certified_entities[msg.sender].gf_ultima_certified == true, "ULTIMA: This entity is not certified to mint Nyota."); 

    uint256 _minterMax = certified_entities[msg.sender].minterMax;
    uint256 _totalMinted = getMinterTotal(msg.sender);
    uint16 quantum = 1000 * multiple;
    minted = mintTierWise(receiver, quantum);
    require(_totalMinted + minted <= _minterMax, "ULTIMA: Minting this amount will exceed the cap."); 
    
    if( totalSupply + minted <= maxSupply){
      totalSupply += minted;
      gaia_balanceOf[receiver][geohash] += minted;
      certified_entities[msg.sender].totalGeofencedMinted += minted;
      emit Transfer(address(0), receiver, minted);
    }
  }


  function mintUltima10GF(bytes8 geohash, address receiver, uint8 multiple) public rangeCheck(multiple) returns(uint256 minted){
    require(certified_entities[msg.sender].gf_ultima10_certified == true, "ULTIMA: This entity is not certified to mint Nyota."); 

    uint256 _minterMax = certified_entities[msg.sender].minterMax;
    uint256 _totalMinted = getMinterTotal(msg.sender);
    uint16 quantum = 10000 * multiple;
    minted = mintTierWise(receiver, quantum);
    require(_totalMinted + minted <= _minterMax, "ULTIMA: Minting this amount will exceed the cap."); 
    
    if( totalSupply + minted <= maxSupply){
      totalSupply += minted;
      gaia_balanceOf[receiver][geohash] += minted;
      certified_entities[msg.sender].totalGeofencedMinted += minted;
      emit Transfer(address(0), receiver, minted);
    }
  }


  function mintUltima100GF(bytes8 geohash, address receiver, uint8 multiple) public rangeCheck(multiple) returns(uint256 minted){
    require(certified_entities[msg.sender].gf_ultima100_certified == true, "ULTIMA: This entity is not certified to mint Nyota."); 

    uint256 _minterMax = certified_entities[msg.sender].minterMax;
    uint256 _totalMinted = getMinterTotal(msg.sender);
    uint24 quantum = 100000 * multiple;
    minted = mintTierWise(receiver, quantum);
    require(_totalMinted + minted <= _minterMax, "ULTIMA: Minting this amount will exceed the cap."); 
    
    if( totalSupply + minted <= maxSupply){
      totalSupply += minted;
      gaia_balanceOf[receiver][geohash] += minted;
      certified_entities[msg.sender].totalGeofencedMinted += minted;
      emit Transfer(address(0), receiver, minted);
    }
  }



  function mintUltima1000GF(bytes8 geohash, address receiver, uint8 multiple) public rangeCheck(multiple) returns(uint256 minted){
    require(multiple >= 1 && multiple < 10, "ULTIMA: The multiple provided falls outside the minting spectrum.");
    require(certified_entities[msg.sender].gf_ultima1000_certified == true, "ULTIMA: This entity is not certified to mint Nyota."); 

    uint256 _minterMax = certified_entities[msg.sender].minterMax;
    uint256 _totalMinted = getMinterTotal(msg.sender);
    uint24 quantum = 1000000 * multiple;
    minted = mintTierWise(receiver, quantum);
    require(_totalMinted + minted <= _minterMax, "ULTIMA: Minting this amount will exceed the cap."); 
    
    if( totalSupply + minted <= maxSupply){
      totalSupply += minted;
      gaia_balanceOf[receiver][geohash] += minted;
      certified_entities[msg.sender].totalGeofencedMinted += minted;
      emit Transfer(address(0), receiver, minted);
    }
  }



  //----- MINTING VESTING FLAVORS -----//

  //uint8 and uint256 units being used here, is the implicit conversion problematic?
  function getPayday(uint8 hodl) internal view returns (uint256){
    uint256 hodl_base = 2592000;
    return block.timestamp + (hodl_base * hodl);
  }

  function mintNyota100V(address receiver, uint8 multiple, uint8 hodl) public rangeCheck(multiple) returns(uint256 minted){
    require(certified_entities[msg.sender].v_nyota100_certified == true, "ULTIMA: This entity is not certified to mint Nyota.");
    require(hodl >= 1 && hodl <= 60, "ULTIMA: Please provide a compliant vesting period."); 

    uint256 _minterMax = certified_entities[msg.sender].minterMax;
    uint256 _totalMinted = getMinterTotal(msg.sender);
    uint16 quantum = 100 * multiple;
    minted = mintTierWise(receiver, quantum);
    require(_totalMinted + minted <= _minterMax, "ULTIMA: Minting this amount will exceed the cap."); 
    uint256 payday = getPayday(hodl);

    if( totalSupply + minted <= maxSupply){
      totalSupply += minted;
      vesting_balanceOf[receiver][payday] += minted;
      certified_entities[msg.sender].totalVestingMinted += minted;
      emit Transfer(address(0), receiver, minted);
    }
  }


  function mintUltimaV(address receiver, uint8 multiple, uint8 hodl) public rangeCheck(multiple) returns(uint256 minted){
    require(certified_entities[msg.sender].v_ultima_certified == true, "ULTIMA: This entity is not certified to mint Nyota."); 
    require(hodl >= 1 && hodl <= 60, "ULTIMA: Please provide a compliant vesting period."); 

    uint256 _minterMax = certified_entities[msg.sender].minterMax;
    uint256 _totalMinted = getMinterTotal(msg.sender);
    uint16 quantum = 1000 * multiple;
    minted = mintTierWise(receiver, quantum);
    require(_totalMinted + minted <= _minterMax, "ULTIMA: Minting this amount will exceed the cap."); 
    uint256 payday = getPayday(hodl);
    
    if( totalSupply + minted <= maxSupply){
      totalSupply += minted;
      vesting_balanceOf[receiver][payday] += minted;
      certified_entities[msg.sender].totalVestingMinted += minted;
      emit Transfer(address(0), receiver, minted);
    }
  }


  function mintUltima10V(address receiver, uint8 multiple, uint8 hodl) public rangeCheck(multiple) returns(uint256 minted){
    require(certified_entities[msg.sender].v_ultima10_certified == true, "ULTIMA: This entity is not certified to mint Nyota."); 
    require(hodl >= 1 && hodl <= 60, "ULTIMA: Please provide a compliant vesting period."); 

    uint256 _minterMax = certified_entities[msg.sender].minterMax;
    uint256 _totalMinted = getMinterTotal(msg.sender);
    uint16 quantum = 10000 * multiple;
    minted = mintTierWise(receiver, quantum);
    require(_totalMinted + minted <= _minterMax, "ULTIMA: Minting this amount will exceed the cap."); 
    uint256 payday = getPayday(hodl);
    
    if( totalSupply + minted <= maxSupply){
      totalSupply += minted;
      vesting_balanceOf[receiver][payday] += minted;
      certified_entities[msg.sender].totalVestingMinted += minted;
      emit Transfer(address(0), receiver, minted);
    }
  }


  function mintUltima100V(address receiver, uint8 multiple, uint8 hodl) public rangeCheck(multiple) returns(uint256 minted){
    require(certified_entities[msg.sender].v_ultima100_certified == true, "ULTIMA: This entity is not certified to mint Nyota."); 
    require(hodl >= 1 && hodl <= 60, "ULTIMA: Please provide a compliant vesting period."); 

    uint256 _minterMax = certified_entities[msg.sender].minterMax;
    uint256 _totalMinted = getMinterTotal(msg.sender);
    uint24 quantum = 100000 * multiple;
    minted = mintTierWise(receiver, quantum);
    require(_totalMinted + minted <= _minterMax, "ULTIMA: Minting this amount will exceed the cap."); 
    uint256 payday = getPayday(hodl);
    
    if( totalSupply + minted <= maxSupply){
      totalSupply += minted;
      vesting_balanceOf[receiver][payday] += minted;
      certified_entities[msg.sender].totalVestingMinted += minted;
      emit Transfer(address(0), receiver, minted);
    }
  }


  function mintUltima1000V(address receiver, uint8 multiple, uint8 hodl) public rangeCheck(multiple) returns(uint256 minted){
    require(certified_entities[msg.sender].v_ultima1000_certified == true, "ULTIMA: This entity is not certified to mint Nyota."); 
    require(hodl >= 1 && hodl <= 60, "ULTIMA: Please provide a compliant vesting period."); 

    uint256 _minterMax = certified_entities[msg.sender].minterMax;
    uint256 _totalMinted = getMinterTotal(msg.sender);
    uint24 quantum = 1000000 * multiple;
    minted = mintTierWise(receiver, quantum);
    require(_totalMinted + minted <= _minterMax, "ULTIMA: Minting this amount will exceed the cap."); 
    uint256 payday = getPayday(hodl);
    
    if( totalSupply + minted <= maxSupply){
      totalSupply += minted;
      vesting_balanceOf[receiver][payday] += minted;
      certified_entities[msg.sender].totalVestingMinted += minted;
      emit Transfer(address(0), receiver, minted);
    }
  }


  //----- MINTING VESTING-GAIA FLAVORS -----//

  function mintNyota100VGF(bytes8 geohash, address receiver, uint8 multiple, uint8 hodl) public rangeCheck(multiple) returns(uint256 minted){
    require(multiple >= 1 && multiple < 10, "ULTIMA: The multiple provided falls outside the minting spectrum.");
    require(certified_entities[msg.sender].v_gf_nyota100_certified == true, "ULTIMA: This entity is not certified to mint Nyota."); 
    require(hodl >= 1 && hodl <= 60, "ULTIMA: Please provide a compliant vesting period."); 

    uint256 _minterMax = certified_entities[msg.sender].minterMax;
    uint256 _totalMinted = getMinterTotal(msg.sender);
    uint16 quantum = 100 * multiple;
    minted = mintTierWise(receiver, quantum);
    require(_totalMinted + minted <= _minterMax, "ULTIMA: Minting this amount will exceed the cap."); 
    uint256 payday = getPayday(hodl);
    
    if( totalSupply + minted <= maxSupply){
      totalSupply += minted;
      gaia_vesting_balanceOf[receiver][geohash][payday] += minted;
      gaia_vesting_schedule[geohash][receiver].push(payday);
      certified_entities[msg.sender].totalVestingGeofencedMinted += minted;
      emit Transfer(address(0), receiver, minted);
    }
  }


  function mintUltimaVGF(bytes8 geohash, address receiver, uint8 multiple, uint8 hodl) public rangeCheck(multiple) returns(uint256 minted){
    require(certified_entities[msg.sender].v_gf_ultima_certified == true, "ULTIMA: This entity is not certified to mint Nyota."); 
    require(hodl >= 1 && hodl <= 60, "ULTIMA: Please provide a compliant vesting period."); 

    uint256 _minterMax = certified_entities[msg.sender].minterMax;
    uint256 _totalMinted = getMinterTotal(msg.sender);
    uint16 quantum = 1000 * multiple;
    minted = mintTierWise(receiver, quantum);
    require(_totalMinted + minted <= _minterMax, "ULTIMA: Minting this amount will exceed the cap."); 
    uint256 payday = getPayday(hodl);
    
    if( totalSupply + minted <= maxSupply){
      totalSupply += minted;
      gaia_vesting_balanceOf[receiver][geohash][payday] += minted;
      gaia_vesting_schedule[geohash][receiver].push(payday);
      certified_entities[msg.sender].totalVestingGeofencedMinted += minted;
      emit Transfer(address(0), receiver, minted);
    }
  }


  function mintUltima10VGF(bytes8 geohash, address receiver, uint8 multiple, uint8 hodl) public rangeCheck(multiple) returns(uint256 minted){
    require(certified_entities[msg.sender].v_gf_ultima10_certified == true, "ULTIMA: This entity is not certified to mint Nyota."); 
    require(hodl >= 1 && hodl <= 60, "ULTIMA: Please provide a compliant vesting period."); 

    uint256 _minterMax = certified_entities[msg.sender].minterMax;
    uint256 _totalMinted = getMinterTotal(msg.sender);
    uint24 quantum = 10000 * multiple;
    minted = mintTierWise(receiver, quantum);
    require(_totalMinted + minted <= _minterMax, "ULTIMA: Minting this amount will exceed the cap."); 
    uint256 payday = getPayday(hodl);
    
    if( totalSupply + minted <= maxSupply){
      totalSupply += minted;
      gaia_vesting_balanceOf[receiver][geohash][payday] += minted;
      gaia_vesting_schedule[geohash][receiver].push(payday);
      certified_entities[msg.sender].totalVestingGeofencedMinted += minted;
      emit Transfer(address(0), receiver, minted);
    }
  }


  function mintUltima100VGF(bytes8 geohash, address receiver, uint8 multiple, uint8 hodl) public rangeCheck(multiple) returns(uint256 minted){
    require(multiple >= 1 && multiple < 10, "ULTIMA: The multiple provided falls outside the minting spectrum.");
    require(certified_entities[msg.sender].v_gf_ultima100_certified == true, "ULTIMA: This entity is not certified to mint Nyota."); 
    require(hodl >= 1 && hodl <= 60, "ULTIMA: Please provide a compliant vesting period."); 

    uint256 _minterMax = certified_entities[msg.sender].minterMax;
    uint256 _totalMinted = getMinterTotal(msg.sender);
    uint24 quantum = 100000 * multiple;
    minted = mintTierWise(receiver, quantum);
    require(_totalMinted + minted <= _minterMax, "ULTIMA: Minting this amount will exceed the cap."); 
    uint256 payday = getPayday(hodl);
    
    if( totalSupply + minted <= maxSupply){
      totalSupply += minted;
      gaia_vesting_balanceOf[receiver][geohash][payday] += minted;
      gaia_vesting_schedule[geohash][receiver].push(payday);
      certified_entities[msg.sender].totalVestingGeofencedMinted += minted;
      emit Transfer(address(0), receiver, minted);
    }
  }


  function mintUltima1000VGF(bytes8 geohash, address receiver, uint8 multiple, uint8 hodl) public rangeCheck(multiple) returns(uint256 minted){
    require(multiple >= 1 && multiple < 10, "ULTIMA: The multiple provided falls outside the minting spectrum.");
    require(certified_entities[msg.sender].v_gf_ultima1000_certified == true, "ULTIMA: This entity is not certified to mint Nyota."); 
    require(hodl >= 1 && hodl <= 60, "ULTIMA: Please provide a compliant vesting period."); 

    uint256 _minterMax = certified_entities[msg.sender].minterMax;
    uint256 _totalMinted = getMinterTotal(msg.sender);
    uint24 quantum = 1000000 * multiple;
    minted = mintTierWise(receiver, quantum);
    require(_totalMinted + minted <= _minterMax, "ULTIMA: Minting this amount will exceed the cap."); 
    uint256 payday = getPayday(hodl);
    
    if( totalSupply + minted <= maxSupply){
      totalSupply += minted;
      gaia_vesting_balanceOf[receiver][geohash][payday] += minted;
      gaia_vesting_schedule[geohash][receiver].push(payday);
      certified_entities[msg.sender].totalVestingGeofencedMinted += minted;
      emit Transfer(address(0), receiver, minted);
    }
  }
}