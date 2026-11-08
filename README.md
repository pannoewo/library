# Library

Rails API for managing books, readers, and loans.

## Run

Requires Docker Desktop. Start the app and PostgreSQL with:

```sh
docker compose up --build
```

Open <http://localhost:3000>. Sample data is loaded into the development database
on first startup. Emails are saved in `tmp/mails/` and are not sent.

## API

Base URL: `http://localhost:3000`. Endpoints accept and return JSON.

| Method | Path | Description |
| --- | --- | --- |
| `GET` | `/books` | List books with availability |
| `GET` | `/books/:id` | Show a book and its borrowing history |
| `POST` | `/books` | Create a book |
| `DELETE` | `/books/:id` | Delete a book |
| `POST` | `/loans` | Borrow a book |
| `PATCH` | `/books/:book_id/return` | Return a book |

Create a book with a six-digit serial number, title, and author:

```sh
curl -X POST http://localhost:3000/books \
	-H 'Content-Type: application/json' \
	-d '{"book":{"serial_number":"900004","title":"New Book","author":"A. Writer"}}'
```

Borrowing requires existing book and reader IDs. `borrowed_at` is set to the
current time; `due_at` is set 30 days later. Replace the IDs with existing ones:

```sh
curl -X POST http://localhost:3000/loans \
	-H 'Content-Type: application/json' \
	-d '{"loan":{"book_id":1,"reader_id":1}}'
```

The API has no reader-list endpoint. Returning a book needs no request body:

```sh
curl -X PATCH http://localhost:3000/books/1/return
```

Successful creates return `201`; deleting returns `204`. Invalid data returns
`422`, and conflicts such as borrowing an unavailable book return `409`.

## Reminders

In production, reminders run once daily at 08:00 for loans due in 3 days or
that day. Each reminder is sent only once per loan. In development, real emails
are not sent; `.eml` files are written to `tmp/mails/` instead.

## Tests

```sh
docker compose exec web bin/rails test
```
