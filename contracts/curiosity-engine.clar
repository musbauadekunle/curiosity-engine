;; Curiosity Engine - Research Question Bounty System
;; Funds research questions that remain unanswered for a set period
;; Bounties paid to first correct answerers

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-answered (err u102))
(define-constant err-insufficient-bounty (err u103))
(define-constant err-not-question-owner (err u104))
(define-constant err-question-expired (err u105))
(define-constant err-question-not-expired (err u106))
(define-constant err-invalid-answer (err u107))

(define-constant min-bounty u1000000) ;; 1 STX minimum

;; Data Variables
(define-data-var question-nonce uint u0)

;; Data Maps
(define-map questions
  uint
  {
    owner: principal,
    question: (string-ascii 500),
    bounty: uint,
    expiry-block: uint,
    answered: bool,
    answer: (optional (string-ascii 1000)),
    answerer: (optional principal)
  }
)

;; Public Functions

;; Post a new research question with bounty
(define-public (post-question (question (string-ascii 500)) (expiry-blocks uint))
  (let
    (
      (question-id (var-get question-nonce))
      (bounty (stx-get-balance tx-sender))
      (expiry-block (+ block-height expiry-blocks))
    )
    ;; Validate bounty amount
    (asserts! (>= bounty min-bounty) err-insufficient-bounty)

    ;; Transfer bounty to contract
    (try! (stx-transfer? bounty tx-sender (as-contract tx-sender)))

    ;; Store question
    (map-set questions question-id
      {
        owner: tx-sender,
        question: question,
        bounty: bounty,
        expiry-block: expiry-block,
        answered: false,
        answer: none,
        answerer: none
      }
    )

    ;; Increment nonce
    (var-set question-nonce (+ question-id u1))

    (ok question-id)
  )
)

;; Submit an answer to a question
(define-public (submit-answer (question-id uint) (answer (string-ascii 1000)))
  (let
    (
      (question-data (unwrap! (map-get? questions question-id) err-not-found))
      (answerer-principal tx-sender)
    )
    ;; Validate question is not already answered
    (asserts! (not (get answered question-data)) err-already-answered)

    ;; Validate question has not expired
    (asserts! (< block-height (get expiry-block question-data)) err-question-expired)

    ;; Update question with answer
    (map-set questions question-id
      (merge question-data
        {
          answered: true,
          answer: (some answer),
          answerer: (some answerer-principal)
        }
      )
    )

    ;; Pay bounty to answerer
    (try! (as-contract (stx-transfer? (get bounty question-data) tx-sender answerer-principal)))

    (ok true)
  )
)

;; Reclaim bounty if question expires without answer
(define-public (reclaim-bounty (question-id uint))
  (let
    (
      (question-data (unwrap! (map-get? questions question-id) err-not-found))
    )
    ;; Validate caller is question owner
    (asserts! (is-eq tx-sender (get owner question-data)) err-not-question-owner)

    ;; Validate question is not answered
    (asserts! (not (get answered question-data)) err-already-answered)

    ;; Validate question has expired
    (asserts! (>= block-height (get expiry-block question-data)) err-question-not-expired)

    ;; Return bounty to question owner
    (try! (as-contract (stx-transfer? (get bounty question-data) tx-sender (get owner question-data))))

    ;; Mark as answered to prevent double-claiming
    (map-set questions question-id
      (merge question-data { answered: true })
    )

    (ok true)
  )
)

;; Read-Only Functions

;; Get question details
(define-read-only (get-question (question-id uint))
  (ok (map-get? questions question-id))
)

;; Get total number of questions
(define-read-only (get-question-count)
  (ok (var-get question-nonce))
)

;; Check if question is still open
(define-read-only (is-question-open (question-id uint))
  (match (map-get? questions question-id)
    question-data
      (ok (and
        (not (get answered question-data))
        (< block-height (get expiry-block question-data))
      ))
    (ok false)
  )
)

;; Get question expiry status
(define-read-only (get-expiry-status (question-id uint))
  (match (map-get? questions question-id)
    question-data
      (ok {
        expired: (>= block-height (get expiry-block question-data)),
        blocks-remaining: (if (< block-height (get expiry-block question-data))
          (- (get expiry-block question-data) block-height)
          u0
        )
      })
    err-not-found
  )
)
