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
   import "./utils/Contextualizer.sol";

   interface ultimaContract{
      function exalt(address receiver, uint256 zenith) external returns(uint256);
   }

contract InfinityPool {
   struct SupremeStack {
      uint256 vintage;
      uint256 cluster;
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
   mapping(address => SupremeStack[]) public constellationsOf;

   constructor(address _ultimaAddress){
      ultimaAddress = _ultimaAddress;
   }

   function getInfinityPoolFingerprint() external pure returns(bytes32){
      return 0x2473005d5f1c62bb0bab659db0b42e386021eff8c155dc283d36cb4cda096ccf;
   }

   function addCommunityUtility(address contractAddress, uint256 shareOfPool, bytes32 callsign) external onlyFlamekeers {
      UtilityCharter memory newUtility;
      newUtility.utilityContract = contractAddress;
      newUtility.callsign = callsign;
      newUtility.shareOfPool = shareOfPool;
      communityUtilities.push(newUtility);
   }

   function updateUtilityStatus(bool newStatus, uint8 id) external onlyFlamekeepers returns(bool){
      communityUtilities[utilityId].operative = newStatus;
      return (communityUtilities[utilityId].callsign, newStatus);
   }

   function newConstellation(address rainmaker, uint256 nova) internal {
      constellationsOf[rainmaker].push(SupremeStack(block.timestamp, nova));
   }

   function exaltRainmaker(address rainmaker, uint8 quantum) internal returns(uint256 newPoise){
      uint256 zenith = supremeValue[quantum];
      newPoise = ultimaContract(ultimaAddreess).exalt(rainmaker, zenith);
      newConstallation(rainmaker, zenith);
      InfinityPoolExpanse += zenith;
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

   //logic for founders' rewards? Maybe it should be a separate contract?

}
