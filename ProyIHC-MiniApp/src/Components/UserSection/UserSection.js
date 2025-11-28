import React from "react";
import "./UserSection.css";

function UserSection({ cartItems, subtotal }) {
  const totalItems = cartItems.reduce((acc, item) => acc + item.quantity, 0);
  const shipping = 5.0;
  const total = subtotal + shipping;

  return (
    <div className="user-section">
      <h3>Información de Envío</h3>
      <p>Total de productos: {totalItems}</p>
      <p>Subtotal: ${subtotal.toFixed(2)}</p>
      <p>Envío: ${shipping.toFixed(2)}</p>
      <p>Total: ${total.toFixed(2)}</p>
      <p>Dirección de envío: Calle Falsa 123, Ciudad, País</p>
      <button className="finalizar-btn" onClick={() => alert("Pedido finalizado!")}>
        Finalizar Pedido
      </button>
    </div>
  );
}

export default UserSection;
