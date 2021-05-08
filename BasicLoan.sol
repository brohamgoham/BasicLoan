pragma solidity ^0.7.0;

import (DAI) from "./DAI.sol";

 
contract BasicLoan {
    struct TermsAndConditions {
        uint256 loanDaiAmount;
    
        uint256 feeDaiAmount;
        //amount of collaterall in ETHER , make it more avail then the loanDaiAmount * the feeDaiAmount , therre wise the borrow had incentive to not pay! lol
    
        uint256 ethCollateralAmount;

        //made a timestamp to indicate when loan should be repayed!
        uint256 repayByTimestamp;

        
    }
    TermsAndConditions public terms;
    enum LoanState {Created, Funded, Taken}
    LoanState public state;
    address payable public lender;
    address payable public borrower;
    address public daiAddress;
    constructor (TermsAndConditions memory _terms, address _daiAddress) {
        TermsAndConditions = _terms;
        daiAddress = _daiAddress;
        lender = msg.sender;
        state = LoanState.Created;
    }

    modifier onlyInState(LoanState expeectedState) {
        require(state == expeectedState, "Not allowed");
        _;
    }
//here we fund the loan, pulling the funds from the lender and lock into contract , avail to borrow later
//we use the onlyInState to execute it so we can execute loan twice #moralz
    function fundLoan() public onlyInState(LoanState.Created) {
        state = LoanState.Funded;
        DAI(daiAddress).transferFrom(msg.sender, address(this), terms.loanDaiAmount);
    }
// this takeALoanAndAcceptLoanTerms function ONLY in the funded state by checking if ther e is enough collaterall
// the ETH gets locked in S.C if not enuff eth we thro errow INVALID
    function takeALoanAndAcceptLoanTerms() public payable onlyInState(LoanState.Funded) {
        require( msg.value == terms.ethCollateralAmount,"INVALID AMOUNT!");
        borrower = msg.sender;
        state = LoanState.Taken;
        DAI(daiAddress).transferFrom(borrower, terms.loanDaiAmount);
    }
//this one does what is says aswell, simply repays, can be repayed early with no fees
//also allowing anyone to repay would unlock collaterall so we must secure that , thats why we check the borrow is msg.sender becuz collat amy should be more then loan 
//and we then pull tokens, and finally send collaterall back to borrow and destroy contract!
    function repay() public onlyInState(LoanState.Taken) {
        require(msg.sender == borrower, "Only the borrower can repay the loan");
        DAI(daiAddress).transferFrom(borrower, lender, terms.loanDaiAmount + terms.feeDaiAmount);
        selfdestruct(borrower);
    //Lol i love calling SELFDESTRUCT its fun lol lol "bihh betta have my money" - Rihanna lol
        
    }
//this is so we dont lose no money and get played lol 
    function liquidate() public onlyInState(LoanState.Taken) {
        require(msg.sender == lender, "Only lendr can liquidate the LOAN!!");
        require(block.timestamp >= terms.repayByTimestamp, "Cannot liquidate before the loan is due");
        selfdestruct(lender);
    }
}