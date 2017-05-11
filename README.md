The project consists of UI screens and a backend smart contract to sign and verify an investor's one time mandate for investing in mutual fund SIPs with his bank.
The UI screens are as follows:<br>
(1) RIA - Registered Investment Advisor: This person collects the details of the mandate from investor via email or phone call. Only base fields are collected for the purpose of this POC<br>
(2) Investor - Verifies the information in the one time mandate submitted by the investor. The investor signs by providing his bank account number, date of both and any other unique identifier known to him and his bank, along with his Ethereum account<br>
(3) CAMS (Transfer Agency) - Verifies and validates new mandates recieved. After verification, sends details to the bank for processing.<br>
(4) Investor's Bank - Receives verified CAMS mandates. Decodes the user signature recieved by forming a hash with the registered user details (in this case bank account number + date of birth + unique identifier) and calls an ecrecover solidity function to check the address of the signer of the signature. If the signer of the signature is the given investor address (sent by CAMS), then the bank approves the mandate.<br>
Developer Note: The smart contract needs to hosted on a reliable instance or a local geth node needs to fired up.<br>
A total of six accounts are precreated with funds. Please do replace them with 6 new funded accounts for the following persons:<br>
CAMS/RIA - 1<br>
Investor Accoutns - 4<br>
Bank Accounts - 1<br>
This logic can be extended to other domains and areas where user signature needs to verified and validated by multiple parties. It obviates the need for paper signatures and time consuming processes like courier of documents.
