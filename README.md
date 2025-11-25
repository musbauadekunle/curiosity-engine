README: Curiosity Engine - Research Question Bounty System
Overview

The Curiosity Engine is a blockchain-based smart contract on the Stacks network that allows users to post research questions with a bounty. Users who provide the first correct answer within a set timeframe receive the bounty, incentivizing knowledge discovery and collaborative problem-solving. If a question remains unanswered past its expiry, the bounty can be reclaimed by the question owner.

Features

Post research questions with a minimum STX bounty.

Submit answers to earn bounties.

Reclaim bounties if questions expire without answers.

Track question status (open, answered, or expired).

Read-only functions to query questions and their expiry status.

Constants
Constant	Description
contract-owner	Owner of the contract (deployer).
err-owner-only	Error for unauthorized access.
err-not-found	Error for non-existent questions.
err-already-answered	Error for submitting answer to already answered question.
err-insufficient-bounty	Error for posting bounty below the minimum.
err-not-question-owner	Error for unauthorized bounty reclaim.
err-question-expired	Error for answering an expired question.
err-question-not-expired	Error when trying to reclaim bounty before expiry.
err-invalid-answer	Error for invalid answers.
min-bounty	Minimum STX bounty (1 STX = 1,000,000 micro-STX).
Data Variables

question-nonce: Tracks the next question ID.

Data Maps

questions: Stores each question with:

owner (principal)

question (string, max 500 chars)

bounty (uint)

expiry-block (uint)

answered (bool)

answer (optional string, max 1000 chars)

answerer (optional principal)

Public Functions
post-question
(define-public (post-question (question (string-ascii 500)) (expiry-blocks uint)))


Posts a new research question with a bounty.

Bounty is transferred to the contract.

Validates minimum bounty and calculates expiry based on block height.

Returns question-id.

submit-answer
(define-public (submit-answer (question-id uint) (answer (string-ascii 1000))))


Submit an answer to a question.

Validates that the question is not already answered and has not expired.

Updates the question as answered and pays the bounty to the answerer.

reclaim-bounty
(define-public (reclaim-bounty (question-id uint)))


Allows the question owner to reclaim the bounty if the question expires unanswered.

Validates ownership, expiry, and that the question is still unanswered.

Marks the question as answered to prevent double claims.

Read-Only Functions
get-question
(define-read-only (get-question (question-id uint)))


Returns all data related to a question.

get-question-count
(define-read-only (get-question-count))


Returns total number of questions posted.

is-question-open
(define-read-only (is-question-open (question-id uint)))


Checks if a question is open (not answered and not expired).

get-expiry-status
(define-read-only (get-expiry-status (question-id uint)))


Returns:

expired (bool)

blocks-remaining until expiry (0 if expired).

Usage Flow

Post a Question

User specifies question text and expiry in blocks.

Must send STX equal to or greater than min-bounty.

Answer a Question

User submits an answer before expiry.

First correct answer receives the bounty.

Reclaim Bounty

If no answer is submitted and question expires, the owner can reclaim the bounty.

Query Question Status

Check if a question is still open or expired.

Get details of the question including owner, bounty, and answer.

Notes

All bounties are denominated in micro-STX.

expiry-block is based on the current block-height.

The contract ensures single payout per question.