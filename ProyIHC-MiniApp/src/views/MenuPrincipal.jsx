import { useEffect } from "react";
import "./MenuPrincipal.css";
import Card from "../Components/Card/Card.jsx";
import Header from "../Components/Header/Header.jsx";
import kingLogo from "../images/kingLogo.jpg";

import cartIcon from "../images/cartLogo.png";
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
      <Header
        title="Menú Principal"
        cartItems={cartItems}
        navigate={navigate}
        showCart={true}
        
      />


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
