"use client";

import { useState } from "react";
import { PhotoSlot } from "@/components/ui/PhotoSlot";
import { Button } from "@/components/ui/Button";

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
  variant: string; // e.g. "Forest / M"
};

// Swatch colour mapping, ported from merch.html's COLOURS map.
const SWATCH_COLOURS: Record<string, string> = {
  Forest: "#0C4831",
  Navy: "#1C2B4A",
  Cream: "#F3EDE3",
  Black: "#201A16",
  Clay: "#C55B3D",
};

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
  }

  return (
    <div className="card">
      {product.photoSrc ? (
        <PhotoSlot src={product.photoSrc} alt={product.name} ratio="r1" slotLabel="" />
      ) : (
        <div className="ph r1">
          <span className="slotlabel">
            PHOTO SLOT
            <br />
            {product.name}
          </span>
        </div>
      )}

      <div className="num">{product.kind}</div>
      <h3>{product.name}</h3>
      <p>{product.blurb}</p>
      <p className="mono">
        {currency} {product.price.toLocaleString()}
      </p>

      {product.options.map((opt) => (
        <div key={opt.label}>
          <div className="mono">{opt.label}</div>
          <div style={{ display: "flex", gap: 8, flexWrap: "wrap", margin: "8px 0" }}>
            {opt.values.map((value) => {
              const isActive = selected[opt.label] === value;
              if (opt.swatch) {
                return (
                  <button
                    key={value}
                    type="button"
                    aria-label={value}
                    aria-pressed={isActive}
                    onClick={() => setSelected((s) => ({ ...s, [opt.label]: value }))}
                    style={{
                      width: 28,
                      height: 28,
                      borderRadius: "50%",
                      background: SWATCH_COLOURS[value] ?? "#999",
                      border: isActive ? "2px solid var(--gold)" : "2px solid var(--rule)",
                      cursor: "pointer",
                    }}
                  />
                );
              }
              return (
                <button
                  key={value}
                  type="button"
                  aria-pressed={isActive}
                  onClick={() => setSelected((s) => ({ ...s, [opt.label]: value }))}
                  className="btn btn-line"
                  style={{ padding: "6px 14px", minHeight: "auto" }}
                >
                  {value}
                </button>
              );
            })}
          </div>
        </div>
      ))}

      <div style={{ display: "flex", alignItems: "center", gap: 12, margin: "12px 0" }}>
        <button type="button" onClick={() => setQty((q) => Math.max(1, q - 1))} aria-label="Decrease quantity">
          −
        </button>
        <span>{qty}</span>
        <button type="button" onClick={() => setQty((q) => q + 1)} aria-label="Increase quantity">
          +
        </button>
      </div>

      <Button variant="dark" onClick={handleAdd}>
        Add to order
      </Button>

      {product.partnerStoreUrl ? (
        <a
          className="btn-line"
          style={{ display: "block", marginTop: 8, textAlign: "center" }}
          href={product.partnerStoreUrl}
          target="_blank"
          rel="noopener noreferrer"
        >
          Order from partner store
        </a>
      ) : null}
    </div>
  );
}
