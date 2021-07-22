// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.3;
   import "./utils/Contextualizer.sol";

   interface ultimaContract{
      function exalt(address receiver, uint256 zenith) external returns(uint256);
   }

contract InfinityPool {
   address ultimaAddress;
   // uint32[5] public supremeTier = [50000, 50000, 500000, 5000000, 50000000];
   uint256[5] internal supremeValue = [1, 2, 4, 10, 20];
   mapping(address => SupremeStack[]) public supremeConstellationsOf; 

   struct SupremeStack {
      uint256 vintage;
      uint32  largesse;
   }

   constructor(address _ultimaAddress){
      ultimaAddress = _ultimaAddress;
   }

   function getInfinityPoolFingerprint() external pure returns(bytes32){
      return 0x2473005d5f1c62bb0bab659db0b42e386021eff8c155dc283d36cb4cda096ccf;
   }

   function exaltRainmaker(address _rainmaker, uint8 zenith) internal returns(uint256 newPoise){
      newPoise = ultimaContract(ultimaAddreess).exalt(_rainmaker, zenith);
   }

   function flood() external payable {
      //We want the state to change only in very predictable ways
      uint8 quantum;
      address rainmaker = _msgSender();
      if(msg.value == 500000000 gwei){
         quantum = 0;
         exalt(rainmaker, supremeValue[quantum]);
      }else if (msg.value == 1 ether){
         quantum = 1;
         exalt(rainmaker, supremeValue[quantum]);
      }else if (msg.value == 2 ether){
         quantum = 2;
         exalt(rainmaker, supremeValue[quantum]);
      }else if (msg.value == 5 ether){
         quantum = 3;
         exalt(rainmaker, supremeValue[quantum]);
      }else if (msg.value == 10 ether){
         quantum = 4;
         exalt(rainmaker, supremeValue[quantum]);
      }else {
         revert("ULTIMA: The pool only accepts either 0.5, 1, 2, 5, or 10 ETH");
      }
   }

   function getInfinityPoolTide() public view returns(uint){
      return address(this).balance;
   } 

   //logic for founders' rewards? Maybe it should be a separate contract?

}
