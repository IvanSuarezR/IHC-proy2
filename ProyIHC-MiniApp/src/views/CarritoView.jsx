import React from "react";
import "./CarritoView.css";
import kingLogo from "../images/kingLogo.jpg";
/*import cartIcon from "../images/cartLogo.png";*/

import Button from "../Components/Button/Button.jsx";
import Header from "../Components/Header/Header.jsx";

function CarritoView({ cartItems, setCartItems, navigate }) {

  const onAdd = (food) => {
    const exist = cartItems.find((x) => x.id === food.id);
    if (exist) {
      setCartItems(
        cartItems.map((x) =>
          x.id === food.id
            ? { ...exist, quantity: exist.quantity + 1 }
            : x
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
          x.id === food.id
            ? { ...exist, quantity: exist.quantity - 1 }
            : x
        )
      );
    }
  };

  const onClearCart = () => setCartItems([]);

  const subtotal = cartItems.reduce(
    (acc, item) => acc + item.price * item.quantity,
    0
  );

  return (
    <div className="cart-container-new">
      <Header
        title="Tu Pedido"
        cartItems={cartItems}
        navigate={navigate}
        showCart={false}
        showBack={true}
        onBack={() => navigate("menu")}
      />


      {/* CARRITO VACÍO */}
      {cartItems.length === 0 ? (
        <p className="empty-cart-new">Tu carrito está vacío 😔</p>
      ) : (
        <>
          {/* LISTA */}
          <div className="cart-card-new">

            {cartItems.map((item) => (
              <div key={item.id} className="cart-item-new">

                {/* Imagen */}
                <img
                  src={item.Image}
                  alt={item.title}
                  className="cart-img-new"
                />

                {/* Info */}
                <div className="cart-info-new">
                  <div className="cart-title-new">{item.title}</div>
                  <div className="cart-price-new">{item.price} Bs</div>
                </div>

                {/* Cantidad */}
                <div className="cart-qty-new">
                  <button onClick={() => onRemove(item)}>-</button>
                  <span>{item.quantity}</span>
                  <button onClick={() => onAdd(item)}>+</button>
                </div>

                {/* Eliminar */}
                <button
                  className="cart-remove-new"
                  onClick={() => setCartItems(cartItems.filter((x) => x.id !== item.id))}
                >
                  Quitar
                </button>

              </div>
            ))}

            {/* RESUMEN */}
            <div className="cart-summary-new">
              <div className="summary-row">
                <span>Subtotal</span>
                <span>{subtotal.toFixed(2)} Bs</span>
              </div>

              <div className="summary-row total-row">
                <span>Total</span>
                <span>{subtotal.toFixed(2)} Bs</span>
              </div>
            </div>

            {/* BOTÓN FINALIZAR */}
            <button className="btn-checkout-new" onClick={() => navigate("envio")}>
              Finalizar pedido
            </button>

            {/* BOTONES INFERIORES */}
            <div className="cart-bottom-buttons">
              <button className="btn-back-new" onClick={() => navigate("menu")}>
                Volver
              </button>
              <button className="btn-remove-all-new" onClick={onClearCart}>
                Vaciar carrito
              </button>
            </div>

          </div>
        </>
      )}
    </div>
  );
}

export default CarritoView;
