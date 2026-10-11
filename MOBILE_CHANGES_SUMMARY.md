# Mobile changes 

## 1. App Promo overlay
- Fetches active promo from API and shows a full-screen overlay on main navigation
- User can dismiss; dismiss is stored by **promo id**, so a new published promo shows again
- New files: `app_promo_model.dart`, `app_promo_provider.dart`, `app_promo_overlay.dart`
- Wired in `main_navigation_screen.dart` + API URL / translations

## 2. Multi-lottery payment fix
- Paying one lottery then another no longer fails with “Something went wrong”
- Payment payload is built **per lottery / equberUser**, and only sends items with `paidAmount > 0`
- Touches: `my_ekub_detail_screen.dart`, `my_other_ekubs.dart`, `payment_arrangement_screen.dart`, `payment_screen.dart`

## 3. Fully paid lottery lock (correct threshold)
- A lottery locks only when that spot is fully paid for the whole equb (e.g. **105/105**)
- Uses total equb rounds (`numberOfEqubers` / `ekubCycle`), **not** how many lotteries the user joined
- Fully paid spots: amount locked at **0**, **Paid** badge, no +/-
- Other lotteries stay payable

## 4. Cap “+” so you can’t overpay a lottery
- Each lottery has a max remaining amount: `(round × total rounds) − already paid`
- Example: 50/105 at 10 ETB → max **550**; **+** disables at the cap
- Last step can snap to the exact remaining amount if less than one full round

## 5. Transaction History vs Equb History
- Transaction History **hides payments for completed equbs**
- Those stay on **Equb History** (Completed)
- Model helper: `withoutCompletedEqubs()`; equb chips also exclude `status == completed`
- Added lang key: `noTransactionHistory`

## 6. Small compile / cleanup fixes
- Removed duplicate `numberOfEqubers` in `my_other_ekubs.dart`
- Added missing `AppKeys.noTransactionHistory`

---

## Main files to review

| Area | Files |
|------|--------|
| Promo | `app_promo_*.dart`, `app_promo_overlay.dart`, `main_navigation_screen.dart` |
| Payment | `my_ekub_detail_screen.dart`, `my_other_ekubs.dart`, `payment_arrangement_screen.dart`, `payment_screen.dart` |
| History | `transaction_history.dart`, `transaction_history_model.dart` |

---

## Suggested test plan

- [ ] Promo shows once, dismisses, and shows again only after a new promo id is published
- [ ] Equb with 3 lotteries: pay one, then another — both succeed
- [ ] 105/105 locked; 50/105 and 0/105 still payable
- [ ] On 50/105, **+** stops at remaining total (can’t go past 105)
- [ ] Transaction History has no completed-equb payments; Equb History Completed still does

---

## Notes

- The working tree may also include other diffs (e.g. `home_screen.dart`, Android/Gradle, `pubspec`). Call those out separately if they aren’t part of this payment/promo work.
- OTP 4-digit change was **backend only**, not mobile.
