pragma solidity ^0.4.11;
contract OTMMandate {
    enum CurrentOwner { Bank, RIA, Investor, CAMSCheck, CAMSFinal, Approved }
    struct Mandate {
        string InvestorName;
        bytes InvestorSignature;
        address InvestorAddress;
        uint MandateReference;
        CurrentOwner MandateOwner;
        bool BankApproved;
        bool CAMSApproved;
    }
    uint  numMandates;
    uint[] signedMandates;
    mapping (uint => Mandate) mandates;
    mapping (address => uint) investorLink;

    function OTMMandate(){
        numMandates = 0;
    }
    // When an RIA creates a mandate on behalf of the investor
    function newMandateRIA(address investorAddress, string investorName) returns (uint) {
        if(investorLink[investorAddress] == 0){
            numMandates++;
            mandates[numMandates] = Mandate(investorName,'Unsigned',investorAddress,numMandates,CurrentOwner.Investor,false,false);
            investorLink[investorAddress] = numMandates;
            return numMandates;
        }else{
            return 0;
        }
    }

    // To collect the investor signature from his application when the RIA sends him his details
    // In UI -> var signature = web3.eth.sign(userAddress, sha3(secret))
    // secret = (full name + dob + bank account number)
    function investorSignature(bytes signature,uint mandateID){
        if(mandates[mandateID].MandateOwner == CurrentOwner.Investor){
            mandates[mandateID].InvestorSignature = signature;
            mandates[mandateID].MandateOwner = CurrentOwner.CAMSCheck;
            signedMandates.push(mandateID);
        }
    }

    function camsApproval(uint mandateID){
        if(mandates[mandateID].MandateOwner == CurrentOwner.CAMSCheck){
            mandates[mandateID].CAMSApproved = true;
            mandates[mandateID].MandateOwner = CurrentOwner.Bank;
        }
    }

    function bankApproval(uint mandateID,string secret, uint8 v, bytes32 r, bytes32 s) returns (bool result){
        if(mandates[mandateID].MandateOwner == CurrentOwner.Bank){
            result = verify(sha3(secret),v,r,s,mandateID);
            if(result == true) mandates[mandateID].BankApproved = true;
            mandates[mandateID].MandateOwner = CurrentOwner.CAMSFinal;
        }
    }
    function verify(bytes32 hash, uint8 v, bytes32 r, bytes32 s, uint mandateID) constant returns(bool) {
		bytes memory prefix = "\x19Ethereum Signed Message:\n32";
		bytes32 prefixedHash = sha3(prefix, hash);
        return ecrecover(prefixedHash, v, r, s) == mandates[mandateID].InvestorAddress;
    }
    function camsFinal(uint mandateID){
        if(mandates[mandateID].MandateOwner == CurrentOwner.CAMSFinal){
            mandates[mandateID].MandateOwner == CurrentOwner.Approved;
        }
    }

    function getMandatesCount() constant returns (uint retVal) {
        return numMandates;
    }
    
    function getMandateIDforInvestor() returns (uint){
        return investorLink[msg.sender];
    }

    function getMandateDetails() returns (uint,string,bytes,address,uint,CurrentOwner,bool,bool){
        var mandateID = investorLink[msg.sender];
        return (mandateID,mandates[mandateID].InvestorName,mandates[mandateID].InvestorSignature,mandates[mandateID].InvestorAddress,mandates[mandateID].MandateReference,mandates[mandateID].MandateOwner,mandates[mandateID].BankApproved,mandates[mandateID].CAMSApproved);
    }
    
    function getCAMSMandates() returns (uint[]){
        return signedMandates;
    }

    function getCAMSMandatesDetails(uint mandateID) returns (string,bytes,address,bool,bool){
        return (mandates[mandateID].InvestorName,mandates[mandateID].InvestorSignature,mandates[mandateID].InvestorAddress,mandates[mandateID].BankApproved,mandates[mandateID].CAMSApproved);
    }

}
