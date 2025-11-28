// src/Components/Cart/CartItem.js
import React from "react";
import "./CartItem.css"; // opcional

function CartItem({ item, onRemove }) {
  return (
    <div className="cart-item">
      <span>{item.title} x {item.quantity}</span>
      <button onClick={() => onRemove(item)}>-</button>
    </div>
  );
}

export default CartItem;
