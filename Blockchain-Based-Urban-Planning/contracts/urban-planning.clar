;; Blockchain-Based Urban Planning Smart Contract
;; A decentralized system for citizen participation in city development through token-weighted voting

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-OWNER-ONLY (err u100))
(define-constant ERR-NOT-AUTHORIZED (err u101))
(define-constant ERR-PROPOSAL-NOT-FOUND (err u102))
(define-constant ERR-VOTING-ENDED (err u103))
(define-constant ERR-ALREADY-VOTED (err u104))
(define-constant ERR-INSUFFICIENT-TOKENS (err u105))
(define-constant ERR-INVALID-PROPOSAL (err u106))
(define-constant ERR-PROPOSAL-ACTIVE (err u107))
(define-constant ERR-CIVIC-ACTIVITY-EXISTS (err u108))

;; Data Variables
(define-data-var next-proposal-id uint u1)
(define-data-var next-activity-id uint u1)
(define-data-var total-governance-tokens uint u0)

;; Data Maps
(define-map governance-tokens principal uint)
(define-map citizen-reputation principal uint)

(define-map proposals 
  uint 
  {
    title: (string-ascii 100),
    description: (string-ascii 500),
    proposer: principal,
    start-block: uint,
    end-block: uint,
    votes-for: uint,
    votes-against: uint,
    total-tokens-voted: uint,
    status: (string-ascii 20), ;; "active", "passed", "rejected", "executed"
    category: (string-ascii 50) ;; "infrastructure", "zoning", "budget", "environment"
  }
)

(define-map proposal-votes 
  {proposal-id: uint, voter: principal}
  {tokens-voted: uint, vote-type: bool} ;; true for yes, false for no
)

(define-map civic-activities
  uint
  {
    name: (string-ascii 100),
    description: (string-ascii 300),
    token-reward: uint,
    reputation-reward: uint,
    is-active: bool
  }
)

(define-map citizen-activity-participation
  {citizen: principal, activity-id: uint}
  {completed: bool, completion-block: uint}
)

;; Public Functions

;; Initialize governance tokens for new citizens
(define-public (register-citizen)
  (let ((caller tx-sender))
    (if (is-eq (default-to u0 (map-get? governance-tokens caller)) u0)
      (begin
        (map-set governance-tokens caller u100) ;; Initial allocation
        (map-set citizen-reputation caller u10) ;; Starting reputation
        (var-set total-governance-tokens (+ (var-get total-governance-tokens) u100))
        (ok u100)
      )
      (ok (default-to u0 (map-get? governance-tokens caller)))
    )
  )
)

;; Create a new development proposal
(define-public (create-proposal 
  (title (string-ascii 100))
  (description (string-ascii 500))
  (voting-duration uint)
  (category (string-ascii 50))
)
  (let 
    (
      (proposal-id (var-get next-proposal-id))
      (caller tx-sender)
      (current-block block-height)
    )
    (asserts! (>= (get-token-balance caller) u50) ERR-INSUFFICIENT-TOKENS) ;; Minimum tokens to propose
    (asserts! (> voting-duration u0) ERR-INVALID-PROPOSAL)
    
    (map-set proposals proposal-id
      {
        title: title,
        description: description,
        proposer: caller,
        start-block: current-block,
        end-block: (+ current-block voting-duration),
        votes-for: u0,
        votes-against: u0,
        total-tokens-voted: u0,
        status: "active",
        category: category
      }
    )
    
    (var-set next-proposal-id (+ proposal-id u1))
    (ok proposal-id)
  )
)

;; Vote on a proposal
(define-public (vote-on-proposal (proposal-id uint) (vote-for bool) (tokens-to-vote uint))
  (let 
    (
      (caller tx-sender)
      (proposal (unwrap! (map-get? proposals proposal-id) ERR-PROPOSAL-NOT-FOUND))
      (caller-tokens (get-token-balance caller))
      (current-block block-height)
    )
    (asserts! (<= current-block (get end-block proposal)) ERR-VOTING-ENDED)
    (asserts! (is-eq (get status proposal) "active") ERR-VOTING-ENDED)
    (asserts! (>= caller-tokens tokens-to-vote) ERR-INSUFFICIENT-TOKENS)
    (asserts! (> tokens-to-vote u0) ERR-INSUFFICIENT-TOKENS)
    (asserts! (is-none (map-get? proposal-votes {proposal-id: proposal-id, voter: caller})) ERR-ALREADY-VOTED)
    
    ;; Record the vote
    (map-set proposal-votes 
      {proposal-id: proposal-id, voter: caller}
      {tokens-voted: tokens-to-vote, vote-type: vote-for}
    )
    
    ;; Update proposal vote counts
    (map-set proposals proposal-id
      (merge proposal
        {
          votes-for: (if vote-for (+ (get votes-for proposal) tokens-to-vote) (get votes-for proposal)),
          votes-against: (if vote-for (get votes-against proposal) (+ (get votes-against proposal) tokens-to-vote)),
          total-tokens-voted: (+ (get total-tokens-voted proposal) tokens-to-vote)
        }
      )
    )
    
    ;; Lock voting tokens (simulate token locking)
    (map-set governance-tokens caller (- caller-tokens tokens-to-vote))
    
    (ok true)
  )
)

;; Finalize proposal voting
(define-public (finalize-proposal (proposal-id uint))
  (let 
    (
      (proposal (unwrap! (map-get? proposals proposal-id) ERR-PROPOSAL-NOT-FOUND))
      (current-block block-height)
    )
    (asserts! (> current-block (get end-block proposal)) ERR-PROPOSAL-ACTIVE)
    (asserts! (is-eq (get status proposal) "active") ERR-PROPOSAL-ACTIVE)
    
    (let 
      (
        (votes-for (get votes-for proposal))
        (votes-against (get votes-against proposal))
        (new-status (if (> votes-for votes-against) "passed" "rejected"))
      )
      (map-set proposals proposal-id
        (merge proposal {status: new-status})
      )
      (ok new-status)
    )
  )
)

;; Create civic activity
(define-public (create-civic-activity 
  (name (string-ascii 100))
  (description (string-ascii 300))
  (token-reward uint)
  (reputation-reward uint)
)
  (let ((activity-id (var-get next-activity-id)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-OWNER-ONLY)
    
    (map-set civic-activities activity-id
      {
        name: name,
        description: description,
        token-reward: token-reward,
        reputation-reward: reputation-reward,
        is-active: true
      }
    )
    
    (var-set next-activity-id (+ activity-id u1))
    (ok activity-id)
  )
)

;; Participate in civic activity
(define-public (participate-in-activity (activity-id uint))
  (let 
    (
      (caller tx-sender)
      (activity (unwrap! (map-get? civic-activities activity-id) ERR-PROPOSAL-NOT-FOUND))
      (participation-key {citizen: caller, activity-id: activity-id})
    )
    (asserts! (get is-active activity) ERR-INVALID-PROPOSAL)
    (asserts! (is-none (map-get? citizen-activity-participation participation-key)) ERR-CIVIC-ACTIVITY-EXISTS)
    
    ;; Record participation
    (map-set citizen-activity-participation participation-key
      {completed: true, completion-block: block-height}
    )
    
    ;; Reward tokens and reputation
    (let 
      (
        (current-tokens (get-token-balance caller))
        (current-reputation (get-reputation caller))
        (token-reward (get token-reward activity))
        (reputation-reward (get reputation-reward activity))
      )
      (map-set governance-tokens caller (+ current-tokens token-reward))
      (map-set citizen-reputation caller (+ current-reputation reputation-reward))
      (var-set total-governance-tokens (+ (var-get total-governance-tokens) token-reward))
      
      (ok {tokens-earned: token-reward, reputation-earned: reputation-reward})
    )
  )
)

;; Read-only functions

(define-read-only (get-proposal (proposal-id uint))
  (map-get? proposals proposal-id)
)

(define-read-only (get-token-balance (citizen principal))
  (default-to u0 (map-get? governance-tokens citizen))
)

(define-read-only (get-reputation (citizen principal))
  (default-to u0 (map-get? citizen-reputation citizen))
)

(define-read-only (get-vote (proposal-id uint) (voter principal))
  (map-get? proposal-votes {proposal-id: proposal-id, voter: voter})
)

(define-read-only (get-civic-activity (activity-id uint))
  (map-get? civic-activities activity-id)
)

(define-read-only (get-participation-status (citizen principal) (activity-id uint))
  (map-get? citizen-activity-participation {citizen: citizen, activity-id: activity-id})
)

(define-read-only (get-total-governance-tokens)
  (var-get total-governance-tokens)
)

(define-read-only (get-next-proposal-id)
  (var-get next-proposal-id)
)

(define-read-only (get-next-activity-id)
  (var-get next-activity-id)
)

;; Admin functions

(define-public (emergency-pause-activity (activity-id uint))
  (let ((activity (unwrap! (map-get? civic-activities activity-id) ERR-PROPOSAL-NOT-FOUND)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-OWNER-ONLY)
    
    (map-set civic-activities activity-id
      (merge activity {is-active: false})
    )
    (ok true)
  )
)

(define-public (update-activity-rewards (activity-id uint) (new-token-reward uint) (new-reputation-reward uint))
  (let ((activity (unwrap! (map-get? civic-activities activity-id) ERR-PROPOSAL-NOT-FOUND)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-OWNER-ONLY)
    
    (map-set civic-activities activity-id
      (merge activity 
        {
          token-reward: new-token-reward,
          reputation-reward: new-reputation-reward
        }
      )
    )
    (ok true)
  )
)