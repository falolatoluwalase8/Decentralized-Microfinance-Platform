;; Repayment Tracking Contract - Simplified
;; Monitors loan payments and schedules

;; Define data variables
(define-map loan-repayments
  { loan-id: uint }
  {
    total-amount: uint,
    amount-paid: uint,
    payments-made: uint,
    total-payments: uint,
    status: (string-ascii 10)
  }
)

(define-map payments
  { loan-id: uint, payment-id: uint }
  {
    amount: uint,
    paid-by: principal
  }
)

;; Error codes
(define-constant ERR_UNAUTHORIZED u1)
(define-constant ERR_NOT_FOUND u2)
(define-constant ERR_INVALID_INPUT u3)
(define-constant ERR_COMPLETED u4)

;; Contract owner
(define-data-var contract-owner principal tx-sender)

;; Initialize loan repayment
(define-public (initialize-repayment (loan-id uint) (total-amount uint) (total-payments uint))
  (begin
    ;; Only contract owner can initialize
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR_UNAUTHORIZED))

    ;; Validate inputs
    (asserts! (> total-amount u0) (err ERR_INVALID_INPUT))
    (asserts! (> total-payments u0) (err ERR_INVALID_INPUT))

    ;; Store repayment info
    (map-set loan-repayments
      { loan-id: loan-id }
      {
        total-amount: total-amount,
        amount-paid: u0,
        payments-made: u0,
        total-payments: total-payments,
        status: "active"
      }
    )

    (ok true)
  )
)

;; Make a payment
(define-public (make-payment (loan-id uint) (amount uint))
  (let
    (
      (repayment (unwrap! (map-get? loan-repayments { loan-id: loan-id }) (err ERR_NOT_FOUND)))
      (payment-id (get payments-made repayment))
    )
    ;; Check if loan is active
    (asserts! (is-eq (get status repayment) "active") (err ERR_COMPLETED))

    ;; Validate amount
    (asserts! (> amount u0) (err ERR_INVALID_INPUT))

    ;; Record payment
    (map-set payments
      { loan-id: loan-id, payment-id: payment-id }
      {
        amount: amount,
        paid-by: tx-sender
      }
    )

    ;; Update repayment info
    (let
      (
        (new-amount-paid (+ (get amount-paid repayment) amount))
        (new-payments-made (+ payment-id u1))
        (is-completed (>= new-payments-made (get total-payments repayment)))
      )
      (map-set loan-repayments
        { loan-id: loan-id }
        (merge repayment
          {
            amount-paid: new-amount-paid,
            payments-made: new-payments-made,
            status: (if is-completed "completed" "active")
          }
        )
      )

      (ok true)
    )
  )
)

;; Mark loan as defaulted
(define-public (mark-defaulted (loan-id uint))
  (let
    (
      (repayment (unwrap! (map-get? loan-repayments { loan-id: loan-id }) (err ERR_NOT_FOUND)))
    )
    ;; Only contract owner can mark defaulted
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR_UNAUTHORIZED))

    ;; Check if loan is active
    (asserts! (is-eq (get status repayment) "active") (err ERR_COMPLETED))

    ;; Update status
    (map-set loan-repayments
      { loan-id: loan-id }
      (merge repayment { status: "defaulted" })
    )

    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-repayment (loan-id uint))
  (map-get? loan-repayments { loan-id: loan-id })
)

(define-read-only (get-payment (loan-id uint) (payment-id uint))
  (map-get? payments { loan-id: loan-id, payment-id: payment-id })
)

;; Set contract owner
(define-public (set-contract-owner (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR_UNAUTHORIZED))
    (ok (var-set contract-owner new-owner))
  )
)

