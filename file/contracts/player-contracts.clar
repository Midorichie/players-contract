;; Player Contract System - Enhanced Implementation (v2)
;; Adds token functionality, vesting, team performance, and dispute resolution

;; Define constants
(define-constant contract-owner tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-PLAYER-EXISTS (err u101))
(define-constant ERR-INVALID-AMOUNT (err u102))
(define-constant ERR-PLAYER-NOT-FOUND (err u103))
(define-constant ERR-TEAM-NOT-FOUND (err u104))
(define-constant ERR-INVALID-VESTING (err u105))
(define-constant ERR-DISPUTE-EXISTS (err u106))

;; Define fungible token
(define-fungible-token player-salary-token)

;; Define data variables
(define-data-var minimum-salary uint u50000)
(define-data-var performance-multiplier uint u100)
(define-data-var team-bonus-multiplier uint u20)
(define-data-var dispute-resolution-period uint u144) ;; ~1 day in blocks

;; Enhanced data maps
(define-map Players 
    principal 
    {
        base-salary: uint,
        contract-start: uint,
        contract-duration: uint,
        performance-score: uint,
        tokens-issued: uint,
        bonus-threshold: uint,
        team-id: (optional uint),
        vesting-schedule: {
            cliff-period: uint,
            vesting-period: uint,
            vested-amount: uint
        },
        last-claim-height: uint
    }
)

(define-map PerformanceMetrics
    principal
    {
        games-played: uint,
        scores: uint,
        assists: uint,
        team-contribution: uint,
        total-performance: uint,
        season-highlights: uint
    }
)

(define-map Teams
    uint
    {
        team-performance: uint,
        player-count: uint,
        total-salary-cap: uint,
        bonus-pool: uint
    }
)

(define-map Disputes
    principal
    {
        dispute-type: (string-ascii 64),
        filed-at: uint,
        resolved: bool,
        resolution-votes: uint,
        evidence-hash: (buff 32)
    }
)

;; Enhanced read-only functions
(define-read-only (get-vested-amount (player principal))
    (let (
        (player-data (unwrap! (map-get? Players player) ERR-PLAYER-NOT-FOUND))
        (vesting-data (get vesting-schedule player-data))
        (blocks-passed (- block-height (get contract-start player-data)))
    )
    (if (< blocks-passed (get cliff-period vesting-data))
        u0
        (min
            (get base-salary player-data)
            (/ (* (get base-salary player-data) blocks-passed) (get vesting-period vesting-data))
        ))
    )
)

(define-read-only (calculate-team-bonus (team-id uint))
    (let (
        (team-data (unwrap! (map-get? Teams team-id) ERR-TEAM-NOT-FOUND))
    )
    (if (> (get team-performance team-data) u800)
        (some (/ (* (get bonus-pool team-data) (var-get team-bonus-multiplier)) u100))
        none
    ))
)

;; Enhanced public functions
(define-public (register-player-v2
    (player principal) 
    (base-salary uint)
    (duration uint)
    (bonus-threshold uint)
    (team-id uint)
    (cliff-period uint)
    (vesting-period uint)
)
    (begin
        (asserts! (is-eq tx-sender contract-owner) ERR-NOT-AUTHORIZED)
        (asserts! (is-none (map-get? Players player)) ERR-PLAYER-EXISTS)
        (asserts! (>= base-salary (var-get minimum-salary)) ERR-INVALID-AMOUNT)
        (asserts! (>= vesting-period cliff-period) ERR-INVALID-VESTING)
        
        (map-set Players player {
            base-salary: base-salary,
            contract-start: block-height,
            contract-duration: duration,
            performance-score: u0,
            tokens-issued: u0,
            bonus-threshold: bonus-threshold,
            team-id: (some team-id),
            vesting-schedule: {
                cliff-period: cliff-period,
                vesting-period: vesting-period,
                vested-amount: u0
            },
            last-claim-height: block-height
        })
        
        (map-set PerformanceMetrics player {
            games-played: u0,
            scores: u0,
            assists: u0,
            team-contribution: u0,
            total-performance: u0,
            season-highlights: u0
        })
        
        (ok true)
    )
)

(define-public (mint-salary-tokens-v2 (player principal))
    (let (
        (player-data (unwrap! (map-get? Players player) ERR-PLAYER-NOT-FOUND))
        (current-height block-height)
        (vested-amount (get-vested-amount player))
    )
    (asserts! (is-eq tx-sender contract-owner) ERR-NOT-AUTHORIZED)
    
    (let (
        (token-amount (/ (* vested-amount u100) u12)) ;; Monthly vested tokens
        (bonus (default-to u0 (calculate-bonus player)))
        (team-bonus (default-to u0 (calculate-team-bonus (unwrap! (get team-id player-data) ERR-TEAM-NOT-FOUND))))
        (total-amount (+ (+ token-amount bonus) team-bonus))
    )
        ;; Mint tokens to player
        (ft-mint? player-salary-token total-amount player)
    ))
)

(define-public (file-dispute 
    (player principal)
    (dispute-type (string-ascii 64))
    (evidence-hash (buff 32))
)
    (begin
        (asserts! (is-some (map-get? Players player)) ERR-PLAYER-NOT-FOUND)
        (asserts! (is-none (map-get? Disputes player)) ERR-DISPUTE-EXISTS)
        
        (map-set Disputes player {
            dispute-type: dispute-type,
            filed-at: block-height,
            resolved: false,
            resolution-votes: u0,
            evidence-hash: evidence-hash
        })
        (ok true)
    )
)

(define-public (resolve-dispute
    (player principal)
    (resolution bool)
)
    (let (
        (dispute (unwrap! (map-get? Disputes player) ERR-PLAYER-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender contract-owner) ERR-NOT-AUTHORIZED)
    (asserts! (not (get resolved dispute)) ERR-NOT-AUTHORIZED)
    
    (map-set Disputes player
        (merge dispute { resolved: resolution })
    )
    (ok true)
    )
)

(define-public (update-team-performance
    (team-id uint)
    (new-performance uint)
    (bonus-pool uint)
)
    (begin
        (asserts! (is-eq tx-sender contract-owner) ERR-NOT-AUTHORIZED)
        (asserts! (is-some (map-get? Teams team-id)) ERR-TEAM-NOT-FOUND)
        
        (map-set Teams team-id {
            team-performance: new-performance,
            player-count: (get player-count (unwrap! (map-get? Teams team-id) ERR-TEAM-NOT-FOUND)),
            total-salary-cap: (get total-salary-cap (unwrap! (map-get? Teams team-id) ERR-TEAM-NOT-FOUND)),
            bonus-pool: bonus-pool
        })
        (ok true)
    )
)