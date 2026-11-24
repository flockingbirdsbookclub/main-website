export type Book = {
  title: string;
  author: string;
  coverSrc?: string | null;
  purchaseUrl?: string | null;
  partnerStoreName?: string | null;
  tag?: string;
};

// One book on the shelf. Covers come in different shapes, so they are shown
// whole (contain), never cropped. With no cover file yet, the card draws a
// plain typographic cover instead of a TO DO box. The buy link only appears
// when there is somewhere real to send people.
export function BookCard({ book }: { book: Book }) {
  return (
    <div className="bk">
      <div className="bk-cover">
        {book.coverSrc ? (
          <img src={book.coverSrc} alt={`Cover of ${book.title} by ${book.author}`} loading="lazy" />
        ) : (
          <div className="bk-type" role="img" aria-label={`${book.title} by ${book.author}`}>
            <span className="bt">{book.title}</span>
            <span className="ba">{book.author}</span>
          </div>
        )}
      </div>
      <div className="t">{book.title}</div>
      <div className="a">{book.author}</div>
      {book.tag ? <div className="tag">{book.tag}</div> : null}
      {book.purchaseUrl ? (
        <a className="buy" href={book.purchaseUrl} target="_blank" rel="noopener noreferrer">
          Buy from {book.partnerStoreName ?? "our partner"}
        </a>
      ) : null}
    </div>
  );
}
