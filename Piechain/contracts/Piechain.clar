;; Pizza Chain Empire Contract
;; Operate pizza restaurants and earn profit tokens
(define-fungible-token pizza-profit)
(define-constant PIZZA-CEO tx-sender)

;; Error Codes
(define-constant ERR-NOT-CEO (err u101))
(define-constant ERR-INVALID-INVESTMENT (err u102))
(define-constant ERR-NO-RESTAURANT-OWNED (err u103))
(define-constant ERR-RESTAURANT-CLOSED (err u104))
(define-constant ERR-INVALID-RESTAURANT (err u105))
(define-constant ERR-INVALID-COST (err u106))
(define-constant ERR-INVALID-MARGIN (err u107))
(define-constant ERR-EMPTY-BRAND-NAME (err u108))

;; Business Variables
(define-data-var recession-mode bool false)
(define-data-var bankruptcy-loss uint u20) ;; 20% loss during bankruptcy
(define-data-var profit-per-customer uint u6)
(define-data-var total-restaurants-value uint u0)
(define-data-var restaurant-chains uint u0)

;; Data Maps
(define-map restaurant-chains-map
  { restaurant-id: uint }
  { brand-name: (string-ascii 30), location-cost: uint, profit-margin: uint, total-value: uint, operating: bool }
)

(define-map franchise-ownership
  { owner: principal, restaurant-id: uint }
  { investment-amount: uint, last-profit-block: uint }
)

;; Launch pizza empire
(define-public (launch-pizza-empire)
  (begin
    (try! (ft-mint? pizza-profit u600000 PIZZA-CEO))
    (try! (open-restaurant-chain "Food Truck" u4 u80))
    (try! (open-restaurant-chain "Local Shop" u7 u115))
    (try! (open-restaurant-chain "Franchise Store" u10 u160))
    (ok true)
  )
)

;; Open new restaurant chain
(define-public (open-restaurant-chain (brand-name (string-ascii 30)) (cost uint) (margin uint))
  (begin
    (asserts! (is-eq tx-sender PIZZA-CEO) ERR-NOT-CEO)
    ;; Validate inputs
    (asserts! (> (len brand-name) u0) ERR-EMPTY-BRAND-NAME)
    (asserts! (and (> cost u0) (<= cost u1000)) ERR-INVALID-COST)
    (asserts! (and (> margin u0) (<= margin u500)) ERR-INVALID-MARGIN)
    
    (let ((new-restaurant-id (var-get restaurant-chains)))
      (map-set restaurant-chains-map { restaurant-id: new-restaurant-id }
        { brand-name: brand-name, location-cost: cost, profit-margin: margin, total-value: u0, operating: true })
      (var-set restaurant-chains (+ new-restaurant-id u1))
      (ok new-restaurant-id)
    )
  )
)

;; Invest in restaurant chain
(define-public (invest-in-restaurant (restaurant-id uint) (investment uint))
  (begin
    (asserts! (> investment u0) ERR-INVALID-INVESTMENT)
    ;; Validate restaurant-id exists and is within valid range
    (asserts! (< restaurant-id (var-get restaurant-chains)) ERR-INVALID-RESTAURANT)
    (let ((chain (unwrap! (map-get? restaurant-chains-map { restaurant-id: restaurant-id }) ERR-INVALID-RESTAURANT)))
      (asserts! (get operating chain) ERR-RESTAURANT-CLOSED)
      (try! (ft-transfer? pizza-profit investment tx-sender (as-contract tx-sender)))
      (let ((current-ownership (default-to { investment-amount: u0, last-profit-block: stacks-block-height }
              (map-get? franchise-ownership { owner: tx-sender, restaurant-id: restaurant-id }))))
        (if (> (get investment-amount current-ownership) u0)
          (try! (pay-profits tx-sender (calculate-restaurant-profits tx-sender restaurant-id)))
          true)
        (map-set franchise-ownership { owner: tx-sender, restaurant-id: restaurant-id }
          { investment-amount: (+ (get investment-amount current-ownership) investment),
            last-profit-block: stacks-block-height })
        (map-set restaurant-chains-map { restaurant-id: restaurant-id }
          (merge chain { total-value: (+ (get total-value chain) investment) }))
        (var-set total-restaurants-value (+ (var-get total-restaurants-value) investment))
        (ok true)
      )
    )
  )
)

;; Sell restaurant investment
(define-public (sell-restaurant-stake (restaurant-id uint) (amount uint))
  (begin
    ;; Validate restaurant-id exists and is within valid range
    (asserts! (< restaurant-id (var-get restaurant-chains)) ERR-INVALID-RESTAURANT)
    (let ((chain (unwrap! (map-get? restaurant-chains-map { restaurant-id: restaurant-id }) ERR-INVALID-RESTAURANT))
          (ownership (unwrap! (map-get? franchise-ownership { owner: tx-sender, restaurant-id: restaurant-id }) ERR-NO-RESTAURANT-OWNED)))
      (asserts! (<= amount (get investment-amount ownership)) ERR-INVALID-INVESTMENT)
      (try! (pay-profits tx-sender (calculate-restaurant-profits tx-sender restaurant-id)))
      (try! (as-contract (ft-transfer? pizza-profit amount tx-sender tx-sender)))
      (map-set franchise-ownership { owner: tx-sender, restaurant-id: restaurant-id }
        { investment-amount: (- (get investment-amount ownership) amount),
          last-profit-block: stacks-block-height })
      (ok true)
    )
  )
)

;; Emergency bankruptcy exit
(define-public (declare-bankruptcy (restaurant-id uint))
  (begin
    (asserts! (var-get recession-mode) ERR-NOT-CEO)
    ;; Validate restaurant-id exists and is within valid range
    (asserts! (< restaurant-id (var-get restaurant-chains)) ERR-INVALID-RESTAURANT)
    (let ((chain (unwrap! (map-get? restaurant-chains-map { restaurant-id: restaurant-id }) ERR-INVALID-RESTAURANT))
          (ownership (unwrap! (map-get? franchise-ownership { owner: tx-sender, restaurant-id: restaurant-id }) ERR-NO-RESTAURANT-OWNED))
          (invested (get investment-amount ownership))
          (bankruptcy-fee (/ (* invested (var-get bankruptcy-loss)) u100)))
      (try! (as-contract (ft-transfer? pizza-profit (- invested bankruptcy-fee) tx-sender tx-sender)))
      (map-delete franchise-ownership { owner: tx-sender, restaurant-id: restaurant-id })
      (ok (- invested bankruptcy-fee))
    )
  )
)

;; Calculate restaurant profits
(define-private (calculate-restaurant-profits (owner principal) (restaurant-id uint))
  (let ((ownership (unwrap! (map-get? franchise-ownership { owner: owner, restaurant-id: restaurant-id }) u0))
        (chain (unwrap! (map-get? restaurant-chains-map { restaurant-id: restaurant-id }) u0))
        (days-operating (- stacks-block-height (get last-profit-block ownership))))
    (/ (* (get investment-amount ownership) days-operating (var-get profit-per-customer) (get profit-margin chain))
       (* (get total-value chain) u100))
  )
)

(define-private (pay-profits (owner principal) (profit-amount uint))
  (ft-mint? pizza-profit profit-amount owner)
)

;; Admin functions
(define-public (set-recession-mode (active bool))
  (begin
    (asserts! (is-eq tx-sender PIZZA-CEO) ERR-NOT-CEO)
    (var-set recession-mode active)
    (ok active)
  )
)

;; Read-only functions
(define-read-only (get-franchise-ownership (owner principal) (restaurant-id uint))
  (default-to { investment-amount: u0, last-profit-block: u0 }
    (map-get? franchise-ownership { owner: owner, restaurant-id: restaurant-id }))
)

(define-read-only (get-restaurant-chain-info (restaurant-id uint))
  (map-get? restaurant-chains-map { restaurant-id: restaurant-id })
)

(define-read-only (get-empire-stats)
  { total-restaurants-value: (var-get total-restaurants-value),
    recession-mode: (var-get recession-mode),
    restaurant-chains: (var-get restaurant-chains) }
)