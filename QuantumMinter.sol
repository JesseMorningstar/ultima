// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.3;

import "utils/Contextualizer.sol";
import "utils/UltimaDataLayout.sol";

contract QuantumMinter is Contextualizer, UltimaDataLayout {

  bytes32 internal constant QUANTUMMINTER_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  function updateCodeAddress(address newAddress) external onlyFlamekeepers onlyProxy{
    quantumMinterVersions.push(newAddress);
    assembly {
        sstore(QUANTUMMINTER_SLOT, newAddress)
    }

    emit Upgraded(newAddress);
  }

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
    }else{
      //throw some kind of error
    }
  }

  function getMinterTotal(address minter) public view returns (uint128 minterTotal){
    MinterCharter memory _minter = certified_entities[minter];
    uint128 _totalSovereign = _minter.totalSovereignMinted;
    uint128 _totalGeofenced = _minter.totalGeofencedMinted;
    uint128 _totalVesting = _minter.totalVestingMinted;
    uint128 _totalVestingGeofenced = _minter.totalVestingGeofencedMinted;
    uint128 _totalLaurels = _minter.totalLaurelsGranted;

    minterTotal = _totalSovereign + _totalGeofenced + _totalVesting + _totalVestingGeofenced + _totalLaurels;
  }

  function getHodlerBonus(uint128 value, address hodler)internal view returns(uint128){
    uint8 percentage = base_percentage * whichTier(hodler);
    return (value * percentage) / 100;
  }

  function getPayday(uint8 hodl) internal view returns (uint256){
    uint256 hodl_base = 2592000;
    return block.timestamp + (hodl_base * hodl);
  }

  function supremeReward(address receiver, uint128 quantum) public view returns(uint128 _minted){
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

  event Upgraded(address indexed newImplementation);
  event MintedSovereign(address indexed minter, address indexed receiver, uint8 flavor, uint256 value);
  event MintedVesting(address indexed minter, address indexed receiver, uint8 flavor, uint256 value, uint256 payday);
  event MintedGaia(address indexed minter, address indexed receiver, uint8 flavor, bytes8 indexed geohash, uint256 value);
  event MintedGaiaVesting(address indexed minter, address indexed receiver, uint8 flavor, bytes8 indexed geohash, uint256 payday, uint256 value);
  event LaurelsGranted(address indexed minter, address indexed receiver, uint32 laurels);


  //----- CORE MINTING FUNCTIONS -----//

  function grantLaurels(uint8 flavor, uint8 multiple, address minter, address receiver) private onlyProxy returns(uint32 newLaurels) {
    MinterCharter memory _minter = certified_entities[_msgSender()];
    require(_minter.minterPermit[flavor] == true, "ULTIMA: This entity is not allowed to grant Laurels.");
    require(flavor >= 24 && flavor <= 25, "ULTIMA: This process can only be used to grant Laurels.");
    newLaurels = base[flavor] * multiple;
    uint128 _totalMinted = getMinterTotal(minter);
    require(_totalMinted + newLaurels <= _minter.minterMax, "ULTIMA: Granting these many Laurels exceeds this entity's cap.");

    if(totalLaurels + newLaurels <= maxLaurelsSupply && totalSupply + newLaurels <= maxSupply){
      totalLaurels += newLaurels;
      laurelsOf[receiver] += newLaurels;
      _minter.totalLaurelsGranted += newLaurels;
      emit LaurelsGranted(minter, receiver, newLaurels);
    }
  }

  function mintSovereign(uint8 flavor, uint8 multiple, address minter, address receiver) private onlyProxy returns(uint128 minted){
    MinterCharter memory _minter = certified_entities[_msgSender()];
    require(_minter.minterPermit[flavor] == true, "ULTIMA: This minter is not allowed to mint this quantum.");
    require(flavor >= 0 && flavor <= 6, "ULTIMA: This process can only mint the Sovereign flavor.");
    uint128 quantum = base[flavor] * multiple;
    minted = supremeReward(receiver, quantum);
    uint128 _totalMinted = getMinterTotal(minter);
    require(_totalMinted + minted <= _minter.minterMax, "ULTIMA: Minting this amount will exceed the cap.");

    if( totalSupply + minted <= maxSupply){
      totalSupply += minted;
      balanceOf[receiver] += minted;
      _minter.totalSovereignMinted += minted;
      emit MintedSovereign(minter, receiver, flavor, minted);
    }
  }

  function mintVesting(uint8 flavor, uint8 hodl, uint8 multiple, address minter, address receiver) private onlyProxy returns(uint128 minted){
    MinterCharter memory _minter = certified_entities[_msgSender()];
    require(_minter.minterPermit[flavor] == true, "ULTIMA: This minter is not allowed to mint this quantum.");
    require(flavor >= 7 && flavor <= 11, "ULTIMA: This process can only mint the Vesting flavor.");
    require(hodl >= 1 && hodl <= 60, "ULTIMA: Please provide a compliant vesting period.");

    uint128 quantum = base[flavor] * multiple;
    minted = supremeReward(receiver, quantum);
    uint128 _totalMinted = getMinterTotal(minter);
    require(_totalMinted + minted <= _minter.minterMax, "ULTIMA: Minting this amount will exceed the cap.");
    uint256 payday = getPayday(hodl);

    if( totalSupply + minted <= maxSupply){
      totalSupply += minted;
      vesting_balanceOf[receiver][payday] += minted;
      _minter.totalVestingMinted += minted;
      emit MintedVesting(minter, receiver, flavor, minted, payday);
    }
  }

  function mintGeofenced(uint8 flavor, bytes8 geohash, uint8 multiple, address minter, address receiver) private onlyProxy returns(uint128 minted){
    MinterCharter memory _minter = certified_entities[_msgSender()];
    require(_minter.minterPermit[flavor] == true, "ULTIMA: This minter is not allowed to mint this quantum.");
    require(flavor >= 12 && flavor <= 18, "ULTIMA: This process can only mint the Gaia flavor.");
    //check for whether the Gaiaring is active => you'll have to update the data structure for this

    uint128 quantum = base[flavor] * multiple;
    minted = supremeReward(receiver, quantum);
    uint128 _totalMinted = getMinterTotal(minter);
    require(_totalMinted + minted <= _minter.minterMax, "ULTIMA: Minting this amount will exceed the cap.");

    if( totalSupply + minted <= maxSupply){
      totalSupply += minted;
      gaia_balanceOf[receiver][geohash] += minted;
      _minter.totalGeofencedMinted += minted;
      emit MintedGaia(minter, receiver, flavor, geohash, minted);
    }
  }


  function mintGeofencedVesting(uint8 flavor, uint8 multiple, bytes8 geohash, uint8 hodl, address minter, address receiver ) private onlyProxy returns(uint128 minted){
    MinterCharter memory _minter = certified_entities[_msgSender()];
    require(_minter.minterPermit[flavor] == true, "ULTIMA: This minter is not allowed to mint this quantum.");
    require(flavor >= 19 && flavor <= 23, "ULTIMA: This process can only mint the Gaia Vesting flavor.");
    require(hodl >= 1 && hodl <= 60, "ULTIMA: Please provide a compliant vesting period."); 
    //check for whether the Gaiaring is active

    uint128 quantum = base[flavor] * multiple;
    minted = supremeReward(receiver, quantum);
    uint128 _totalMinted = getMinterTotal(minter);
    require(_totalMinted + minted <= _minter.minterMax, "ULTIMA: Minting this amount will exceed the cap.");
    uint256 payday = getPayday(hodl);

    if( totalSupply + minted <= maxSupply){
      totalSupply += minted;
      gaia_vesting_balanceOf[receiver][geohash][payday] += minted;
      _minter.totalVestingGeofencedMinted += minted;
      emit MintedGaiaVesting(minter, receiver, flavor, geohash, payday, minted);
    }
  }


  //----- MINTING SOVEREIGN FLAVORS -----//

  function mintNyota(address receiver, uint8 multiple) external onlyProxy rangeCheck(multiple) returns(uint128 minted) {
    uint8 flavor = uint8(Quanta.nyota);
    address minter = msg.sender;
    minted = mintSovereign(flavor, multiple, minter, receiver);
  }

  function mintNyota10(address receiver, uint8 multiple) external onlyProxy rangeCheck(multiple) returns(uint256 minted){
    uint8 flavor = uint8(Quanta.nyota10);
    address minter = msg.sender;
    minted = mintSovereign(flavor, multiple, minter, receiver);
  }

  function mintNyota100(address receiver, uint8 multiple) external onlyProxy rangeCheck(multiple) returns(uint256 minted){
    uint8 flavor = uint8(Quanta.nyota100);
    address minter = msg.sender;
    minted = mintSovereign(flavor, multiple, minter, receiver);
  }

  function mintUltima(address receiver, uint8 multiple) external onlyProxy rangeCheck(multiple) returns(uint256 minted){
    uint8 flavor = uint8(Quanta.ultima);
    address minter = msg.sender;
    minted = mintSovereign(flavor, multiple, minter, receiver);
  }

  function mintUltima10(address receiver, uint8 multiple) external onlyProxy rangeCheck(multiple) returns(uint256 minted) {
    uint8 flavor = uint8(Quanta.ultima10);
    address minter = msg.sender;
    minted = mintSovereign(flavor, multiple, minter, receiver);
  }

  function mintUltima100(address receiver, uint8 multiple) external onlyProxy rangeCheck(multiple) returns(uint256 minted){
    uint8 flavor = uint8(Quanta.ultima100);
    address minter = _msgSender();
    minted = mintSovereign(flavor, multiple, minter, receiver);
  }

  function mintUltima1000(address receiver, uint8 multiple) external onlyProxy rangeCheck(multiple) returns(uint256 minted){
    uint8 flavor = uint8(Quanta.ultima1000);
    address minter = msg.sender;
    minted = mintSovereign(flavor, multiple, minter, receiver);
  }

  
  //----- MINTING VESTING FLAVORS -----//

  function mintNyota100V(address receiver, uint8 multiple, uint8 hodl) external onlyProxy rangeCheck(multiple) returns(uint256 minted){
   uint8 flavor = uint8(Quanta.v_nyota100);
    address minter = _msgSender();
    minted = mintVesting(flavor, hodl, multiple, minter, receiver);
  }

  function mintUltimaV(address receiver, uint8 multiple, uint8 hodl) external onlyProxy rangeCheck(multiple) returns(uint256 minted){
    uint8 flavor = uint8(Quanta.v_ultima);
    address minter = _msgSender();
    minted = mintVesting(flavor, hodl, multiple, minter, receiver);
  }

  function mintUltima10V(address receiver, uint8 multiple, uint8 hodl) external onlyProxy rangeCheck(multiple) returns(uint256 minted){
    uint8 flavor = uint8(Quanta.v_ultima10);
    address minter = _msgSender();
    minted = mintVesting(flavor, hodl, multiple, minter, receiver);
  }

  function mintUltima100V(address receiver, uint8 multiple, uint8 hodl) external onlyProxy rangeCheck(multiple) returns(uint256 minted){
    uint8 flavor = uint8(Quanta.v_ultima100);
    address minter = _msgSender();
    minted = mintVesting(flavor, hodl, multiple, minter, receiver);
  }

  function mintUltima1000V(address receiver, uint8 multiple, uint8 hodl) external onlyProxy rangeCheck(multiple) returns(uint256 minted){
    uint8 flavor = uint8(Quanta.v_ultima1000);
    address minter = _msgSender();
    minted = mintVesting(flavor, hodl, multiple, minter, receiver);
  }


  //----- MINTING GAIA FLAVORS -----//

  function mintNyotaGF(bytes8 geohash, address receiver, uint8 multiple) external onlyProxy rangeCheck(multiple) returns(uint256 minted){
    uint8 flavor = uint8(Quanta.gf_nyota);
    address minter = _msgSender();
    minted = mintGeofenced(flavor, geohash, multiple, minter, receiver);
  }

  function mintNyota10GF(bytes8 geohash, address receiver, uint8 multiple) external onlyProxy rangeCheck(multiple) returns(uint256 minted){
    uint8 flavor = uint8(Quanta.gf_nyota10);
    address minter = _msgSender();
    minted = mintGeofenced(flavor, geohash, multiple, minter, receiver);
  }

  function mintNyota100GF(bytes8 geohash, address receiver, uint8 multiple) external onlyProxy rangeCheck(multiple) returns(uint256 minted){
    uint8 flavor = uint8(Quanta.gf_nyota100);
    address minter = _msgSender();
    minted = mintGeofenced(flavor, geohash, multiple, minter, receiver);
  }

  function mintUltimaGF(bytes8 geohash, address receiver, uint8 multiple) external onlyProxy rangeCheck(multiple) returns(uint256 minted){
    uint8 flavor = uint8(Quanta.gf_ultima);
    address minter = _msgSender();
    minted = mintGeofenced(flavor, geohash, multiple, minter, receiver);
  }

  function mintUltima10GF(bytes8 geohash, address receiver, uint8 multiple) external onlyProxy rangeCheck(multiple) returns(uint256 minted){
    uint8 flavor = uint8(Quanta.gf_ultima10);
    address minter = _msgSender();
    minted = mintGeofenced(flavor, geohash, multiple, minter, receiver);
  }

  function mintUltima100GF(bytes8 geohash, address receiver, uint8 multiple) external onlyProxy rangeCheck(multiple) returns(uint256 minted){
    uint8 flavor = uint8(Quanta.gf_ultima100);
    address minter = _msgSender();
    minted = mintGeofenced(flavor, geohash, multiple, minter, receiver);
  }

  function mintUltima1000GF(bytes8 geohash, address receiver, uint8 multiple) external onlyProxy rangeCheck(multiple) returns(uint256 minted){
    uint8 flavor = uint8(Quanta.gf_ultima1000);
    address minter = _msgSender();
    minted = mintGeofenced(flavor, geohash, multiple, minter, receiver);
  }


  //----- MINTING VESTING-GAIA FLAVORS -----//

  function mintNyota100VGF(bytes8 geohash, uint8 hodl, uint8 multiple, address receiver) external onlyProxy rangeCheck(multiple) returns(uint256 minted){
    uint8 flavor = uint8(Quanta.v_gf_nyota100);
    address minter = _msgSender();
    minted = mintGeofencedVesting(flavor, multiple, geohash, hodl, minter, receiver);
  }

  function mintUltimaVGF(bytes8 geohash, address receiver, uint8 multiple, uint8 hodl) external onlyProxy rangeCheck(multiple) returns(uint256 minted){
    uint8 flavor = uint8(Quanta.v_gf_ultima);
    address minter = _msgSender();
    minted = mintGeofencedVesting(flavor, multiple, geohash, hodl, minter, receiver);
  }

  function mintUltima10VGF(bytes8 geohash, address receiver, uint8 multiple, uint8 hodl) external onlyProxy rangeCheck(multiple) returns(uint256 minted){
    uint8 flavor = uint8(Quanta.v_gf_ultima10);
    address minter = _msgSender();
    minted = mintGeofencedVesting(flavor, multiple, geohash, hodl, minter, receiver);
  }

  function mintUltima100VGF(bytes8 geohash, address receiver, uint8 multiple, uint8 hodl) external onlyProxy rangeCheck(multiple) returns(uint256 minted){
    uint8 flavor = uint8(Quanta.v_gf_ultima100);
    address minter = _msgSender();
    minted = mintGeofencedVesting(flavor, multiple, geohash, hodl, minter, receiver);
  }

  function mintUltima1000VGF(bytes8 geohash, address receiver, uint8 multiple, uint8 hodl) external onlyProxy rangeCheck(multiple) returns(uint256 minted){
    uint8 flavor = uint8(Quanta.v_gf_ultima1000);
    address minter = _msgSender();
    minted = mintGeofencedVesting(flavor, multiple, geohash, hodl, minter, receiver);
  }


  //----- GRANTING LAURELS -----//
  function grantLowMerit(address receiver, uint8 multiple) external onlyProxy rangeCheck(multiple) returns(uint256 newLaurels){
    uint8 flavor = uint8(Quanta.lowMerit);
    address minter = _msgSender();
    newLaurels = grantLaurels(flavor, multiple, minter, receiver);
  }

  function grantHighMerit(address receiver, uint8 multiple) external onlyProxy rangeCheck(multiple) returns(uint256 newLaurels){
    uint8 flavor = uint8(Quanta.highMerit);
    address minter = _msgSender();
    newLaurels = grantLaurels(flavor, multiple, minter, receiver);
  }

  //----- BURNING LAURELS -----//
}