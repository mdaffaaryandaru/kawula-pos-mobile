# Kawula POS Mobile

Flutter client for the Kawula POS API.

## Authentication

Authentication uses the existing backend endpoints:

- `POST /api/auth/login` to exchange an email and password for an access token.
- `GET /api/auth/me` with `Authorization: Bearer <access_token>` to restore and
  verify the current user session.

The token is stored using platform secure storage. Logout removes it locally;
the backend does not expose a logout endpoint.

## Shift kasir

After login, the app checks `GET /api/shifts/active`. An active shift is shown
with its outlet, opening cash, expected cash, sales, and transaction count. If
there is no active shift, the cashier can check available cash through
`GET /api/balances/cash-availability` and open one with
`POST /api/shifts/open` using the cashier PIN and starting cash. The backend
remains the source of truth for PIN validation and cash availability.

The active shift can be closed with `POST /api/shifts/:id/close`. The close
form submits actual cash and optional notes; it requires a four-digit PIN for
cashiers, matching the backend rule. A confirmation step shows expected cash,
actual cash, and the estimated difference before submission.
The POS catalog keeps the active shift visible with its outlet, start time, and
opening cash. Its shift action returns a cashier to shift controls; for Admin,
it opens the existing shift-monitoring screen where force-close is available.
Opening a shift still uses the existing available-cash and PIN validation flow.

## Dashboard admin

After login, Admin is taken to a mobile navigation shell with Dashboard,
Kasir, and Manajemen destinations. The Manajemen destination links to
transaction reports, finance, shift monitoring, products, variant groups,
categories, store settings, and cashier PIN management; it also contains the
logout action. The Kasir destination checks
the current shift through the existing shift endpoints; if there is no active
shift, it shows the existing shift-opening flow, and if a shift is active, it
opens the existing product catalog and checkout flow. Shift monitoring and
catalog management are available through Manajemen. The dashboard shows shift
status and summary without management shortcuts.
The dashboard shows active-shift status and the shift's sales and transaction
count from `GET /api/shifts/active`; it does not label these values as daily
totals or invent dashboard statistics when the endpoint has no active shift.
The Kawula logo is bundled from `assets/images/logo.jpg`.

The dashboard has separate entries for products, categories, cashier PIN
management, finance, and cashier shifts. The product
list includes active and inactive products. Admins can create, edit, and delete
products, including their name, price, product stock, category, active status,
photo gallery, and assignments to variant groups. Variant groups are managed
as a separate feature and can be created, edited, and deleted from the product
management screen, including their options, selection limits, price adjustments,
and optional inventory recipes.

The Flutter code follows those feature boundaries: dashboard navigation is in
`lib/features/dashboard`, product management is in `lib/features/products`,
variant group management is in `lib/features/variant_groups`, category
management is in `lib/features/categories`, and PIN management stays in
`lib/features/users`.

Product photos are selected from the device and uploaded to
`POST /api/products/upload` as multipart files under the `images` field. The
backend accepts up to five JPG/JPEG/PNG/WEBP/GIF files per request, with a
maximum size of 2 MB per file. The returned relative URLs are saved to the
product `images` array, with one photo marked `is_main`; `image_url` is set to
the selected main photo URL to match the backend product schema.

The category screen supports create, edit, activate/deactivate, and delete
operations. These screens use the existing authenticated endpoints:

- `GET /api/products`, `POST /api/products`, `PATCH /api/products/:id`, and
  `DELETE /api/products/:id`.
- `GET /api/categories`, `POST /api/categories`, `PATCH /api/categories/:id`,
  and `DELETE /api/categories/:id`.
- `GET /api/variant-groups`, `POST /api/variant-groups`,
  `PATCH /api/variant-groups/:id`, and `DELETE /api/variant-groups/:id`.
- `GET /api/inventories` and `GET /api/product-units` provide the existing
  inventory and unit choices for optional variant recipes. Recipes submit
  `inventory_id`, `quantity`, `unit_id`, and `conversion_factor`.

The variant-group editor follows backend constraints: each group needs at
least one option, selection counts must be valid, and optional recipes use
existing inventory and product-unit IDs. The mobile UI prevents deleting a
group while products returned by the API still reference it.

Product stock is set through the `stock` field on the existing product create
and update endpoints, so this is a direct stock value update rather than a
stock-adjustment record. It is not the same as ingredient inventory stock,
whose separate endpoints and adjustment history are under `/api/inventories`.
Backend validation errors (for example, duplicate names) are surfaced in the
app. The Admin route is a Flutter UI decision; endpoint authorization remains
whatever the existing backend enforces.

The Admin dashboard includes store settings backed by `GET /api/store-settings`
and `PATCH /api/store-settings`. It edits store name, address, logo URL, tax
percentage, service charge, and automatic shift-close settings. Store logos
upload through `POST /api/store-settings/upload-logo` using the `logo`
multipart field; supported files are JPG/JPEG/PNG/WEBP/GIF up to 2 MB.

## Riwayat transaksi dan open bill

The transaction screen reads `GET /api/transactions`, whose results depend on
the authenticated role as defined by the backend. It separates pending open
bills from the complete result set, and displays status, amount, item details,
payment method, and payment/change values when provided. Open bills can be
settled through `PATCH /api/transactions/:id/pay` with the selected active
payment method, paid amount, and cashier PIN. Cash payments are checked against
the transaction total before submission; the server remains authoritative.

The finance screen reads `GET /api/balances` and
`GET /api/balances/history`. Admins can record expenses through
`POST /api/balances/expense` or reconcile a payment-method balance through
`POST /api/balances/adjust`; the adjustment form submits the actual ending
balance, not the difference. Its total is the sum of the returned balance
accounts, and history amounts retain the sign supplied by the backend
(expenses appear as deductions). Payment methods are loaded from the existing
`GET /api/payment-methods` endpoint, and the open-bill method is excluded.

The Admin dashboard also provides a transaction report using
`GET /api/transactions` and `GET /api/balances/history`. Date range and search
filters are applied in the app because the transaction endpoint does not expose
date-filter parameters. Completed sales, pending open bills, recorded COGS,
expenses, cancellations, and refunds are shown separately; pending, cancelled,
and refunded transactions are not counted as completed sales. The report can be
shared as a CSV file. It does not estimate net profit.

The cashier shift screen reads `GET /api/shifts` with an optional status filter.
Opening a shift shows its detail and transactions using `GET /api/shifts/:id`.
An Admin can force-close an open shift with `POST /api/shifts/:id/force-close`,
submitting the actual cash and optional notes. The app displays expected cash
and estimated difference and asks for confirmation before sending the request.
These are Flutter Admin dashboard routes only; the backend was not changed,
and server-side authorization remains authoritative.

## Product catalog and cart

An active shift provides a link to the cashier catalog. The catalog reads
`GET /api/products` and `GET /api/categories`, filters inactive entries, and
supports search and category filtering. Products with variant groups require
their configured selections before they can be added to the cart. The cart
supports quantity changes, item notes, and an estimated subtotal. Checkout
loads active payment methods and store settings, submits completed or open-bill
transactions through the existing transaction endpoints, and displays a
receipt from the backend response. The backend remains the source of truth for
final transaction totals. Cashiers can optionally search active members by name
or phone through `GET /api/members?search=...` and attach the selected
`member_id` to checkout; leaving the member field empty omits `member_id`.
Completed sales award a stamp immediately, while open bills award it when
settled, matching the backend behavior.

## Environment configuration

Copy `.env.example` to `.env` and set the API URL for each platform. The local
`.env` file is loaded by Flutter and is excluded from Git. Android emulator
uses `http://10.0.2.2:3001/api`; web and desktop use
`http://localhost:3001/api` by default.

```shell
flutter run
```

For another device or environment, change the relevant `API_BASE_URL_*` value
to a backend address reachable from that platform. You can also override all
platform URLs at build time with
`--dart-define=API_BASE_URL=https://your-api-host/api`.

Do not put passwords, JWT signing secrets, database credentials, or other
server-side secrets in this file. Flutter assets, including `.env`, are bundled
with the application and can be extracted. The API base URL is configuration,
not a secret. Use HTTPS for production.
