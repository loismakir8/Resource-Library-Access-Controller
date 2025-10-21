(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-OWNER-ONLY (err u100))
(define-constant ERR-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-EXISTS (err u102))
(define-constant ERR-NOT-AUTHORIZED (err u103))
(define-constant ERR-RESOURCE-UNAVAILABLE (err u104))
(define-constant ERR-INVALID-PARAMETERS (err u105))
(define-constant ERR-ACCESS-DENIED (err u106))
(define-constant ERR-MEMBERSHIP-EXPIRED (err u107))
(define-constant ERR-RESOURCE-CHECKED-OUT (err u108))
(define-constant ERR-OVERDUE (err u109))

(define-data-var next-resource-id uint u1)
(define-data-var next-member-id uint u1)
(define-data-var late-fee-per-day uint u100)
(define-data-var max-checkout-days uint u14)
(define-data-var max-renewals uint u2)

(define-map resources
  { resource-id: uint }
  {
    title: (string-ascii 100),
    resource-type: (string-ascii 20),
    author: (string-ascii 50),
    isbn: (string-ascii 20),
    available: bool,
    total-copies: uint,
    available-copies: uint,
    created-at: uint
  }
)

(define-map members
  { member-id: uint }
  {
    wallet: principal,
    name: (string-ascii 50),
    email: (string-ascii 100),
    membership-type: (string-ascii 20),
    expiry-date: uint,
    active: bool,
    total-checkouts: uint,
    overdue-count: uint
  }
)

(define-map checkouts
  { checkout-id: uint }
  {
    member-id: uint,
    resource-id: uint,
    checkout-date: uint,
    due-date: uint,
    returned: bool,
    return-date: (optional uint),
    renewals-used: uint,
    late-fee: uint
  }
)

(define-map member-wallets
  { wallet: principal }
  { member-id: uint }
)

(define-map resource-queue
  { resource-id: uint, queue-position: uint }
  { member-id: uint, requested-at: uint }
)

(define-data-var next-checkout-id uint u1)

(define-public (add-resource (title (string-ascii 100)) (resource-type (string-ascii 20)) (author (string-ascii 50)) (isbn (string-ascii 20)) (total-copies uint))
  (let ((resource-id (var-get next-resource-id)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-OWNER-ONLY)
    (asserts! (> total-copies u0) ERR-INVALID-PARAMETERS)
    (map-set resources
      { resource-id: resource-id }
      {
        title: title,
        resource-type: resource-type,
        author: author,
        isbn: isbn,
        available: true,
        total-copies: total-copies,
        available-copies: total-copies,
        created-at: stacks-block-height
      }
    )
    (var-set next-resource-id (+ resource-id u1))
    (ok resource-id)
  )
)

(define-public (register-member (wallet principal) (name (string-ascii 50)) (email (string-ascii 100)) (membership-type (string-ascii 20)) (duration-days uint))
  (let ((member-id (var-get next-member-id)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-OWNER-ONLY)
    (asserts! (is-none (map-get? member-wallets { wallet: wallet })) ERR-ALREADY-EXISTS)
    (map-set members
      { member-id: member-id }
      {
        wallet: wallet,
        name: name,
        email: email,
        membership-type: membership-type,
        expiry-date: (+ stacks-block-height duration-days),
        active: true,
        total-checkouts: u0,
        overdue-count: u0
      }
    )
    (map-set member-wallets { wallet: wallet } { member-id: member-id })
    (var-set next-member-id (+ member-id u1))
    (ok member-id)
  )
)

(define-public (checkout-resource (resource-id uint))
  (let (
    (member-data (unwrap! (get-member-by-wallet tx-sender) ERR-NOT-AUTHORIZED))
    (member-wallet-data (unwrap! (map-get? member-wallets { wallet: tx-sender }) ERR-NOT-AUTHORIZED))
    (member-id (get member-id member-wallet-data))
    (resource (unwrap! (map-get? resources { resource-id: resource-id }) ERR-NOT-FOUND))
    (checkout-id (var-get next-checkout-id))
    (due-date (+ stacks-block-height (var-get max-checkout-days)))
  )
    (asserts! (get active member-data) ERR-ACCESS-DENIED)
    (asserts! (> (get expiry-date member-data) stacks-block-height) ERR-MEMBERSHIP-EXPIRED)
    (asserts! (get available resource) ERR-RESOURCE-UNAVAILABLE)
    (asserts! (> (get available-copies resource) u0) ERR-RESOURCE-UNAVAILABLE)
    
    (map-set checkouts
      { checkout-id: checkout-id }
      {
        member-id: member-id,
        resource-id: resource-id,
        checkout-date: stacks-block-height,
        due-date: due-date,
        returned: false,
        return-date: none,
        renewals-used: u0,
        late-fee: u0
      }
    )
    
    (map-set resources
      { resource-id: resource-id }
      (merge resource { available-copies: (- (get available-copies resource) u1) })
    )
    
    (map-set members
      { member-id: member-id }
      (merge member-data { total-checkouts: (+ (get total-checkouts member-data) u1) })
    )
    
    (var-set next-checkout-id (+ checkout-id u1))
    (ok checkout-id)
  )
)

(define-public (return-resource (checkout-id uint))
  (let (
    (checkout (unwrap! (map-get? checkouts { checkout-id: checkout-id }) ERR-NOT-FOUND))
    (member-data (unwrap! (map-get? members { member-id: (get member-id checkout) }) ERR-NOT-FOUND))
    (resource (unwrap! (map-get? resources { resource-id: (get resource-id checkout) }) ERR-NOT-FOUND))
    (is-overdue (> stacks-block-height (get due-date checkout)))
    (days-overdue (if is-overdue (- stacks-block-height (get due-date checkout)) u0))
    (late-fee (if is-overdue (* days-overdue (var-get late-fee-per-day)) u0))
  )
    (asserts! (not (get returned checkout)) ERR-INVALID-PARAMETERS)
    (asserts! (or (is-eq tx-sender (get wallet member-data)) (is-eq tx-sender CONTRACT-OWNER)) ERR-NOT-AUTHORIZED)
    
    (map-set checkouts
      { checkout-id: checkout-id }
      (merge checkout {
        returned: true,
        return-date: (some stacks-block-height),
        late-fee: late-fee
      })
    )
    
    (map-set resources
      { resource-id: (get resource-id checkout) }
      (merge resource { available-copies: (+ (get available-copies resource) u1) })
    )
    
    (if is-overdue
      (map-set members
        { member-id: (get member-id checkout) }
        (merge member-data { overdue-count: (+ (get overdue-count member-data) u1) })
      )
      true
    )
    
    (ok { late-fee: late-fee, days-overdue: days-overdue })
  )
)

(define-public (renew-resource (checkout-id uint))
  (let (
    (checkout (unwrap! (map-get? checkouts { checkout-id: checkout-id }) ERR-NOT-FOUND))
    (member-data (unwrap! (map-get? members { member-id: (get member-id checkout) }) ERR-NOT-FOUND))
    (new-due-date (+ (get due-date checkout) (var-get max-checkout-days)))
  )
    (asserts! (not (get returned checkout)) ERR-INVALID-PARAMETERS)
    (asserts! (is-eq tx-sender (get wallet member-data)) ERR-NOT-AUTHORIZED)
    (asserts! (< (get renewals-used checkout) (var-get max-renewals)) ERR-INVALID-PARAMETERS)
    (asserts! (<= stacks-block-height (get due-date checkout)) ERR-OVERDUE)
    
    (map-set checkouts
      { checkout-id: checkout-id }
      (merge checkout {
        due-date: new-due-date,
        renewals-used: (+ (get renewals-used checkout) u1)
      })
    )
    
    (ok new-due-date)
  )
)

(define-public (suspend-member (member-id uint))
  (let ((member-data (unwrap! (map-get? members { member-id: member-id }) ERR-NOT-FOUND)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-OWNER-ONLY)
    (map-set members
      { member-id: member-id }
      (merge member-data { active: false })
    )
    (ok true)
  )
)

(define-public (reactivate-member (member-id uint))
  (let ((member-data (unwrap! (map-get? members { member-id: member-id }) ERR-NOT-FOUND)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-OWNER-ONLY)
    (map-set members
      { member-id: member-id }
      (merge member-data { active: true })
    )
    (ok true)
  )
)

(define-public (update-late-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-OWNER-ONLY)
    (var-set late-fee-per-day new-fee)
    (ok true)
  )
)

(define-read-only (get-resource (resource-id uint))
  (map-get? resources { resource-id: resource-id })
)

(define-read-only (get-member (member-id uint))
  (map-get? members { member-id: member-id })
)

(define-read-only (get-member-by-wallet (wallet principal))
  (match (map-get? member-wallets { wallet: wallet })
    member-ref (map-get? members { member-id: (get member-id member-ref) })
    none
  )
)

(define-read-only (get-checkout (checkout-id uint))
  (map-get? checkouts { checkout-id: checkout-id })
)

(define-read-only (get-resource-availability (resource-id uint))
  (match (map-get? resources { resource-id: resource-id })
    resource (ok {
      available: (get available resource),
      available-copies: (get available-copies resource),
      total-copies: (get total-copies resource)
    })
    ERR-NOT-FOUND
  )
)

(define-read-only (is-resource-overdue (checkout-id uint))
  (match (map-get? checkouts { checkout-id: checkout-id })
    checkout (ok (and (not (get returned checkout)) (> stacks-block-height (get due-date checkout))))
    ERR-NOT-FOUND
  )
)

(define-read-only (calculate-late-fee (checkout-id uint))
  (match (map-get? checkouts { checkout-id: checkout-id })
    checkout 
      (let ((days-overdue (if (> stacks-block-height (get due-date checkout))
                           (- stacks-block-height (get due-date checkout))
                           u0)))
        (ok (* days-overdue (var-get late-fee-per-day)))
      )
    ERR-NOT-FOUND
  )
)

(define-read-only (get-member-active-checkouts (member-id uint))
  (ok member-id)
)

(define-read-only (get-contract-stats)
  (ok {
    total-resources: (- (var-get next-resource-id) u1),
    total-members: (- (var-get next-member-id) u1),
    total-checkouts: (- (var-get next-checkout-id) u1),
    late-fee-per-day: (var-get late-fee-per-day),
    max-checkout-days: (var-get max-checkout-days),
    max-renewals: (var-get max-renewals)
  })
)
