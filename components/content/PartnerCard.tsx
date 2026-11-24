export type Partner = {
  name: string;
  role: string; // one line, e.g. "Bookshop · 10% off for members"
  imageSrc: string;
  url: string;
};

// One partner: their spotlight card (already in the Flocking Birds style),
// their name and what they do for the flock. The whole card links out.
// Only real partners go in the list; an empty list hides the grid.
export function PartnerCard({ partner }: { partner: Partner }) {
  return (
    <a className="pcard" href={partner.url} target="_blank" rel="noopener noreferrer">
      <img src={partner.imageSrc} alt={`${partner.name} spotlight card`} loading="lazy" />
      <span className="pc-body">
        <span className="pc-name">{partner.name}</span>
        <span className="pc-role">{partner.role}</span>
      </span>
    </a>
  );
}
