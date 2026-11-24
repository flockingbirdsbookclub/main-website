import { PhotoSlot } from "@/components/ui/PhotoSlot";

export type Book = {
  title: string;
  author: string;
  coverSrc?: string;
  purchaseUrl?: string | null;
  partnerStoreName?: string | null;
  tag?: string;
};

// Used for both the single "currently reading" treatment and the shelf
// grid. A missing purchaseUrl renders the same "TO DO" incompleteness as
// an empty photo slot, rather than a dead link or a silently absent button.
export function BookCard({ book }: { book: Book }) {
  return (
    <div className="bk">
      <PhotoSlot src={book.coverSrc} alt={`${book.title} cover`} ratio="r34" slotLabel="Book cover 3:4" />
      <div className="t">{book.title}</div>
      <div className="a">{book.author}</div>
      {book.tag ? <div className="tag">{book.tag}</div> : null}
      {book.purchaseUrl ? (
        <a className="buy" href={book.purchaseUrl} target="_blank" rel="noopener noreferrer">
          Buy from {book.partnerStoreName ?? "our partner"}
        </a>
      ) : (
        <span className="buy" data-pending>
          Buy link coming soon
        </span>
      )}
    </div>
  );
}
