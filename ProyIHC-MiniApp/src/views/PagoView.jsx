// src/views/PagoView.jsx
import React, { useState } from "react";
import "./PagoView.css";

function PagoView({ cartItems, navigate }) {
  const [metodo, setMetodo] = useState("efectivo");

  const subtotal = cartItems.reduce(
    (acc, item) => acc + item.price * item.quantity,
    0
  );
  const delivery = 2;
  const discount = subtotal * 0.002;
  const total = subtotal + delivery - discount;

  return (
    <div className="pago-container">
      <h2> Método de Pago</h2>

      <div className="pago-resumen">
        {cartItems.map((item) => (
          <p key={item.id}>
            {item.title} ({item.quantity}) — ${item.price * item.quantity}
          </p>
        ))}
        <p>Delivery: ${delivery}</p>
        <p>Descuento: -${discount.toFixed(2)}</p>
        <h3>Total a pagar: ${total.toFixed(2)}</h3>
      </div>

      <div className="pago-opciones">
        <label>
          <input
            type="radio"
            name="metodo"
            value="efectivo"
            checked={metodo === "efectivo"}
            onChange={(e) => setMetodo(e.target.value)}
          />
          💵 Efectivo
        </label>
        <label>
          <input
            type="radio"
            name="metodo"
            value="qr"
            checked={metodo === "qr"}
            onChange={(e) => setMetodo(e.target.value)}
          />
          📱 Código QR
        </label>
        <label>
          <input
            type="radio"
            name="metodo"
            value="tarjeta"
            checked={metodo === "tarjeta"}
            onChange={(e) => setMetodo(e.target.value)}
          />
          💳 Tarjeta
        </label>
      </div>

      <div className="pago-buttons">
        <button className="btn-volver" onClick={() => navigate("envio")}>
          🔙 Volver
        </button>
        <button className="btn-confirmar" onClick={() => navigate("confirmacion")}>
          ✅ Confirmar Pedido
        </button>
      </div>
    </div>
  );
}

export default PagoView;
