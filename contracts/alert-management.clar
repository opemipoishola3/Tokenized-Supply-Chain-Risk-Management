;; Alert Management Contract
;; Handles notification of potential issues

(define-data-var admin principal tx-sender)

;; Alert severity: 1 = low, 2 = medium, 3 = high, 4 = critical
;; Alert status: 0 = new, 1 = acknowledged, 2 = resolved, 3 = dismissed
(define-map alerts
  { alert-id: uint }
  {
    title: (string-utf8 100),
    description: (string-utf8 500),
    severity: uint,
    status: uint,
    source-type: uint, ;; 1 = monitor, 2 = risk, 3 = manual
    source-id: uint,
    entity-id: uint,
    created-at: uint,
    updated-at: uint,
    resolved-at: uint
  }
)

(define-data-var alert-counter uint u0)

;; Create a new alert
(define-public (create-alert
    (title (string-utf8 100))
    (description (string-utf8 500))
    (severity uint)
    (source-type uint)
    (source-id uint)
    (entity-id uint))
  (let
    (
      (alert-id (+ (var-get alert-counter) u1))
    )
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (and (> severity u0) (<= severity u4)) (err u400))
    (asserts! (and (> source-type u0) (<= source-type u3)) (err u400))

    (map-insert alerts
      { alert-id: alert-id }
      {
        title: title,
        description: description,
        severity: severity,
        status: u0,
        source-type: source-type,
        source-id: source-id,
        entity-id: entity-id,
        created-at: block-height,
        updated-at: block-height,
        resolved-at: u0
      }
    )
    (var-set alert-counter alert-id)
    (ok alert-id)
  )
)

;; Acknowledge an alert
(define-public (acknowledge-alert (alert-id uint))
  (let
    (
      (alert (unwrap! (map-get? alerts { alert-id: alert-id }) (err u404)))
    )
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-eq (get status alert) u0) (err u400))

    (map-set alerts
      { alert-id: alert-id }
      (merge alert {
        status: u1,
        updated-at: block-height
      })
    )
    (ok true)
  )
)

;; Resolve an alert
(define-public (resolve-alert (alert-id uint))
  (let
    (
      (alert (unwrap! (map-get? alerts { alert-id: alert-id }) (err u404)))
    )
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (or (is-eq (get status alert) u0) (is-eq (get status alert) u1)) (err u400))

    (map-set alerts
      { alert-id: alert-id }
      (merge alert {
        status: u2,
        updated-at: block-height,
        resolved-at: block-height
      })
    )
    (ok true)
  )
)

;; Dismiss an alert
(define-public (dismiss-alert (alert-id uint))
  (let
    (
      (alert (unwrap! (map-get? alerts { alert-id: alert-id }) (err u404)))
    )
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (or (is-eq (get status alert) u0) (is-eq (get status alert) u1)) (err u400))

    (map-set alerts
      { alert-id: alert-id }
      (merge alert {
        status: u3,
        updated-at: block-height
      })
    )
    (ok true)
  )
)

;; Get alert details
(define-read-only (get-alert (alert-id uint))
  (map-get? alerts { alert-id: alert-id })
)

;; Count active alerts (new or acknowledged)
(define-read-only (count-active-alerts)
  (var-get alert-counter)
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)
