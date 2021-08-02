// SPDX-License-Identifier: AGPL-3.0-or-later

/*
So this contract's purpose is to aggregate capital and then route it. 
It's at its core an autonomous capital router.
Concentrate capital and then route it to crucial community endeavors.
Key functions include:
1. Providing a superbly incentivized mechanism for pooling capital. 
2. Setting up calculations to determine how that capital will be fanned out into the ecosystem.
3. Implementing an algorithm for the fair distribution of the profits obtained from that productive deployment of capital
*/


pragma solidity 0.8.3;

import "./modules/Contextualizer.sol"; 

interface ultimaContract{
   function exalt(address receiver, uint256 zenith) external returns(uint256);
}

contract InfinityPool {
   //Information about last withdrawal is essential for computing values for next withdrawal
   uint256 currentQuarter;
   uint128 quarterSpan     = 115200 minutes;
   uint64  enrollmentPeriod = 10080 minutes;
   uint64  withdrawalPeriod = 4320 minutes;
   uint256 genesisPoint; 
   bool    genesisPointExists = false;
   bool withdrawalManifestIsLive = false; 
   bool withdrawalWindowIsOpened = false;

   struct SupremeStacked {
      uint256 vintage;
      uint256 supreme;
   }

   struct Quarter{
      uint256 id;
      uint256 start; 
      uint256 end;
      uint256 valueCreated;
      uint256 valueDistributed;
   }

   struct WithdrawalSummary{
      //mark after which deposit they withdrew money. After each withdrawal the time value of Supreme resets.
      //We use this variable to pinpoint when to do the reset.
      uint256 stackLevel; 
      uint256 timestamp;
      uint256 quarterNumber; 
      uint256 distributionUnits;
      uint8   percentage;
   }

   struct UtilityCharter{
      bool    operative;
      uint256 shareOfPool;
      uint256 utilityPool;
      uint256 fundsReceived;
      uint256 fundsRestored;
      bytes32 callsign;
      address utilityContract;
   }

   uint256 public InfnityPoolExpanse;
   uint256 public CommunityTreasury;
   address ultimaAddress;
   uint256[5] internal supremeValue = [1000, 2000, 4000, 10000, 20000];
   UtilityCharter[] public communityUtilities;
   Quarter[] public quarters; 
   mapping(address => SupremeStacked[]) public depositsOf;
   mapping(address => WithdrawalSummary[]) public withdrawalsHistory;

   constructor(address _ultimaAddress){
      ultimaAddress = _ultimaAddress;
   }

   function getInfinityPoolFingerprint() external pure returns(bytes32){
      return 0x2473005d5f1c62bb0bab659db0b42e386021eff8c155dc283d36cb4cda096ccf;
   }

   function setGenesispoint() external onlyFlamekeepers {
      require(genesisPointExists == false, "ULTIMA: The Genesis Point already exists.");
      genesisPoint = block.timestamp;
      genesisPointExists = true;
      currentQuarter = 1;
      //populate quarters - create quarters parameters (call the function here);
   }

   function rollOutQuarters() external onlyFlamekeepers {
      uint256 lastQuarterId;
      uint256 lastQuarterEnded;
      uint128 targetSlot = quarters.length; 
      uint128 quartersToAdd = 120;
      uint128 lastSlot = targetSlot + (quartersToAdd - 1);
      uint32  quarterId;
      uint256 start;
      uint256 end;
      uint256 valueCreated;
      uint256 valueDistributed;

      while(targetSlot <= lastSlot){
         if(targetSlot == 0){ 
            lastQuarterEnded = genesisPoint;
         }else {
            previousQuarterSlot = targetSlot - 1;
            lastQuarterEnded = quarters[previousQuarterSlot].end;
         }
         quarterId = targetSlot + 1;
         start = lastQuarterEnded + 30 minutes;
         end = start + quarterSpan;
         quarters[targetSlot] = Quarter(quarterId, start, end, valueCreated, valueDistributed);
         targetSlot++;
      }
   }

   function addCommunityUtility(address contractAddress, uint256 shareOfPool, bytes32 callsign) external onlyFlamekeepers {
      UtilityCharter memory newUtility;
      newUtility.utilityContract = contractAddress;
      newUtility.callsign = callsign;
      newUtility.shareOfPool = shareOfPool;
      communityUtilities.push(newUtility);
   }

   function updateUtilityStatus(bool newStatus, uint8 utilityId) external onlyFlamekeepers returns(bool){
      communityUtilities[utilityId].operative = newStatus;
      return (communityUtilities[utilityId].callsign, newStatus);
   }

   //Newly minted Supreme tokens form a constellation
   function newConstellation(address rainmaker, uint256 amount) internal {
      depositsOf[rainmaker].push(SupremeStacked(block.timestamp, amount));
   }

   function exaltRainmaker(address rainmaker, uint8 quantum) internal returns(uint256 newPoise){
      uint256 zenith = supremeValue[quantum];
      newPoise = ultimaContract(ultimaAddreess).exalt(rainmaker, zenith);
      newConstallation(rainmaker, zenith);
      InfinityPoolExpanse += zenith;
   }

   function getDistributionUnits(address supremeHodler) internal returns(uint256 distributionUnits){
      SupremeStacked[] memory deposits = depositsOf[supremeHodler];
      uint256 numberOfDeposits = deposits.length;
      for(uint i = 0; i < numberOfDeposits; i++){
         uint256 lifespan = (block.timestamp - deposits[i].vintage) / 60;
         uint256  depositDistributionUnits = lifespan * deposits[i].supreme;
         distributionUnits += depositDistributionUnits;
      }  
   }

   function getSupremeHodlerPoolShare(uint256) internal returns(uint256){
   }


   function flood() external payable returns(uint256 exaltation) {
      //We want the state to change only in very predictable ways
      uint8 quantum;
      address rainmaker = _msgSender();
      if(msg.value == 500000000 gwei){
         quantum = 0;
         exaltation = exaltRainmaker(rainmaker, quantum);
         
      }else if (msg.value == 1 ether){
         quantum = 1;
         exaltation = exaltRainmaker(rainmaker, quantum);

      }else if (msg.value == 2 ether){
         quantum = 2;
         exaltation = exaltRainmaker(rainmaker, quantum);

      }else if (msg.value == 5 ether){
         quantum = 3;
         exaltation = exaltRainmaker(rainmaker, quantum);

      }else if (msg.value == 10 ether){
         quantum = 4;
         exaltation = exaltRainmaker(rainmaker, quantum);
         
      }else {
         revert("ULTIMA: The pool only accepts either 0.5, 1, 2, 5, or 10 ETH");
      }
   }

   function getInfinityPoolTide() public view returns(uint){
      return address(this).balance;
   }

}
