// src/Views/MenuPrincipal.jsx
import { useEffect } from "react";
import "./MenuPrincipal.css";
import Card from "../Components/Card/Card.jsx";
import kingLogo from "../images/kingLogo.jpg";
import { getData } from "../db/db.js";
const foods = getData();

const tele = window.Telegram.WebApp;

function MenuPrincipal({ cartItems, setCartItems, navigate }) {
  useEffect(() => {
    tele.ready();
  }, []);

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

  return (
    <div className="menu-container">
      <header className="menu-header">
        <img src={kingLogo} alt="King Logo" className="logo" />
        <h1>Ordenar Comida</h1>
      </header>

      {/* Botón para ir al carrito */}
      <button className="btn-carrito" onClick={() => navigate("carrito")}>
        🛒 Ver carrito ({cartItems.length})
      </button>

      <div className="cards__container">
        {foods.map((food) => (
          <Card
            key={food.id}
            food={food}
            onAdd={onAdd}
            onRemove={onRemove}
            count={
              cartItems.find((item) => item.id === food.id)?.quantity || 0
            } // Sincroniza el contador con carrito
          />
        ))}
      </div>
    </div>
  );
}

export default MenuPrincipal;
