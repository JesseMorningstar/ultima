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
   function isSupremeHolder(address ballerina) view external returns(bool ballerinaIsHodler);
}

contract InfinityPool {
   struct SupremeStacked { //should probably be supremeDeposit
      uint256 vintage;
      uint256 supreme;
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

   struct Quarter{
      uint256 id;
      uint256 start; 
      uint256 end;
      bool claimingWindowStatus;
      uint256 valueCreated;
      uint256 totalDistributionUnits;
      //should probably caluclate what the size of the payoff pool will be. it has to be a ratio. 80/20 type situation.
      uint256 payoffPool;
      PayoffClaim[] payoffClaims;
   }

   struct PayoffClaim {
      address payable supremeHodler;
      uint256 distributionUnits;
      uint256 payoffFactorScaled;
   }

   struct WithdrawalMetadata{
      //mark after which deposit they withdrew money. After each withdrawal the time value of Supreme resets.
      //We use this variable to pinpoint when to do the reset.
      uint256 stackLevel;
      uint256 claimSlot;
      uint256 claimTimestamp; 
      uint256 quarterId; 
      uint8   payoffFactorScaled;
      bool    withdrawn;
      uint256 withdrawalTimestamp;
      uint256 supremeScored;
      uint256[] pendingWithdrawals;
   }

   //Information about last withdrawal is essential for computing values for next withdrawal
   uint256 currentQuarter;
   uint256 quarterSpan = 90 days;
   uint256 genesisPoint; 
   bool    genesisPointExists = false;

   uint256 public InfnityPoolExpanse;
   uint256 public CommunityTreasury;
   address ultimaAddress;
   uint256[5] internal supremeValue = [1000, 2000, 4000, 10000, 20000];
   UtilityCharter[] public communityUtilities;
   Quarter[] public quarters; 
   mapping(address => SupremeStacked[]) public depositsOf;
   mapping(address => WithdrawalMetadata[]) public withdrawalsHistory;

   modifier onlySupremeHodlers(address hodler){
      bool supremeHodler = ultimaContract(ultimaAddress).isSupremeHolder(hodler);
      require(supremeHodler == true, "ULTIMA: Must be A Supremehodler to proceed.");
      _;
   }

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
      bool claimingWindowStatus = false;
      uint256 valueCreated;
      uint256 totalDistributionUnits;
      uint256 payoffPool;
      PayoffClaim[] _payoffClaims;

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

         quarters[targetSlot] = Quarter(
            quarterId, 
            start, 
            end, 
            claimingWindowStatus,
            valueCreated,
            totalDistributionUnit,
            payoffPool,
            _payoffClaims
         );

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
      newPoise = ultimaContract(ultimaAddress).exalt(rainmaker, zenith);
      newConstallation(rainmaker, zenith);
      InfinityPoolExpanse += zenith;
   }

   function claimSupremePayoff() external onlySupremeHodlers(_msgSender()){
      uint256 currentQuarterSlot = currentQuarter - 1;
      int256 lastClaimSlot = withdrawalsHistory[_msgSender()].length - 1;
      bool uniqueClaim = false;
      
      if(lastClaimSlot < 0){uniqueclaim = true;} else{
         WithdrawalMetadata lastClaimMetadata = withdrawalsHistory[_msgSender()][lastClaimSlot];
         if(lastClaimMetadata.quarterId < currentQuarter){uniqueClaim = true;}
      }
      require(uniqueClaim == true, "ULTIMA: You've already claimed your payoff");

      uint256 quarterEndMark = quarters[currentQuarterSlot].end;
      uint256 ClaimingWindowStatus = quarters[currentQuarterSlot].claimingWindowStatus;
      uint256 claimingWindowOpened = quarterEndMark - 10 days;
      uint256 claimingWindowClosed = claimingWindowOpened + 7 days;
      uint256 blockTime = block.timestamp;
      bool    greenLight;
      if(blockTime >= claimingWindowopened && blockTime <= claimingWindowClosed) greenLight = true;
      require(greenLight == true && claimingWindowStatus == true, "ULTIMA: Sorry, you can't claim your payoff at this time.");

      
      uint256 stackLevel = depositsOf[_msgSender()].length - 1;
      uint256 claimSlot = quarters[currentQuarterSlot].payoffClaims.length;
      uint256 (supremeScored, distributionUnits) = getDistributionUnits(_msgSender()); //test these values
      uint256 payoffFactorScaled;
      uint256 withdrawalTimestamp;

      //do something here for pending withdrawals 
      //check if the last quarter withdrawn is true or false. 
      //if false then add it to the uint256[] pendingWithdrawals
      
      quarters[currentQuarterSlot].payoffClaims.push(PayoffClaim(_msgSender(), distributionUnits, payoffFactorScaled));
      withdrawalsHistory[_msgSender()].push(WithdrawalMetadata(
         stackLevel, 
         claimSlot, 
         blockTime, 
         currentQuarter, 
         supremeScored,
         payoffFactorScaled, 
         false, 
         withdrawalTimestamp
      ));
      quarters[currentQuarterSlot].totalDistributionUnits += distributionUnits;
   }

   function getPendingWithdrawals() external {

   }

   function withdrawPayoff(uint256 quarterId) external onlySupremeHodlers(_msgSender())  returns(bool){
      uint256 quarterSlot = quarterId - 1;
      Quarter quarter = quarters[currentQuarterSlot]; 
      WithdrawalMetadata withdrawalParameters; // Resume
      uint256 withdrawalsWindowOpened = quarter.end - 3 days; 

      //of course they can only call this function during the withdrawal period
      //and they must be a supremeHodler, so add that modifier
      //make sure that only those holders who have made a claim can make a withdrawal (so a claim must exist for this to work)
      //where are we getting the distribution units from? [We need to extract that value]
      uint256 payoffFactorScaled = getPayoffFactorScaled(distributionUnits);
      //write the payoffFactorScaled to the withdrawal metadata
      //make the withdrawal calculation 
      //and actually carry out the withdrawal
   }

   function getPayoffFactorScaled(uint256 dUnits) public returns(uint256 payoffFactorScaled){
      uint256 scale = 10**18;
      uint256 currentQuarterSlot = currentQuarter - 1;
      uint256 totalDUnits = quarters[currentQuarterSlot].totalDistributionUnits;
      payoffFactorScaled = (dUnits * scale) / totalDUnits;
   }

   function getDistributionUnits(address supremeHodler) internal returns(uint256 supremeScored, distributionUnits){
      SupremeStacked[] memory deposits = depositsOf[supremeHodler];
      uint256 currentQuarterSlot = currentQuarter - 1;
      uint256 nextQuarterSlot = currentQuarter;
      Quarter thisQuarter = quarters[currentQuarterSlot];
      uint256 numberOfDeposits = deposits.length;
      uint256 withdrawalsToDate = withdrawalsHistory[_msgSender()].length;
      uint256 lastWithdrawalSlot = withdrawalsToDate - 1;
      uint256 accountingPoint = thisQuarter.end;
      uint256 stackLevel;
      uint226 i;

      if(withdrawalsToDate < 1){
         i = 0;
         distributionUnits = 0;
         supremeScored = 0;
      } else {
         WithdrawalMetadata lastWithdrawal = withdrawalsHistory[lastWithdrawalSlot];
         stackLevel = lastWithdrawal.stackLevel; 
         uint256 resetQuarterSlot = lastWithdrawal.quarterId; //check this stuff, it can get dangerous fast
         uint256 resetPoint = quarters[resetQuarterSlot].start;
         uint256 lifespan = (accountingPoint - resetPoint) / 86400;
         supremeScored = lastWithdrawal.supremeScored;
         distributionUnits = lifespan * supremeScored;
         i = stackLevel + 1;
      }

      while( i < numberOfDeposits){
         SupremeStacked deposit = deposits[i];
         uint256 _lifespan = (quarters[nextQuarterSlot].start - deposit.vintage) / 86400;
         uint256 depositDistributionUnits = _lifespan * deposit.supreme;
         supremeScored += deposit.supreme;
         distributionUnits += depositDistributionUnits;
         i++;
      }  
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
