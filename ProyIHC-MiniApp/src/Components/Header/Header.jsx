import React from "react";
import "./Header.css";

import kingLogo from "../../images/kingLogo.jpg";
import cartIcon from "../../images/cartLogo.png";

function Header({
  title,
  cartItems = [],
  navigate,
  showCart = true,
  showBack = false,
  onBack
}) {
  const totalItems = cartItems.reduce(
    (sum, item) => sum + item.quantity,
    0
  );

  return (
    <header className="menu-header-new">

      {/* LOGO SIEMPRE A LA IZQUIERDA */}
      <img src={kingLogo} alt="Logo" className="menu-logo-new" />

      {/* TÍTULO CENTRADO */}
      <h1 className="menu-header-title">{title}</h1>

      {/* LADO DERECHO: BACK O CARRITO */}
      {showBack ? (
        <button
          className="menu-back-btn"
          onClick={onBack || (() => navigate("menu"))}
        >
          ⬅
        </button>
      ) : showCart ? (
        <button
          className="menu-header-cart"
          onClick={() => navigate("carrito")}
        >
          <img src={cartIcon} className="menu-cart-icon" alt="Cart" />

          {totalItems > 0 && (
            <div className="menu-cart-badge-new">{totalItems}</div>
          )}
        </button>
      ) : (
        // Mantener simetría si no hay back ni cart
        <div style={{ width: "58px" }}></div>
      )}
    </header>
  );
}

export default Header;
