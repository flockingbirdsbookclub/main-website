"use client";

import { useEffect, useRef, useState } from "react";

export type MerchOption = {
  label: string;
  swatch?: boolean;
  values: string[];
};

export type MerchProduct = {
  id: string;
  kind: string;
  name: string;
  price: number;
  photoSrc?: string | null;
  blurb: string;
  options: MerchOption[];
  partnerStoreUrl?: string | null;
};

export type MerchSelection = {
  productId: string;
  name: string;
  kind: string;
  price: number;
  photoSrc?: string | null;
  qty: number;
  variant: string; // e.g. "forest / M"
};

// Swatch colour values, ported verbatim from merch.html's COLOURS map.
const SWATCH_COLOURS: Record<string, string> = {
  forest: "#0C4831",
  navy: "#1F2E45",
  cream: "#EFE6D6",
  black: "#211E1B",
  clay: "#B4634A",
};

function titled(s: string) {
  return s.charAt(0).toUpperCase() + s.slice(1);
}

export function MerchProductCard({
  product,
  currency,
  onAdd,
}: {
  product: MerchProduct;
  currency: string;
  onAdd: (selection: MerchSelection) => void;
}) {
  const [selected, setSelected] = useState<Record<string, string>>(() =>
    Object.fromEntries(product.options.map((opt) => [opt.label, opt.values[0]]))
  );
  const [qty, setQty] = useState(1);
  const [justAdded, setJustAdded] = useState(false);
  // One timer at a time: a second tap restarts the "Added" flash instead of
  // an older timer cutting it short. Cleared on unmount.
  const addedTimer = useRef<number | undefined>(undefined);
  useEffect(() => () => window.clearTimeout(addedTimer.current), []);

  function handleAdd() {
    const variant = product.options.map((opt) => selected[opt.label]).join(" / ");
    onAdd({
      productId: product.id,
      name: product.name,
      kind: product.kind,
      price: product.price,
      photoSrc: product.photoSrc,
      qty,
      variant,
    });
    setJustAdded(true);
    window.clearTimeout(addedTimer.current);
    addedTimer.current = window.setTimeout(() => setJustAdded(false), 1600);
  }

  return (
    <div className="product-card">
      <div className="product-photo">
        {product.photoSrc ? (
          <img src={product.photoSrc} alt={product.name} />
        ) : (
          <span className="slotlabel">
            PHOTO SLOT
            <br />
            {product.name}
          </span>
        )}
        <span className="kind">{product.kind}</span>
      </div>

      <div className="product-body">
        <div className="row1">
          <h3>{product.name}</h3>
          <span className="price">
            {currency} {product.price.toLocaleString()}
          </span>
        </div>
        <p className="blurb">{product.blurb}</p>

        {product.options.map((opt) => (
          <div className="opt" key={opt.label}>
            <div className="lab">{opt.label}</div>
            <div className="choices">
              {opt.values.map((value) => {
                const isActive = selected[opt.label] === value;
                if (opt.swatch) {
                  return (
                    <button
                      key={value}
                      type="button"
                      className="sw"
                      aria-label={titled(value)}
                      aria-pressed={isActive}
                      style={{ background: SWATCH_COLOURS[value] ?? "#999" }}
                      onClick={() => setSelected((s) => ({ ...s, [opt.label]: value }))}
                    />
                  );
                }
                return (
                  <button
                    key={value}
                    type="button"
                    className="chip"
                    aria-pressed={isActive}
                    onClick={() => setSelected((s) => ({ ...s, [opt.label]: value }))}
                  >
                    {value}
                  </button>
                );
              })}
            </div>
            {opt.swatch ? <div className="swname">{titled(selected[opt.label])}</div> : null}
          </div>
        ))}

        <div className="addrow">
          <div className="stepper">
            <button type="button" onClick={() => setQty((q) => Math.max(1, q - 1))} aria-label="Decrease quantity">
              −
            </button>
            <span>{qty}</span>
            <button type="button" onClick={() => setQty((q) => q + 1)} aria-label="Increase quantity">
              +
            </button>
          </div>
          <button type="button" className={["add", justAdded ? "done" : ""].join(" ")} onClick={handleAdd}>
            {justAdded ? "Added ✓" : "Add to order"}
          </button>
        </div>

        {product.partnerStoreUrl ? (
          <a className="addmore" href={product.partnerStoreUrl} target="_blank" rel="noopener noreferrer">
            Or order from our partner store
          </a>
        ) : null}
      </div>
    </div>
  );
}
