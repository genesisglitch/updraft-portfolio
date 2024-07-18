# Blockchain Smart Contract Audit Notes

## Introduction
[Provide a brief introduction to the smart contract being audited, including its purpose and functionality.]

- NFT Raffle
- you enter raffle and you can win a NFT
- duration of each raffle is 1 day
- you need to pay entrance fee 
- it must be at least 4 players
- duplicates are not aallowed
- user can get refund (reentrancy?)

## Methodology
[Explain the methodology followed during the audit process, including the different phases and steps taken.]

### Phase 1: Pre-Audit Preparation
- [x] Review project documentation, including the smart contract specifications, architecture, and any relevant design documents.
- [x] Set up the necessary development and testing environment.
- [ ] Familiarize with the project's codebase and dependencies.

### Phase 2: Code Review
- [ ] Perform a thorough code review of the smart contract, focusing on security vulnerabilities, best practices, and potential issues.
- [ ] Identify any potential vulnerabilities, such as reentrancy, integer overflow/underflow, or unauthorized access.
- [ ] Review the contract's logic and ensure it aligns with the intended functionality.
- [ ] Check for compliance with coding standards and best practices.

### Phase 3: Testing
- Develop and execute comprehensive test cases to validate the smart contract's functionality and security.
- Test different scenarios, including edge cases and potential attack vectors.
- Verify that the contract behaves as expected and handles exceptions gracefully.
- Assess the contract's gas usage and optimize where necessary.

### Phase 4: Documentation and Reporting
- Document all findings, including identified vulnerabilities, recommendations, and suggested improvements.
- Provide a detailed report summarizing the audit process, findings, and recommendations.
- Prioritize the identified issues based on their severity and potential impact.
- Include any additional notes or observations that may be relevant to the audit.


## Conclusion
[Summarize the audit findings and recommendations, emphasizing the importance of addressing any identified vulnerabilities or issues.]
