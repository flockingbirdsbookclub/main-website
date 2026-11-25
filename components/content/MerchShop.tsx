"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import { MerchProductCard, type MerchProduct, type MerchSelection } from "@/components/content/MerchProductCard";
import { buildWhatsAppLink } from "@/lib/whatsapp";
import { recordSubmission } from "@/lib/netlifyForms";

export type MerchConfig = {
  whatsapp: string;
  depositPct: number;
  closesDate: string; // ISO date
  currency: string;
  partnerStoreUrl?: string | null;
};

type OrderLine = MerchSelection & { key: string };

function money(currency: string, n: number) {
  return `${currency} ${n.toLocaleString("en-KE")}`;
}

function closingLabel(closesDate: string) {
  const d = new Date(`${closesDate}T23:59:59`);
  const label = d.toLocaleDateString("en-GB", { day: "numeric", month: "long" });
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const left = Math.round((d.getTime() - today.getTime()) / 86400000);
  const daysText =
    left > 1 ? `· ${left} days left` : left === 1 ? "· last day tomorrow" : left === 0 ? "· closing today" : "· closed";
  return { label, daysText };
}

export function MerchShop({ products, config }: { products: MerchProduct[]; config: MerchConfig }) {
  const [order, setOrder] = useState<OrderLine[]>([]);
  const [fields, setFields] = useState({ name: "", phone: "", flock: "", mpesaCode: "" });
  const [flashKey, setFlashKey] = useState<string | null>(null);
  const [copyLabel, setCopyLabel] = useState("Or copy the order as text");
  const cardRefs = useRef<Record<string, HTMLDivElement | null>>({});
  // One timer each for the card flash and the copy label, so a quick second
  // click restarts the feedback instead of an older timer ending it early.
  const flashTimer = useRef<number | undefined>(undefined);
  const copyTimer = useRef<number | undefined>(undefined);
  useEffect(
    () => () => {
      window.clearTimeout(flashTimer.current);
      window.clearTimeout(copyTimer.current);
    },
    []
  );

  const { label: closesLabel, daysText } = useMemo(() => closingLabel(config.closesDate), [config.closesDate]);

  const count = order.reduce((n, l) => n + l.qty, 0);
  const total = order.reduce((n, l) => n + l.qty * l.price, 0);
  const deposit = Math.round((total * config.depositPct) / 100);

  function handleAdd(selection: MerchSelection) {
    const key = `${selection.productId}|${selection.variant}`;
    setOrder((prev) => {
      const existing = prev.find((l) => l.key === key);
      if (existing) {
        return prev.map((l) => (l.key === key ? { ...l, qty: l.qty + selection.qty } : l));
      }
      return [...prev, { ...selection, key }];
    });
  }

  function removeLine(key: string) {
    setOrder((prev) => prev.filter((l) => l.key !== key));
  }

  function goToProduct(productId: string) {
    const el = cardRefs.current[productId];
    if (!el) return;
    el.scrollIntoView({ behavior: "smooth", block: "center" });
    setFlashKey(productId);
    window.clearTimeout(flashTimer.current);
    flashTimer.current = window.setTimeout(() => setFlashKey(null), 1200);
  }

  function summaryText() {
    const m = (n: number) => money(config.currency, n);
    const lines = order
      .map((l) => `\u2022 ${l.qty} \u00D7 ${l.name} (${l.variant}) \u00B7 ${m(l.qty * l.price)}`)
      .join("\n");
    return (
      "FLOCKING BIRDS MERCH PREORDER\n\n" +
      lines +
      `\n\nItems: ${count}` +
      `\nTotal: ${m(total)}` +
      `\nDeposit paid: ${m(deposit)}` +
      `\nBalance on collection: ${m(total - deposit)}` +
      `\n\nName: ${fields.name.trim() || "(name not given)"}` +
      `\nPhone: ${fields.phone.trim() || "(phone not given)"}` +
      `\nFlock: ${fields.flock || "(flock not given)"}` +
      `\nM-Pesa code: ${fields.mpesaCode.trim() || "(will send after paying)"}`
    );
  }

  // A structured row per order, so the size tally for the printer is one CSV
  // export rather than sixty WhatsApp messages read by hand. Saved to Netlify
  // Forms (form "merch-preorder", defined in public/__forms.html).
  function record() {
    recordSubmission("merch-preorder", {
      name: fields.name.trim(),
      phone: fields.phone.trim(),
      flock: fields.flock,
      mpesa_code: fields.mpesaCode.trim(),
      items: String(count),
      total: String(total),
      deposit: String(deposit),
      order: order.map((l) => `${l.qty} x ${l.name} (${l.variant})`).join(" | "),
    });
  }

  function handleSend() {
    record();
    window.open(buildWhatsAppLink(summaryText(), config.whatsapp), "_blank", "noopener");
  }

  async function handleCopy() {
    record();
    try {
      await navigator.clipboard.writeText(summaryText());
      setCopyLabel("Copied. Paste it to us on WhatsApp.");
    } catch {
      setCopyLabel("Could not copy. Screenshot your order instead.");
    }
    window.clearTimeout(copyTimer.current);
    copyTimer.current = window.setTimeout(() => setCopyLabel("Or copy the order as text"), 3000);
  }

  return (
    <div className="merch-page">
      <header className="head">
        <div className="wrap head-in">
          <h1>Merch, before it exists</h1>
          <p className="sub">
            We print to order, so we only make what the flock actually wants. Reserve your size
            now with a deposit and collect it at the Social on 3 October.
          </p>
          <div className="closes">
            Preorders close <b>{closesLabel}</b> <span>{daysText}</span>
          </div>
        </div>
      </header>

      <main>
        <section className="wrap how">
          <h2>How the preorder works</h2>
          <p className="lede">
            Nothing is in stock yet. That is the point. Every item on this page gets made only if
            enough of the flock reserves one, which keeps the prices down and means we never sit on
            forty unsold larges.
          </p>
          <div className="msteps">
            <div className="mstep">
              <div className="n">STEP ONE</div>
              <h3>Pick and reserve</h3>
              <p>Choose your design, colour and size, and add it to your order. Add as many as you like.</p>
            </div>
            <div className="mstep">
              <div className="n">STEP TWO</div>
              <h3>Pay the deposit</h3>
              <p>Send the deposit to our M-Pesa number and paste the confirmation code into your order. That is what holds your size.</p>
            </div>
            <div className="mstep">
              <div className="n">STEP THREE</div>
              <h3>Collect on 3 October</h3>
              <p>Pay the balance and pick it up at the BookClub Social. Not coming? Tell us and we will arrange it.</p>
            </div>
          </div>
        </section>

        <section className="wrap shop" id="shop">
          <div className="shop-head">
            <h2>The first drop</h2>
            <p className="note">Printed in Nairobi · limited run · collect on 3 October</p>
          </div>
          <div className="grid">
            {products.map((p) => (
              <div
                key={p.id}
                ref={(el) => {
                  cardRefs.current[p.id] = el;
                }}
                className={flashKey === p.id ? "flash" : ""}
              >
                <MerchProductCard product={p} currency={config.currency} onAdd={handleAdd} />
              </div>
            ))}
          </div>
        </section>

        <section className="wrap order" id="order">
          <h2>Your order</h2>
          <div className="panel">
            {order.length === 0 ? (
              <p className="empty">Nothing reserved yet. Pick something from the drop above.</p>
            ) : (
              <>
                <ul className="lines">
                  {order.map((line) => (
                    <li className="line" key={line.key}>
                      <button className="thumb" type="button" onClick={() => goToProduct(line.productId)}>
                        {line.photoSrc ? (
                          <img src={line.photoSrc} alt="" />
                        ) : (
                          <span className="tk">{line.kind}</span>
                        )}
                      </button>
                      <div>
                        <button className="nm" type="button" onClick={() => goToProduct(line.productId)}>
                          {line.qty}× {line.name}
                        </button>
                        <div className="vr">{line.variant}</div>
                      </div>
                      <span className="amt">{money(config.currency, line.qty * line.price)}</span>
                      <button className="rm" type="button" onClick={() => removeLine(line.key)}>
                        Remove
                      </button>
                    </li>
                  ))}
                </ul>
                <div className="totals">
                  <div className="tl">
                    <span>Items</span>
                    <b>{count}</b>
                  </div>
                  <div className="tl">
                    <span>Order total</span>
                    <b>{money(config.currency, total)}</b>
                  </div>
                  <div className="tl big">
                    <span>Deposit to reserve</span>
                    <b>{money(config.currency, deposit)}</b>
                  </div>
                </div>
                <div className="dep">
                  Pay <b>{money(config.currency, deposit)}</b> now ({config.depositPct}% deposit) to
                  reserve. Balance due on collection.
                </div>
                <div className="fields">
                  <div className="f">
                    <label htmlFor="o-name">YOUR NAME</label>
                    <input
                      id="o-name"
                      type="text"
                      autoComplete="name"
                      placeholder="First and last name"
                      value={fields.name}
                      onChange={(e) => setFields((f) => ({ ...f, name: e.target.value }))}
                    />
                  </div>
                  <div className="f">
                    <label htmlFor="o-phone">PHONE NUMBER</label>
                    <input
                      id="o-phone"
                      type="tel"
                      autoComplete="tel"
                      placeholder="07XX XXX XXX"
                      value={fields.phone}
                      onChange={(e) => setFields((f) => ({ ...f, phone: e.target.value }))}
                    />
                  </div>
                  <div className="f">
                    <label htmlFor="o-flock">YOUR FLOCK</label>
                    <select
                      id="o-flock"
                      value={fields.flock}
                      onChange={(e) => setFields((f) => ({ ...f, flock: e.target.value }))}
                    >
                      <option value="">Select your flock</option>
                      <option>Kiambu Road</option>
                      <option>Thika Road Bears</option>
                      <option>Online flock</option>
                      <option>Not a member yet</option>
                    </select>
                  </div>
                  <div className="f">
                    <label htmlFor="o-code">M-PESA CODE</label>
                    <input
                      id="o-code"
                      type="text"
                      placeholder="Paste it after you pay"
                      value={fields.mpesaCode}
                      onChange={(e) => setFields((f) => ({ ...f, mpesaCode: e.target.value }))}
                    />
                  </div>
                </div>
                <div className="sendwrap">
                  <button className="send" type="button" onClick={handleSend}>
                    Send my order on WhatsApp
                  </button>
                  <p className="sendnote">
                    Opens WhatsApp with your order already written out. You can pay the deposit
                    before or after sending, just remember to send us the code.
                    <br />
                    <button className="alt" type="button" onClick={handleCopy}>
                      {copyLabel}
                    </button>
                  </p>
                </div>
              </>
            )}
          </div>
          {config.partnerStoreUrl ? (
            <p className="note" style={{ marginTop: 16 }}>
              Prefer to order straight away?{" "}
              <a href={config.partnerStoreUrl} target="_blank" rel="noopener noreferrer">
                Order from our partner store
              </a>
              .
            </p>
          ) : null}
        </section>

        <section className="wrap faq">
          <h2>Before you ask</h2>
          <div className="qa">
            <h3>Why a deposit and not the full price?</h3>
            <p>
              A deposit is what tells the printer this order is real, and it keeps the risk small
              for you. You pay the balance when you collect and can see the thing in your hands.
            </p>
          </div>
          <div className="qa">
            <h3>What if my size is wrong?</h3>
            <p>
              Come and try before you pay the balance. We will hold sizes back where we can, but on
              a print-to-order run there is no warehouse to swap from, so choose carefully.
            </p>
          </div>
          <div className="qa">
            <h3>Can I order if I am not a member?</h3>
            <p>Yes. The Social on 3 October is open to everyone, and so is the merch.</p>
          </div>
          <div className="qa">
            <h3>What happens if not enough people order?</h3>
            <p>
              If an item does not hit its minimum run we will tell you and refund the deposit in
              full. No item gets quietly dropped.
            </p>
          </div>
          <div className="qa">
            <h3>I cannot make it on 3 October.</h3>
            <p>Say so when you send your order and we will sort out collection or delivery with you directly.</p>
          </div>
        </section>
      </main>

      <div className={["orderbar", count > 0 ? "on" : ""].filter(Boolean).join(" ")}>
        <div className="info">
          <b>{money(config.currency, total)}</b>
          <span>{count} items reserved</span>
        </div>
        <a href="#order">Review order</a>
      </div>
    </div>
  );
}
