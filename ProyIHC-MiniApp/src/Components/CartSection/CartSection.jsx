import React from "react";
import CartItem from "../Cart/CartItem";
import "./CartSection.css";

function CartSection({ cartItems, onAdd, onRemove, clearCart }) {
  if (cartItems.length === 0) return <p>Tu carrito está vacío</p>;

  return (
    <div className="cart-section">
      <h3>Carrito</h3>
      {cartItems.map((item) => (
        <CartItem key={item.id} item={item} onAdd={onAdd} onRemove={onRemove} />
      ))}
      <button className="clear-cart-btn" onClick={clearCart}>
        Vaciar Carrito
      </button>
    </div>
  );
}

export default CartSection;
