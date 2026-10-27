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

## Dashboard admin

After login, Admin is taken to a dashboard with separate entries for products,
categories, cashier PIN management, finance, and cashier shifts. The product
list includes active and inactive products. Admins can create, edit, and delete
products, including their name, price, product stock, category, active status, photo gallery, and
assignments to existing variant groups. The app assigns existing variant
groups; it does not create or edit the group definitions here.

The Flutter code follows those feature boundaries: dashboard navigation is in
`lib/features/dashboard`, product management is in `lib/features/products`,
category management is in `lib/features/categories`, and PIN management stays
in `lib/features/users`.

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
- `GET /api/variant-groups` to show the variant groups that can be assigned to
  a product.

Product stock is set through the `stock` field on the existing product create
and update endpoints, so this is a direct stock value update rather than a
stock-adjustment record. It is not the same as ingredient inventory stock,
whose separate endpoints and adjustment history are under `/api/inventories`.
Backend validation errors (for example, duplicate names) are surfaced in the
app. The Admin route is a Flutter UI decision; endpoint authorization remains
whatever the existing backend enforces.

The finance screen reads `GET /api/balances` and
`GET /api/balances/history`. Admins can record expenses through
`POST /api/balances/expense` or reconcile a payment-method balance through
`POST /api/balances/adjust`; the adjustment form submits the actual ending
balance, not the difference. Payment methods are loaded from the existing
`GET /api/payment-methods` endpoint, and the open-bill method is excluded.

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
final transaction totals.

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
