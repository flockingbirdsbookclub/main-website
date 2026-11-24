export type Partner = {
  name: string;
  description: string;
  logoSrc?: string | null;
  url?: string | null;
};

// The legacy #partners section had zero logos and zero links on all 4
// partners — just plain text boxes. This wraps in <a> when a url exists;
// otherwise it renders inert with the same TO DO treatment as an empty
// photo slot, since not every partner will have a link from day one.
export function PartnerCard({ partner }: { partner: Partner }) {
  const content = (
    <>
      {partner.logoSrc ? (
        <img src={partner.logoSrc} alt={partner.name} />
      ) : (
        <div>
          <div className="t">{partner.name}</div>
          <div className="s">{partner.description}</div>
        </div>
      )}
    </>
  );

  if (partner.url) {
    return (
      <a className="plogo" href={partner.url} target="_blank" rel="noopener noreferrer">
        {content}
      </a>
    );
  }

  return (
    <div className="plogo" data-pending>
      {content}
    </div>
  );
}
