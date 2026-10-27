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

## Product catalog and cart

An active shift provides a link to the cashier catalog. The catalog reads
`GET /api/products` and `GET /api/categories`, filters inactive entries, and
supports search and category filtering. Products with variant groups require
their configured selections before they can be added to the cart. The cart
supports quantity changes and displays an estimated subtotal; checkout and
transaction submission are not included yet, and the backend remains the
source of truth for transaction totals.

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
