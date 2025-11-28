import React from "react";
import "./Footer.css";

function Footer({ subtotal, onCheckout, toggleCart, toggleUser }) {
  return (
    <div className="footer">
      <button className="footer-btn">Total: ${subtotal.toFixed(2)}</button>
      <button className="footer-btn" onClick={onCheckout}>
        Pagar
      </button>
      <button className="footer-btn" onClick={toggleCart}>
        Carrito
      </button>
      <button className="footer-btn" onClick={toggleUser}>
        Usuario
      </button>
    </div>
  );
}

export default Footer;
