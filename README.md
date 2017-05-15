<h2>One Time Mandate POC using Ethereum</h2>
The project consists of UI screens and a backend smart contract to sign and verify an investor's one time mandate for investing in mutual fund SIPs with his bank.<br>
The UI screens are as follows:<br>
(1) RIA - Registered Investment Advisor: This person collects the details of the mandate from investor via email or phone call. Only base fields are collected for the purpose of this POC<br>
(2) Investor - Verifies the information in the one time mandate submitted by the investor. The investor signs by providing his bank account number, date of both and any other unique identifier known to him and his bank, along with his Ethereum account<br>
(3) CAMS (Transfer Agency) - Verifies and validates new mandates recieved. After verification, sends details to the bank for processing.<br>
(4) Investor's Bank - Receives verified CAMS mandates. Decodes the user signature recieved by forming a hash with the registered user details (in this case bank account number + date of birth + unique identifier) and calls an ecrecover solidity function to check the address of the signer of the signature. If the signer of the signature is the given investor address (sent by CAMS), then the bank approves the mandate.<br>
Developer Note: The smart contract needs to hosted on a reliable instance or a local geth node needs to fired up.<br>
A total of six accounts are precreated with funds. Please do replace them with 6 new funded accounts for the following persons:<br>
CAMS/RIA - 1<br>
Investor Accounts - 4<br>
Bank Accounts - 1<br>
This logic can be extended to other domains and areas where user signature needs to verified and validated by multiple parties. It obviates the need for paper signatures and time consuming processes like courier of documents.

<h3>Deployment Information and Overall Flow</h3>

1. Navigate to C:\Users\{user}\AppData\Roaming\Ethereum and delete the "testnet" directory<br>

2. Launch testnet<br>

  geth --testnet --fast --cache=512 --rpc --rpccorsdomain --rpcapi "*" console<br>

3. Create 6 new accounts using personal.newAccount(). Unlock all accounts permanently<br>

  personal.unlockAccount(eth.accounts[0],"pass",0)<br>
  personal.unlockAccount(eth.accounts[1],"pass",0)<br>
  personal.unlockAccount(eth.accounts[2],"pass",0)<br>
  personal.unlockAccount(eth.accounts[3],"pass",0)<br>
  personal.unlockAccount(eth.accounts[4],"pass",0)<br>
  personal.unlockAccount(eth.accounts[5],"pass",0)<br>
  personal.unlockAccount(eth.accounts[6],"pass",0)<br>

4. Start mining and generate ether on coinbase accounts<br>

5. After a few minutes, transfer ether to all other accounts and fund them<br>

  eth.sendTransaction({from:eth.coinbase, to:eth.accounts[1], value: web3.toWei(0.05, "ether")})<br>
  eth.sendTransaction({from:eth.coinbase, to:eth.accounts[2], value: web3.toWei(0.05, "ether")})<br>
  eth.sendTransaction({from:eth.coinbase, to:eth.accounts[3], value: web3.toWei(0.05, "ether")})<br>
  eth.sendTransaction({from:eth.coinbase, to:eth.accounts[4], value: web3.toWei(0.05, "ether")})<br>
  eth.sendTransaction({from:eth.coinbase, to:eth.accounts[5], value: web3.toWei(0.05, "ether")})<br>
  eth.sendTransaction({from:eth.coinbase, to:eth.accounts[6], value: web3.toWei(0.05, "ether")})<br>

  The accounts are allocated to the users in the following manner in the code:<br>

   0 ->  CAMS<br>
   1 ->  Investor 1<br>
   2 ->  Investor 2<br>
   3 ->  CAMS<br>
   4 ->  Bank<br>
   5 ->  Investor 3<br>
   6 ->  Investor 4<br>

6. Copy the contents of OTMMandate.sol into Remix and generate web3 deploy<br>

7. Paste web3 deploy in js console and save the contract address<br>

8. Update 'accounts.js' with abi and contract address<br>

9. Launch and initialize contract by opening RIA.html first, so that variable 'owner' in the contract gets initialized to the CAMS address<br>

10.Create RIA transaction by hitting submit. Wait till bottom text gets changed to 'Mined'. If errors exist check console.<br>

11. Navigate to investor page and check if new investor registration is visible<br>

12. Sign the relevant fields and hit submit to start a new transaction<br>

13. Open CAMS.html. Investor record should be displayed after investor signature transactions gets confirmed<br>

14. Hit on Verify & Send to Bank. Note Mandate ID. Wait for transaction to get mined.<br>

15. Open Bank.html and query the record with Mandate ID by hitting Get Record<br>

16. When record is displayed, fill in correct fields (as before) and click 'Verify'<br>

17. If 'Success' is displayed hit 'Approve Mandate' and wait for transaction to get Mined<br>

18. Go back to CAMS.html after transaction gets mined to verify whether bank status changed to 'true'<br>

