;; EscapeVerse - Virtual Escape Room Game with NFT and Token Rewards
;; Built on Stacks Blockchain

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-solved (err u102))
(define-constant err-wrong-answer (err u103))
(define-constant err-room-locked (err u104))
(define-constant err-insufficient-balance (err u105))
(define-constant err-already-claimed (err u106))

;; Token name and symbol
(define-fungible-token escape-token)
(define-non-fungible-token escape-nft uint)

;; Data Variables
(define-data-var token-name (string-ascii 32) "EscapeVerse Token")
(define-data-var token-symbol (string-ascii 10) "ESCAPE")
(define-data-var nft-last-id uint u0)
(define-data-var room-count uint u0)

;; Data Maps
(define-map rooms
    uint
    {
        name: (string-ascii 50),
        difficulty: uint,
        reward-tokens: uint,
        reward-nft: bool,
        is-active: bool,
        puzzle-hash: (buff 32)
    }
)

(define-map player-progress
    {player: principal, room-id: uint}
    {
        completed: bool,
        attempts: uint,
        completion-time: uint,
        nft-claimed: bool
    }
)

(define-map player-stats
    principal
    {
        total-rooms-completed: uint,
        total-tokens-earned: uint,
        total-nfts-earned: uint
    }
)

;; NFT Metadata
(define-map nft-metadata
    uint
    {
        room-id: uint,
        player: principal,
        completion-time: uint,
        rarity: (string-ascii 20)
    }
)

;; Read-only functions

(define-read-only (get-token-name)
    (ok (var-get token-name))
)

(define-read-only (get-token-symbol)
    (ok (var-get token-symbol))
)

(define-read-only (get-balance (account principal))
    (ok (ft-get-balance escape-token account))
)

(define-read-only (get-token-uri (token-id uint))
    (ok (some "https://escapeverse.io/nft/{id}"))
)

(define-read-only (get-owner (token-id uint))
    (ok (nft-get-owner? escape-nft token-id))
)

(define-read-only (get-room (room-id uint))
    (map-get? rooms room-id)
)

(define-read-only (get-player-progress (player principal) (room-id uint))
    (map-get? player-progress {player: player, room-id: room-id})
)

(define-read-only (get-player-stats (player principal))
    (default-to 
        {total-rooms-completed: u0, total-tokens-earned: u0, total-nfts-earned: u0}
        (map-get? player-stats player)
    )
)

(define-read-only (get-nft-metadata (token-id uint))
    (map-get? nft-metadata token-id)
)

(define-read-only (get-total-rooms)
    (ok (var-get room-count))
)

;; Private functions

(define-private (update-player-stats (player principal) (tokens uint) (nft bool))
    (let
        (
            (stats (get-player-stats player))
            (new-rooms (+ (get total-rooms-completed stats) u1))
            (new-tokens (+ (get total-tokens-earned stats) tokens))
            (new-nfts (if nft (+ (get total-nfts-earned stats) u1) (get total-nfts-earned stats)))
        )
        (map-set player-stats player
            {
                total-rooms-completed: new-rooms,
                total-tokens-earned: new-tokens,
                total-nfts-earned: new-nfts
            }
        )
    )
)

;; Public functions

;; Initialize the contract (mint initial tokens to contract)
(define-public (initialize)
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (try! (ft-mint? escape-token u1000000 contract-owner))
        (ok true)
    )
)

;; Create a new escape room
(define-public (create-room 
    (name (string-ascii 50))
    (difficulty uint)
    (reward-tokens uint)
    (reward-nft bool)
    (puzzle-hash (buff 32)))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (let
            ((new-room-id (+ (var-get room-count) u1)))
            (map-set rooms new-room-id
                {
                    name: name,
                    difficulty: difficulty,
                    reward-tokens: reward-tokens,
                    reward-nft: reward-nft,
                    is-active: true,
                    puzzle-hash: puzzle-hash
                }
            )
            (var-set room-count new-room-id)
            (ok new-room-id)
        )
    )
)

;; Solve a puzzle and claim rewards
(define-public (solve-puzzle (room-id uint) (answer (buff 32)))
    (let
        (
            (room (unwrap! (get-room room-id) err-not-found))
            (progress (get-player-progress tx-sender room-id))
            (current-time stacks-block-height)
        )
        ;; Check if room is active
        (asserts! (get is-active room) err-room-locked)
        
        ;; Check if already completed
        (asserts! 
            (match progress
                prog (not (get completed prog))
                true
            )
            err-already-solved
        )
        
        ;; Verify answer
        (asserts! (is-eq (sha256 answer) (get puzzle-hash room)) err-wrong-answer)
        
        ;; Update progress
        (map-set player-progress {player: tx-sender, room-id: room-id}
            {
                completed: true,
                attempts: (match progress prog (+ (get attempts prog) u1) u1),
                completion-time: current-time,
                nft-claimed: false
            }
        )
        
        ;; Award tokens
        (try! (ft-mint? escape-token (get reward-tokens room) tx-sender))
        
        ;; Update stats
        (update-player-stats tx-sender (get reward-tokens room) (get reward-nft room))
        
        (ok true)
    )
)

;; Claim NFT reward for completed room
(define-public (claim-nft-reward (room-id uint))
    (let
        (
            (room (unwrap! (get-room room-id) err-not-found))
            (progress (unwrap! (get-player-progress tx-sender room-id) err-not-found))
            (new-nft-id (+ (var-get nft-last-id) u1))
        )
        ;; Check if completed and NFT reward available
        (asserts! (get completed progress) err-not-found)
        (asserts! (get reward-nft room) err-not-found)
        (asserts! (not (get nft-claimed progress)) err-already-claimed)
        
        ;; Mint NFT
        (try! (nft-mint? escape-nft new-nft-id tx-sender))
        
        ;; Store metadata
        (map-set nft-metadata new-nft-id
            {
                room-id: room-id,
                player: tx-sender,
                completion-time: (get completion-time progress),
                rarity: (if (<= (get difficulty room) u3) "Common" "Rare")
            }
        )
        
        ;; Update progress
        (map-set player-progress {player: tx-sender, room-id: room-id}
            (merge progress {nft-claimed: true})
        )
        
        (var-set nft-last-id new-nft-id)
        (ok new-nft-id)
    )
)

;; Transfer tokens
(define-public (transfer (amount uint) (sender principal) (recipient principal))
    (begin
        (asserts! (is-eq tx-sender sender) err-owner-only)
        (try! (ft-transfer? escape-token amount sender recipient))
        (ok true)
    )
)

;; Transfer NFT
(define-public (transfer-nft (token-id uint) (sender principal) (recipient principal))
    (begin
        (asserts! (is-eq tx-sender sender) err-owner-only)
        (try! (nft-transfer? escape-nft token-id sender recipient))
        (ok true)
    )
)

;; Admin: Toggle room active status
(define-public (toggle-room-status (room-id uint))
    (let
        ((room (unwrap! (get-room room-id) err-not-found)))
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set rooms room-id
            (merge room {is-active: (not (get is-active room))})
        )
        (ok true)
    )
)

;; Admin: Update room rewards
(define-public (update-room-rewards (room-id uint) (new-tokens uint) (new-nft bool))
    (let
        ((room (unwrap! (get-room room-id) err-not-found)))
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set rooms room-id
            (merge room {reward-tokens: new-tokens, reward-nft: new-nft})
        )
        (ok true)
    )
)