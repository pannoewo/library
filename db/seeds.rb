if Rails.env.development?
  books_data = [
    [ "900001", "The Quiet Observatory", "Mira Stone" ],
    [ "900002", "Maps of the Inland Sea", "Jonas Reed" ],
    [ "900003", "A Clockwork Orchard", "Lena Hart" ]
  ]

  books = books_data.map do |serial_number, title, author|
    Book.find_or_create_by!(serial_number: serial_number) do |book|
      book.title = title
      book.author = author
    end
  end

  readers_data = [
    [ "910001", "Anna Nowak", "anna.nowak@example.com" ],
    [ "910002", "Jan Kowalski", "jan.kowalski@example.com" ],
    [ "910003", "Maria Zielinska", "maria.zielinska@example.com" ],
    [ "910004", "Piotr Wisniewski", "piotr.wisniewski@example.com" ]
  ]

  readers = readers_data.map do |library_card_number, full_name, email|
    Reader.find_or_create_by!(library_card_number: library_card_number) do |reader|
      reader.full_name = full_name
      reader.email = email
    end
  end

  active_loans = [
    [ 0, 0 ],
    [ 1, 1 ],
    [ 2, 2 ]
  ]

  active_loans.each do |book_index, reader_index|
    Loan.find_or_create_by!(book: books.fetch(book_index), returned_at: nil) do |loan|
      loan.reader = readers.fetch(reader_index)
      loan.borrowed_at = 5.days.ago
    end
  end

  historical_loans = [
    [ 0, 1, Time.zone.local(2025, 1, 10, 12) ],
    [ 0, 3, Time.zone.local(2025, 2, 20, 12) ],
    [ 1, 0, Time.zone.local(2025, 3, 15, 12) ]
  ]

  historical_loans.each do |book_index, reader_index, borrowed_at|
    Loan.find_or_create_by!(
      book: books.fetch(book_index),
      reader: readers.fetch(reader_index),
      borrowed_at: borrowed_at
    ) do |loan|
      loan.returned_at = borrowed_at + 30.days
    end
  end
end
