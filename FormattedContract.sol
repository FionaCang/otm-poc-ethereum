pragma solidity ^0.4.11;
contract OTMMandate {
    enum CurrentOwner { Bank, RIA, Investor, CAMSCheck, CAMSFinal, Approved }
    struct Mandate {
        string InvestorName;
        bytes InvestorSignature;
        address InvestorAddress;
        address bankAddress;
        uint MandateReference;
        CurrentOwner MandateOwner;
        bool BankApproved;
        bool CAMSApproved;
    }
    uint  numMandates;
    uint[] signedMandates;
    mapping (uint => Mandate) mandates;
    mapping (address => uint) investorLink;
    event InvalidAccess(address requestor);
    modifier onlyBy(address _account){
        if (msg.sender != _account){
            InvalidAccess(msg.sender);
            throw;
        } 
        _;
    }
    
}

contract CAMSProcess is OTMMandate{
    address public camsAddress;
    function CAMS(){
        camsAddress = msg.sender;
    }
        // When an RIA creates a mandate on behalf of the investor
    function newMandateRIA(address investorAddress,address bankAddress, string investorName) onlyBy(camsAddress) returns (uint) {
        if(investorLink[investorAddress] == 0){
            numMandates++;
            mandates[numMandates] = Mandate(investorName,'Unsigned',investorAddress,bankAddress,numMandates,CurrentOwner.Investor,false,false);
            investorLink[investorAddress] = numMandates;
            return numMandates;
        }else{
            return 0;
        }
    }
    
    function camsApproval(uint mandateID) onlyBy(camsAddress){
        if(mandates[mandateID].MandateOwner == CurrentOwner.CAMSCheck){
            mandates[mandateID].CAMSApproved = true;
            mandates[mandateID].MandateOwner = CurrentOwner.Bank;
        }
    }
    
    function camsFinal(uint mandateID) onlyBy(camsAddress){
        if(mandates[mandateID].MandateOwner == CurrentOwner.CAMSFinal){
            mandates[mandateID].MandateOwner == CurrentOwner.Approved;
        }
    }
    
    function getCAMSMandates() onlyBy(camsAddress) returns (uint[]){
        return signedMandates;
    }
    
    function getCAMSMandatesDetails(uint mandateID) onlyBy(camsAddress) returns (string,bytes,address,address,bool,bool){
        return (mandates[mandateID].InvestorName,mandates[mandateID].InvestorSignature,mandates[mandateID].InvestorAddress,mandates[mandateID].bankAddress,mandates[mandateID].BankApproved,mandates[mandateID].CAMSApproved);
    }
    
}
contract InvestorProcess is OTMMandate{
    function investorSignature(bytes signature,uint mandateID) onlyBy(mandates[mandateID].InvestorAddress){
        if(mandates[mandateID].MandateOwner == CurrentOwner.Investor){
            mandates[mandateID].InvestorSignature = signature;
            mandates[mandateID].MandateOwner = CurrentOwner.CAMSCheck;
            signedMandates.push(mandateID);
        }
    }
    function getMandateIDforInvestor() onlyBy(msg.sender) returns (uint) {
        return investorLink[msg.sender];
    }
    function getMandateDetails() onlyBy(msg.sender) returns (uint,string,bytes,address,address,uint,CurrentOwner,bool,bool){
        var mandateID = investorLink[msg.sender];
        return (mandateID,mandates[mandateID].InvestorName,mandates[mandateID].InvestorSignature,mandates[mandateID].InvestorAddress,mandates[mandateID].bankAddress,mandates[mandateID].MandateReference,mandates[mandateID].MandateOwner,mandates[mandateID].BankApproved,mandates[mandateID].CAMSApproved);
    }
    
}

contract BankProcess is OTMMandate{
    function bankApproval(uint mandateID,string secret, uint8 v, bytes32 r, bytes32 s) onlyBy(mandates[mandateID].bankAddress) returns (bool result){
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
    function getMandatesDetailsForBank(uint mandateID) onlyBy(mandates[mandateID].bankAddress) returns (string,bytes,address,address,bool,bool){
        return (mandates[mandateID].InvestorName,mandates[mandateID].InvestorSignature,mandates[mandateID].InvestorAddress,mandates[mandateID].bankAddress,mandates[mandateID].BankApproved,mandates[mandateID].CAMSApproved);
    }
}