;; Loan Application Contract - Simplified
;; Manages borrower requests and loan terms

;; Define data variables
(define-data-var loan-id-counter uint u0)
(define-data-var application-id-counter uint u0)

(define-map loans
  { id: uint }
  {
    borrower: principal,
    amount: uint,
    term: uint,
    status: (string-ascii 10)
  }
)

(define-map applications
  { id: uint }
  {
    borrower: principal,
    amount: uint,
    term: uint,
    purpose: (string-ascii 50),
    status: (string-ascii 10)
  }
)

;; Error codes
(define-constant ERR_UNAUTHORIZED u1)
(define-constant ERR_INVALID_INPUT u2)
(define-constant ERR_NOT_FOUND u3)
(define-constant ERR_ALREADY_PROCESSED u4)

;; Contract owner
(define-data-var contract-owner principal tx-sender)

;; Submit a loan application
(define-public (submit-application (amount uint) (term uint) (purpose (string-ascii 50)))
  (let
    (
      (app-id (+ (var-get application-id-counter) u1))
    )
    ;; Validate inputs
    (asserts! (> amount u0) (err ERR_INVALID_INPUT))
    (asserts! (> term u0) (err ERR_INVALID_INPUT))

    ;; Update counter
    (var-set application-id-counter app-id)

    ;; Store application
    (map-set applications
      { id: app-id }
      {
        borrower: tx-sender,
        amount: amount,
        term: term,
        purpose: purpose,
        status: "pending"
      }
    )

    (ok app-id)
  )
)

;; Approve a loan application
(define-public (approve-application (app-id uint))
  (let
    (
      (application (unwrap! (map-get? applications { id: app-id }) (err ERR_NOT_FOUND)))
      (loan-id (+ (var-get loan-id-counter) u1))
    )
    ;; Only contract owner can approve
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR_UNAUTHORIZED))

    ;; Check if application is pending
    (asserts! (is-eq (get status application) "pending") (err ERR_ALREADY_PROCESSED))

    ;; Update counter
    (var-set loan-id-counter loan-id)

    ;; Create loan
    (map-set loans
      { id: loan-id }
      {
        borrower: (get borrower application),
        amount: (get amount application),
        term: (get term application),
        status: "active"
      }
    )

    ;; Update application status
    (map-set applications
      { id: app-id }
      (merge application { status: "approved" })
    )

    (ok loan-id)
  )
)

;; Reject a loan application
(define-public (reject-application (app-id uint))
  (let
    (
      (application (unwrap! (map-get? applications { id: app-id }) (err ERR_NOT_FOUND)))
    )
    ;; Only contract owner can reject
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR_UNAUTHORIZED))

    ;; Check if application is pending
    (asserts! (is-eq (get status application) "pending") (err ERR_ALREADY_PROCESSED))

    ;; Update application status
    (map-set applications
      { id: app-id }
      (merge application { status: "rejected" })
    )

    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-loan (id uint))
  (map-get? loans { id: id })
)

(define-read-only (get-application (id uint))
  (map-get? applications { id: id })
)

;; Set contract owner
(define-public (set-contract-owner (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR_UNAUTHORIZED))
    (ok (var-set contract-owner new-owner))
  )
)

