pragma solidity ^0.4.11;
contract OTMMandate {
    
    // Enum for representing the current status owner of the mandate
    // Parsed from 0 to 5 in javascript: with 0 -> Bank, 1 -> RIA,...,5 -> Approved
    enum CurrentOwner { Bank, RIA, Investor, CAMSCheck, CAMSFinal, Approved }
    
    // Basic mandate structure with all fields
    // MandateReference links Mandate Storage in Ethereum to local database
    // Local db stores other mandate form information
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
    
    // Variable to represent the number of mandates in the system
    // Incremented each time newMandateRIA() is called
    uint  numMandates;
    
    // List of signed investor mandates for display at CAMS UI
    uint[] signedMandates;
    
    // RIA/CAMS address which initiates the contract becomes the owner of the contract
    address public owner;
    
    // List of all investor mandates. Array mapping Mandate ID -> Mandate Details
    mapping (uint => Mandate) mandates;
    
    // mapping which returns Mandate ID for a given investor address. Investor Address -> Mandate ID
    mapping (address => uint) investorLink;
    
    // Initial constructor call for intializing contract
    function OTMMandate(){
        numMandates = 0;
        owner = msg.sender;
    }
    
    // Modifier for permission to only functions executed by CAMS and RIA
    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }
    
    // Function called when RIA creates new Mandate on behalf of the investor
    // Mandate details are stored in 'mandates' array of objects
    // Mandate ID is sequentially incremented number
    // InvestorLink is created which connects the new input Investor Address to a Mandate ID
    // First time execution will return Mandate ID '1'
    // If failed will return Mandate ID '0'
    // Calling newMandateRIA.call(...) will execute function locally and return the new mandate ID to be created without publishing a new transaction to the Blockchain
    // Calling newMandateRIA(...) will publish new transaction to the Blockchain and store mandate details in 'mandates' array
    // Mandate Signature is first given 'Unsigned' value until Investor signs
    // Current Owner of Mandate is pushed to investor since his signature is pending on his UI
    // Both CAMS Approval status and Bank Approval status are kept to false
    function newMandateRIA(address investorAddress,address bankAddress, string investorName) onlyOwner returns (uint) {
        if(investorLink[investorAddress] == 0){
            numMandates++;
            mandates[numMandates] = Mandate(investorName,'Unsigned',investorAddress,bankAddress,numMandates,CurrentOwner.Investor,false,false);
            investorLink[investorAddress] = numMandates;
            return numMandates;
        }else{
            return 0;
        }
    }
    
    // Modifier to allow permission to only the account specified in the _account variable
    modifier onlyBy(address _account)
    {
        require(msg.sender == _account);
        _;
    }
    
    // To collect the investor signature from his application when the RIA sends him his details
    // In UI -> var signature = web3.eth.sign(userAddress, sha3(secret))
    // secret = (full name + dob + bank account number)
    // New investor signature is stored in mandates array replacing 'Unsigned'
    // List of signed mandates is populated with the new signed mandate ID
    // New owner of the mandate is changed to CAMS for pre-processing
    // Modifier kept to allow only the investor address registed in the 'mandates' array to perform the action
    function investorSignature(bytes signature,uint mandateID) onlyBy(mandates[mandateID].InvestorAddress){
        if(mandates[mandateID].MandateOwner == CurrentOwner.Investor){
            mandates[mandateID].InvestorSignature = signature;
            mandates[mandateID].MandateOwner = CurrentOwner.CAMSCheck;
            signedMandates.push(mandateID);
        }
    }
    
    // When CAMS approves investor signed mandate and pushes update to bank
    // Modifier kept only to allow CAMS address to perform the action
    function camsApproval(uint mandateID) onlyOwner{
        if(mandates[mandateID].MandateOwner == CurrentOwner.CAMSCheck){
            mandates[mandateID].CAMSApproved = true;
            mandates[mandateID].MandateOwner = CurrentOwner.Bank;
        }
    }
    
    // Method to complete bank authentication
    // Modifier ensures that only the bank address provided by the RIA at the time of mandate registeration can perform this method
    // String secret -> hash(unique identifier + bank account + DoB). Bank enters these details in their screen
    // Variables v,r and s, are three string splits of the investor signature (mandates[mandateID].InvestorSignature) which are required by solidity to call the method 'ecrecover' which takes in 4 parameters
    // Method 'ecrecover' decodes the investor address, with 2 inputs -> Investor signature + the hash of his secret (3 unique identifiers)
    // After positive return from verify method, mandate ownership is changed to CAMS for post processing
    function bankApproval(uint mandateID,string secret, uint8 v, bytes32 r, bytes32 s) onlyBy(mandates[mandateID].bankAddress) returns (bool result){
        if(mandates[mandateID].MandateOwner == CurrentOwner.Bank){
            result = verify(sha3(secret),v,r,s,mandateID);
            if(result == true) mandates[mandateID].BankApproved = true;
            mandates[mandateID].MandateOwner = CurrentOwner.CAMSFinal;
        }
    }
    
    // Prefix hash is appended to signed user secret only because Solidity requires this format
    // When there is a match between the decoded address using 'ecrecover' and the investor address stored in 'mandate' array, verify method returns true
    // Returns result to bankApproval method
    function verify(bytes32 hash, uint8 v, bytes32 r, bytes32 s, uint mandateID) constant returns(bool) {
		bytes memory prefix = "\x19Ethereum Signed Message:\n32";
		bytes32 prefixedHash = sha3(prefix, hash);
        return ecrecover(prefixedHash, v, r, s) == mandates[mandateID].InvestorAddress;
    }
    
    // When bank approval is recieved positivesly, CAMS can generate UMRN and end the flow
    // Mandate ownership is changed to approved after UMRN is generated and stored in the database
    // Modifier to allow only CAMS to execute the method
    function camsFinal(uint mandateID) onlyOwner{
        if(mandates[mandateID].MandateOwner == CurrentOwner.CAMSFinal){
            mandates[mandateID].MandateOwner == CurrentOwner.Approved;
        }
    }
    
    // Function called in the investor screen to retrieve the mandate ID for the investor address
    // InvestorLink mapping, will link Investor Address to the Investor's Mandate ID
    // If the given address does not exist in InvestorLink mapping, it will return '0'
    function getMandateIDforInvestor() returns (uint) {
        return investorLink[msg.sender];
    }
    
    // Fuction called in the investor screen to retrieve all mandate details of the investor using his mandate ID
    function getMandateDetails() returns (uint,string,bytes,address,address,uint,CurrentOwner,bool,bool){
        var mandateID = investorLink[msg.sender];
        return (mandateID,mandates[mandateID].InvestorName,mandates[mandateID].InvestorSignature,mandates[mandateID].InvestorAddress,mandates[mandateID].bankAddress,mandates[mandateID].MandateReference,mandates[mandateID].MandateOwner,mandates[mandateID].BankApproved,mandates[mandateID].CAMSApproved);
    }
    
    // Function used in the CAMS UI, to retrieve list of all signed mandates in the application
    function getCAMSMandates() onlyOwner returns (uint[]){
        return signedMandates;
    }
    
    // Function called in the CAMS UI to retrieve all mandate details from the mandate ID
    // Modifer to allow only CAMS to execute call method
    function getCAMSMandatesDetails(uint mandateID) onlyOwner returns (string,bytes,address,address,bool,bool){
        return (mandates[mandateID].InvestorName,mandates[mandateID].InvestorSignature,mandates[mandateID].InvestorAddress,mandates[mandateID].bankAddress,mandates[mandateID].BankApproved,mandates[mandateID].CAMSApproved);
    }
    
    // Function called in the Bank UI to retrieve all mandate details from the mandate ID
    // Modifer to allow only the bank address stored in the 'mandates' array at the time of RIA registeration can execute this method.
    // Hence only the investor's registered bank can view his mandate details and other bank addresses cannot view his details
    function getMandatesDetailsForBank(uint mandateID) onlyBy(mandates[mandateID].bankAddress) returns (string,bytes,address,address,bool,bool){
        return (mandates[mandateID].InvestorName,mandates[mandateID].InvestorSignature,mandates[mandateID].InvestorAddress,mandates[mandateID].bankAddress,mandates[mandateID].BankApproved,mandates[mandateID].CAMSApproved);
    }

}
