// src/Views/CarritoView.jsx
import React from "react";
import "./CarritoView.css";
import Button from "../Components/Button/Button.jsx";

function CarritoView({ cartItems, setCartItems, navigate }) {
  const onAdd = (food) => {
    const exist = cartItems.find((x) => x.id === food.id);
    if (exist) {
      setCartItems(
        cartItems.map((x) =>
          x.id === food.id ? { ...exist, quantity: exist.quantity + 1 } : x
        )
      );
    } else {
      setCartItems([...cartItems, { ...food, quantity: 1 }]);
    }
  };

  const onRemove = (food) => {
    const exist = cartItems.find((x) => x.id === food.id);
    if (exist.quantity === 1) {
      setCartItems(cartItems.filter((x) => x.id !== food.id));
    } else {
      setCartItems(
        cartItems.map((x) =>
          x.id === food.id ? { ...exist, quantity: exist.quantity - 1 } : x
        )
      );
    }
  };

  const onClearCart = () => setCartItems([]);

  const subtotal = cartItems.reduce((acc, item) => acc + item.price * item.quantity, 0);

  return (
    <div className="carrito-container">
      <div className="carrito-header">
        <h2>🛒 Tu Carrito</h2>
        <button className="btn-volver" onClick={() => navigate("menu")}>
          Volver al Menú
        </button>
      </div>

      {cartItems.length === 0 ? (
        <p className="empty-cart">Tu carrito está vacío 😔</p>
      ) : (
        <>
          <div className="cart-list">
            {cartItems.map((item) => (
              <div key={item.id} className="cart-item">
                <img src={item.Image} alt={item.title} className="cart-image" />
                <div className="cart-info">
                  <h3>{item.title}</h3>
                  <p>Precio : {item.price} Bs</p>
                  <div className="cart-actions">
                    <Button title="-" type="remove" onClick={() => onRemove(item)} />
                    <span>{item.quantity}</span>
                    <Button title="+" type="add" onClick={() => onAdd(item)} />
                  </div>
                  <p>Total: {(item.price * item.quantity).toFixed(2)} Bs</p>
                </div>
              </div>
            ))}
          </div>

          <div className="cart-footer">
            <h3>Subtotal: {subtotal.toFixed(2)} Bs</h3>
            <div className="cart-buttons">
              <button className="btn-clear" onClick={onClearCart}>
                🗑️ Vaciar carrito
              </button>
              <button className="btn-pay" onClick={() => navigate("envio")}>💳 Finalizar pedido</button>

            </div>
          </div>
        </>
      )}
    </div>
  );
}

export default CarritoView;
