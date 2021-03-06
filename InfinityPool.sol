// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.3;

import "./modules/Contextualizer.sol"; 

interface ultimaContract{
   function exalt(address receiver, uint256 zenith) external returns(uint256);
   function isFlamekeeper(address ballerina) view external returns(bool isAKeeper);
   function isSupremeHolder(address ballerina) view external returns(bool ballerinaIsHodler);
}

contract InfinityPool is Contextualizer {
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
      uint256 valueCreated;
      uint256 totalDistributionUnits;
      uint256 payoffPool;
      uint256 payoffReleased;
      uint256 payoffLeftover;
      PayoffClaim[] payoffClaims;
   }

   struct Synchronizer{
      uint256 quarterId;
      uint256 claimingPhaseStart;
      uint256 claimingPhaseEnd;
      uint256 withdrawalsKickoff;
      bool claimingPhase;
      bool withdrawalPhase;
   }

   struct PayoffClaim {
      address supremeHodler;
      uint256 distributionUnits;
      uint256 withdrawalReceiptSlot;
      bool processed;
      //should we add a timestamp to record when exactly it was processed
   }

   struct PendingPayoff{
      uint256 quarterId;
      uint256 claimSlot;
   }

   struct WithdrawalMetadata{
      //mark after which deposit they withdrew money. After each withdrawal the time value of Supreme resets.
      //We use this variable to pinpoint when to do the reset.
      uint256 stackLevel;
      uint256 claimSlot;
      uint256 claimTimestamp; 
      uint256 quarterId; 
      uint256 payoffFactorScaled;
      bool    withdrawn;
      uint256 supremeScored;
      uint256 withdrawalTimestamp;
   }

   //Information about last withdrawal is essential for computing values for next withdrawal
   uint256 public currentQuarter;
   uint256 public quarterSpan = 90 days;
   uint256 public genesisPoint; 
   bool    public genesisPointExists = false;

   uint256 public InfinityPoolExpanse;
   uint256 public CommunityTreasury;
   address ultimaAddress;
   uint256[5] internal supremeValue = [1000, 2000, 4000, 10000, 20000];
   UtilityCharter[] public communityUtilities;
   Quarter[] public quarters; 
   Synchronizer[] public watersheds;
   mapping(address => SupremeStacked[]) public depositsOf;
   mapping(address => PendingPayoff[]) public pendingPayoffs;
   mapping(address => WithdrawalMetadata[]) public withdrawalsHistory;

   event PayoffWithdrawn(address indexed sepremeHodler, uint256 indexed quarterId, uint256 indexed EthPayoff);

   modifier onlyFlamekeepers(address theCaller){
      bool isAKeeper = ultimaContract(ultimaAddress).isFlamekeeper(theCaller);
      require(isAKeeper == true, "ULTIMA: Must be A flamekeeper to proceed.");
      _;
   }

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

   function setGenesispoint() external onlyFlamekeepers(_msgSender()) {
      require(genesisPointExists == false, "ULTIMA: The Genesis Point already exists.");
      genesisPoint = block.timestamp;
      genesisPointExists = true;
      currentQuarter = 1;
   }

   //the synchronizing functions will get more sophisticated
   //maybe we won't need to sync explicitly. They can first call an oracle that timestapms the transaction
   //use the timestamp to carry out the transaction. 
   //so everything can remain contained in the claim function call
   function syncClaimingPhaseStart(uint256 start) external onlyFlamekeepers(_msgSender()){
      uint256 quarterSlot = currentQuarter - 1;
      watersheds[quarterSlot].claimingPhaseStart = start;
      watersheds[quarterSlot].claimingPhase = true;
   }

   function syncClaimingPhaseEnd(uint256 end) external onlyFlamekeepers(_msgSender()){
      uint256 quarterSlot = currentQuarter - 1;
      watersheds[quarterSlot].claimingPhaseEnd = end;
      watersheds[quarterSlot].claimingPhase = false;
   }

   function syncWithdrawalsKickoff(uint256 kickoffPoint) external onlyFlamekeepers(_msgSender()){
      uint256 quarterSlot = currentQuarter - 1;
      watersheds[quarterSlot].withdrawalsKickoff = kickoffPoint;
      watersheds[quarterSlot].withdrawalPhase = true;
   }

   function rollOutQuarters() external onlyFlamekeepers(_msgSender()){
      // uint256 lastQuarterId;
      uint256 lastQuarterEnded;
      uint256 targetSlot = quarters.length; 
      uint128 quartersToAdd = 120;
      uint256 lastSlot = targetSlot + (quartersToAdd - 1);
      uint256  quarterId;
      uint256 start;
      uint256 end;
      uint256 previousQuarterSlot;
      uint256 valueCreated;
      uint256 totalDistributionUnits;
      uint256 payoffPool;
      uint256 payoffReleased;
      uint256 payoffLeftover;
      PayoffClaim[] memory _payoffClaims;

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
            valueCreated,
            totalDistributionUnits,
            payoffPool,
            payoffReleased,
            payoffLeftover,
            _payoffClaims
         );

         //you also need to update the watersheds for each quarter. They're independent from each other.

         targetSlot++;
      }
   }

   function addCommunityUtility(address contractAddress, uint256 shareOfPool, bytes32 callsign) external onlyFlamekeepers(_msgSender()) {
      UtilityCharter memory newUtility;
      newUtility.utilityContract = contractAddress;
      newUtility.callsign = callsign;
      newUtility.shareOfPool = shareOfPool;
      communityUtilities.push(newUtility);
   }

   function updateUtilityStatus(bool newStatus, uint8 utilityId) external onlyFlamekeepers(_msgSender()) returns(bytes32, bool){
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
      newConstellation(rainmaker, zenith);
      InfinityPoolExpanse += zenith;
   }

   function claimSupremePayoff() external onlySupremeHodlers(_msgSender()){
      uint256 currentQuarterSlot = currentQuarter - 1;
      uint256 withdrawalReceiptSlot = withdrawalsHistory[_msgSender()].length;
      int256 lastReceiptSlot = int256(withdrawalsHistory[_msgSender()].length) - 1;
      uint256 claimSlot;
      bool uniqueClaim = false;
      bool processedClaim = false;
      bool withdrawn = false;
      
      if(lastReceiptSlot < 0){uniqueClaim = true;} else{
         WithdrawalMetadata memory lastWithdrawalReceipt = withdrawalsHistory[_msgSender()][uint256(lastReceiptSlot)];
         if(lastWithdrawalReceipt.quarterId < currentQuarter){uniqueClaim = true;}
      }
      require(uniqueClaim == true, "ULTIMA: You've already claimed your payoff");

      uint256 quarterEndMark = quarters[currentQuarterSlot].end;
      uint256 claimingWindowOpened = quarterEndMark - 10 days;
      uint256 claimingWindowClosed = claimingWindowOpened + 7 days;
      uint256 supremeScored;
      uint256 distributionUnits;
      uint256 blockTime = block.timestamp;
      bool    greenLight;
      if(blockTime >= claimingWindowOpened && blockTime <= claimingWindowClosed) greenLight = true;
      require(greenLight == true && watersheds[currentQuarterSlot].claimingPhase == true, "ULTIMA: Sorry, you can't claim payoffs at this time.");

      
      uint256 stackLevel = depositsOf[_msgSender()].length - 1;
      (supremeScored, distributionUnits) = getDistributionUnits(_msgSender()); //t
      uint256 payoffFactorScaled;
      uint256 withdrawalTimestamp;

      quarters[currentQuarterSlot].payoffClaims.push(PayoffClaim(_msgSender(), distributionUnits, withdrawalReceiptSlot, processedClaim));
      claimSlot = quarters[currentQuarterSlot].payoffClaims.length - 1; 
      pendingPayoffs[_msgSender()].push(PendingPayoff(currentQuarter, claimSlot));
      withdrawalsHistory[_msgSender()].push(WithdrawalMetadata(
         stackLevel, 
         claimSlot, 
         blockTime, 
         currentQuarter,
         payoffFactorScaled, 
         withdrawn, 
         supremeScored, 
         withdrawalTimestamp
      ));
      quarters[currentQuarterSlot].totalDistributionUnits += distributionUnits;
   }

   function getNumberOfPendingPayoffs(address hodler) view external onlySupremeHodlers(_msgSender()) returns(uint256 numPayoffsPending){
      numPayoffsPending = pendingPayoffs[hodler].length;
   }

   function getPendingPayoffClaimSlot(address hodler, uint256 index) view external onlySupremeHodlers(_msgSender()) returns(uint256 quarterId, uint256 pendingPayoffSlot){
      quarterId = pendingPayoffs[hodler][index].quarterId;
      pendingPayoffSlot = pendingPayoffs[hodler][index].claimSlot;
   }

   function withdrawPayoff(uint256 pendingIndex, uint256 quarterId, uint256 pendingPayoffSlot) external onlySupremeHodlers(_msgSender()) returns(uint256 EthPayoff){
      uint256 quarterSlot = quarterId - 1;
      PayoffClaim memory payoffClaim = quarters[quarterSlot].payoffClaims[pendingPayoffSlot];
      require(payoffClaim.processed == false, "ULTIMA: the payoff for this claim has already been withdrawn.");
      uint256 withdrawalReceiptSlot = payoffClaim.withdrawalReceiptSlot;
      address payable supremeHodler = payable(_msgSender());
      WithdrawalMetadata memory withdrawalReceipt = withdrawalsHistory[supremeHodler][withdrawalReceiptSlot];
      uint256 targetQuarter = withdrawalReceipt.quarterId; 
      require(quarterId == targetQuarter, "ULTIMA: Withdrawal parameters mismatch. quarterId must match withdrawal receipt.");
      
      Quarter memory quarter = quarters[quarterSlot]; 
      uint256 withdrawalsKickoff = quarter.end - 3 days;
      uint256 blockTime = block.timestamp;
      require(blockTime >= withdrawalsKickoff && watersheds[quarterSlot].withdrawalPhase == true, "ULTIMA: Good things come to those who wait.");
      
      uint256 distributionUnits = payoffClaim.distributionUnits;
      uint256 payoffFactorScaled = getPayoffFactorScaled(distributionUnits);
      withdrawalsHistory[supremeHodler][withdrawalReceiptSlot].payoffFactorScaled = payoffFactorScaled;
      uint256 payoffPool = quarter.payoffPool;
      EthPayoff = (payoffPool / 10**18) * payoffFactorScaled;

      uint256 lastElementSlot = pendingPayoffs[supremeHodler].length - 1;
      if(lastElementSlot == pendingIndex) {
         pendingPayoffs[supremeHodler].pop();
      }else{
         PendingPayoff memory swapElement = pendingPayoffs[supremeHodler][lastElementSlot];
         pendingPayoffs[supremeHodler][pendingPayoffSlot] = swapElement;
         pendingPayoffs[supremeHodler].pop();
      }

      quarters[quarterSlot].payoffReleased += EthPayoff;
      quarters[quarterSlot].payoffLeftover -= EthPayoff;
      quarters[quarterSlot].payoffClaims[pendingPayoffSlot].processed = true;
      withdrawalsHistory[supremeHodler][withdrawalReceiptSlot].withdrawn = true;
      supremeHodler.transfer(EthPayoff);
      emit PayoffWithdrawn(supremeHodler, quarterId, EthPayoff);
   }

   function getPayoffFactorScaled(uint256 dUnits) public view returns(uint256 payoffFactorScaled){
      uint256 scale = 10**18;
      uint256 currentQuarterSlot = currentQuarter - 1;
      uint256 totalDUnits = quarters[currentQuarterSlot].totalDistributionUnits;
      payoffFactorScaled = (dUnits * scale) / totalDUnits;
   }

   function getDistributionUnits(address supremeHodler) internal view returns(uint256 supremeScored, uint256 distributionUnits){
      SupremeStacked[] memory deposits = depositsOf[supremeHodler];
      uint256 currentQuarterSlot = currentQuarter - 1;
      uint256 nextQuarterSlot = currentQuarter;
      Quarter memory thisQuarter = quarters[currentQuarterSlot];
      uint256 numberOfDeposits = deposits.length;
      uint256 withdrawalsToDate = withdrawalsHistory[_msgSender()].length;
      uint256 lastWithdrawalSlot = withdrawalsToDate - 1;
      uint256 accountingPoint = thisQuarter.end;
      uint256 stackLevel;
      uint256 i;

      if(withdrawalsToDate < 1){
         i = 0;
         distributionUnits = 0;
         supremeScored = 0;
      } else {
         WithdrawalMetadata memory lastWithdrawal = withdrawalsHistory[_msgSender()][lastWithdrawalSlot];
         stackLevel = lastWithdrawal.stackLevel; 
         uint256 resetQuarterSlot = lastWithdrawal.quarterId; //t
         uint256 resetPoint = quarters[resetQuarterSlot].start;
         uint256 lifespan = (accountingPoint - resetPoint) / 86400;
         supremeScored = lastWithdrawal.supremeScored;
         distributionUnits = lifespan * supremeScored;
         i = stackLevel + 1;
      }

      while( i < numberOfDeposits){
         SupremeStacked memory deposit = deposits[i];
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

   function harvest() external payable {
   }

   function getInfinityPoolTide() public view returns(uint){
      return address(this).balance;
   }
}
