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
    <div className="menu-container-new">

      {/* HEADER estilo React Native */}
      <header className="menu-header-new">
        <img src={kingLogo} alt="King Logo" className="menu-logo-new" />
        <h1 className="menu-header-title">KingsFoods_Express</h1>

        <button
          className="menu-header-cart"
          onClick={() => navigate("carrito")}
        >
          🛒
          {cartItems.length > 0 && (
            <div className="menu-cart-badge-new">
              {cartItems.reduce((sum, item) => sum + item.quantity, 0)}
            </div>
          )}
        </button>
      </header>

      {/* GRID DE PRODUCTOS */}
      <div className="cards-container-new">
        {foods.map((food) => (
          <Card
            key={food.id}
            food={food}
            onAdd={onAdd}
            onRemove={onRemove}
            count={cartItems.find((item) => item.id === food.id)?.quantity || 0}
          />
        ))}
      </div>
    </div>
  );
}

export default MenuPrincipal;
