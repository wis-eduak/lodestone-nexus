;; Title: LodeStone Nexus - Bitcoin-Anchored NFT Engine
;;
;; Summary:
;; A secure, governance-aware NFT primitive for tokenized real-world assets
;; on Stacks, featuring mint, transfer, stake/unstake with reward accrual,
;; burn controls, and redeemable governance balances.
;;
;; Description:
;; LodeStone Nexus provides a production-minded path to issue and manage
;; asset-backed NFTs that settle to Bitcoin via Stacks. The contract enforces
;; rigorous input validation, owner/authorization checks, and staking lifecycle
;; rules. Stakers earn governance credits proportional to asset value and time
;; staked, which can be redeemed. Read-only views expose metadata and balances.

;; Token definition
(define-non-fungible-token bitcoin-backed-nft (buff 32))

;; Constants & error codes
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-UNAUTHORIZED (err u1))
(define-constant ERR-NOT-FOUND (err u2))
(define-constant ERR-ALREADY-MINTED (err u3))
(define-constant ERR-INVALID-TRANSFER (err u4))
(define-constant ERR-STAKING-ERROR (err u5))
(define-constant ERR-INSUFFICIENT-BALANCE (err u6))
(define-constant ERR-INVALID-INPUT (err u7))
(define-constant ERR-INVALID-TOKEN (err u8))

;; Input validation helpers
(define-private (is-valid-token-id (token-id (buff 32)))
  (and
    (not (is-eq token-id 0x))
    (< (len token-id) u33)
  )
)

(define-private (is-valid-asset-type (asset-type (string-utf8 50)))
  (and
    (> (len asset-type) u0)
    (<= (len asset-type) u50)
  )
)

(define-private (is-valid-asset-value (asset-value uint))
  (and
    (> asset-value u0)
    (< asset-value u1000000)
  )
)

;; Storage maps
(define-map nft-metadata
  { token-id: (buff 32) }
  {
    owner: principal,
    asset-type: (string-utf8 50),
    asset-value: uint,
    mint-timestamp: uint,
    staking-start: (optional uint),
    staking-rewards: uint,
  }
)

(define-map nft-staking
  { token-id: (buff 32) }
  {
    staked-by: principal,
    stake-start-block: uint,
    total-staked-blocks: uint,
  }
)

(define-map governance-tokens
  principal
  uint
)

;; Read-only views
(define-read-only (get-nft-metadata (token-id (buff 32)))
  (begin
    (asserts! (is-valid-token-id token-id) none)
    (map-get? nft-metadata { token-id: token-id })
  )
)

(define-read-only (get-governance-tokens (user principal))
  (default-to u0 (map-get? governance-tokens user))
)

;; Mint: create an NFT with validated metadata
(define-public (mint-nft
    (token-id (buff 32))
    (asset-type (string-utf8 50))
    (asset-value uint)
  )
  (begin
    (asserts! (is-valid-token-id token-id) ERR-INVALID-TOKEN)
    (asserts! (is-valid-asset-type asset-type) ERR-INVALID-INPUT)
    (asserts! (is-valid-asset-value asset-value) ERR-INVALID-INPUT)

    (asserts! (is-none (nft-get-owner? bitcoin-backed-nft token-id))
      ERR-ALREADY-MINTED
    )

    (try! (nft-mint? bitcoin-backed-nft token-id tx-sender))

    (map-set nft-metadata { token-id: token-id } {
      owner: tx-sender,
      asset-type: asset-type,
      asset-value: asset-value,
      mint-timestamp: stacks-block-height,
      staking-start: none,
      staking-rewards: u0,
    })

    (ok token-id)
  )
)

;; Transfer: owner-checked transfer when not staked
(define-public (transfer-nft
    (token-id (buff 32))
    (sender principal)
    (recipient principal)
  )
  (let ((metadata (unwrap! (map-get? nft-metadata { token-id: token-id }) ERR-NOT-FOUND)))
    (asserts! (is-valid-token-id token-id) ERR-INVALID-TOKEN)
    (asserts! (not (is-eq sender recipient)) ERR-INVALID-TRANSFER)
    (asserts! (is-eq sender (get owner metadata)) ERR-UNAUTHORIZED)
    (asserts! (is-none (get staking-start metadata)) ERR-INVALID-TRANSFER)

    (try! (nft-transfer? bitcoin-backed-nft token-id sender recipient))

    (map-set nft-metadata { token-id: token-id }
      (merge metadata { owner: recipient })
    )

    (ok true)
  )
)

;; Stake: lock NFT to accrue governance rewards
(define-public (stake-nft (token-id (buff 32)))
  (let (
      (metadata (unwrap! (map-get? nft-metadata { token-id: token-id }) ERR-NOT-FOUND))
      (current-block stacks-block-height)
    )
    (asserts! (is-valid-token-id token-id) ERR-INVALID-TOKEN)
    (asserts! (is-eq tx-sender (get owner metadata)) ERR-UNAUTHORIZED)
    (asserts! (is-none (get staking-start metadata)) ERR-STAKING-ERROR)

    (map-set nft-metadata { token-id: token-id }
      (merge metadata { staking-start: (some current-block) })
    )

    (map-set nft-staking { token-id: token-id } {
      staked-by: tx-sender,
      stake-start-block: current-block,
      total-staked-blocks: u0,
    })

    (ok true)
  )
)

;; Unstake: release NFT and credit proportional rewards
;; reward = (asset-value * staked-blocks) / 10000
(define-public (unstake-nft (token-id (buff 32)))
  (let (
      (metadata (unwrap! (map-get? nft-metadata { token-id: token-id }) ERR-NOT-FOUND))
      (staking-info (unwrap! (map-get? nft-staking { token-id: token-id }) ERR-STAKING-ERROR))
      (current-block stacks-block-height)
      (stake-start (get stake-start-block staking-info))
      (staked-blocks (- current-block stake-start))
      (reward-calculation (/ (* (get asset-value metadata) staked-blocks) u10000))
    )
    (asserts! (is-valid-token-id token-id) ERR-INVALID-TOKEN)
    (asserts! (is-eq tx-sender (get staked-by staking-info)) ERR-UNAUTHORIZED)

    (map-set governance-tokens tx-sender
      (+ (default-to u0 (map-get? governance-tokens tx-sender))
        reward-calculation
      ))

    (map-set nft-metadata { token-id: token-id }
      (merge metadata {
        staking-start: none,
        staking-rewards: (+ (get staking-rewards metadata) reward-calculation),
      })
    )

    (map-delete nft-staking { token-id: token-id })

    (ok reward-calculation)
  )
)

;; Burn: destroy an NFT that is not staked
(define-public (burn-nft (token-id (buff 32)))
  (let ((metadata (unwrap! (map-get? nft-metadata { token-id: token-id }) ERR-NOT-FOUND)))
    (asserts! (is-valid-token-id token-id) ERR-INVALID-TOKEN)
    (asserts! (is-eq tx-sender (get owner metadata)) ERR-UNAUTHORIZED)
    (asserts! (is-none (get staking-start metadata)) ERR-INVALID-TRANSFER)

    (try! (nft-burn? bitcoin-backed-nft token-id tx-sender))

    (map-delete nft-metadata { token-id: token-id })

    (ok true)
  )
)

;; Governance redemption: zero out credited balance and return amount
(define-public (redeem-governance-tokens)
  (let ((available-tokens (default-to u0 (map-get? governance-tokens tx-sender))))
    (asserts! (> available-tokens u0) ERR-INSUFFICIENT-BALANCE)
    (map-set governance-tokens tx-sender u0)
    (ok available-tokens)
  )
)

;; Init signal
(print "LodeStone Nexus deployed: Bitcoin-anchored NFT engine with staking + governance")
