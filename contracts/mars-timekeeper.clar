;; Mars Timekeeper Contract
;; Tracks Martian sols (days) alongside Bitcoin block time
;; 1 Martian sol = ~24 hours, 39 minutes, 35 seconds = 88,775 seconds
;; 1 Earth day = 86,400 seconds
;; Sol conversion factor: 1 sol = 1.02749125 Earth days

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_INVALID_BLOCK (err u101))
(define-constant ERR_MISSION_EXISTS (err u102))
(define-constant ERR_MISSION_NOT_FOUND (err u103))

;; Mars sol is longer than Earth day by this factor (scaled by 1000000)
;; 1.02749125 * 1000000 = 1027491
(define-constant SOL_TO_EARTH_DAY_FACTOR u1027491)
(define-constant SCALE_FACTOR u1000000)

;; Approximate blocks per Earth day (assuming ~10 min blocks = 144 blocks/day)
(define-constant BLOCKS_PER_EARTH_DAY u144)

;; Data Variables
(define-data-var mission-start-block uint u0)
(define-data-var mission-start-time uint u0)
(define-data-var total-missions uint u0)

;; Data Maps
;; Track sol observations with Bitcoin block height
(define-map sol-records
  { sol: uint }
  {
    block-height: uint,
    timestamp: uint,
    recorder: principal,
    notes: (string-utf8 256)
  }
)

;; Track mission milestones
(define-map missions
  { mission-id: uint }
  {
    name: (string-utf8 64),
    start-block: uint,
    start-time: uint,
    creator: principal,
    active: bool
  }
)

;; Track user contributions
(define-map user-records
  { user: principal }
  {
    records-count: uint,
    first-record-block: uint
  }
)

;; Public Functions

;; Initialize a new Mars mission with a starting block
(define-public (start-mission (name (string-utf8 64)) (start-block uint))
  (let
    (
      (mission-id (+ (var-get total-missions) u1))
      (current-block block-height)
    )
    (asserts! (>= start-block current-block) ERR_INVALID_BLOCK)
    (asserts! (is-none (map-get? missions { mission-id: mission-id })) ERR_MISSION_EXISTS)

    (map-set missions
      { mission-id: mission-id }
      {
        name: name,
        start-block: start-block,
        start-time: (unwrap-panic (get-block-info? time start-block)),
        creator: tx-sender,
        active: true
      }
    )

    (var-set total-missions mission-id)
    (ok mission-id)
  )
)

;; Record a sol observation
(define-public (record-sol (sol uint) (notes (string-utf8 256)))
  (let
    (
      (current-block block-height)
      (user tx-sender)
      (user-data (default-to
        { records-count: u0, first-record-block: current-block }
        (map-get? user-records { user: user })
      ))
    )
    (map-set sol-records
      { sol: sol }
      {
        block-height: current-block,
        timestamp: (unwrap-panic (get-block-info? time current-block)),
        recorder: user,
        notes: notes
      }
    )

    (map-set user-records
      { user: user }
      {
        records-count: (+ (get records-count user-data) u1),
        first-record-block: (get first-record-block user-data)
      }
    )

    (ok true)
  )
)

;; End a mission
(define-public (end-mission (mission-id uint))
  (let
    (
      (mission (unwrap! (map-get? missions { mission-id: mission-id }) ERR_MISSION_NOT_FOUND))
    )
    (asserts! (is-eq tx-sender (get creator mission)) ERR_UNAUTHORIZED)

    (map-set missions
      { mission-id: mission-id }
      (merge mission { active: false })
    )

    (ok true)
  )
)

;; Read-Only Functions

;; Get sol record
(define-read-only (get-sol-record (sol uint))
  (map-get? sol-records { sol: sol })
)

;; Get mission details
(define-read-only (get-mission (mission-id uint))
  (map-get? missions { mission-id: mission-id })
)

;; Get user record statistics
(define-read-only (get-user-stats (user principal))
  (map-get? user-records { user: user })
)

;; Convert blocks to approximate sols since mission start
(define-read-only (blocks-to-sols (start-block uint) (current-block uint))
  (let
    (
      (blocks-elapsed (- current-block start-block))
      ;; Convert blocks to Earth days: blocks / 144
      (earth-days (/ blocks-elapsed BLOCKS_PER_EARTH_DAY))
      ;; Convert Earth days to Mars sols: days / 1.02749125
      ;; Which is: (days * SCALE_FACTOR) / SOL_TO_EARTH_DAY_FACTOR
      (mars-sols (/ (* earth-days SCALE_FACTOR) SOL_TO_EARTH_DAY_FACTOR))
    )
    (ok mars-sols)
  )
)

;; Calculate current sol for a mission
(define-read-only (get-current-mission-sol (mission-id uint))
  (let
    (
      (mission (unwrap! (map-get? missions { mission-id: mission-id }) ERR_MISSION_NOT_FOUND))
      (start-block (get start-block mission))
      (current-block block-height)
    )
    (blocks-to-sols start-block current-block)
  )
)

;; Get total number of missions
(define-read-only (get-total-missions)
  (ok (var-get total-missions))
)

;; Calculate time difference in sols between two blocks
(define-read-only (get-sol-difference (block-1 uint) (block-2 uint))
  (let
    (
      (blocks-diff (if (> block-2 block-1)
        (- block-2 block-1)
        (- block-1 block-2)))
      (earth-days (/ blocks-diff BLOCKS_PER_EARTH_DAY))
      (mars-sols (/ (* earth-days SCALE_FACTOR) SOL_TO_EARTH_DAY_FACTOR))
    )
    (ok mars-sols)
  )
)

;; Get contract info
(define-read-only (get-contract-info)
  (ok {
    sol-to-earth-factor: SOL_TO_EARTH_DAY_FACTOR,
    blocks-per-day: BLOCKS_PER_EARTH_DAY,
    total-missions: (var-get total-missions),
    current-block: block-height
  })
)
