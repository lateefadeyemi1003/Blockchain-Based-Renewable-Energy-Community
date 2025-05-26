;; Community Verification Contract
;; Validates and manages renewable energy communities

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-invalid-status (err u103))

;; Community status types
(define-constant status-pending u0)
(define-constant status-verified u1)
(define-constant status-suspended u2)

;; Data structures
(define-map communities
  { community-id: uint }
  {
    name: (string-ascii 50),
    admin: principal,
    location: (string-ascii 100),
    capacity: uint,
    status: uint,
    created-at: uint
  }
)

(define-map community-members
  { community-id: uint, member: principal }
  { joined-at: uint, energy-contribution: uint }
)

(define-data-var next-community-id uint u1)

;; Register a new community
(define-public (register-community (name (string-ascii 50)) (location (string-ascii 100)) (capacity uint))
  (let ((community-id (var-get next-community-id)))
    (map-set communities
      { community-id: community-id }
      {
        name: name,
        admin: tx-sender,
        location: location,
        capacity: capacity,
        status: status-pending,
        created-at: block-height
      }
    )
    (var-set next-community-id (+ community-id u1))
    (ok community-id)
  )
)

;; Verify a community (owner only)
(define-public (verify-community (community-id uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (match (map-get? communities { community-id: community-id })
      community-data
      (begin
        (map-set communities
          { community-id: community-id }
          (merge community-data { status: status-verified })
        )
        (ok true)
      )
      err-not-found
    )
  )
)

;; Join a community
(define-public (join-community (community-id uint))
  (match (map-get? communities { community-id: community-id })
    community-data
    (if (is-eq (get status community-data) status-verified)
      (begin
        (map-set community-members
          { community-id: community-id, member: tx-sender }
          { joined-at: block-height, energy-contribution: u0 }
        )
        (ok true)
      )
      err-invalid-status
    )
    err-not-found
  )
)

;; Get community info
(define-read-only (get-community (community-id uint))
  (map-get? communities { community-id: community-id })
)

;; Check if user is community member
(define-read-only (is-community-member (community-id uint) (member principal))
  (is-some (map-get? community-members { community-id: community-id, member: member }))
)
